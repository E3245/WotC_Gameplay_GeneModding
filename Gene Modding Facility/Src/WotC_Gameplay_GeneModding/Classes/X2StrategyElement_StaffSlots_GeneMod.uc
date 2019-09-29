class X2StrategyElement_StaffSlots_GeneMod extends X2StrategyElement_DefaultStaffSlots;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> StaffSlots;
	StaffSlots.AddItem(CreateGeneModdingChamberSoldierStaffSlotTemplate());
		
	return StaffSlots;
}

static function X2DataTemplate CreateGeneModdingChamberSoldierStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	Template = CreateStaffSlotTemplate('GeneModdingChamberSoldierStaffSlot');
	Template.bSoldierSlot = true;
	Template.bRequireConfirmToEmpty = true;
	Template.bPreventFilledPopup = true;
	Template.UIStaffSlotClass = class'UIFacility_GeneModChamberSlot';
	Template.AssociatedProjectClass = class'XComGameState_HeadquartersProjectGeneModOperation';
	Template.FillFn = FillGMChamberSoldierSlot;
	Template.EmptyFn = EmptyGMChamberSoldierSlot;
	Template.EmptyStopProjectFn = EmptyStopProjectGMChamberSoldierSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayGMSoldierToDoWarning;
	Template.GetSkillDisplayStringFn = GetGMChamberSoldierSkillDisplayString;
	Template.GetBonusDisplayStringFn = GetGMChamberSoldierBonusDisplayString;
	Template.IsUnitValidForSlotFn = IsUnitValidForGMChamberSoldierSlot;
	Template.MatineeSlotName = "Soldier";

	return Template;
}

static function FillGMChamberSoldierSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo, optional bool bTemporary = false)
{
	local XComGameState_Unit				NewUnitState;
	local XComGameState_StaffSlot			NewSlotState;
	local StateObjectReference				EmptyRef;
	local XComGameState_HeadquartersXCom	NewXComHQ;
	local int								SquadIndex;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);

	//Set to training and nothing else.
	NewUnitState.SetStatus(eStatus_Training);
	
	// If the unit undergoing training is in the squad, remove them
	SquadIndex = NewXComHQ.Squad.Find('ObjectID', UnitInfo.UnitRef.ObjectID);
	if (SquadIndex != INDEX_NONE)
	{
		// Remove them from the squad
		NewXComHQ.Squad[SquadIndex] = EmptyRef;
	}
}

static function EmptyGMChamberSoldierSlot(XComGameState NewGameState, StateObjectReference SlotRef)
{
	local XComGameState_StaffSlot	NewSlotState;
	local XComGameState_Unit		NewUnitState;

	EmptySlot(NewGameState, SlotRef, NewSlotState, NewUnitState);
	
	NewUnitState.SetStatus(eStatus_Active);
}

static function EmptyStopProjectGMChamberSoldierSlot(StateObjectReference SlotRef)
{
	local HeadquartersOrderInputContext							OrderInput;
	local XComGameState_StaffSlot								SlotState;
	local XComGameState_Unit									Unit;
	local XComGameState_HeadquartersProjectGeneModOperation		GeneProject;

	SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(SlotRef.ObjectID));
	Unit = SlotState.GetAssignedStaff();
	GeneProject = class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.static.GetGeneModProjectFromHQ();

	if (GeneProject != none)
	{
		// If the unit is undergoing Gene modification, cancel the project and give negative effects on him
		if (Unit.GetStatus() == eStatus_Training)
		{
			OrderInput.OrderType = eHeadquartersOrderType_CancelPsiTraining;
			OrderInput.AcquireObjectReference = GeneProject.GetReference();

			class'XComGameStateContext_HeadquartersOrder_GeneMod'.static.IssueHeadquartersOrder_GM(OrderInput);
		}
	}
}



static function bool ShouldDisplayGMSoldierToDoWarning(StateObjectReference SlotRef)
{
	local XComGameStateHistory				History;
	local XComGameState_HeadquartersXCom	XComHQ;
	local XComGameState_StaffSlot			SlotState;
	local StaffUnitInfo						UnitInfo;
	local int								i;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(SlotRef.ObjectID));

	for (i = 0; i < XComHQ.Crew.Length; i++)
	{
		UnitInfo.UnitRef = XComHQ.Crew[i];

		if (IsUnitValidForGMChamberSoldierSlot(SlotState, UnitInfo))
		{
			return true;
		}
	}

	return false;
}

//	IsActive() and CanBeStaffed() checks combined, and also added the feature to allow staffing injured soldiers if the relevant Second Wave Option is enabled.
static function bool IsUnitValidForGMChamberSoldierSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit; 

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	if (Unit.IsSoldier() &&
		Unit.IsAlive() &&
		Unit.GetMyTemplate().bStaffingAllowed &&
		SlotState.GetMyTemplate().ExcludeClasses.Find(Unit.GetSoldierClassTemplateName()) == INDEX_NONE &&
		(`SecondWaveEnabled('GM_SWO_MutagenicGrowth') && (Unit.GetStatus() == eStatus_Healing || Unit.GetStatus() == eStatus_Active) || //	Second Wave is enabled and the soldier is recovering from wounds or awaiting augmentation
			!Unit.IsInjured() &&	// If Second Wave is not enabled, we screen out wounded or shaken soldiers.
			Unit.GetMentalState() != eMentalState_Shaken &&
			Unit.GetStatus() == eStatus_Active))
	{
		return true;
	}

	return false;
}



static function string GetGMChamberSoldierBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local XComGameState_HeadquartersProjectGeneModOperation		GeneProject;
	local X2AbilityTemplate										AbilityTemplate;
	local string												Contribution;

	if (SlotState.IsSlotFilled())
	{
		GeneProject = class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.static.GetGeneModProjectFromHQ();

		if (GeneProject != none)
		{
			AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(GeneProject.GetMyTemplate().AbilityName);
			Contribution = Caps(AbilityTemplate.LocFriendlyName);
		}
	}

	return GetBonusDisplayString(SlotState, "%SKILL", Contribution);
}

static function string GetGMChamberSoldierSkillDisplayString(XComGameState_StaffSlot SlotState)
{
	return "";
}