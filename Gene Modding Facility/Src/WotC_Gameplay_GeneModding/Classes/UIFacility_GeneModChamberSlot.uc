class UIFacility_GeneModChamberSlot extends UIFacility_StaffSlot
	dependson(UIPersonnel) config(GM_NullConfig);

var config bool bDismissedWarning;

var localized string m_strWarnFirstTimeGeneModDialogTitle;
var localized string m_strWarnFirstTimeGeneModDialogText;

var localized string m_strOKDisable;

var localized string m_strWarnStopGeneModDialogTitle;

var localized string m_strWarnStopGeneModNegEnabledDialogText;

var localized string m_strWarnStopGeneModNegDisabledDialogText;

simulated function UIStaffSlot InitStaffSlot(UIStaffContainer OwningContainer, StateObjectReference LocationRef, int SlotIndex, delegate<OnStaffUpdated> onStaffUpdatedDel)
{
	super.InitStaffSlot(OwningContainer, LocationRef, SlotIndex, onStaffUpdatedDel);
	
	return self;
}

//-----------------------------------------------------------------------------
simulated function ShowDropDown()
{
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_Unit UnitState;
	local string PopupText;

	StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	if (StaffSlot.IsSlotEmpty())
	{
		StaffContainer.ShowDropDown(self);
	}
	else // Ask the user to confirm that they want to empty the slot and stop training
	{
		UnitState = StaffSlot.GetAssignedStaff();

		if (UnitState.GetStatus() == eStatus_Training)
		{
			if (class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.EnableNegativeAbilityOnProjectCancelled) 
			{
				PopupText = m_strWarnStopGeneModNegEnabledDialogText;
			}
			else
			{
				PopupText = m_strWarnStopGeneModNegDisabledDialogText;
			}

			PopupText = Repl(PopupText, "%UNITNAME", UnitState.GetName(eNameType_RankFull));
			if (UnitState.kAppearance.iGender == 1)
				PopupText = Repl(PopupText, "%GENDER", "she");
			else
				PopupText = Repl(PopupText, "%GENDER", "he");

			ConfirmEmptyProjectSlotPopup(m_strWarnStopGeneModDialogTitle, PopupText, false);
		}
	}
}

simulated function OnPersonnelSelected(StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit;
	local XComHQPresentationLayer Pres;
	local UICommodity_GeneModUpgrade kScreen;

	Pres = `HQPRES;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	
	if (Unit.CanBeStaffed()
		&& Unit.IsSoldier()
		&& Unit.IsActive())
	{
		if(!(class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.static.IsDisallowedClass(Unit.GetSoldierClassTemplateName())))
		{
			if(!bDismissedWarning)
				GeneModdingWarnDialogFirstTime();

			if (Pres.ScreenStack.IsNotInStack(class'UICommodity_GeneModUpgrade'))
			{
				kScreen = Pres.Spawn(class'UICommodity_GeneModUpgrade', self);
				kScreen.m_UnitRef = UnitInfo.UnitRef;
				kScreen.m_StaffSlotRef = StaffSlotRef;
				Pres.ScreenStack.Push(kScreen);
			}
		}
	}
}

simulated function GeneModdingWarnDialogFirstTime()
{
	local TDialogueBoxData DialogData;

	DialogData.eType = eDialog_Alert;
	DialogData.strTitle = m_strWarnFirstTimeGeneModDialogTitle;
	DialogData.strText = `XEXPAND.ExpandString(m_strWarnFirstTimeGeneModDialogText);

	DialogData.strAccept = m_strOKDisable;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericContinue;
	DialogData.fnCallback = OnAcceptGeneModWarningCallback;

	`PRESBASE.UIRaiseDialog(DialogData);
}

simulated function OnAcceptGeneModWarningCallback(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		`PRESBASE.PlayUISound(eSUISound_MenuSelect);
		bDismissedWarning = true;
		self.SaveConfig();
	}
	else
	{
		`PRESBASE.PlayUISound(eSUISound_MenuSelect);
	}
}

//==============================================================================

defaultproperties
{
	width = 370;
	height = 65;
}
