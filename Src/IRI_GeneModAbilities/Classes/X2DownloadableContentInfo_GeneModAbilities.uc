class X2DownloadableContentInfo_GeneModAbilities extends X2DownloadableContentInfo;

static event OnPostTemplatesCreated()
{
	//	Add a condition to Psionic Abilities so that they cannot target or affect soldiers with Tranquil Mind ability.
	if (class'X2Ability_IRI_GeneMods'.default.TRANQUIL_MIND_PATCH_PSIONIC_ABILITIES)
		TranquilMind_PatchPsionicAbilities();

	//	Attach Secondary Heart Stabilize abilities to regular Stabilize abilities.
	SecondaryHeart_AddStabilizeAbilities();
}

//	==========================================
//	******************************************
//				TRANQUIL MIND
//	******************************************
//	==========================================
//	Tranquil Mind -> Cycle through all Psionic Abilities in the game,
//	and make it so they cannot target or affect units with the Tranquil Mind ability.
static function TranquilMind_PatchPsionicAbilities()
{
	local delegate<X2AbilityTemplate.BuildNewGameStateDelegate> BuildGameStateDelegate;

	local X2AbilityTemplateManager	AbilityTemplateManager;
	local X2DataTemplate			DataTemplate;
	local X2AbilityTemplate			AbilityTemplate;	
	local X2Condition_ExcludeSoldierAbility	Condition;
	local int i;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Condition = new class'X2Condition_ExcludeSoldierAbility';
	Condition.ExcludeAbility = 'IRI_TranquilMind';

	//	Set up a mock Build Game State Delegate. We only need it as a vessel for TypicalAbility_BuildGameState so we can compare the Build Game State functions
	//	of Psionic abilities to it. Apparently you can't do this comparison directly: 
	//	AbilityTemplate.BuildNewGameStateFn != class'X2Ability'.static.TypicalAbility_BuildGameState
	BuildGameStateDelegate = class'X2Ability'.static.TypicalAbility_BuildGameState;

	//	Cycle through all Psionic abilities and add a condition to to their effects
	foreach AbilityTemplateManager.IterateTemplates(DataTemplate)
	{
		AbilityTemplate = X2AbilityTemplate(DataTemplate);
		if (AbilityTemplate != none && AbilityTemplate.AbilitySourceName == 'eAbilitySource_Psionic')
		{
			//	Some abilities, like Templars' Exchange, don't have any target effects, and do their magic through
			//	Build Game State function.
			if (AbilityTemplate.AbilityTargetEffects.Length != 0 ||
				AbilityTemplate.BuildNewGameStateFn != BuildGameStateDelegate)
			{
				AbilityTemplate.AbilityTargetConditions.AddItem(Condition);
			}
			for (i = 0; i < AbilityTemplate.AbilityTargetEffects.Length; i++)
			{
				AbilityTemplate.AbilityTargetEffects[i].TargetConditions.AddItem(Condition);
			}
			for (i = 0; i < AbilityTemplate.AbilityMultiTargetEffects.Length; i++)
			{
				AbilityTemplate.AbilityMultiTargetEffects[i].TargetConditions.AddItem(Condition);
			}
			for (i = 0; i < AbilityTemplate.AbilityShooterEffects.Length; i++)
			{
				AbilityTemplate.AbilityShooterEffects[i].TargetConditions.AddItem(Condition);
			}
		}
	}
}

