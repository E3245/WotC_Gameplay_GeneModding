//Class that fixes all of the ListItems so they appear proper on UI screens that are not children of UISimpleCommodity

class UIInventory_ListItem_Custom extends UIInventory_ListItem;

// Set bDisabled variable
simulated function RealizeDisabledState()
{
	local bool bIsDisabled;
	local string Message;
	local UICommodity_GeneModUpgrade GMCommScreen;
	local XComGameState_Unit UnitState;
	local int GMIndex;

	if( ClassIsChildOf(Screen.Class, class'UICommodity_GeneModUpgrade') )
	{
		//Grab Screen
		GMCommScreen = UICommodity_GeneModUpgrade(Screen);
		//Initialize UnitState
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GMCommScreen.m_UnitRef.ObjectID));
		//Grab Current Commodity
		GMIndex = GMCommScreen.GetGeneModIndexFromCommodity(ItemComodity);

		//Disable if any of these conditions are met
		bIsDisabled = !GMCommScreen.MeetsItemReqs(ItemComodity) || 
		GMCommScreen.IsItemPurchased(GMCommScreen.arrGeneMod_Master[GMIndex]) || 
		GMCommScreen.CheckIfPurchasedCategory(GMCommScreen.arrGeneMod_Master[GMIndex]);

		//We have to do this check separately
		//Don't do it unless the bool is still false
		if (!bIsDisabled)
		{
			Message = GMCommScreen.arrGeneMod_Master[GMIndex].GetGMPreventedByAugmentationMessage(UnitState);
			if (Message != "")
				bIsDisabled = true;
		}
	}

	SetDisabled(bIsDisabled);
}

//simulated function RealizeGoodState()
//{
//	local UICommodity_GeneModUpgrade GMCommScreen;
//	local int CommodityIndex;
//
//	if( ClassIsChildOf(Screen.Class, class'UICommodity_GeneModUpgrade') )
//	{
//		GMCommScree = UISimpleCommodityScreen(Screen);
//		CommodityIndex = GMCommScreen.GetItemIndex(ItemComodity);
//		ShouldShowGoodState(GMCommScreen.ShouldShowGoodState(CommodityIndex));
//	}
//}

// Set bBad variable
simulated function RealizeBadState()
{
	local bool bBad;
	local UICommodity_GeneModUpgrade GMCommScreen;

	if( ClassIsChildOf(Screen.Class, class'UICommodity_GeneModUpgrade') )
	{
		GMCommScreen = UICommodity_GeneModUpgrade(Screen);
//		CommodityIndex = GMCommScreen.GetItemIndex(ItemComodity);
		bBad = !GMCommScreen.CanAffordItem(ItemComodity);
	}

	SetBad(bBad);
}

//simulated function RealizeAttentionState()
//{
//	local UISimpleCommodityScreen CommScreen;
//	local int CommodityIndex;
//
//	if( ClassIsChildOf(Screen.Class, class'UICommodity_GeneModUpgrade') )
//	{
//		GMCommScreen = UICommodity_GeneModUpgrade(Screen);
//		CommodityIndex = GMCommScreen.GetItemIndex(ItemComodity);
//		NeedsAttention( GMCommScreen.NeedsAttention(CommodityIndex), UseObjectiveIcon() );
//	}
//}