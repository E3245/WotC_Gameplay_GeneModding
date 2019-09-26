class X2EventListener_GeneMods_UI extends X2EventListener;

const bLog = true;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateArmoryUIListeners());

	return Templates;
}

static function CHEventListenerTemplate CreateArmoryUIListeners()
{
	local CHEventListenerTemplate Template;
	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'UI_Armory_GeneMod');

	Template.AddCHEvent('CustomizeStatusStringsSeparate', UIArmory_UpdateStatuses, ELD_Immediate);

	Template.AddCHEvent('OnResearchReport', UIArmory_ShowNewGeneModsPopUp, ELD_OnStateSubmitted);
	Template.AddCHEvent('UpgradeCompleted', UIArmory_ShowNewGeneModsPopUp, ELD_OnStateSubmitted);

	Template.AddCHEvent('PostMissionUpdateSoldierHealing', OnPostMissionUpdateSoldierHealing, ELD_OnStateSubmitted);
	`LOG("Register Event OnPostMissionUpdateSoldierHealing",, 'RPG');

	Template.RegisterInStrategy = true;
	`LOG("Register Event CustomizeStatusStringsSeparate",, 'WotC_Gameplay_GeneModding');

	return Template;
}

static protected function EventListenerReturn UIArmory_UpdateStatuses(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit								Unit;
	local XComGameState_StaffSlot							StaffSlot;
	local XComLWTuple										OverrideTuple;
	local XComGameState_HeadquartersProjectGeneModOperation ProjectState;

	OverrideTuple = XComLWTuple(EventData);
	if (OverrideTuple == none || OverrideTuple.Id != 'CustomizeStatusStringsSeparate') return ELR_NoInterrupt;

	`LOG("Event CustomizeStatusStringsSeparate triggered",, 'WotC_Gameplay_GeneModding');
	//This is the correct event, get unit and assigned staff slot
	Unit = XComGameState_Unit(EventSource);
	StaffSlot = Unit.GetStaffSlot();

	if (StaffSlot != None && StaffSlot.GetMyTemplateName() == 'GeneModdingChamberSoldierStaffSlot')
	{
		ProjectState = class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.static.GetGeneModProjectFromHQ();

		if (ProjectState != none)
		{
			OverrideTuple.Data[0].s = StaffSlot.GetBonusDisplayString();
			`LOG("Tuple.Data[0].s = " $ OverrideTuple.Data[0].s ,, 'WotC_Gameplay_GeneModding');
			OverrideTuple.Data[1].b = true;
			OverrideTuple.Data[3].i = ProjectState.GetCurrentNumHoursRemaining();
		}
	}

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn UIArmory_ShowNewGeneModsPopUp(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local X2StrategyElementTemplateManager  StrategyElementTemplateMgr;
	local X2GeneModTemplate					GeneModTemplate;
	local array<X2StrategyElementTemplate>	GeneModTemplates;
	local XComGameState_HeadquartersXCom	XComHQ;
	local int i;

	StrategyElementTemplateMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	GeneModTemplates = StrategyElementTemplateMgr.GetAllTemplatesOfClass(class'X2GeneModTemplate');

	`LOG("Show Gene Mod popups triggered by event: " @ EventID, bLog, 'IRIPOPUP');
	`LOG("Pulled this many Gene Mod templates: " @ GeneModTemplates.Length, bLog, 'IRIPOPUP');

	XComHQ = `XCOMHQ;

	for (i=0; i < GeneModTemplates.Length; i++)
	{
		GeneModTemplate = X2GeneModTemplate(GeneModTemplates[i]);

		`LOG("=================================================", bLog, 'IRIPOPUP');
		`LOG("Looking at Gene Mod template: " @ GeneModTemplate.DataName, bLog, 'IRIPOPUP');

		if (XComHQ.MeetsEnoughRequirementsToBeVisible(GeneModTemplate.Requirements))
		{
			`LOG("All requirements for this Gene Mod are complete, it's now available, showing popup!", bLog, 'IRIPOPUP');
			`LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^", bLog, 'IRIPOPUP');
			//Display popup here
			class'XComGameState_ShownGeneModPopups'.static.DisplayPopupOnce(GeneModTemplate);
		}
		else
		{
			`LOG("Not all requirements for this Gene Mod are complete yet, NOT showing popup.", bLog, 'IRIPOPUP');
			`LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^", bLog, 'IRIPOPUP');
		}
	}
	return ELR_NoInterrupt;
}

static function EventListenerReturn OnPostMissionUpdateSoldierHealing(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit				UnitState;
	local X2StrategyElementTemplateManager  StrategyElementTemplateMgr;
	local X2GeneModTemplate					GeneModTemplate;
	local array<X2GeneModTemplate>			RemovedGeneMods;
	local array<X2StrategyElementTemplate>	GeneModTemplates;
	local XComGameState						NewGameState;
	local int i, j;
	local string ErrMsg;

	UnitState = XComGameState_Unit(EventSource);

	`LOG("Post mission update triggered for: " @ UnitState.GetFullName(), bLog, 'IRIPOPUP');

	if (UnitState != none)
	{
		StrategyElementTemplateMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		GeneModTemplates = StrategyElementTemplateMgr.GetAllTemplatesOfClass(class'X2GeneModTemplate');
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Remove Gene Mods due to loss of limb");
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

		for (i=0; i < GeneModTemplates.Length; i++)
		{
			GeneModTemplate = X2GeneModTemplate(GeneModTemplates[i]);

			`LOG("Looking at Gene Mod template: " @ GeneModTemplate.DataName, bLog, 'IRIPOPUP');

			ErrMsg = class'UICommodity_GeneModUpgrade'.static.GetAugmentedErrorMessage(UnitState, GeneModTemplate);
			if (ErrMsg != "")
			{	
				`LOG("Soldier's Augments or Wounds prohibit this Gene Mod:", bLog, 'IRIPOPUP');
				`LOG(" === " @ ErrMsg, bLog, 'IRIPOPUP');

				for (j = 0; j < UnitState.AWCAbilities.Length; j++)
				{
					if (UnitState.AWCAbilities[j].AbilityType.AbilityName == GeneModTemplate.AbilityName)
					{
						`LOG("Soldier has this Gene Mod, disabling it.", bLog, 'IRIPOPUP');

						//	Unit will not receive any AdditionalAbilities associated with this ability as well.
						UnitState.AWCAbilities[j].bUnlocked = false;
						RemovedGeneMods.AddItem(GeneModTemplate);
						break;
					}
				}
				if (j == UnitState.AWCAbilities.Length)
				{
					`LOG("Soldier does not have this Gene Mod.", bLog, 'IRIPOPUP');
				}
			}
			else
			{
				`LOG("Soldier does not have wounds or augments that would block this Gene Mod.", bLog, 'IRIPOPUP');
			}
		}
	}
	`LOG("Removed Gene Mods: " @ RemovedGeneMods.Length, bLog, 'IRIPOPUP');
	if (RemovedGeneMods.Length > 0) 
	{
		//	TODO for E3245: show popup here.
		//	ShowPopup(UnitState, RemovedGeneMods);

		`LOG("Submitting game state.", bLog, 'IRIPOPUP');
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else 
	{
		`LOG("Cancelling game state.", bLog, 'IRIPOPUP');
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}