class X2Effect_SuperCompensation extends X2Effect_Persistent config(GeneMods);

//	The SuperCompensation part of this ability is copied from RPGO, which copied it from LW2's X2Effect_ReducedRecoveryTime
//	If the soldier was damaged below a certain THRESHOLD during the mission, 
//	it will increase soldier's Recovery Time if the lowest HP they had during the mission was >1, and increase Max HP by 1.

//	The Adaptation part of the ability is all new. It stores the list of Unit Values on the soldier which is used to determine soldier's accumulated
//	resistance to certain damage types. Resistance goes up each time the soldier takes damage from a certain effect.
//	We don't reduce damage below 1.

var config bool SUPERCOMPENSATION_ENABLE_LOGGING;

var config float SUPERCOMPENSATION_HEALTH_THRESHOLD;
var config int SUPERCOMPENSATION_HEALTH_BONUS;
var config int SUPERCOMPENSATION_EXTRA_HEALTH_RECOVERY;

var config int ADAPTATION_DAMAGE_REDUCTION;

struct AdaptationDamageReductionStruct
{
	var name DamageType;
	var float Resistance;
};

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local Object				EffectObj;
	local X2EventManager		EventMgr;
	local XComGameState_Unit	SourceUnitState;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	SourceUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	// Remove the default UnitRemovedFromPlay registered by XComGameState_Effect. This is necessary so we can
	// suppress the usual behavior of the effects being removed when a unit evacs. We can't process field surgeon
	// at that time because we could evac a wounded unit and then have the surgeon get killed on a later turn. We
	// need to wait until the mission ends and then process this effect.

	//	Iridar: this problem doesn't apply with SuperCompensation, since it's an individual ability, but I'm afraid of changing anything.
	//	there are no downsides to keeping the original implementation.
	EventMgr.UnRegisterFromEvent(EffectObj, 'UnitRemovedFromPlay');
	EventMgr.RegisterForEvent(EffectObj, 'UnitTakeEffectDamage', Adaptation_Listener, ELD_OnStateSubmitted,, SourceUnitState);
	EventMgr.RegisterForEvent(EffectObj, 'IRI_GeneMod_Adaptation_Flyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, SourceUnitState);
}

//	================================
//	SUPERCOMPENSATION
//	================================
//	 This function is triggered from X2EventListener_GeneMods at the end of tactical mission.
function ApplySupercompensation(XComGameState_Effect EffectState, XComGameState_Unit OrigUnitState, XComGameState NewGameState)
{
	local XComGameState_Unit		UnitState;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(OrigUnitState.ObjectID));
	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', OrigUnitState.ObjectID));
		NewGameState.AddStateObject(UnitState);
	}

	`LOG("SuperCompensation triggered on:" @ UnitState.GetFullName(), default.SUPERCOMPENSATION_ENABLE_LOGGING, 'GENEMODS');
	`LOG("Lowest HP:" @ UnitState.LowestHP @ "Max HP:" @ UnitState.GetMaxStat(eStat_HP), default.SUPERCOMPENSATION_ENABLE_LOGGING, 'GENEMODS');
	`LOG("Unit threshold" @ UnitState.LowestHP / UnitState.GetMaxStat(eStat_HP) @ "vs" @ default.SUPERCOMPENSATION_HEALTH_THRESHOLD, default.SUPERCOMPENSATION_ENABLE_LOGGING, 'GENEMODS');

	//	Iridar: SuperCompensation should work even if the unit was extracted unconscious or bleeding out,
	//	as long as the unit is alive, you should get the benefit. 
	if(UnitState == none) { return; }
	if(UnitState.IsDead()) { return; }
	//if(UnitState.IsBleedingOut()) { return; }

	// Note: Only test lowest HP here: CurrentHP cannot be trusted in UnitEndedTacticalPlay because
	// armor HP may have already been removed, but we have not yet invoked the EndTacticalHealthMod adjustment.
	if(UnitState.LowestHP / UnitState.GetMaxStat(eStat_HP) <= default.SUPERCOMPENSATION_HEALTH_THRESHOLD)
	{
		`LOG("Unit is valid.", default.SUPERCOMPENSATION_ENABLE_LOGGING, 'GENEMODS');
	
		UnitState.SetBaseMaxStat(eStat_HP, UnitState.GetMaxStat(eStat_HP) + default.SUPERCOMPENSATION_HEALTH_BONUS);
		`LOG("New Max HP:" @ UnitState.GetMaxStat(eStat_HP), default.SUPERCOMPENSATION_ENABLE_LOGGING, 'GENEMODS');

		//	Iridar: Reduce Unit's Lowest HP to increase recovery time.
		UnitState.LowestHP += default.SUPERCOMPENSATION_EXTRA_HEALTH_RECOVERY;

		// Iridar: clamp it just in case?
		if (UnitState.LowestHP <= 0) UnitState.LowestHP = 0;

		`LOG("New Lowest HP:" @ UnitState.LowestHP, default.SUPERCOMPENSATION_ENABLE_LOGGING, 'GENEMODS');
	}
}

//	================================
//	ADAPTATION
//	================================

