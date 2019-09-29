class XComGameStateContext_HeadquartersOrder_GeneMod extends XComGameStateContext_HeadquartersOrder;

static function IssueHeadquartersOrder_GM(const out HeadquartersOrderInputContext UseInputContext)
{
	local XComGameStateContext_HeadquartersOrder NewOrderContext;

	NewOrderContext = XComGameStateContext_HeadquartersOrder(class'XComGameStateContext_HeadquartersOrder_GeneMod'.static.CreateXComGameStateContext());
	NewOrderContext.InputContext = UseInputContext;

	`GAMERULES.SubmitGameStateContext(NewOrderContext);
}

static function CompletePsiTraining(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectGeneModOperation ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;

	local name GeneModCategory;
	local X2GeneModTemplate GeneMod;
	local SoldierClassAbilityType AbilityType;
	local ClassAgnosticAbility GMAgAbility;

	local float MaxStat, NewMaxStat, NewCurrentStat;
	local bool bHasBonus, bCosmetic;
	local UnitValue GeneModSuccess, GeneModFailed;
	local int i, j, UV_Holder;
	local ECharStatType NewStatName;
	local int Boost;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectGeneModOperation(History.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		`LOG("Gene Modding | Headquarters Order | CompletePsiTraining() :: Got Valid ProjectState", , 'WotC_Gameplay_GeneModding');
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		if (UnitState != none)
		{
			`LOG("Gene Modding | Headquarters Order | CompletePsiTraining() :: " $ UnitState.GetName(eNameType_FullNick), , 'WotC_Gameplay_GeneModding');
			
			GeneMod = ProjectState.GetMyTemplate();
			
			// Set the soldier status back to active, and add the learned ability
			UnitState = XComGameState_Unit(AddToGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			AbilityType.AbilityName = GeneMod.AbilityName;
			AbilityType.ApplyToWeaponSlot = eInvSlot_Unknown;
			
			`LOG("Gene Modding | Headquarters Order | CompletePsiTraining() :: Adding " $ AbilityType.AbilityName $ " to soldier", , 'WotC_Gameplay_GeneModding');			
			GMAgAbility.AbilityType = AbilityType;
			GMAgAbility.bUnlocked = true;
			GMAgAbility.iRank = 0;
			UnitState.bSeenAWCAbilityPopup = true;
			UnitState.AWCAbilities.AddItem(GMAgAbility);

			UnitState.GetUnitValue('GeneModsImplantsFailed', GeneModFailed);

			if (GeneModFailed.fValue > 0)
			{
				for (i = 0; i < UnitState.AWCAbilities.Length; i++)
				{
					for (j = 0; j < class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.NegativeAbilityName.Length; j++)
					{
						if (UnitState.AWCAbilities[i].AbilityType.AbilityName == class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.NegativeAbilityName[j])
						{
							UnitState.AWCAbilities.Remove(i,1);
							i--;
						}
					}
				}
				//Reset stat
				UnitState.SetUnitFloatValue('GeneModsImplantsFailed', 0, eCleanup_Never);
			}

			//Get the HQ and check for Integrated Warfare

			if (class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.IntegratedWarfare_BoostGeneStats)
			{
				XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
				if (XComHQ != none)
				{
					bHasBonus = XComHQ.SoldierUnlockTemplates.Find('IntegratedWarfareUnlock') != INDEX_NONE;
				}
			}

			`LOG("Gene Modding | Headquarters Order | CompletePsiTraining() :: Adjusting Stats", , 'WotC_Gameplay_GeneModding');
			// Adjust Stats Accordingly
			for (i = 0; i < GeneMod.StatChanges.Length; i++)
			{
				NewStatName = GeneMod.StatChanges[i].StatName;
				Boost = GeneMod.StatChanges[i].StatModValue;
				bCosmetic = GeneMod.StatChanges[i].bUICosmetic;

				//If it's cosmetic, then nothing should be done
				if (!bCosmetic) 
				{
					if (bHasBonus)
					{
						Boost += class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostIncrement;
					}

					//Compensate if Beta Strike is enabled
					if ((NewStatName == eStat_HP) && `SecondWaveEnabled('BetaStrike'))
					{
						Boost *= class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod;
					}

					//From PCS code in XCGS_Unit
					MaxStat = UnitState.GetMaxStat(NewStatName);
					NewMaxStat = MaxStat + Boost;
					NewCurrentStat = int(UnitState.GetCurrentStat(NewStatName)) + Boost;
					UnitState.SetBaseMaxStat(NewStatName, NewMaxStat);

					//Note the second one won't happen since you aren't allowed to assign wounded soldiers to GM
					if(NewStatName != eStat_HP || !UnitState.IsInjured())
					{
						UnitState.SetCurrentStat(NewStatName, NewCurrentStat);
					}
				}
			}

			// Check which category was the Gene mod in and add it to the unit value
			GeneModCategory = GeneMod.GeneCategory;

			// Get and set the unit value for future purposes
			UnitState.GetUnitValue(GeneModCategory, GeneModSuccess);
			UV_Holder = GeneModSuccess.fValue + 1;
			
			UnitState.SetUnitFloatValue(GeneModCategory, UV_Holder, eCleanup_Never);

			// Set back to active
			UnitState.SetStatus(eStatus_Active);

			// Remove the soldier from the staff slot
			StaffSlotState = UnitState.GetStaffSlot();
			if (StaffSlotState != none)
			{
				StaffSlotState.EmptySlot(AddToGameState);
			}

			//The Project was a success so force it to false and delete the state
			ProjectState.bCanceled = false;
			XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			if (XComHQ != none)
			{
				XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				XComHQ.Projects.RemoveItem(ProjectState.GetReference());
				AddToGameState.RemoveStateObject(ProjectState.ObjectID);
			}

			//	If second wave enabled, heal the soldier, and restore the Gene Modded limb if it was marked as lost.
			if (`SecondWaveEnabled('GM_SWO_MutagenicGrowth'))
			{
				SWO_RestoreLostLimb(UnitState, AddToGameState, GeneMod, XComHQ);
			}

			`XEVENTMGR.TriggerEvent('GeneModOperationCompleted', UnitState, UnitState, AddToGameState);
		}		
	}
}

