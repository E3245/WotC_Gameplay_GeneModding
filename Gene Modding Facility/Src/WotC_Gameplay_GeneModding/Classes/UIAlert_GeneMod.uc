//---------------------------------------------------------------------------------------
//  FILE:    UIAlert_DLC_Day60.uc
//  AUTHOR:  Joe Weinhoffer
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIAlert_GeneMod extends UIAlert;

enum UIAlert_GeneMod
{
	eAlert_GeneModdingComplete,
	eAlert_GeneModNegativeAbilityAcquired
};

var public localized string m_strTitleLabelComplete;
var public localized string m_strTitleLabelNegativeAbility;
var public localized string m_strTitleLabelNewGeneModAvailable;
var public localized string m_strNewGMAvailable;
var public localized string m_strGrantsAbility;
var public localized string m_strSoldierGMHeader;
var public localized string m_strGoToAWC;

simulated function BuildAlert()
{
	BindLibraryItem();

	switch ( eAlertName )
	{
	case 'eAlert_GeneModdingComplete':
		BuildGeneModOpCompleteAlert(m_strTitleLabelComplete);
		break;
	case 'eAlert_GeneModNegativeAbilityAcquired':
		BuildGeneModOpCompleteAlert(m_strTitleLabelNegativeAbility);
		break;	
	case 'eAlert_NewGeneModAvailable':
		BuildGeneNewModOpAvailableAlert(m_strTitleLabelNewGeneModAvailable);
		break;		
	default:
		AddBG(MakeRect(0, 0, 1000, 500), eUIState_Normal).SetAlpha(0.75f);
		break;
	}

	// Set  up the navigation *after* the alert is built, so that the button visibility can be used. 
	RefreshNavigation();
//	if (!Movie.IsMouseActive())
//	{
//		Navigator.Clear();
//	}
}

simulated function Name GetLibraryID()
{
	//This gets the Flash library name to load in a panel. No name means no library asset yet. 
	switch ( eAlertName )
	{
	case 'eAlert_GeneModdingComplete':						return 'Alert_TrainingComplete';
	case 'eAlert_GeneModNegativeAbilityAcquired':			return 'Alert_NegativeSoldierEvent';
	case 'eAlert_NewGeneModAvailable':						return 'Alert_Complete';
	default:
		return '';
	}
}

simulated function BuildGeneModOpCompleteAlert(string TitleLabel)
{
	local XComGameState_Unit UnitState;
	local X2AbilityTemplateManager TemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local string AbilityIcon, AbilityName, AbilityDescription;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplate = TemplateManager.FindAbilityTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'AbilityTemplate'));

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));

	AbilityName = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for ability '" $ AbilityTemplate.DataName $ "'");

	// Ability Description
	AbilityDescription = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, UnitState) : ("Missing 'LocLongDescription' for ability " $ AbilityTemplate.DataName $ "'");
	AbilityIcon = AbilityTemplate.IconImage;

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierGMHeader);
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
	LibraryPanel.MC.QueueString(TitleLabel);
	LibraryPanel.MC.QueueString(AbilityIcon);
	LibraryPanel.MC.QueueString(class'UIAlert'.default.m_strNewAbilityLabel);
	LibraryPanel.MC.QueueString(AbilityName);
	LibraryPanel.MC.QueueString(AbilityDescription);
	LibraryPanel.MC.QueueString(m_strGoToAWC);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();

	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
}

simulated function BuildGeneNewModOpAvailableAlert(string TitleLabel)
{
	local X2StrategyElementTemplateManager  StrategyElementTemplateMgr;
	local X2GeneModTemplate					GeneModTemplate;
	local X2AbilityTemplateManager			AbilityTemplateManager;
	local X2AbilityTemplate					AbilityTemplate;
	local TAlertCompletedInfo				kInfo;
	local XGParamTag						ParamTag;

	StrategyElementTemplateMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	
	GeneModTemplate = X2GeneModTemplate(StrategyElementTemplateMgr.FindStrategyElementTemplate(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'GeneModTemplate')));

	if (GeneModTemplate != none)
	{
		AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(GeneModTemplate.AbilityName);
		
		kInfo.strName = GeneModTemplate.GetDisplayName();
		kInfo.strHeaderLabel = m_strResearchCompleteLabel;
		kInfo.strBody = m_strNewGMAvailable;		
		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		kInfo.strBody $= "\n" $ `XEXPAND.ExpandString(GeneModTemplate.GetSummary());
		kInfo.strConfirm = m_strAssignNewResearch;
		kInfo.strCarryOn = m_strCarryOn;
		kInfo.strImage = GeneModTemplate.strImage;
		kInfo = FillInTyganAlertComplete(kInfo);
		kInfo.eColor = eUIState_Warning;
		kInfo.clrAlert = MakeLinearColor(0.75, 0.75, 0.0, 1);

		BuildCompleteAlert(kInfo);
	}
}

//simulated function BuildGeneModNegativeAbilityAcquiredAlert()
//{
//	local XComGameState_Unit UnitState;
//	local X2AbilityTemplateManager TemplateManager;
//	local string AbilityIcon, AbilityName, AbilityDescription, ClassIcon, ClassName, RankName;
//
//	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
//
//	AbilityTemplate = TemplateManager.FindAbilityTemplate(
//		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'AbilityTemplate'));
//
//	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
//		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
//
//	ClassTemplate = UnitState.GetSoldierClassTemplate();
//	AbilityName = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for ability '" $ AbilityTemplate.DataName $ "'");
//
//	// Ability Description
//	AbilityDescription = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, UnitState) : ("Missing 'LocLongDescription' for ability " $ AbilityTemplate.DataName $ "'");
//	AbilityIcon = AbilityTemplate.IconImage;
//
//	// Send over to flash
//	LibraryPanel.MC.BeginFunctionOp("UpdateData");
//	LibraryPanel.MC.QueueString(TitleLabel);
//	LibraryPanel.MC.QueueString("");
//	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
//	LibraryPanel.MC.QueueString(AbilityIcon);
//	LibraryPanel.MC.QueueString(m_strNewAbilityLabel);
//	LibraryPanel.MC.QueueString(AbilityName);
//	LibraryPanel.MC.QueueString(AbilityDescription);
//	LibraryPanel.MC.QueueString(m_strContinueTraining);
//	LibraryPanel.MC.QueueString(m_strCarryOn);
//	LibraryPanel.MC.EndOp();
//	GetOrStartWaitingForStaffImage();
//	Button2.DisableNavigation();
//	Button2.Hide(); 
//}