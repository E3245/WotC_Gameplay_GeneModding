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
	Template.AddCHEvent('UpgradeCompleted', UIArmory_ShowNewGeneModsPopUp, ELD_OnStateSubmitted);

	//	Replaced by X2DLCInfo::OnExitPostMissionSequence()
	//Template.AddCHEvent('PostMissionUpdateSoldierHealing', OnPostMissionUpdateSoldierHealing, ELD_OnStateSubmitted);

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

//	This Event Listener runs whenever the player purchases a Facility Upgrade or a completes a Research.
//	We intentionally don't check what triggered this Listener, in case some obscure Gene Mod adds some bullshit strategic requirements, like need to have a Shadow Chamber constructed first.
//	Purpose: for each Gene Mod, display a "New Gene Mod Available" popup, but only once per campaign.
static protected function EventListenerReturn UIArmory_ShowNewGeneModsPopUp(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local X2GeneModTemplate					GeneModTemplate;
	local array<X2GeneModTemplate>			GeneModTemplates;
	local XComGameState_HeadquartersXCom	XComHQ;

	GeneModTemplates = class'X2GeneModTemplate'.static.GetGeneModTemplates();
	XComHQ = `XCOMHQ;

	foreach GeneModTemplates(GeneModTemplate)
	{
		if (XComHQ.MeetsEnoughRequirementsToBeVisible(GeneModTemplate.Requirements))
		{
			class'XComGameState_ShownGeneModPopups'.static.DisplayPopupOnce(GeneModTemplate);
		}
	}
	return ELR_NoInterrupt;
}

//	This Event Listener runs around the time a squad returns back to Avenger from a tactical mission, right before you see your squad walking towards the camera from the Skyranger.
//	Augments mod has a similar Event Listener, but it uses ELD_Immediate, so it runs before this one. 
//	Augments' listener will determine if a wounded soldier has "lost a limb" and now requires augmentation.
//	This Event Listener triggers right after that, and will disable the Gene Mod associated with the "lost limb", and show a popup, informing the player.
/*
static function EventListenerReturn OnPostMissionUpdateSoldierHealing(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(EventSource);

	if (UnitState != none)
	{
		class'X2GeneModTemplate'.static.DisableGeneModsForAugmentedSoldier(UnitState, true);
	}
	return ELR_NoInterrupt;
}*/