static function SWO_RestoreLostLimb(out XComGameState_Unit UnitState, out XComGameState NewGameState, const X2GeneModTemplate GeneModTemplate, out XComGameState_HeadquartersXCom XComHQ)
{
	local UnitValue SeveredBodyPart;
	local XComGameState_HeadquartersProjectHealSoldier ProjectState;

	if (UnitState.GetUnitValue('SeveredBodyPart', SeveredBodyPart))
	{
		if ((int(SeveredBodyPart.fValue) == 0 && GeneModTemplate.GeneCategory == 'GMCat_eyes') ||
			(int(SeveredBodyPart.fValue) == 1 && GeneModTemplate.GeneCategory == 'GMCat_chest') ||
			(int(SeveredBodyPart.fValue) == 2 && GeneModTemplate.GeneCategory == 'GMCat_arms') ||
			(int(SeveredBodyPart.fValue) == 3 && GeneModTemplate.GeneCategory == 'GMCat_legs')) // Skin Gene Mods don't restore lost limbs, duh
		{
			if (UnitState.IsInjured() && !UnitState.HasHealingProject())
			{
				ProjectState = XComGameState_HeadquartersProjectHealSoldier(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectHealSoldier'));
				ProjectState.SetProjectFocus(UnitState.GetReference(), NewGameState);
				XComHQ.Projects.AddItem(ProjectState.GetReference());
			}

			//	Mark Gene Modded limb as no longer lost.
			UnitState.ClearUnitValue('SeveredBodyPart');
		}
	}
	if (UnitState.IsInjured())
	{
		//	Restore X percent of missing health
		UnitState.ModifyCurrentStat(eStat_HP, UnitState.GetCurrentStat(eStat_HP) + (UnitState.GetMaxStat(eStat_HP) - UnitState.GetCurrentStat(eStat_HP)) * class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.MUTAGENIC_GROWTH_RESTORE_HEALTH);
	}
}

//Cancel state: Remove the soldier from the slot 
static function CancelSoldierTrainingProject(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectGeneModOperation ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;

//	local SoldierClassAbilityType AbilityType;
//	local ClassAgnosticAbility GMAgAbility;

	local UnitValue GeneModFailed;
	local int UV_Holder;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectGeneModOperation(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));
	if (ProjectState != none)
	{
		ProjectState.bCanceled = true;

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}

		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));

		if (UnitState != none)
		{
			// Set the soldier status back to active
			UnitState = XComGameState_Unit(AddToGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

			if(class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.EnableNegativeAbilityOnProjectCancelled)
			{
				GiveRandomNegativeTraitToUnit(UnitState, AddToGameState, XComHQ);
				/*
				AbilityType.AbilityName = class'X2DownloadableContentInfo_WotC_GeneModdingFacility'.default.NegativeAbilityName[ProjectState.RandomNegPerk];
				AbilityType.ApplyToWeaponSlot = eInvSlot_Unknown;
				
				GMAgAbility.AbilityType = AbilityType;
				GMAgAbility.bUnlocked = true;
				GMAgAbility.iRank = 0;
				UnitState.bSeenAWCAbilityPopup = true;
				UnitState.AWCAbilities.AddItem(GMAgAbility);*/
				
				UnitState.GetUnitValue('GeneModsImplantsFailed', GeneModFailed);
				UV_Holder = GeneModFailed.fValue + 1;
				
				UnitState.SetUnitFloatValue('GeneModsImplantsFailed', UV_Holder, eCleanup_Never);
			}

			UnitState.SetStatus(eStatus_Active);

			// Remove the soldier from the staff slot
			StaffSlotState = UnitState.GetStaffSlot();
			if (StaffSlotState != none)
			{
				StaffSlotState.EmptySlot(AddToGameState);
			}
		}
		/* Moved upwards so that we have an XComHQ state to pass to GiveRandomNegativeTraitToUnit
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}*/
	}
}

