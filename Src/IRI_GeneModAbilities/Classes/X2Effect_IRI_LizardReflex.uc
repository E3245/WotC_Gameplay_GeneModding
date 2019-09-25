class X2Effect_IRI_LizardReflex extends X2Effect_PersistentStatChange config(GeneMods);

var config bool TriggerOncePerTurn;
var config bool ForceMoveSoldier;
var config bool ENABLE_LOGGING;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'IRI_GeneMod_LizardReflex_Flyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted, , UnitState);

	super.RegisterForEvents(EffectGameState);
}

function bool ChangeHitResultForTarget(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, bool bIsPrimaryTarget, const EAbilityHitResult CurrentResult, out EAbilityHitResult NewHitResult)
{ 
	local XComGameState_Ability	LizardReflexAbilityState;
	local UnitValue				ReflexValue;
	local X2EventManager		EventMgr;

	`LOG("Lizard Reflex -> Attack against: " @ TargetUnit.GetFullName() @ ", hit result: " @ CurrentResult, default.ENABLE_LOGGING, 'GENEMODS');
	
	//	Trigger only if Unit Value is not already present.
	TargetUnit.GetUnitValue('IRI_LizardReflex_Value', ReflexValue);

	if (default.TriggerOncePerTurn && ReflexValue.fValue != 0)
	{
		`LOG("Lizard Reflex -> Already triggered this turn, exiting.", default.ENABLE_LOGGING, 'GENEMODS');
		return false;
	}

	if (CurrentResult == eHit_Graze)	//	only affects attacks that would've been dodges.
	{
		`LOG("Lizard Reflex -> Changing hit result.", default.ENABLE_LOGGING, 'GENEMODS');

		//	Grant an action point and force the soldier to move.
		if (default.ForceMoveSoldier && TargetUnit.ActionPoints.Length == 0) // a fuzzy check to ensure the shot happens during enemy turn. weird thing happens when running overwatch.
		{
			TargetUnit.ActionPoints.AddItem('move');
			TargetUnit.AutoRunBehaviorTree('IRI_LizardMove', 1, `XCOMHISTORY.GetCurrentHistoryIndex() + 1, true);
		}
		//	Put a unit value on the soldier so that this effect doesn't trigger again this turn.
		if (default.TriggerOncePerTurn)
			TargetUnit.SetUnitFloatValue('IRI_LizardReflex_Value', 1, eCleanup_BeginTurn);

		//	Trigger flyover
		EventMgr = `XEVENTMGR;
		LizardReflexAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		EventMgr.TriggerEvent('IRI_GeneMod_LizardReflex_Flyover', LizardReflexAbilityState, TargetUnit);

		//	Change hit result
		NewHitResult = eHit_LightningReflexes;
		return true;
	}
	`LOG("Lizard Reflex -> Keeping hit result.", default.ENABLE_LOGGING, 'GENEMODS');
	return false; 
}