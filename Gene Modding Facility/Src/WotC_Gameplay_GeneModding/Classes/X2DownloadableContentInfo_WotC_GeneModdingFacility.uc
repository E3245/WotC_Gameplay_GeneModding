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

var config bool HideGeneModIfRequirementsNotMet;

var localized string GeneModEventLabel;

var config int GeneModLimitCat1;
var config int GeneModLimitCat2;
var config int GeneModLimitCat3;
var config int GeneModLimitCat4;
var config int GeneModLimitCat5;
var config int GeneModLimitCat6;
var config int GeneModLimitCat7;

var config bool IntegratedWarfare_BoostGeneStats;

var localized string			str_SWO_OnlyMutant_Description;
var localized string			str_SWO_OnlyMutant_Tooltip;
var localized string			str_SWO_MutagenicGrowth_Description;
var localized string			str_SWO_MutagenicGrowth_Tooltip;
var localized string			str_SWO_Biosynthesis_Description;
var localized string			str_SWO_Biosynthesis_Tooltip;

var config float MUTAGENIC_GROWTH_RESTORE_HEALTH;

//	Accessed like this: 
//	`SecondWaveEnabled('GM_SWO_OnlyMutant')	- Losing a limb permanently removes Gene Mod associated with that limb.
//	`SecondWaveEnabled('GM_SWO_MutagenicGrowth') - Gene Modding a wounded soldier recovers their wounds and restores lost limb if Gene Modding that limb.
//	`SecondWaveEnabled('GM_SWO_Biosynthesis') - Can Gene Mod augmented limbs.
static function UpdateSecondWaveOptionsList()
{
	local array<Object>			UIShellDifficultyArray;
	local Object				ArrayObject;
	local UIShellDifficulty		UIShellDifficulty;
    local SecondWaveOption		SWO_OnlyMutant;
	local SecondWaveOption		SWO_MutagenicGrowth;
	local SecondWaveOption		SWO_Biosynthesis;
	local bool					bAugmentsModLoaded;
	
	SWO_MutagenicGrowth.ID = 'GM_SWO_MutagenicGrowth';
	SWO_MutagenicGrowth.DifficultyValue = 0;
	
	bAugmentsModLoaded = DLCLoaded('Augmentations');
	SWO_OnlyMutant.ID = 'GM_SWO_OnlyMutant';
	SWO_OnlyMutant.DifficultyValue = 0;

	SWO_Biosynthesis.ID = 'GM_SWO_Biosynthesis';
	SWO_Biosynthesis.DifficultyValue = 0;
	
	UIShellDifficultyArray = class'XComEngine'.static.GetClassDefaultObjects(class'UIShellDifficulty');
	foreach UIShellDifficultyArray(ArrayObject)
	{
		UIShellDifficulty = UIShellDifficulty(ArrayObject);
		UIShellDifficulty.SecondWaveOptions.AddItem(SWO_MutagenicGrowth);
		UIShellDifficulty.SecondWaveDescriptions.AddItem(default.str_SWO_MutagenicGrowth_Description);
		UIShellDifficulty.SecondWaveToolTips.AddItem(default.str_SWO_MutagenicGrowth_Tooltip);

		if (bAugmentsModLoaded)
		{
			UIShellDifficulty.SecondWaveOptions.AddItem(SWO_OnlyMutant);
			UIShellDifficulty.SecondWaveDescriptions.AddItem(default.str_SWO_OnlyMutant_Description);
			UIShellDifficulty.SecondWaveToolTips.AddItem(default.str_SWO_OnlyMutant_Tooltip);

			UIShellDifficulty.SecondWaveOptions.AddItem(SWO_Biosynthesis);
			UIShellDifficulty.SecondWaveDescriptions.AddItem(default.str_SWO_Biosynthesis_Description);
			UIShellDifficulty.SecondWaveToolTips.AddItem(default.str_SWO_Biosynthesis_Tooltip);
		}
	}
}

