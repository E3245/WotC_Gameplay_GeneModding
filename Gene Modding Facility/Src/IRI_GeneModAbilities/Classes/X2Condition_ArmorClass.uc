class X2Condition_ArmorClass extends X2Condition;

var name AllowedClass;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Item ItemState;
	local XComGameState_Unit UnitState;
	local X2ArmorTemplate ArmorTemplate;

	UnitState = XComGameState_Unit(kTarget);
	if (UnitState == none)	return 'AA_NotAUnit';

	ItemState = UnitState.GetItemInSlot(eInvSlot_Armor);

	if (ItemState != none) ArmorTemplate = X2ArmorTemplate(ItemState.GetMyTemplate());

	if (ArmorTemplate != none && ArmorTemplate.ArmorClass == AllowedClass) return 'AA_Success';

	return 'AA_AbilityUnavailable';
}