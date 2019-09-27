class UICommodity_GeneModUpgrade extends UIScreen;

struct Tracker
{
	var int ListID;
	var int GeneModID;
	var int CommodityID;	
};

var array<X2GeneModTemplate>			m_arrUnlocks;

var X2GeneModTemplate					SelectedGeneMod;

var StateObjectReference				m_UnitRef; // set in XComHQPresentationLayer
var StateObjectReference				m_StaffSlotRef; // set in XComHQPresentationLayer

var localized string					m_strGMDialogNegDisabledTitle;
var localized string					m_strGMDialogNegDisabledText;

var localized string					m_strGMDialogNegEnabledTitle;
var localized string					m_strGMDialogNegEnabledText;

var localized string					m_strSoldierStatus;
var localized string					m_strSoldierTimeLabel;

//Borrowed from UISimpleCommodity and UIInventory

var	XComGameStateHistory				History;
var	XComGameState_HeadquartersXCom		XComHQ;
var XComGameState_Unit					UnitState;

var name								DisplayTag;
var name								CameraTag;

var int									ConfirmButtonX;
var int									ConfirmButtonY;

var EUIState							m_eMainColor;


//Flag for type of info to fill in right info card. 
var bool								bSelectFirstAvailable; 

var localized string					m_strTitle;
var localized string					m_strSubTitle;
var localized string					m_strConfirmButtonLabel;
var localized string					m_strInventoryLabel;
var localized string					m_strSellLabel;
var localized string					m_strTotalLabel;
var localized string					m_strEmptyListTitle;
var localized string					m_strBuy;
var localized string					m_strRestricted;

var localized string					m_strGMCat1;
var localized string					m_strGMCat2;
var localized string					m_strGMCat3;
var localized string					m_strGMCat4;
var localized string					m_strGMCat5;

var UIX2PanelHeader						TitleHeader;

var UIItemCard							ItemCard;
var UIArmory_LoadoutItemTooltip			StatTooltip;

//This array need several blank templates to be in the correct order
var array<X2GeneModTemplate>			arrGeneMod_Master;
var array<Commodity>					arrGeneMod_Comm;
var array<Tracker>						arrTracker;
var int									currentInterator;

var UIPanel								ListContainer; // contains all controls bellow
var UIList								List;
var UIPanel								ListBG;
var int									iSelectedItem;
var UIScrollingText						TitleControl;
var UIStatList							StatListBasic; 
var UIPanel								StatArea;

// Set this to specify how long camera transition should take for this screen
var float								OverrideInterpTime;

//-------------- EVENT HANDLING --------------------------------------------------------

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(m_UnitRef.ObjectID));

	m_arrUnlocks.Remove(0, m_arrUnlocks.Length);

	//Set iterator to 0
	currentInterator = 0;
	BuildScreen();
	UpdateList();

	UpdateNavHelp();
}


