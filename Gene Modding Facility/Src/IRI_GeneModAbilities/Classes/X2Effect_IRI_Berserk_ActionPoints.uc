class X2Effect_IRI_Berserk_ActionPoints extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'IRI_GeneMod_BerserkFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted, , UnitState);
}

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{
	local X2EventManager		EventMgr;
	local XComGameState_Ability AbilityState;
	local int i;

	//`LOG("Post ability cost paid for: " @ SourceUnit.GetFullName() @ "AP: " @ SourceUnit.ActionPoints.Length @ "pre cost AP: " @ PreCostActionPoints.Length,, 'GENEMODS');

	//	If the unit spent an Action Point on something
	if (SourceUnit.ActionPoints.Length != PreCostActionPoints.Length)
	{
		//	Restore all action points
		SourceUnit.ActionPoints = PreCostActionPoints;
					
		//	Take away one standard action point
		for (i = 0; i < SourceUnit.ActionPoints.Length; i++)
		{
			if (SourceUnit.ActionPoints[i] == class'X2CharacterTemplateManager'.default.StandardActionPoint)
			{
				SourceUnit.ActionPoints.Remove(i, 1);
				break;
			}
		}	

		//`LOG("Ap after restoring and removing one: " @ SourceUnit.ActionPoints.Length,, 'GENEMODS');
		//	Implementing it this way will mean MovementOnly action points will be ignored; standard move will still cost a standard action point, but I don't care about it.
		//	Soldier is berserk, only natural that standard rules won't apply.		

		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		if (AbilityState != none)
		{
			//	Trigger flyover
			EventMgr = `XEVENTMGR;
			EventMgr.TriggerEvent('IRI_GeneMod_BerserkFlyover', AbilityState, SourceUnit, NewGameState);
		}
		return true;
	}
	return false;
}

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_Berserk_ActionPoints_Effect"
}