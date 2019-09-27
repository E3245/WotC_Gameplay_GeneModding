//---------------------------------------------------------------------------------------
//  FILE:    X2DownloadableContentInfo_*.uc
//  AUTHOR:  Ryan McFall
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_WotC_GeneModdingFacility extends X2DownloadableContentInfo config(GameData);

var config int DefaultGeneModOpWorkPerHour;
var config array<int> GeneModOpDays;

var config array<name> DisallowedClasses;

var config array<name> NegativeAbilityName;

var config bool EnableNegativeAbilityOnProjectCancelled;

var localized string GeneModEventLabel;

var config int GeneModLimitCat1;
var config int GeneModLimitCat2;
var config int GeneModLimitCat3;
var config int GeneModLimitCat4;
var config int GeneModLimitCat5;

var config bool IntegratedWarfare_BoostGeneStats;

//	This event runs when the squad returns to Avenger from a tactical mission.
//	We cycle through squad members and if any of them sustained wounds that have 
//	"destroyed" the limbs associated with their Gene Mods, we disable those Gene Mods 
//	and inform the player with a popup message.
static event OnExitPostMissionSequence()
{
	local XComGameState_Unit				UnitState;
	local XComGameStateHistory				History;
	local XComGameState_HeadquartersXCom	XComHQ;
	local int i;

	History = `XCOMHISTORY;
	XComHQ = `XCOMHQ;

	//`LOG("OnExitPostMissionSequence",, 'IRIPOPUP');

	for (i = 0; i < XComHQ.Squad.Length; i++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[i].ObjectID));

		//`LOG("Displaying popup for squad member: " @  UnitState.GetFullName(),, 'IRIPOPUP');
		class'X2GeneModTemplate'.static.DisableGeneModsForAugmentedSoldier(UnitState, true);
	}
}


/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{

}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed. When a new campaign is started the initial state of the world
/// is contained in a strategy start state. Never add additional history frames inside of InstallNewCampaign, add new state objects to the start state
/// or directly modify start state objects
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{

}

/// <summary>
/// Called just before the player launches into a tactical a mission while this DLC / Mod is installed.
/// </summary>
static event OnPreMission(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{

}

/// <summary>
/// Called when the player completes a mission while this DLC / Mod is installed.
/// </summary>
static event OnPostMission()
{

}

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
	PatchFacility();
}

static function PatchFacility() 
{
	local X2StrategyElementTemplateManager StrategyTemplateManager;
	local X2FacilityTemplate Template;
	local StaffSlotDefinition StaffSlotDef;
	
	StrategyTemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();;
	Template = X2FacilityTemplate(StrategyTemplateManager.FindStrategyElementTemplate('AdvancedWarfareCenter'));
	
	if (Template != none)
	{
		Template.MapName = "AVG_Infirmary_B";
		Template.Upgrades.AddItem('Infirmary_GeneModdingChamber');

		StaffSlotDef.StaffSlotTemplateName = 'GeneModdingChamberSoldierStaffSlot';
		StaffSlotDef.bStartsLocked = true;
		Template.StaffSlotDefs.AddItem(StaffSlotDef);
	}
}

/// <summary>
/// Calls DLC specific popup handlers to route messages to correct display functions
/// </summary>
static function bool DisplayQueuedDynamicPopup(DynamicPropertySet PropertySet)
{
	if (PropertySet.PrimaryRoutingKey == 'UIAlert_GeneMod')
	{
		CallUIAlert_GeneMod(PropertySet);
		return true;
	}

	return false;
}

