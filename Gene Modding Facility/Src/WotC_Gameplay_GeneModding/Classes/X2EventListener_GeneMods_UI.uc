class X2EventListener_GeneMods_UI extends X2EventListener dependson(X2GeneModTemplate);

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
//	This Event Listener triggers right after that. If the the Augments mod decided that the soldier has lost a Gene Modded limb, we change it to another limb, if possible, 
//	or make it so the soldier doesn't lose any limbs.

static function EventListenerReturn OnPostMissionUpdateSoldierHealing(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit		UnitState;
	local BodyParts					SafeParts;
	local BodyParts					LostParts;
	local UnitValue					SeveredBodyPart;
	local XComGameState				NewGameState;

	UnitState = XComGameState_Unit(EventSource);

	/*
	`LOG("OnPostMissionUpdateSoldierHealing listener activated for :" @ UnitState.GetFullName() @ "status:" @ UnitState.GetStatus(),, 'IRISWO');
	`LOG("Only mutant SWO is enabled: " @ `SecondWaveEnabled('GM_SWO_OnlyMutant'),, 'IRISWO');
	`LOG("Soldier lost a limb during the mission: " @ UnitState.GetUnitValue('SeveredBodyPart', SeveredBodyPart),, 'IRISWO');
	*/
	if (UnitState != none &&
		!`SecondWaveEnabled('GM_SWO_OnlyMutant') &&	 // If losing a limb SHOULD NOT remove the Gene Mod
		UnitState.GetUnitValue('SeveredBodyPart', SeveredBodyPart))	 // And the soldier DID lose a limb, as set by Augments listener that ran just before
	{
		//	These parts were assigned by Augments Event Listener as lost.
		LostParts = class'X2GeneModTemplate'.static.GetDestroyedBodyParts(UnitState);

		//	These body parts must not be allowed to become lost.
		SafeParts = class'X2GeneModTemplate'.static.GetAugmentedOrGeneModdedBodyParts(UnitState);
		/*
		`LOG("Lost head: " @ LostParts.Head,, 'IRISWO');
		`LOG("Lost torso: " @ LostParts.Torso,, 'IRISWO');
		`LOG("Lost arms: " @ LostParts.Arms,, 'IRISWO');
		`LOG("Lost legs: " @ LostParts.Legs,, 'IRISWO');
		`LOG("==============================",, 'IRISWO');

		`LOG("Safe head: " @ SafeParts.Head,, 'IRISWO');
		`LOG("Safe torso: " @ SafeParts.Torso,, 'IRISWO');
		`LOG("Safe arms: " @ SafeParts.Arms,, 'IRISWO');
		`LOG("Safe legs: " @ SafeParts.Legs,, 'IRISWO');
		`LOG("==============================",, 'IRISWO');*/

		//	Soldier lost some body part due to a Grave Wound that we don't want to allow losing
		if (LostParts.Head && SafeParts.Head || LostParts.Torso && SafeParts.Torso || LostParts.Arms && SafeParts.Arms || LostParts.Legs && SafeParts.Legs)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Remove Gene Mods due to loss of limb or Augmentation from" @ UnitState.GetFullName());
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

			//	Assign a random body part to be "lost", but only if it's not one of the safe ones.
			if (AssignNewLostLimbToUnit(UnitState, SafeParts))
			{
				
			}
			else
			{
				//`LOG("No unsafe limbs, restarting healing.",, 'IRISWO');
				//	Remove the "needs augmentation" status
				UnitState.ClearUnitValue('SeveredBodyPart'); //clear this so it doesn't count anymore

				//	Start healing the soldier.
				StartSoldierHealing(NewGameState, UnitState);
			}
			
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			//`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		}
	}
	return ELR_NoInterrupt;
}