static function bool DLCLoaded(name DLCName)
{
	local XComOnlineEventMgr	EventManager;
	local int					Index;

	EventManager = `ONLINEEVENTMGR;

	for(Index = EventManager.GetNumDLC() - 1; Index >= 0; Index--)	
	{
		if(EventManager.GetDLCNames(Index) == DLCName)	
		{
			return true;
		}
	}
	return false;
}

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

	if (`SecondWaveEnabled('GM_SWO_OnlyMutant'))	//	Check if losing the limb due to a Grave Wound (Augments mod) should disable Gene Mod associated with that limb.
	{	
		for (i = 0; i < XComHQ.Crew.Length; i++)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[i].ObjectID));
			if (UnitState.IsSoldier())
			{
				class'X2GeneModTemplate'.static.DisableGeneModsForAugmentedSoldier(UnitState, true);
			}
		}
	}
}


/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{
	class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ConsoleCommand("suppress WotC_Gameplay_GeneModding");
	class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ConsoleCommand("suppress IRIPOPUP");
}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed. When a new campaign is started the initial state of the world
/// is contained in a strategy start state. Never add additional history frames inside of InstallNewCampaign, add new state objects to the start state
/// or directly modify start state objects
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{
	class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ConsoleCommand("suppress WotC_Gameplay_GeneModding");
	class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ConsoleCommand("suppress IRIPOPUP");
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
	UpdateSecondWaveOptionsList();
	RecolorGeneModAbilities();
	AssignImageAndLocalizationToPurePassives();
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

static function RecolorGeneModAbilities()
{
    local X2AbilityTemplate         Template;
    local X2AbilityTemplateManager  AbilityTemplateManager;
	local X2GeneModTemplate			GeneModTemplate;
	local array<X2GeneModTemplate>	GeneModTemplates;
	local int i;

    AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	GeneModTemplates = class'X2GeneModTemplate'.static.GetGeneModTemplates();

	foreach GeneModTemplates(GeneModTemplate)
	{
		Template = AbilityTemplateManager.FindAbilityTemplate(GeneModTemplate.AbilityName);
		if (Template != none)
		{
			Template.AbilitySourceName = 'eAbilitySource_Commander';

			for (i = 0; i < Template.AbilityTargetEffects.Length; i++)
			{
				if (X2Effect_Persistent(Template.AbilityTargetEffects[i]).BuffCategory == ePerkBuff_Passive)
				{
					X2Effect_Persistent(Template.AbilityTargetEffects[i]).AbilitySourceName = 'eAbilitySource_Commander';
				}
			}
			for (i = 0; i < Template.AbilityShooterEffects.Length; i++)
			{
				if (X2Effect_Persistent(Template.AbilityShooterEffects[i]).BuffCategory == ePerkBuff_Passive)
				{
					X2Effect_Persistent(Template.AbilityShooterEffects[i]).AbilitySourceName = 'eAbilitySource_Commander';
				}
			}
		}
	}
}

static function AssignImageAndLocalizationToPurePassives()
{
    local X2AbilityTemplate         Template;
    local X2AbilityTemplateManager  AbilityTemplateManager;
	local X2GeneModTemplate			GeneModTemplate;
	local array<X2GeneModTemplate>	GeneModTemplates;

    AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	GeneModTemplates = class'X2GeneModTemplate'.static.GetGeneModTemplates();

	foreach GeneModTemplates(GeneModTemplate)
	{
		if (Right(String(GeneModTemplate.AbilityName), 10) == "_GMPassive")
		{
			Template = AbilityTemplateManager.FindAbilityTemplate(GeneModTemplate.AbilityName);

			if (Template != none)
			{
				if (Template.LocFriendlyName == "") 
				{
					Template.LocFriendlyName = GeneModTemplate.DisplayName;
					X2Effect_Persistent(Template.AbilityTargetEffects[0]).FriendlyName = GeneModTemplate.DisplayName;
				}
				if (Template.LocLongDescription == "") 
				{
					Template.LocLongDescription = GeneModTemplate.Summary;
					X2Effect_Persistent(Template.AbilityTargetEffects[0]).FriendlyDescription = GeneModTemplate.Summary;
				}
				if (Template.LocHelpText == "") Template.LocHelpText = GeneModTemplate.Summary;
				
				if (GeneModTemplate.strAbilityImage != "") 
				{
					Template.IconImage = GeneModTemplate.strAbilityImage;
					X2Effect_Persistent(Template.AbilityTargetEffects[0]).IconImage = GeneModTemplate.strAbilityImage;
				}
			}
		}
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
	local XComGameState_HeadquartersProjectGeneModOperation		GeneProject;
	local XComGameState_Unit									UnitState;
	local XComGameStateHistory									History;

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