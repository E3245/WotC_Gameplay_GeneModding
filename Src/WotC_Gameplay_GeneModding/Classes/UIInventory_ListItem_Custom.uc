//Class that fixes all of the ListItems so they appear proper on UI screens that are not children of UISimpleCommodity

class UIInventory_ListItem_Custom extends UIInventory_ListItem;

// Set bDisabled variable
simulated function RealizeDisabledState()
{
	local bool bIsDisabled;
	local UICommodity_GeneModUpgrade GMCommScreen;
	local int GMIndex;

	if( ClassIsChildOf(Screen.Class, class'UICommodity_GeneModUpgrade') )
	{
		GMCommScreen = UICommodity_GeneModUpgrade(Screen);
		GMIndex = GMCommScreen.GetGeneModIndexFromCommodity(ItemComodity);
		bIsDisabled = !GMCommScreen.MeetsItemReqs(ItemComodity) || GMCommScreen.IsItemPurchased(GMCommScreen.arrGeneMod_Master[GMIndex]) || GMCommScreen.CheckIfPurchasedCategory(GMCommScreen.arrGeneMod_Master[GMIndex]);
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