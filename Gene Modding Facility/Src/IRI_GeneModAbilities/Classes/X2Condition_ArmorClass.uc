class X2Condition_ArmorClass extends X2Condition;

var name AllowedClass;

function bool CanEverBeValid(XComGameState_Unit SourceUnit, bool bStrategyCheck)
{
	local XComGameState_Item ItemState;
	local X2ArmorTemplate ArmorTemplate;

	ItemState = SourceUnit.GetItemInSlot(eInvSlot_Armor);

	if (ItemState != none) ArmorTemplate = X2ArmorTemplate(ItemState.GetMyTemplate());

	if (ArmorTemplate != none && ArmorTemplate.ArmorClass == AllowedClass) return true;

	return false;
}