simulated function BuildScreen()
{
	local UIPanel Line; 

	TitleHeader = Spawn(class'UIX2PanelHeader', self);
	TitleHeader.InitPanelHeader('TitleHeader', m_strTitle, "");
	TitleHeader.SetHeaderWidth( 580 );
	if( m_strTitle == "")
		TitleHeader.Hide();

	ListContainer = Spawn(class'UIPanel', self).InitPanel('InventoryContainer');

	ItemCard = Spawn(class'UIItemCard', ListContainer).InitItemCard('ItemCard');

	//Small box on the upper corner
	Spawn(class'UIPanel', self).InitPanel('BGBox', class'UIUtilities_Controls'.const.MC_X2Background).SetPosition(725, 135).SetSize(560, 320);

	TitleControl = Spawn(class'UIScrollingText', self);
	TitleControl.InitScrollingText('ScrollingText', m_strSubTitle, 535, 725 + 15, 135 + 15); 
	
	Line = class'UIUtilities_Controls'.static.CreateDividerLineBeneathControl(TitleControl, none, 2 );

	StatArea = Spawn(class'UIPanel', self);
	StatArea.InitPanel('StatArea').SetPosition(725, Line.Y + 4).SetSize(535, 305 - Line.Y - 2); 

	StatListBasic = Spawn(class'UIStatList', StatArea);
	StatListBasic.InitStatList('StatListLeft', , 15, 15, StatArea.Width - 5, StatArea.Height);
//	StatListBasic.SetPanelScale(0.5);
//	StatListBasic.OnSizeRealized = OnStatListSizeRealized;

	ListBG = Spawn(class'UIPanel', ListContainer);
	ListBG.InitPanel('InventoryListBG'); 
	ListBG.bShouldPlayGenericUIAudioEvents = false;
	ListBG.Show();

	List = Spawn(class'UIList', ListContainer);
	List.InitList('inventoryListMC');
	List.bSelectFirstAvailable = bSelectFirstAvailable;
	List.bStickyHighlight = true;
	List.OnItemDoubleClicked = OnPurchaseClickedCB;
	List.OnSelectionChanged = SelectedItemChanged;
	Navigator.SetSelected(ListContainer);
	ListContainer.Navigator.SetSelected(List);

	MC.BeginFunctionOp("setItemCategory");
	MC.QueueString(m_strInventoryLabel);
	MC.EndOp();

	MC.BeginFunctionOp("setBuiltLabel");
	MC.QueueString(m_strTotalLabel);
	MC.EndOp();
	// send mouse scroll events to the list
	ListBG.ProcessMouseEvents(List.OnChildMouseEvent);

	if( bIsIn3D )
		class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, OverrideInterpTime != -1 ? OverrideInterpTime : `HQINTERPTIME);
}

//
//Item Card
//
simulated function PopulateItemCard(optional X2ItemTemplate ItemTemplate, optional StateObjectReference ItemRef)
{
	if( ItemCard != none )
	{
		if( ItemTemplate != None )
		{
			ItemCard.PopulateItemCard(ItemTemplate, ItemRef);
			ItemCard.Show();
		}
		else
			ItemCard.Hide();
	}
}

simulated function PopulateResearchCard(optional Commodity ItemCommodity, optional StateObjectReference ItemRef)
{
	ItemCard.PopulateResearchCard(ItemCommodity, ItemRef);
	ItemCard.Show();
}

simulated function SelectedItemChanged(UIList ContainerList, int ItemIndex)
{
	local UIInventory_ListItem ListItem;
	ListItem = UIInventory_ListItem(ContainerList.GetItem(ItemIndex));
	`LOG("Gene Modding | UI | SelectedItemChanged() :: Last Selected Option " $ List.SelectedIndex $ " From List", , 'WotC_Gameplay_GeneModding');
	if(ListItem != none)
	{
		PopulateResearchCard(ListItem.ItemComodity, ListItem.ItemRef);
		StatListBasic.RefreshData(GetUISummary_GeneModStats(), false); 
	}
}
//
// Nav Help
//
simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;
	NavHelp.AddBackButton(CloseScreen);
	if(`ISCONTROLLERACTIVE)
		NavHelp.AddSelectNavHelp();
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function UpdateList()
{
	local array<Commodity> arrGeneMod;

	// Well this is stupid, but I have to call PopulateData() after 
	// obtaining the list of commodities for each category to create a new UIContainerList with it's proper format
	// Each category has it's own header
	List.ClearItems();
	PopulateItemCard();

	arrGeneMod = ConvertGeneModsToCommodities('GMCat_brain');
	`log("Gene Modding | UI | UpdateList() :: Counted: " $ arrGeneMod.Length $ " Commodities for Category 1" , , 'WotC_Gameplay_GeneModding');
	if (arrGeneMod.Length > 0)
	{
		UI_CreateHeaderandList(m_strGMCat1, arrGeneMod); 
	}
	
	arrGeneMod = ConvertGeneModsToCommodities('GMCat_eyes');
	`log("Gene Modding | UI | UpdateList() :: Counted: " $ arrGeneMod.Length $ " Commodities for Category 2" , , 'WotC_Gameplay_GeneModding');
	if (arrGeneMod.Length > 0)
	{
		UI_CreateHeaderandList(m_strGMCat2, arrGeneMod); 
	}

	arrGeneMod = ConvertGeneModsToCommodities('GMCat_chest');
	`log("Gene Modding | UI | UpdateList() :: Counted: " $ arrGeneMod.Length $ " Commodities for Category 3" , , 'WotC_Gameplay_GeneModding');
	if (arrGeneMod.Length > 0)
	{
		UI_CreateHeaderandList(m_strGMCat3, arrGeneMod); 
	}

	arrGeneMod = ConvertGeneModsToCommodities('GMCat_skin');
	`log("Gene Modding | UI | UpdateList() :: Counted: " $ arrGeneMod.Length $ " Commodities for Category 4" , , 'WotC_Gameplay_GeneModding');
	if (arrGeneMod.Length > 0)
	{
		UI_CreateHeaderandList(m_strGMCat4, arrGeneMod); 
	}

	arrGeneMod = ConvertGeneModsToCommodities('GMCat_legs');
	`log("Gene Modding | UI | UpdateList() :: Counted: " $ arrGeneMod.Length $ " Commodities for Category 5" , , 'WotC_Gameplay_GeneModding');
	if (arrGeneMod.Length > 0)
	{
		UI_CreateHeaderandList(m_strGMCat5, arrGeneMod); 
	}
}