function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, optional XComGameState NewGameState) 
{ 
	local XComGameState_Unit		UnitState;
	local array<name>				DamageTypesArray;
	local float DamageModifier;
	local int i;

	if (CurrentDamage == 0) return 0;

	UnitState = XComGameState_Unit(TargetDamageable);
	WeaponDamageEffect.GetEffectDamageTypes(NewGameState, AppliedData, DamageTypesArray);

	`LOG("Defending Damage Modifier for unit: " @ UnitState.GetFullName(), default.SUPERCOMPENSATION_ENABLE_LOGGING, 'GENEMODS');

	for (i = 0; i < DamageTypesArray.Length; i++)
	{
		if (DamageTypesArray[i] != 'None')
		{
			`LOG("Getting modifier for Damage Type: " @ DamageTypesArray[i] @ ":" @ GetAdaptationDamageReduction(UnitState, DamageTypesArray[i]), default.SUPERCOMPENSATION_ENABLE_LOGGING, 'GENEMODS');
			DamageModifier -= GetAdaptationDamageReduction(UnitState, DamageTypesArray[i]);
		}
	}
	`LOG("CurrentDamage: " @ CurrentDamage @ "Modified damage" @ CurrentDamage + DamageModifier, default.SUPERCOMPENSATION_ENABLE_LOGGING, 'GENEMODS');

	//	Round accumulated damage reduction upwards. Since DamageModifier is a negative value, it should round it towards the nearest positive value.
	//	i.e.g FCeil(-5.75) = -5;
	DamageModifier = FCeil(DamageModifier);

	//	If accumulated Damage Reduction is bigger than damage received, make sure we take at least 1 damage from the effect.
	if (Abs(DamageModifier) >= CurrentDamage)
	{
		DamageModifier = -1 * (CurrentDamage - 1);
	}

	return DamageModifier; 
}

static function float GetAdaptationDamageReduction(XComGameState_Unit UnitState, name DamageType)
{
	local UnitValue UV;

	if (UnitState.GetUnitValue(Name(DamageType $ '_IRI_GeneMod_Adaptation'), UV))
	{
		return UV.fValue;
	}
	else return 0;
}

static function SetAdaptationDamageReduction(XComGameState_Unit UnitState, name DamageType, float DamageReduction)
{
	UnitState.SetUnitFloatValue(Name(DamageType $ '_IRI_GeneMod_Adaptation'), DamageReduction, eCleanup_Never);
}



static function EventListenerReturn Adaptation_Listener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit			UnitState;
	local DamageResult					DmgResult;
	local float							DamageReduction;
	local X2Effect_ApplyWeaponDamage	DamageEffect;
	local array<name>					DamageTypesArray;
	local X2EventManager				EventMgr;
	local XComGameState_Ability			AbilityState;
	local bool							bTriggerFlyover;
	local int i;

	UnitState = XComGameState_Unit(EventSource);

	`LOG("Unit take effect damage: " @ UnitState.GetFullName(), default.SUPERCOMPENSATION_ENABLE_LOGGING, 'GENEMODS');

	if (UnitState != none)
	{
		//	Get information about the last instance of damage received by the unit
		DmgResult = UnitState.DamageResults[UnitState.DamageResults.Length - 1];


		//	The DmgResult.DamageTypes is optional and doesn't always get filled
		/*
		`LOG("Looking for explicit Damage Types: " @ DmgResult.DamageTypes.Length,, 'GENEMODS');
		for (i = 0; i < DmgResult.DamageTypes.Length; i++)
		{
			if (DmgResult.DamageTypes[i] != 'None')
			{
				DamageReduction = GetAdaptationDamageReduction(UnitState, DmgResult.DamageTypes[i]);
				`LOG("Getting modifier for Damage Type: " @ DmgResult.DamageTypes[i] @ ":" @ DamageReduction,, 'GENEMODS');
				DamageReduction += 1;
				`LOG("Setting modifier for Damage Type: " @ DmgResult.DamageTypes[i] @ "to:" @ DamageReduction,, 'GENEMODS');
				SetAdaptationDamageReduction(UnitState, DmgResult.DamageTypes[i], DamageReduction);
			}
		}*/

		DamageEffect = X2Effect_ApplyWeaponDamage(class'X2Effect'.static.GetX2Effect(DmgResult.SourceEffect.EffectRef));
		if (DamageEffect != none)
		{	
			DamageEffect.GetEffectDamageTypes(GameState, DmgResult.SourceEffect, DamageTypesArray);

			`LOG("Looking for Effect Damage Types: " @ DamageTypesArray.Length, default.SUPERCOMPENSATION_ENABLE_LOGGING, 'GENEMODS');
			for (i = 0; i < DamageTypesArray.Length; i++)
			{
				if (DamageTypesArray[i] != 'None')
				{
					DamageReduction = GetAdaptationDamageReduction(UnitState, DamageTypesArray[i]);
					`LOG("Getting modifier for Damage Type: " @ DamageTypesArray[i] @ ":" @ DamageReduction, default.SUPERCOMPENSATION_ENABLE_LOGGING, 'GENEMODS');
					DamageReduction += default.ADAPTATION_DAMAGE_REDUCTION;
					`LOG("Setting modifier for Damage Type: " @ DamageTypesArray[i] @ "to:" @ DamageReduction, default.SUPERCOMPENSATION_ENABLE_LOGGING, 'GENEMODS');
					SetAdaptationDamageReduction(UnitState, DamageTypesArray[i], DamageReduction);
					bTriggerFlyover = true;
				}
			}
		}

		if (bTriggerFlyover)
		{
			AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(UnitState.FindAbility('IRI_Adaptation').ObjectID));
			if (AbilityState != none)
			{
				EventMgr = `XEVENTMGR;
				EventMgr.TriggerEvent('IRI_GeneMod_Adaptation_Flyover', AbilityState, UnitState, GameState);
			}
		}
	}

	return ELR_NoInterrupt;
}

DefaultProperties
{
	EffectName="IRI_SuperCompensation"
	DuplicateResponse=eDupe_Ignore
}