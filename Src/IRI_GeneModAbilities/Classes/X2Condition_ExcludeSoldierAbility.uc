class X2Condition_ExcludeSoldierAbility extends X2Condition;

// This condition will fail if the target unit has the specified ability.

var name ExcludeAbility;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(kTarget);

	//`LOG("Exclude ability condition triggered against: " @ UnitState.GetFullName() @ "they have ability: " @ UnitState.HasSoldierAbility(ExcludeAbility),, 'GENEMOD');

	if (UnitState != none && UnitState.HasSoldierAbility(ExcludeAbility))
	{
		return 'AA_UnitIsImmune';
	}
	return 'AA_Success';
}