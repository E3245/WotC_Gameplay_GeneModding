//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersProjectPsiTraining.uc
//  AUTHOR:  Mark Nauta  --  11/11/2014
//  PURPOSE: This object represents the instance data for an XCom HQ psi training project
//           Will eventually be a component
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersProjectGeneModOperation extends XComGameState_HeadquartersProject;

var name GeneModTemplateName;
var int RandomNegPerk;

var bool bCanceled;

//---------------------------------------------------------------------------------------
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_GameTime TimeState;


	History = `XCOMHISTORY;
	ProjectFocus = FocusRef; // Unit
	AuxilaryReference = AuxRef; // Facility

	ProjectPointsRemaining = CalculatePointsToTrain(GetMyTemplate().BaseTimeToCompletion);
	InitialProjectPoints = ProjectPointsRemaining;



	`log("Gene Modding | ProjectState | GetGMOrderDays() :: Hours Calculated by ProjectState: " $ ProjectPointsRemaining , , 'WotC_Gameplay_GeneModding');
	UpdateWorkPerHour(NewGameState); 
	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	StartDateTime = TimeState.CurrentTime;

	if (`STRATEGYRULES != none)
	{
		if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(TimeState.CurrentTime, `STRATEGYRULES.GameTime))
		{
			StartDateTime = `STRATEGYRULES.GameTime;
		}
	}

	if(MakingProgress())
	{
		SetProjectedCompletionDateTime(StartDateTime);
	}
	else
	{
		// Set completion time to unreachable future
		CompletionDateTime.m_iYear = 9999;
	}


}

function X2GeneModTemplate GetMyTemplate()
{
	local X2StrategyElementTemplate StratTemplate;

	StratTemplate = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(GeneModTemplateName);

	return X2GeneModTemplate(StratTemplate);
}

//---------------------------------------------------------------------------------------
function int CalculatePointsToTrain(int BaseTimeToCompletion)
{
	local int NewTime;
	NewTime = BaseTimeToCompletion * (24 * class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.DefaultGeneModOpWorkPerHour);

	return NewTime;
}

//---------------------------------------------------------------------------------------
function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	return class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.DefaultGeneModOpWorkPerHour;
}

//---------------------------------------------------------------------------------------
function OnProjectCompleted()
{
	local HeadquartersOrderInputContext OrderInput;
	local X2AbilityTemplate AbilityTemplate;

	OrderInput.OrderType = eHeadquartersOrderType_PsiTrainingCompleted;
	OrderInput.AcquireObjectReference = self.GetReference();

	class'XComGameStateContext_HeadquartersOrder_GeneMod'.static.IssueHeadquartersOrder_GM(OrderInput);

	if (bCanceled)
	{
		if(class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.EnableNegativeAbilityOnProjectCancelled)
		{
			AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.NegativeAbilityName[RandomNegPerk]);
			class'X2Helpers_BuildAlert_GeneMod'.static.GM_UIGeneModOpCanceled(ProjectFocus, AbilityTemplate);
		}
	}
	else
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(GetMyTemplate().AbilityName);
		class'X2Helpers_BuildAlert_GeneMod'.static.GM_UIGeneModOpComplete(ProjectFocus, AbilityTemplate);
	}
}


//---------------------------------------------------------------------------------------
DefaultProperties
{
}