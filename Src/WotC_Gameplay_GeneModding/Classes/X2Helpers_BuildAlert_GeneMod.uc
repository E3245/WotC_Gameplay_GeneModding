class X2Helpers_BuildAlert_GeneMod extends Object
	abstract;

static function BuildUIAlert_Mod_GeneMod(
	out DynamicPropertySet PropertySet,
	Name AlertName,
	delegate<X2StrategyGameRulesetDataStructures.AlertCallback> CallbackFunction,
	Name EventToTrigger,
	string SoundToPlay,
	bool bImmediateDisplay)
{
	class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIAlert_GeneMod', AlertName, CallbackFunction, bImmediateDisplay, true, true, false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'EventToTrigger', EventToTrigger);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'SoundToPlay', SoundToPlay);
}

static function GM_UINewGeneModAvailable(X2GeneModTemplate GeneModTemplate)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert_Mod_GeneMod(PropertySet, 'eAlert_NewGeneModAvailable', NewGMAvailablePopupCB, '', "Geoscape_CrewMemberLevelledUp", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'GeneModTemplate', GeneModTemplate.DataName);
	class'XComPresentationLayerBase'.static.QueueDynamicPopup(PropertySet);
}


static function GM_UIGeneModOpComplete(StateObjectReference UnitRef, X2AbilityTemplate AbilityTemplate)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert_Mod_GeneMod(PropertySet, 'eAlert_GeneModdingComplete', GM_GeneModOpCompleteCB, '', "Geoscape_CrewMemberLevelledUp", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'AbilityTemplate', AbilityTemplate.DataName);
	class'XComPresentationLayerBase'.static.QueueDynamicPopup(PropertySet);
}

static function GM_UIGeneModOpCanceled(StateObjectReference UnitRef, X2AbilityTemplate AbilityTemplate)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert_Mod_GeneMod(PropertySet, 'eAlert_GeneModNegativeAbilityAcquired', GM_GeneModOpCompleteCB, '', "Geoscape_CrewMemberLevelledUp", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'AbilityTemplate', AbilityTemplate.DataName);
	class'XComPresentationLayerBase'.static.QueueDynamicPopup(PropertySet);
}

simulated function NewGMAvailablePopupCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;

	if (eAction == 'eUIAction_Accept')
	{
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		FacilityState = XComHQ.GetFacilityByName('AdvancedWarfareCenter');

		if( `GAME.GetGeoscape().IsScanning() )
			StrategyMap2D.ToggleScan();

		FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference(), true);
	}
}


static function GM_GeneModOpCompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstantComplete = false)
{
	local StateObjectReference UnitRef;

	if (eAction == 'eUIAction_Accept')
	{
		UnitRef.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'UnitRef');
		GoToAWC(UnitRef);
	}
}

static function GoToAWC(StateObjectReference UnitRef)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom AWCState;
	local StaffUnitInfo UnitInfo;
	local UIFacility CurrentFacilityScreen;
	local int emptyStaffSlotIndex;

	if (`GAME.GetGeoscape().IsScanning())
		`HQPRES.StrategyMap2D.ToggleScan();

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	AWCState = XComHQ.GetFacilityByName('AdvancedWarfareCenter');
	AWCState.GetMyTemplate().SelectFacilityFn(AWCState.GetReference(), true);

	if (AWCState.GetNumEmptyStaffSlots() > 0) // First check if there are any open staff slots
	{
		// get to choose scientist screen (from staff slot)
		CurrentFacilityScreen = UIFacility(`HQPRES.m_kAvengerHUD.Movie.Stack.GetCurrentScreen());
		emptyStaffSlotIndex = AWCState.GetEmptySoldierStaffSlotIndex();
		if (CurrentFacilityScreen != none && emptyStaffSlotIndex > -1)
		{
			// Only allow the unit to be selected if they are valid
			UnitInfo.UnitRef = UnitRef;
			if (AWCState.GetStaffSlot(emptyStaffSlotIndex).ValidUnitForSlot(UnitInfo))
			{
				CurrentFacilityScreen.SelectPersonnelInStaffSlot(emptyStaffSlotIndex, UnitInfo);
			}
		}
	}
}