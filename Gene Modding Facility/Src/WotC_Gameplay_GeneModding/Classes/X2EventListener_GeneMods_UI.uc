class X2EventListener_GeneMods_UI extends X2EventListener;

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
	local XComGameState_Tech				TechState;
	local X2StrategyElementTemplateManager  StrategyElementTemplateMgr;
	local X2GeneModTemplate					GeneModTemplate;
	local array<X2StrategyElementTemplate>	GeneModTemplates;
	local XComGameState_HeadquartersXCom	XComHQ;
	local name								TechTemplateName;
	local bool								bThisTechUnlocksGeneMod;
	local bool								bOtherTechsAreUnlocked;
	local int i, j;

	TechState = XComGameState_Tech(EventData);
	TechTemplateName = TechState.GetMyTemplateName();

	`LOG("Research complete (Event Data): " @ TechTemplateName, , 'IRIPOPUP');

	StrategyElementTemplateMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	GeneModTemplates = StrategyElementTemplateMgr.GetAllTemplatesOfClass(class'X2GeneModTemplate');
	`LOG("Pulled Gene Mod templates: " @ GeneModTemplates.Length, , 'IRIPOPUP');

	XComHQ = `XCOMHQ;
	for (i=0; i < GeneModTemplates.Length; i++)
	{
		GeneModTemplate = X2GeneModTemplate(GeneModTemplates[i]);

		`LOG("=================================================", , 'IRIPOPUP');
		`LOG("Looking at Gene Mod template: " @ GeneModTemplate.DataName, , 'IRIPOPUP');

		for (j = 0; j < GeneModTemplate.Requirements.RequiredTechs.Length; j++)
		{
			bOtherTechsAreUnlocked = true;
			bThisTechUnlocksGeneMod = false;
			`LOG("It has tech requirement: " @ GeneModTemplate.Requirements.RequiredTechs[j],, 'IRIPOPUP');
			if (GeneModTemplate.Requirements.RequiredTechs[j] == TechTemplateName)
			{
				`LOG("And it was this tech!", , 'IRIPOPUP');
				bThisTechUnlocksGeneMod = true;
			}
			else 
			{
				if (XComHQ.IsTechResearched(TechTemplateName))
				{
					`LOG("It's already completed.", , 'IRIPOPUP');
				}
				else 
				{
					`LOG("It's NOT completed yet, will not show popup for this Gene Mod.",, 'IRIPOPUP');
					`LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^", , 'IRIPOPUP');
					bOtherTechsAreUnlocked = false;
					break;
				}
			}
		}

		if (bOtherTechsAreUnlocked && bThisTechUnlocksGeneMod)
		{
			`LOG("All tech requirements for this Gene Mod are complete, it's now available, showing popup!", , 'IRIPOPUP');
			`LOG("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^", , 'IRIPOPUP');

			class'X2Helpers_BuildAlert_GeneMod'.static.GM_UINewGeneModAvailable(GeneModTemplate);
		}
	}

	return ELR_NoInterrupt;
}