//	==========================================
//	******************************************
//				SECONDARY HEART
//	******************************************
//	==========================================
static function SecondaryHeart_AddStabilizeAbilities()
{
	local X2AbilityTemplateManager	AbilityTemplateManager;
	local X2AbilityTemplate			FirstAbilityTemplate;	
	local X2AbilityTemplate			SecondAbilityTemplate;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	//	Attach Secondary Heart Medkit Stabilize to the regular Medkit Stabilize
	FirstAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('MedikitStabilize');
	FirstAbilityTemplate.AdditionalAbilities.AddItem('IRI_SecondaryHeart_MedikitStabilize');

	SecondAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('IRI_SecondaryHeart_MedikitStabilize');
	CopyAbilityLocalization(FirstAbilityTemplate, SecondAbilityTemplate);

	//	Attach Secondary Heart Gremlin Stabilize to the regular Gremlin Stabilize
	FirstAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('GremlinStabilize');
	FirstAbilityTemplate.AdditionalAbilities.AddItem('IRI_SecondaryHeart_GremlinStabilize');

	SecondAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('IRI_SecondaryHeart_GremlinStabilize');
	CopyAbilityLocalization(FirstAbilityTemplate, SecondAbilityTemplate);
}
//	Copying the localization from original abilities so I don't have to deal with it myself.
static function CopyAbilityLocalization(const X2AbilityTemplate FirstAbilityTemplate, out X2AbilityTemplate SecondAbilityTemplate)
{
	SecondAbilityTemplate.LocFriendlyName = FirstAbilityTemplate.LocFriendlyName;
	SecondAbilityTemplate.LocHelpText = FirstAbilityTemplate.LocHelpText;
	SecondAbilityTemplate.LocLongDescription = FirstAbilityTemplate.LocLongDescription;
	SecondAbilityTemplate.LocPromotionPopupText = FirstAbilityTemplate.LocPromotionPopupText;
	SecondAbilityTemplate.LocFlyOverText = FirstAbilityTemplate.LocFlyOverText;
	SecondAbilityTemplate.LocMissMessage = FirstAbilityTemplate.LocMissMessage;
	SecondAbilityTemplate.LocHitMessage = FirstAbilityTemplate.LocHitMessage;
	SecondAbilityTemplate.LocFriendlyNameWhenConcealed = FirstAbilityTemplate.LocFriendlyNameWhenConcealed;
	SecondAbilityTemplate.LocLongDescriptionWhenConcealed = FirstAbilityTemplate.LocLongDescriptionWhenConcealed;
	SecondAbilityTemplate.LocDefaultSoldierClass = FirstAbilityTemplate.LocDefaultSoldierClass;
	SecondAbilityTemplate.LocDefaultPrimaryWeapon = FirstAbilityTemplate.LocDefaultPrimaryWeapon;
	SecondAbilityTemplate.LocDefaultSecondaryWeapon = FirstAbilityTemplate.LocDefaultSecondaryWeapon;
}