simulated function UI_CreateHeaderandList(string LocHeader, array<Commodity> arrComm)
{
    local UIInventory_HeaderListItem Header;
    local UIInventory_ListItem_Custom ListItem;
	local Commodity Template;
	local int i;

    Header = Spawn(class'UIInventory_HeaderListItem', List.ItemContainer);
	Header.InitHeaderItem(, LocHeader);
    Header.bIsNavigable = false;

	for(i = 0; i < arrComm.Length; i++)
	{
		Template = arrComm[i];
		ListItem = Spawn(class'UIInventory_ListItem_Custom', List.ItemContainer);
		ListItem.InitInventoryListCommodity(Template, , GetButtonString(i), eUIConfirmButtonStyle_Default, ConfirmButtonX, ConfirmButtonY);

		if (currentInterator <= arrTracker.Length)
		{
			arrTracker[currentInterator].ListID = List.GetItemIndex(ListItem);
			`LOG("Gene Modding | UI | UI_CreateHeaderandList() :: Assigned: " $ arrGeneMod_Master[currentInterator].GetDisplayName() $ " To List.ItemContainer Slot " $ arrTracker[currentInterator].ListID , , 'WotC_Gameplay_GeneModding');
			currentInterator++;
		}
	}

	if(List.ItemCount > 0)
	{
		List.SetSelectedIndex(1);
		PopulateResearchCard(UIInventory_ListItem(List.GetItem(1)).ItemComodity, UIInventory_ListItem(List.GetItem(1)).ItemRef);

		List.Navigator.SetSelected(List.GetItem(1));
		StatListBasic.RefreshData(GetUISummary_GeneModStats(), false ); 
	}
}

simulated function array<Commodity> ConvertGeneModsToCommodities(name category)
{
	local int iUnlock;
	local array<Commodity> arrCommodoties;
	local Commodity GMComm;
	local StrategyCost EmptyCost;
	local StrategyRequirement EmptyReq;
	local Tracker Track;
	local string sAugErrorMsg;

	m_arrUnlocks = GetUnlocks(category);
	m_arrUnlocks.Sort(SortUnlocksByPrerequisite);
	m_arrUnlocks.Sort(SortUnlocksByCost);
	m_arrUnlocks.Sort(SortUnlocksByRank);
	m_arrUnlocks.Sort(SortUnlocksByClass);
	m_arrUnlocks.Sort(SortUnlocksCanPurchase);
	m_arrUnlocks.Sort(SortUnlocksByTime);
	m_arrUnlocks.Sort(SortUnlocksPurchased);

	for (iUnlock = 0; iUnlock < m_arrUnlocks.Length; iUnlock++)
	{
		GMComm.Title = m_arrUnlocks[iUnlock].GetDisplayName();
//		GMComm.Image = m_arrUnlocks[iUnlock].GetImage();


		// If a soldier has an augmentation in a particular slot, return a message.
		sAugErrorMsg = m_arrUnlocks[iUnlock].GetGMPreventedByAugmentationMessage(UnitState);
		if (sAugErrorMsg != "")
		{
			GMComm.Title = m_strRestricted @ GMComm.Title;
			GMComm.Cost = EmptyCost;
			GMComm.Requirements = EmptyReq;
			GMComm.OrderHours = -1;
			GMComm.Desc = class'UIUtilities_Text'.static.GetColoredText(sAugErrorMsg, eUIState_Bad) $ "\n" $ m_arrUnlocks[iUnlock].GetSummary();
		} 
		else   // Iridar end
		if (IsItemPurchased(m_arrUnlocks[iUnlock])) 
		{
			GMComm.Title = class'UIItemCard'.default.m_strPurchased @ GMComm.Title;
			GMComm.Cost = EmptyCost;
			GMComm.Requirements = EmptyReq;
			GMComm.OrderHours = -1;
			GMComm.Desc = m_arrUnlocks[iUnlock].GetSummary();
		}
		else if (!IsItemPurchased(m_arrUnlocks[iUnlock]) && IsItemRestrictedByExistingMod(m_arrUnlocks[iUnlock]))
		{
			GMComm.Title = m_strRestricted @ GMComm.Title;
			GMComm.Cost = EmptyCost;
			GMComm.Requirements = EmptyReq;
			GMComm.OrderHours = -1;
			GMComm.Desc = m_arrUnlocks[iUnlock].GetSummary();
		}
		if (!IsItemPurchased(m_arrUnlocks[iUnlock]) && CheckIfPurchasedCategory(m_arrUnlocks[iUnlock]))
		{
			GMComm.Title = m_strRestricted @ GMComm.Title;
			GMComm.Cost = EmptyCost;
			GMComm.Requirements = EmptyReq;
			GMComm.OrderHours = -1;
			GMComm.Desc = m_arrUnlocks[iUnlock].GetSummary();
		}
		else if (!IsItemPurchased(m_arrUnlocks[iUnlock]))
		{
			GMComm.Cost = m_arrUnlocks[iUnlock].Cost;
			GMComm.Requirements = m_arrUnlocks[iUnlock].Requirements;
			GMComm.OrderHours = GetGMOrderDays(m_arrUnlocks[iUnlock].BaseTimeToCompletion);
			GMComm.Desc = m_arrUnlocks[iUnlock].GetSummary();
		}

		Track.GeneModID = arrTracker.Length;
		Track.CommodityID = arrTracker.Length;

		arrTracker.AddItem(Track);
		//Individual Commodities
		arrCommodoties.AddItem(GMComm);
		//Master Commodities
		arrGeneMod_Comm.AddItem(GMComm);
		arrGeneMod_Master.AddItem(m_arrUnlocks[iUnlock]);
		`LOG("Gene Modding | UI | ConvertGeneModsToCommodities() :: Assigned: " $ arrGeneMod_Master[arrGeneMod_Master.Length - 1].GetDisplayName() $ " To Master Array at Index " $ Track.GeneModID , , 'WotC_Gameplay_GeneModding');
		`log("Gene Modding | UI | ConvertGeneModsToCommodities() :: Hours Calculated for Gene Mod: " $ GMComm.OrderHours , , 'WotC_Gameplay_GeneModding');
	}

	return arrCommodoties;
}

simulated function bool IsItemPurchased(X2GeneModTemplate GeneMod)
{
	return UnitState.HasSoldierAbility(GeneMod.AbilityName);
}

function bool CheckIfPurchasedCategory(X2GeneModTemplate GeneMod)
{
	local UnitValue CurrentValue;
	local int Limit;

	`LOG("Gene Modding | UI | CheckIfPurchasedCategory() :: Checking if soldier already has a Gene Mod of category: " $ GeneMod.GeneCategory, , 'WotC_Gameplay_GeneModding');	
	Limit = MatchLimitValue(GeneMod.GeneCategory);
	UnitState.GetUnitValue(GeneMod.GeneCategory, CurrentValue);
	if (CurrentValue.fValue >= Limit)
	{
		`LOG("Gene Modding | UI | CheckIfPurchasedCategory() ::  Soldier Got Gene Mod of Category: " $ GeneMod.GeneCategory, , 'WotC_Gameplay_GeneModding');
		return true;		
	}
	`LOG("Gene Modding | UI | CheckIfPurchasedCategory() ::  Got Unit Value: " $ CurrentValue.fValue $ " of Category " $ GeneMod.GeneCategory, , 'WotC_Gameplay_GeneModding');
	return false;
}

function int MatchLimitValue(name Category)
{
	switch (Category) {
		case ('GMCat_brain'):
			return class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.GeneModLimitCat1;
			break;
		case ('GMCat_eyes'):
			return class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.GeneModLimitCat2;
			break;
		case ('GMCat_chest'):
			return class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.GeneModLimitCat3;
			break;
		case ('GMCat_skin'):
			return class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.GeneModLimitCat4;
			break;
		case ('GMCat_legs'):
			return class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.GeneModLimitCat5;
			break;
		default:
			break;
		}
}

private function bool IsItemRestrictedByExistingMod(X2GeneModTemplate GeneMod)
{
//	local X2StrategyElementTemplateManager StrategyTemplateManager;
//	local X2StrategyElementTemplate StrategyTemplate;
//	local XComGameState_Unit Unit;
//	local int i;
//	
//	StrategyTemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
//	Unit = XComGameState_Unit(History.GetGameStateForObjectID(m_UnitRef.ObjectID));
//
//	for(i = 0; i < m_arrUnlocks[ItemIndex].RestrictGeneModsIfInstalled.Length; i++)
//	{
//		StrategyTemplate = StrategyTemplateManager.FindStrategyElementTemplate(m_arrUnlocks[ItemIndex].RestrictGeneModsIfInstalled[i]);
//		if (StrategyTemplate != none)
//			if (Unit.HasSoldierAbility(X2GeneModTemplate(StrategyTemplate).AbilityName))
//				return true;
//	}
//	
	return false;
}

simulated function int GetGMOrderDays(int BaseTimeToCompletion)
{
	local int NewTime;

	NewTime = BaseTimeToCompletion * (24 * class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.DefaultGeneModOpWorkPerHour);
	return NewTime / class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.DefaultGeneModOpWorkPerHour;
}

//-----------------------------------------------------------------------------

simulated function array<X2GeneModTemplate> GetUnlocks(name Category)
{
	local X2StrategyElementTemplateManager StrategyTemplateManager;
	local array<X2StrategyElementTemplate> StrategyTemplates;
	local array<X2GeneModTemplate> UnlockTemplates;
	local int i;

	UnlockTemplates.Length = 0;

	StrategyTemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	StrategyTemplates = StrategyTemplateManager.GetAllTemplatesOfClass(class'X2GeneModTemplate');
	for(i = 0; i < StrategyTemplates.Length; i++)
	{
		if (X2GeneModTemplate(StrategyTemplates[i]).AbilityName != '')
			if (XComHQ.MeetsEnoughRequirementsToBeVisible(X2GeneModTemplate(StrategyTemplates[i]).Requirements))
				if (X2GeneModTemplate(StrategyTemplates[i]).GeneCategory == Category)
					UnlockTemplates.AddItem(X2GeneModTemplate(StrategyTemplates[i]));

	}
	return UnlockTemplates;
}


function int SortUnlocksCanPurchase(X2GeneModTemplate UnlockTemplateA, X2GeneModTemplate UnlockTemplateB)
{
	local bool CanPurchaseA, CanPurchaseB;

	CanPurchaseA = XComHQ.MeetsRequirmentsAndCanAffordCost(UnlockTemplateA.Requirements, UnlockTemplateA.Cost, XComHQ.OTSUnlockScalars);
	CanPurchaseB = XComHQ.MeetsRequirmentsAndCanAffordCost(UnlockTemplateB.Requirements, UnlockTemplateB.Cost, XComHQ.OTSUnlockScalars);
	
	if (CanPurchaseA && !CanPurchaseB)
	{
		return 1;
	}
	else if (!CanPurchaseA && CanPurchaseB)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

private function int SortUnlocksPurchased(X2GeneModTemplate UnlockTemplateA, X2GeneModTemplate UnlockTemplateB)
{
	local bool UnlockAPurchased, UnlockBPurchased;

	UnlockAPurchased = UnitState.HasSoldierAbility(UnlockTemplateA.AbilityName);
	UnlockBPurchased = UnitState.HasSoldierAbility(UnlockTemplateB.AbilityName);

	if (UnlockAPurchased && !UnlockBPurchased) // Sort all purchased upgrades to the bottom of the list
		return -1;
	else if (!UnlockAPurchased && UnlockBPurchased)
		return 1;
	else
		return 0;
}

private function int SortUnlocksByClass(X2GeneModTemplate UnlockTemplateA, X2GeneModTemplate UnlockTemplateB)
{
	local bool UnlockARequiresClass, UnlockBRequiresClass;

	UnlockARequiresClass = (UnlockTemplateA.AllowedClasses.Length > 0);
	UnlockBRequiresClass = (UnlockTemplateB.AllowedClasses.Length > 0);

	if (UnlockARequiresClass && !UnlockBRequiresClass) // Sort all class specific perks to the bottom of the list
		return -1;
	else if (!UnlockARequiresClass && UnlockBRequiresClass)
		return 1;
	else 
		return 0;
}

private function int SortUnlocksByRank(X2GeneModTemplate UnlockTemplateA, X2GeneModTemplate UnlockTemplateB)
{
	if (UnlockTemplateA.Requirements.RequiredHighestSoldierRank < UnlockTemplateB.Requirements.RequiredHighestSoldierRank)
		return 1;
	else if (UnlockTemplateA.Requirements.RequiredHighestSoldierRank > UnlockTemplateB.Requirements.RequiredHighestSoldierRank)
		return -1;
	else
		return 0;
}

private function int SortUnlocksByPrerequisite(X2GeneModTemplate UnlockTemplateA, X2GeneModTemplate UnlockTemplateB)
{
	if (UnlockTemplateA.DataName == UnlockTemplateB.RequiresExistingGeneMod)
		return 1;
	else if (UnlockTemplateA.RequiresExistingGeneMod == UnlockTemplateB.DataName)
		return -1;
	else
		return 0;
}

private function int SortUnlocksByCost(X2GeneModTemplate UnlockTemplateA, X2GeneModTemplate UnlockTemplateB)
{
	local int CostA, CostB;

	// Then sort by supply cost
	CostA = class'UIUtilities_Strategy'.static.GetCostQuantity(UnlockTemplateA.Cost, 'Supplies');
	CostB = class'UIUtilities_Strategy'.static.GetCostQuantity(UnlockTemplateB.Cost, 'Supplies');

	if (CostA < CostB)
		return 1;
	else if (CostA > CostB)
		return -1;
	else
		return 0;
}

private function int SortUnlocksByTime(X2GeneModTemplate UnlockTemplateA, X2GeneModTemplate UnlockTemplateB)
{
	local int HoursA, HoursB;

	HoursA = GetGMOrderDays(UnlockTemplateA.BaseTimeToCompletion);
	HoursB = GetGMOrderDays(UnlockTemplateB.BaseTimeToCompletion);

	if (HoursA < HoursB)
	{
		return 1;
	}
	else if (HoursA > HoursB)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

simulated function bool CanAffordItem(Commodity Item)
{
	return XComHQ.CanAffordCommodity(Item);
}

simulated function bool MeetsItemReqs(Commodity Item)
{
	return XComHQ.MeetsCommodityRequirements(Item);
}

//Given the Commodity data structure, finds the index in where it exists
simulated function int GetItemIndex(Commodity Item)
{
	local int i;
	for(i = 0; i < arrTracker.Length; i++)
	{
		if (arrGeneMod_Comm[arrTracker[i].CommodityID] == Item)
			return arrTracker[i].ListID;
	}

	return -1;
}

//Given the Commodity data structure, finds the index in where it exists
simulated function int GetGeneModIndexFromCommodity(Commodity Item)
{
	local int i;
	for(i = 0; i < arrTracker.Length; i++)
	{
		if (arrGeneMod_Comm[arrTracker[i].CommodityID] == Item)
			return arrTracker[i].GeneModID;
	}

	return -1;
}

simulated function Tracker RetrieveTrackerInfoFromListIndex(int ListIndex)
{
	local int i;
	for(i = 0; i < arrTracker.Length; i++)
	{
		if (arrTracker[i].ListID == ListIndex)
			return arrTracker[i];
	}
	
	`Redscreen("Gene modding: Failed to retrieve info of List Index " $ ListIndex);
}

//-----------------------------------------------------------------------------

simulated function OnPurchaseClickedCB(UIList kList, int itemIndex)
{
	OnPurchaseClicked();
}

simulated function OnPurchaseClicked()
{
    local TDialogueBoxData		DialogData;
	local Commodity				SelectedCommodity;	
	local string				strTitle, strText;
	local Tracker				selTracker;

	iSelectedItem = List.SelectedIndex;
	selTracker = RetrieveTrackerInfoFromListIndex(iSelectedItem);
	`LOG("Gene Modding | UI | OnPurchaseClicked() :: Picked Option " $ iSelectedItem $ " From List.ItemContainer", , 'WotC_Gameplay_GeneModding');

	SelectedGeneMod = arrGeneMod_Master[selTracker.GeneModID];
	SelectedCommodity = arrGeneMod_Comm[selTracker.CommodityID];

	if (SelectedGeneMod != none)
		`LOG("Gene Modding | UI | OnPurchasedClicked() :: Selected Gene Mod: " $ SelectedGeneMod.GetDisplayName(), , 'WotC_Gameplay_GeneModding');
	else
		`LOG("Gene Modding | UI | OnPurchasedClicked() :: Selected Gene Mod is blank!", , 'WotC_Gameplay_GeneModding');		

    if (!IsItemPurchased(SelectedGeneMod) && 
		MeetsItemReqs(SelectedCommodity) && 
		CanAffordItem(SelectedCommodity) && 
		!CheckIfPurchasedCategory(SelectedGeneMod) &&
		IsValidUnitForProject(UnitState))
    {
        DialogData.eType = eDialog_Alert;
		
		if (class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.EnableNegativeAbilityOnProjectCancelled) 
		{
			strTitle = m_strGMDialogNegEnabledTitle;
			strText = m_strGMDialogNegEnabledText;
		}
		else
		{
			strTitle = m_strGMDialogNegDisabledTitle;
			strText = m_strGMDialogNegDisabledText;
		}

		DialogData.strTitle = strTitle;
		DialogData.strText = `XEXPAND.ExpandString(strText);
        DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericConfirm;
        DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericBack;
        DialogData.fnCallback = ConfirmPurchasePopupCallback;

        Movie.Pres.UIRaiseDialog(DialogData);
    }
    else
    {
        PlayNegativeSound(); // bsg-jrebar (4/20/17): New PlayNegativeSound Function in Parent Class
    }
}

simulated protected function ConfirmPurchasePopupCallback (name eAction)
{
    if (eAction == 'eUIAction_Accept')
    {
        if (OnUnlockOption())
        {
            PlaySFX("ResearchConfirm");
			UIInventory_ListItem(List.GetSelectedItem()).RealizeDisabledState();
            Movie.Stack.Pop(self);
        }
        else
        {
            `Redscreen("Gene modding: Failed to unlock option even though checks in OnPurchaseClicked have passed");
        }
    }
}

simulated function array<UISummary_ItemStat> GetUISummary_GeneModStats()
{
	local array<UISummary_ItemStat> Stats; 
	local UISummary_ItemStat		Item;
	local X2GeneModTemplate			GMTemplate;
	local Tracker					TrackSt;
	local int						i;

	TrackSt = RetrieveTrackerInfoFromListIndex(List.SelectedIndex);

	GMTemplate = arrGeneMod_Master[TrackSt.GeneModID];

	for(i = 0; i < GMTemplate.StatChanges.Length; i++)
	{
		Item.LabelStyle = eUITextStyle_Tooltip_Body;
		Item.Value = (GMTemplate.StatChanges[i].StatModValue >= 0) ? "+" $ GMTemplate.StatChanges[i].StatModValue : "" $ GMTemplate.StatChanges[i].StatModValue;
		Item.ValueState = (GMTemplate.StatChanges[i].StatModValue >= 0) ? eUIState_Good : eUIState_Bad; 

		switch (GMTemplate.StatChanges[i].StatName)
		{
				case(eStat_HP): 
					Item.Label = class'XLocalizedData'.default.HealthLabel;
					break;
				case(eStat_Offense): 
					Item.Label = class'XLocalizedData'.default.OffenseStat;
					break;
				case(eStat_Defense): 
					Item.Label = class'XLocalizedData'.default.DefenseStat;
					break;
				case(eStat_Mobility): 
					Item.Label = class'XLocalizedData'.default.MobilityLabel;
					break;
				case(eStat_Will): 
					Item.Label = class'XLocalizedData'.default.WillLabel;
					break;
				case(eStat_Hacking): 
					Item.Label = class'XLocalizedData'.default.TechLabel;
					break;
				case(eStat_SightRadius): 
					Item.Label = class'XLocalizedData'.default.WillLabel;
					break;
				case(eStat_Dodge): 
					Item.Label = class'XLocalizedData'.default.DodgeLabel;
					break;
				case(eStat_ArmorMitigation): 
					Item.Label = class'XLocalizedData'.default.ArmorLabel;
					break;
				case(eStat_ArmorPiercing): 
					Item.Label = class'XLocalizedData'.default.PierceLabel;
					break;
				case(eStat_PsiOffense): 
					Item.Label = class'XLocalizedData'.default.PsiOffenseLabel;
					break;
				case(eStat_DetectionRadius): 
					Item.Label = class'XLocalizedData'.default.PierceLabel;
					break;
				case(eStat_DetectionModifier): 
					Item.Label = class'XLocalizedData'.default.PierceLabel;
					break;
				case(eStat_CritChance): 
					Item.Label = class'XLocalizedData'.default.CriticalChanceBonusLabel;
					break;
				case(eStat_FlankingCritChance): 
					Item.Label = class'XLocalizedData'.default.FlankingCritBonus;
					break;
				case(eStat_FlankingAimBonus): 
					Item.Label = class'XLocalizedData'.default.FlankingAimBonus;
					break;
				default:
					break;
		}

		Stats.AddItem(Item);
	}
		return Stats; 
}

function bool OnUnlockOption()
{
	local XComGameState NewGameState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_Unit Unit;
	local int RandomIdx;
	local XComGameState_HeadquartersProjectGeneModOperation GeneModdingOpProject;
	local StaffUnitInfo UnitInfo;

	//Check if XCom can afford this, if not, return false
	if (XComHQ.MeetsRequirmentsAndCanAffordCost(SelectedGeneMod.Requirements, SelectedGeneMod.Cost, XComHQ.ResearchCostScalars,))
	{
		StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(m_StaffSlotRef.ObjectID));
		if (StaffSlotState != none)
		{
			Unit = XComGameState_Unit(History.GetGameStateForObjectID(m_UnitRef.ObjectID));
			
			if (IsValidUnitForProject(Unit))
			{
				UnitInfo.UnitRef = m_UnitRef;
				StaffSlotState.FillSlot(UnitInfo);

				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Gene Modification - " $ SelectedGeneMod.DisplayName $ " For Soldier " $ Unit.GetFullName());

				// Start a new gene modding training project
				GeneModdingOpProject = XComGameState_HeadquartersProjectGeneModOperation(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectGeneModOperation'));
				GeneModdingOpProject.GeneModTemplateName = SelectedGeneMod.DataName; // These need to be set first so project PointsToComplete can be calculated correctly
				// Set to false because we just started it
				GeneModdingOpProject.bCanceled = false;

				//Give a random bad unremovable "trait"
				if (class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.NegativeAbilityName.Length > 0)
					RandomIdx = `SYNC_RAND_STATIC(class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.NegativeAbilityName.Length);
				else
					RandomIdx = class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.NegativeAbilityName.Length;
							
				GeneModdingOpProject.RandomNegPerk = RandomIdx;
				GeneModdingOpProject.SetProjectFocus(UnitInfo.UnitRef, NewGameState, StaffSlotState.Facility);

				XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				XComHQ.Projects.AddItem(GeneModdingOpProject.GetReference());

				//Pay for the Gene Mod
				XComHQ.PayStrategyCost(NewGameState, SelectedGeneMod.Cost, XComHQ.ResearchCostScalars,);

				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

				`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");

				//Let players know that you can staff an engineer/scientist
				FacilityState = XComHQ.GetFacilityByName('AdvancedWarfareCenter');
				if (FacilityState.GetNumEmptyStaffSlots() > 0)
				{
					StaffSlotState = FacilityState.GetStaffSlot(FacilityState.GetEmptyStaffSlotIndex());

					if ((StaffSlotState.IsScientistSlot() && XComHQ.GetNumberOfUnstaffedScientists() > 0) ||
						(StaffSlotState.IsEngineerSlot() && XComHQ.GetNumberOfUnstaffedEngineers() > 0))
					{
						`HQPRES.UIStaffSlotOpen(FacilityState.GetReference(), StaffSlotState.GetMyTemplate());
					}
				}
				
				XComHQ.HandlePowerOrStaffingChange();
				XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
				RefreshFacility();

				return true;
			}
		}
	}

	return false;
}

simulated function RefreshFacility()
{
	local UIScreen QueueScreen;

	QueueScreen = Movie.Stack.GetScreen(class'UIFacility_AdvancedWarfareCenter');
	if (QueueScreen != None)
		UIFacility_AdvancedWarfareCenter(QueueScreen).RealizeFacility();
}

//----------------------------------------------------------------
static function bool IsValidUnitForProject(XComGameState_Unit Unit)
{
	local name UnitClassName;

	UnitClassName = Unit.GetSoldierClassTemplateName();

	if (class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.static.IsDisallowedClass(UnitClassName)) {
		return false;
	}

	return true;
}
//----------------------------------------------------------------
simulated function OnCancelButton(UIButton kButton) { OnCancel(); }

simulated function OnCancel()
{
	local XComGameState_StaffSlot StaffSlotState;
		
	//Get the state and Unslot the unit
	StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(m_StaffSlotRef.ObjectID));
	
	StaffSlotState.EmptySlot();

	CloseScreen();
	if(bIsIn3D)
		UIMovie_3D(Movie).HideDisplay(DisplayTag);
}
//----------------------------------------------------------------
// MISC UTILITIES
//----------------------------------------------------------------
simulated function String GetButtonString(int ItemIndex)
{
	return m_strBuy;
}

simulated function PlayNegativeSound()
{
	if(!`ISCONTROLLERACTIVE)
			class'UIUtilities_Sound'.static.PlayNegativeSound();
}

simulated function PlaySFX(String Sound)
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent(Sound);
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	if(bIsIn3D)
		UIMovie_3D(Movie).HideDisplay(DisplayTag);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateNavHelp();
	if(bIsIn3D)
		class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, `HQINTERPTIME);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = super.OnUnrealCommand(cmd, arg);
	switch( cmd )
	{
//		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
//		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
//			OnPurchaseClicked();
//			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_START:
			`HQPRES.UIPauseMenu( ,true );
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	Package = "/ package/gfxInventory/Inventory";
	InputState = eInputState_Consume;
	m_eMainColor = eUIState_Normal

	DisplayTag = "UIDisplay_Academy"
	CameraTag = "UIDisplay_Academy"
	ConfirmButtonX = 10
	ConfirmButtonY = 0

	bAnimateOnInit = true;
	bSelectFirstAvailable = true;

	OverrideInterpTime = -1;

	bHideOnLoseFocus = true;
}