private static function bool AssignNewLostLimbToUnit(out XComGameState_Unit NewUnitState, const BodyParts SafeParts)
{
	local array<int>	SelectorArray;
	local int			Random;

	//	Build a string that contains number values for Limbs we can allow to be lost - those that are not Gene Modded or already Augmented.
	if (!SafeParts.Head)	SelectorArray.AddItem(0);
	if (!SafeParts.Torso)	SelectorArray.AddItem(1);
	if (!SafeParts.Arms)	SelectorArray.AddItem(2);
	if (!SafeParts.Legs)	SelectorArray.AddItem(3);

	//	Soldier has no body parts that aren't already Gene Modded or Augmented, so there's no limb that we can redirect to.
	if (SelectorArray.Length == 0) return false;

	//	Rand(4); returns 0, 1, 2, 3
	//	Select a random character from the string.
	Random = `SYNC_RAND_STATIC(SelectorArray.Length);

	// Set it as the new numerical value for the lost limb.
	NewUnitState.SetUnitFloatValue('SeveredBodyPart', SelectorArray[Random], eCleanup_Never);
	return true;
}

//	Copy of the original function that starts healing soldiers wounded in combat, minus the Highlander event.
private static function StartSoldierHealing(out XComGameState NewGameState, out XComGameState_Unit UnitState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectHealSoldier ProjectState;
	local int NewBlocksRemaining, NewProjectPointsRemaining;

	if (!UnitState.IsDead() && !UnitState.bCaptured && UnitState.IsSoldier() && UnitState.IsInjured() && UnitState.GetStatus() != eStatus_Healing)
	{
		History = `XCOMHISTORY;

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		
		UnitState.SetStatus(eStatus_Healing);

		if (!UnitState.HasHealingProject())
		{
			ProjectState = XComGameState_HeadquartersProjectHealSoldier(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectHealSoldier'));
			ProjectState.SetProjectFocus(UnitState.GetReference(), NewGameState);
			XComHQ.Projects.AddItem(ProjectState.GetReference());
		}
		else
		{
			foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectHealSoldier', ProjectState)
			{
				if (ProjectState.ProjectFocus == UnitState.GetReference())
				{
					NewBlocksRemaining = UnitState.GetBaseStat(eStat_HP) - UnitState.GetCurrentStat(eStat_HP);
					if (NewBlocksRemaining > ProjectState.BlocksRemaining) // The unit was injured again, so update the time to heal
					{
						ProjectState = XComGameState_HeadquartersProjectHealSoldier(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersProjectHealSoldier', ProjectState.ObjectID));

						// Calculate new wound length again, but ensure it is greater than the previous time, since the unit is more injured
						//ProjectState.SetExtraWoundPointsFromMentalState(NewGameState, UnitState);
						NewProjectPointsRemaining = ProjectState.GetWoundPoints(UnitState, ProjectState.ProjectPointsRemaining);

						ProjectState.ProjectPointsRemaining = NewProjectPointsRemaining;
						ProjectState.BlocksRemaining = NewBlocksRemaining;
						ProjectState.PointsPerBlock = Round(float(NewProjectPointsRemaining) / float(NewBlocksRemaining));
						ProjectState.BlockPointsRemaining = ProjectState.PointsPerBlock;
						ProjectState.UpdateWorkPerHour();
						ProjectState.StartDateTime = `STRATEGYRULES.GameTime;
						ProjectState.SetProjectedCompletionDateTime(ProjectState.StartDateTime);
					}

					break;
				}
			}
		}

		// If a soldier is gravely wounded, roll to see if they are shaken
		if (UnitState.IsGravelyInjured() && !UnitState.bIsShaken && !UnitState.bIsShakenRecovered)
		{
			if (class'X2StrategyGameRulesetDataStructures'.static.Roll(XComHQ.GetShakenChance()))
			{
				// @mnauta - leaving in chance to get random scar, but removing shaken gameplay (for new will system)
				//UnitState.bIsShaken = true;
				//UnitState.bSeenShakenPopup = false;

				//Give this unit a random scar if they don't have one already
				if (UnitState.kAppearance.nmScars == '')
				{
					UnitState.GainRandomScar();
					UnitState.bIsShakenRecovered = true;
				}

				//UnitState.SavedWillValue = UnitState.GetBaseStat(eStat_Will);
				//UnitState.SetBaseMaxStat(eStat_Will, 0);
			}
		}
	}
}