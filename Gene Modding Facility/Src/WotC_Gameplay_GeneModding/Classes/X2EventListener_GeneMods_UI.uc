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
		`LOG("Looking at Gene Mod template: " @ GeneModTemplate.DataName @ "Meets facility reqs: " @ XComHQ.MeetsFacilityRequirements(GeneModTemplate.Requirements.RequiredFacilities) @ GeneModTemplate.Requirements.RequiredFacilities.Length @ GeneModTemplate.Requirements.RequiredFacilities[0] @ GeneModTemplate.Requirements.bVisibleIfFacilitiesNotMet, bLog, 'IRIPOPUP');

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