static function CallUIAlert_GeneMod(const out DynamicPropertySet PropertySet)
{
	local XComHQPresentationLayer Pres;
	local UIAlert_GeneMod Alert;

	Pres = `HQPRES;

	Alert = Pres.Spawn(class'UIAlert_GeneMod', Pres);
	Alert.DisplayPropertySet = PropertySet;
	Alert.eAlertName = PropertySet.SecondaryRoutingKey;

	Pres.ScreenStack.Push(Alert);
}

//From PZ's Psionic Training mod
static function bool IsDisallowedClass(name UnitClassName) {
	local name className;
	foreach default.DisallowedClasses(className) {
		if (className == UnitClassName) {
			return true;
		}
	}

	return false;
}

//
// Code that replaces the Hypervitalization Chamber with the Gene Modding Chamber
//

//static function FixAWCFacility()
//{
//	local XComGameState_HeadquartersXCom XComHQ;
//	local XComGameState_FacilityXCom FacilityState;
//	local XComGameState_FacilityUpgrade UpgradeState;
//	local X2FacilityUpgradeTemplate UpgradeTemplate;
//	local StateObjectReference UpgradeRef;
//	local XComGameState NewGameState;
//
//	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
//
//	FacilityState = XComHQ.GetFacilityByName('AdvancedWarfareCenter');
//	if (FacilityState != none)
//	{
//		//If the state has this upgrade, replace it with the Gene Modding Chamber Facility Upgrade.
//		foreach FacilityState.Upgrades(UpgradeRef)
//		{
//			UpgradeState = XComGameState_FacilityUpgrade(`XCOMHISTORY.GetGameStateForObjectID(UpgradeRef.ObjectID));
//			if (UpgradeState != none && UpgradeState.GetMyTemplateName() == 'Infirmary_RecoveryChamber')
//			{
//				FacilityState.Upgrades.RemoveItem(UpgradeRef);
//				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Replace Facility Upgrade with Gene Modding Chamber - Advanced Warfare Center");
//
//				UpgradeTemplate = X2FacilityUpgradeTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate('Infirmary_GeneModdingChamber'));				
//				UpgradeState = UpgradeTemplate.CreateInstanceFromTemplate(NewGameState);
//
//				FacilityState = XComGameState_FacilityXCom(NewGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
//				FacilityState.Upgrades.AddItem(UpgradeState.GetReference());
//				//Create a new FacilityUpgrade GameState and add it into the AWC.
//
//				`XCOMHISTORY.AddGameStateToHistory(NewGameState);
//			}
//		}
//	}
//}

//start Issue #112
/// <summary>
/// Called from XComGameState_HeadquartersXCom
/// lets mods add their own events to the event queue when the player is at the Avenger or the Geoscape
/// </summary>

static function bool GetDLCEventInfo(out array<HQEvent> arrEvents)
{
	GetGMHQEvents(arrEvents);
	return true; //returning true will tell the game to add the events have been added to the above array
}

//Common function to get the necessary project from headquarters
static function XComGameState_HeadquartersProjectGeneModOperation GetGeneModProjectFromHQ()
{
	local XComGameState_HeadquartersXCom						XComHQ;
	local XComGameState_HeadquartersProjectGeneModOperation		GeneProject;
	local XComGameStateHistory									History;
	local int idx;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	History = `XCOMHISTORY;

	for (idx = 0; idx < XComHQ.Projects.Length; idx++)
	{
		GeneProject = XComGameState_HeadquartersProjectGeneModOperation(History.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));
		if (GeneProject != none)
		{
			return GeneProject;
		}
	}
	`Redscreen("Could not find XComGameState_HeadquartersProjectGeneModOperation in History!");
	return none;
}

static function GetGMHQEvents(out array<HQEvent> arrEvents)
{
	local string												AbilityNameStr, GeneModdingStr;
	local HQEvent												kEvent;
	local XComGameState_HeadquartersXCom						XComHQ;
	local XComGameState_HeadquartersProjectGeneModOperation		GeneProject;
	local XComGameState_Unit									UnitState;
	local XComGameStateHistory									History;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	History = `XCOMHISTORY;
	GeneProject = GetGeneModProjectFromHQ();
	
	if (GeneProject != none)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(GeneProject.ProjectFocus.ObjectID));
		//This should never happen, but if it does, do nothing
		if (UnitState != none)
		{
			//Create HQ Event
			AbilityNameStr = Caps(GeneProject.GetMyTemplate().GetDisplayName());
			GeneModdingStr = Repl(default.GeneModEventLabel, "%CLASSNAME", AbilityNameStr);
			
			kEvent.Data = GeneModdingStr @ UnitState.GetName(eNameType_RankFull);
			kEvent.Hours = GeneProject.GetCurrentNumHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Science;
			arrEvents.AddItem(kEvent);
		}
	}
}