static function GiveRandomNegativeTraitToUnit(out XComGameState_Unit UnitState, out XComGameState NewGameState, out XComGameState_HeadquartersXCom XComHQ)
{
	local X2TraitTemplate					TraitTemplate;
	local array<name>						ValidTraitNames;
	local name								SelectedTraitName;
	local X2EventListenerTemplateManager	EventMgr;
	local X2DataTemplate					EventTemplate;

	EventMgr = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();

	//	Cycle through all Trait Templates in the game
	foreach EventMgr.IterateTemplates(EventTemplate)
	{
		TraitTemplate = X2TraitTemplate(EventTemplate);

		if(	TraitTemplate != none &&		
			!TraitTemplate.bPositiveTrait &&	//	If this is a negative trait
			UnitState.AcquiredTraits.Find(TraitTemplate.DataName) == INDEX_NONE &&	//	and the soldier does not have it already
			UnitState.PendingTraits.Find(TraitTemplate.DataName) == INDEX_NONE)		//	and the soldier is not set up to receive it soon
		{
			//	Add the trait to the list of negative traits we can randomly select from
			ValidTraitNames.AddItem(TraitTemplate.DataName);
		}
	}
	//	select a random trait from the created list
	SelectedTraitName = ValidTraitNames[`SYNC_RAND_STATIC(ValidTraitNames.Length)];

	// add the trait to the unit
	UnitState.AddAcquiredTrait(NewGameState, SelectedTraitName);

	//	show popup
	`HQPRES.UINegativeTraitAlert(NewGameState, UnitState, SelectedTraitName);

	//	Not sure where that's used, but this was in the original code.
	`XEVENTMGR.TriggerEvent( 'UnitTraitsChanged', UnitState, , NewGameState );
}