/*
static function WeaponInitialized(XGWeapon WeaponArchetype, XComWeapon Weapon, optional XComGameState_Item ItemState=none)
{
    local X2WeaponTemplate		WeaponTemplate;
    local XComGameState_Unit	UnitState;
    Local XComGameState_Item	InternalWeaponState;
	local XComGameStateHistory	History;

	History = `XCOMHISTORY;
    InternalWeaponState = ItemState;

    if (InternalWeaponState == none)
    {
        InternalWeaponState = XComGameState_Item(History.GetGameStateForObjectID(WeaponArchetype.ObjectID));
    }
	if (InternalWeaponState != none)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(InternalWeaponState.OwnerStateObject.ObjectID));
	}

	if (UnitState != none)
	{	
		if (UnitState.HasSoldierAbility('IRI_HelenArms', true))
		{
			WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
			if (WeaponTemplate.WeaponCat == 'sword')
			{	
				`LOG("Replacing melee animations for " @ UnitState.GetFullName(),, 'GENEMODS');
				Weapon.CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("WP_OffhandPistol_CV.Anims.AS_Shadowfall_Right")));
			}
		}
	}
}*/
/*
static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	local X2AbilityTemplateManager	AbilityManager;
	local X2AbilityTemplate			Template;
	local XComGameState_Item		SecondaryWeaponState;
	local AbilitySetupData			ExtraSetupData;
	local StateObjectReference		SecondaryWeaponReference;
	//local array<XComGameState_Item>	InventoryItems;
	//local XComGameState_Item		InventoryItem;
	//local X2WeaponTemplate			WeaponTemplate;
	local XComGameState_Item		PrimaryWeaponState;
	local StateObjectReference		PrimaryWeaponReference;

	local name						AbilityName;

	local StateObjectReference		RipjackReference;
	local StateObjectReference		PsiAmpReference;
	local StateObjectReference		ShardGauntletReference;
	//local StateObjectReference		ClaymoreReference;
	local StateObjectReference		MeleeReference;
	local StateObjectReference		GremlinReference;

	local bool						bHasNoMelee;
	local bool						bHasNoRipjack;
	local bool						bHasNoShardGauntlets;
	local bool						bHasNoGremlin;

	local array<XComGameState_Item>	InventoryItems;
	local X2WeaponTemplate			WeaponTemplate;
	local int i;

	if (HasDualPistolEquipped(UnitState, StartState))
	{
		SecondaryWeaponState = UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon);
		SecondaryWeaponReference = SecondaryWeaponState.GetReference();

		PrimaryWeaponState = UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon);
		PrimaryWeaponReference = PrimaryWeaponState.GetReference();

		AbilityManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

		//	Take a look at soldier's equipment
		bHasNoMelee = true;
		bHasNoClaymore = true;
		bHasNoRipjack = true;
		bHasNoPsiAmp = true;
		bHasNoGremlin = true;
		bHasNoShardGauntlets = true;
		InventoryItems = UnitState.GetAllInventoryItems(StartState, true);
		for (i = 0; i < InventoryItems.Length; i++)
		{
			WeaponTemplate = X2WeaponTemplate(InventoryItems[i].GetMyTemplate());
			if (WeaponTemplate != none)
			{
				`LOG("Found weapon: " @ WeaponTemplate.DataName @ "in slot" @ WeaponTemplate.InventorySlot @ "on:" @ UnitState.GetFullName(), default.bLog, 'IRIPISTOL');
				//if (WeaponTemplate.BaseDamage.Damage == 0) `LOG("It has no damage",, 'IRIPISTOL');
					
				if (WeaponTemplate.WeaponCat == 'wristblade' && 
					(WeaponTemplate.InventorySlot == eInvSlot_QuaternaryWeapon || WeaponTemplate.InventorySlot == eInvSlot_QuinaryWeapon))
				{
					if (WeaponTemplate.BaseDamage.Damage == 0) continue;
					`LOG("Found Ripjack: " @ InventoryItems[i].GetMyTemplateName() @ "on:" @ UnitState.GetFullName(), default.bLog, 'IRIPISTOL');
					RipjackReference = InventoryItems[i].GetReference();
					bHasNoRipjack = false;
				}
				if (WeaponTemplate.WeaponCat == 'psiamp' && 
					(WeaponTemplate.InventorySlot == eInvSlot_QuaternaryWeapon || WeaponTemplate.InventorySlot == eInvSlot_QuinaryWeapon))
				{
					//if (WeaponTemplate.BaseDamage.Damage == 0) continue;
					PsiAmpReference = InventoryItems[i].GetReference();
					bHasNoPsiAmp = false;
				}
				if (WeaponTemplate.WeaponCat == 'gauntlet' && 
					(WeaponTemplate.InventorySlot == eInvSlot_QuaternaryWeapon || WeaponTemplate.InventorySlot == eInvSlot_QuinaryWeapon))
				{
					if (WeaponTemplate.BaseDamage.Damage == 0) continue;
					ShardGauntletReference = InventoryItems[i].GetReference();
					bHasNoShardGauntlets = false;
				}
					
				if (WeaponTemplate.WeaponCat == 'claymore')
				{
					//ClaymoreReference = InventoryItems[i].GetReference();
					bHasNoClaymore = false;
				}
				if (WeaponTemplate.WeaponCat == 'gremlin' && (WeaponTemplate.InventorySlot == eInvSlot_QuaternaryWeapon || WeaponTemplate.InventorySlot == eInvSlot_QuinaryWeapon))
				{
					if (WeaponTemplate.InventorySlot == eInvSlot_Utility) continue;
					GremlinReference = InventoryItems[i].GetReference();
					bHasNoGremlin = false;
				}
				if (default.MeleeWeaponCategories.Find(WeaponTemplate.WeaponCat) != INDEX_NONE  && 
					(WeaponTemplate.InventorySlot == eInvSlot_QuaternaryWeapon || WeaponTemplate.InventorySlot == eInvSlot_QuinaryWeapon))
				{
					if (WeaponTemplate.InventorySlot == eInvSlot_Utility) continue;
					MeleeReference = InventoryItems[i].GetReference();
					bHasNoMelee = false;
				}
			}
		}
		//	EQUIPMENT END

		//	Cycle through all soldier's abilities
		for (i = SetupData.Length - 1; i >= 0; i--)
		{
			`LOG("Found abilitiy: " @ SetupData[i].TemplateName @ "DisplayName: " @ SetupData[i].Template.LocFriendlyName @ "on soldier" @ UnitState.GetFullName(), default.bLog, 'IRIPISTOL');

			//	Process Skirmisher abilities before checking for the Inventory slot, as many of those aren't applied to any specific slot
			if (default.RipjackAbilities.Find(SetupData[i].TemplateName) != INDEX_NONE)
			{
				`LOG("Found Ripjack abilitiy: " @ SetupData[i].TemplateName @ "on soldier" @ UnitState.GetFullName(), default.bLog, 'IRIPISTOL');
				if (bHasNoRipjack)
				{
					`LOG("No ripjack, removing it.", default.bLog, 'IRIPISTOL');
					SetupData.Remove(i, 1);
				}
				else
				{
					`LOG("Moving it to Ripjack", default.bLog, 'IRIPISTOL');
					SetupData[i].SourceWeaponRef = RipjackReference;
				}
				continue;
			}

			//	Move Claymore Abilities to a Utility Slot Claymore, or remove them.
			if (default.ClaymoreAbilities.Find(SetupData[i].TemplateName) != INDEX_NONE)
			{
				if (bHasNoClaymore)
				{
					SetupData.Remove(i, 1);
				}
				//else	//Claymores are dummy items, they don't require the ability to be attached to them. Doing so will break their throwing animations.
				//{
					//SetupData[i].SourceWeaponRef = ClaymoreReference;
				//}
				continue;
			}

			//	Move listed melee abilities to another weapon or remove them
			if (default.MeleeAbilities.Find(SetupData[i].TemplateName) != INDEX_NONE)
			{
				if (bHasNoMelee)
				{
					if (bHasNoRipjack)
					{
						SetupData.Remove(i, 1);
					}
					else
					{
						SetupData[i].SourceWeaponRef = RipjackReference;
					}
				}
				else
				{
					SetupData[i].SourceWeaponRef = MeleeReference;
				}
				continue;
			}
			// Move or remove listed GREMLIN abilities
			if (default.GremlinAbilities.Find(SetupData[i].TemplateName) != INDEX_NONE)
			{
				if (bHasNoGremlin)
				{
					SetupData.Remove(i, 1);
				}
				else
				{
					SetupData[i].SourceWeaponRef = GremlinReference;
				}
				continue;
			}
				

			//	Look at abilities associated with Primary and Secondary pistols
			if (SetupData[i].SourceWeaponRef.ObjectID == SecondaryWeaponReference.ObjectID ||
				SetupData[i].SourceWeaponRef.ObjectID == PrimaryWeaponReference.ObjectID)
			{
				//	skip the ability if it's whitelisted
				if (default.AbilityWhitelist.Find(SetupData[i].TemplateName) != INDEX_NONE) 
				{
					`LOG("Skipping whitelisted abilitiy: " @ SetupData[i].TemplateName, default.bLog, 'IRIPISTOL');
					continue;
				}

				//	remove the ability if it's blacklisted
				if (default.AbilityBlacklist.Find(SetupData[i].TemplateName) != INDEX_NONE)
				{
					`LOG("Removing blacklisted abilitiy: " @ SetupData[i].TemplateName, default.bLog, 'IRIPISTOL');
					SetupData.Remove(i, 1);
					continue;
				}
					
				//	Move Psionic Abilities to a Psi Amp or Shard Gauntlet in another slot
				//	If the soldier doesn't have a Psi Amp nor a Shard Gauntlet anywhere, remove the ability.
				//	Not that this concerns only abiliities attached to Primary or Secondary slot, which mostly includes Psi Operative abilities.
				//	Most of the Templar abilities will be left alone, and the rest we whitelist.
				if (default.PROCESS_PSIONIC_ABILITIES && SetupData[i].Template.AbilitySourceName == 'eAbilitySource_Psionic')
				{
					`LOG("Found PSIONIC abilitiy: " @ SetupData[i].TemplateName @ "DisplayName: " @ SetupData[i].Template.LocFriendlyName @ "on soldier" @ UnitState.GetFullName(), default.bLog, 'IRIPISTOL');
					//	lazy hack-exception for Ionic Storm, as it's the only Templar ability that MUST be attached to Shard Gauntlets
					//	Rend itself comes from Utility Slot Shard Gauntlets, and other abilities can be simply whitelisted.
					if (SetupData[i].TemplateName == 'IonicStorm')
					{
						if (bHasNoShardGauntlets)
						{
							SetupData.Remove(i, 1);
						}
						else
						{
							SetupData[i].SourceWeaponRef = ShardGauntletReference;
						}
						continue;
					}

					//	Move all other psionic abilities to Psi Amp, if there is one.
					if (bHasNoPsiAmp)
					{
						//	If there's no Psi Amp, remove the psionic ability from the soldier.
						SetupData.Remove(i, 1);
					}
					else
					{
						SetupData[i].SourceWeaponRef = PsiAmpReference;
					}
					continue;
				}

				//	Move or remove the rest of melee abilities that are attached to Primary or Secondary pistols
				if (SetupData[i].Template.IsMelee())
				{
					if (bHasNoMelee)
					{
						`LOG("Removing melee abilitiy because no melee weapon: " @ SetupData[i].TemplateName, default.bLog, 'IRIPISTOL');
						SetupData.Remove(i, 1);
					}
					else
					{
						`LOG("Moving melee ability to melee weapon: " @ SetupData[i].TemplateName, default.bLog, 'IRIPISTOL');
						SetupData[i].SourceWeaponRef = MeleeReference;
					}
					continue;
				}

				//	Remove reload and shoot abilities attached to the secondary pistol
				if (default.SecondaryPistolAbilityBlacklist.Find(SetupData[i].TemplateName) != INDEX_NONE &&
				SetupData[i].SourceWeaponRef.ObjectID == SecondaryWeaponReference.ObjectID)
				{	
					`LOG("Removing blacklisted ability from secondary pistol: " @ SetupData[i].TemplateName, default.bLog, 'IRIPISTOL');
					SetupData.Remove(i, 1);
					continue;
				}

				//	move the rest of the abilities from Secondary pistol to the Primary one
				if (SetupData[i].SourceWeaponRef.ObjectID == SecondaryWeaponReference.ObjectID)
				{	
					`LOG("Moving ability from secondary pistol to primary: " @ SetupData[i].TemplateName, default.bLog, 'IRIPISTOL');
					SetupData[i].SourceWeaponRef = PrimaryWeaponReference;
				}
			}
		}
	}
	//	END FOR CYCLE

	//	add the secondary shot ability to the secondary weapon
	Template = AbilityManager.FindAbilityTemplate('PistolStandardShot_Secondary');
	if (Template != none)
	{
		ExtraSetupData.TemplateName = 'PistolStandardShot_Secondary';
		ExtraSetupData.Template = Template;
		ExtraSetupData.SourceWeaponRef = SecondaryWeaponReference;
		SetupData.AddItem(ExtraSetupData);
	}

	//	Check if the soldier has an ability that removes the Offhand Penalty, and if they do - exit function
	foreach class'X2Ability_IRI_DualPistols'.default.ABILITIES_THAT_REMOVE_OFFHAND_PENALTY(AbilityName)
	{
		if (UnitState.HasSoldierAbility(AbilityName, true))
		{
			return;
		}
	}
	//	Otherwise, add the Offhand Aim Penalty ability.
	Template = AbilityManager.FindAbilityTemplate('IRI_OffhandAimPenalty');
	if (Template != none)
	{
		ExtraSetupData.TemplateName = 'IRI_OffhandAimPenalty';
		ExtraSetupData.Template = Template;
		ExtraSetupData.SourceWeaponRef = SecondaryWeaponReference;
		SetupData.AddItem(ExtraSetupData);
	}	
}*/