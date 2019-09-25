class X2Ability_IRI_GeneMods extends X2Ability config(GeneMods);

var localized string SecondaryHeartTitle;
var localized string SecondaryHeartMessage;
var localized string SecondaryHeartFlyover;

var localized string CheetahSightRangeBonusTitle;
var localized string CheetahSightRangeBonusDesc;
var localized string CheetahSightRangePenaltyTitle;
var localized string CheetahSightRangePenaltyDesc;

var localized string LizardReflexPenaltyTitle;
var localized string LizardReflexPenaltyDesc;

//	Tranquil Mind
var config bool TRANQUIL_MIND_PATCH_PSIONIC_ABILITIES;

//	Chaotic Mind
var config WeaponDamageValue CHAOTIC_MIND_DAMAGE;
var config int CHAOTIC_MIND_PSI_OFFENSE;
var config int CHAOTIC_MIND_COOLDOWN;
var config float CHAOTIC_MIND_RADIUS_METERS; 

//	Berserk
var config int BERSERK_COOLDOWN;
var config int BERSERK_DURATION;
var config bool BERSERK_REPLACES_PANIC;
var config bool BERSERK_TRIGGERED_BY_DAMAGE;
var config bool BERSERK_TRIGGERED_MANUALLY;

//	Secondary Heart
var config bool SECONDARY_HEART_FORCES_BLEEDOUT;
var config bool SECONDARY_HEART_SELF_REVIVES;

//	Cheetah Genes
var config int CHEETAH_GENES_SIGHT_RANGE_PENALTY_NIGHT;
var config int CHEETAH_GENES_SIGHT_RANGE_BONUS_DAY;
var config int CHEETAH_GENES_HP_PENALTY;

//	Lizard Reflex
var config int LIZARD_REFLEX_BAD_WEATHER_MOBILITY_PENALTY;
var config int LIZARD_REFLEX_BAD_WEATHER_WILL_PENALTY;
var config int LIZARD_REFLEX_DODGE_BONUS;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	//	Tranquil Mind
	Templates.AddItem(Create_TranquilMind());	

	//	Chaotic Mind
	Templates.AddItem(Create_ChaoticMind());
	Templates.AddItem(Create_ChaoticMind_Passive());
	
	//	Adaptation / Supercompensation
	Templates.AddItem(Create_Adaptation());

	//	Secondary Heart
	Templates.AddItem(Create_SecondaryHeart());
	Templates.AddItem(Create_SecondaryHeart_Revive());
	Templates.AddItem(Create_SecondaryHeart_MedkitStabilize());
	Templates.AddItem(Create_SecondaryHeart_GremlinStabilize());

	//	Berserk
	Templates.AddItem(Create_Berserk());
	Templates.AddItem(PurePassive('IRI_Berserk_Passive', "img:///UILibrary_PerkIcons.UIPerk_beserker_rage",, 'eAbilitySource_Commander'));

	//	Cheetah Genes
	Templates.AddItem(Create_CheetahGenes());
	Templates.AddItem(Create_CheetahGenes_Penalty());

	//	Lizard Reflex
	Templates.AddItem(Create_LizardReflex());

	return Templates;
}

//	==========================================
//	******************************************
//				LIZARD REFLEX
//	******************************************
//	==========================================

static function X2AbilityTemplate Create_LizardReflex()
{
	local X2AbilityTemplate				Template;	
	local X2Effect_IRI_LizardReflex 	Effect;
	local X2Effect_PersistentStatChange StatEffect;
	local X2Condition_Biome				BiomeCondition;
	local X2Condition_TimeOfDay			TimeOfDayCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_LizardReflex');

	Template.IconImage = "img:///IRI_GeneMods.UI.GeneMod_LizardReflex";
	Template.AbilitySourceName = 'eAbilitySource_Commander';

	SetPassive(Template);

	//	Penalty in Tundra any time of day.
	StatEffect = new class'X2Effect_PersistentStatChange';
	StatEffect.BuildPersistentEffect(1, true, true, false);
	StatEffect.AddPersistentStatChange(eStat_Mobility, default.LIZARD_REFLEX_BAD_WEATHER_MOBILITY_PENALTY);
	StatEffect.AddPersistentStatChange(eStat_Will, default.LIZARD_REFLEX_BAD_WEATHER_WILL_PENALTY);
	StatEffect.SetDisplayInfo(ePerkBuff_Passive, default.LizardReflexPenaltyTitle, default.LizardReflexPenaltyDesc, "img:///IRI_GeneMods.UI.GeneMod_CheetahGenes_LizardReflex_Cold", true,, 'eAbilitySource_Commander');
		BiomeCondition = new class'X2Condition_Biome';
		BiomeCondition.AllowedBiome= "Tundra";
		StatEffect.TargetConditions.AddItem(BiomeCondition);
	Template.AddTargetEffect(StatEffect);

	//	Penalty during daytime in desert.
	StatEffect = new class'X2Effect_PersistentStatChange';
	StatEffect.BuildPersistentEffect(1, true, true, false);
	StatEffect.AddPersistentStatChange(eStat_Mobility, default.LIZARD_REFLEX_BAD_WEATHER_MOBILITY_PENALTY);
	StatEffect.AddPersistentStatChange(eStat_Will, default.LIZARD_REFLEX_BAD_WEATHER_WILL_PENALTY);
	StatEffect.SetDisplayInfo(ePerkBuff_Passive, default.LizardReflexPenaltyTitle, default.LizardReflexPenaltyDesc, "img:///IRI_GeneMods.UI.GeneMod_CheetahGenes_LizardReflex_Cold", true,, 'eAbilitySource_Commander');
		BiomeCondition = new class'X2Condition_Biome';
		BiomeCondition.AllowedBiome= "Arid";
		StatEffect.TargetConditions.AddItem(BiomeCondition);

		TimeOfDayCondition = new class'X2Condition_TimeOfDay';
		TimeOfDayCondition.AllowedLighting = "Day";
		StatEffect.TargetConditions.AddItem(TimeOfDayCondition);
	Template.AddTargetEffect(StatEffect);

	Effect = new class'X2Effect_IRI_LizardReflex';
	Effect.BuildPersistentEffect(1, true, true, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,, Template.AbilitySourceName);
	Effect.DuplicateResponse = eDupe_Ignore;
	Effect.AddPersistentStatChange(eStat_Dodge, default.LIZARD_REFLEX_DODGE_BONUS);
	Template.AddShooterEffect(Effect);

	return Template;	
}

//	==========================================
//	******************************************
//				CHEETAH GENES
//	******************************************
//	==========================================

static function X2AbilityTemplate Create_CheetahGenes()
{
	local X2AbilityTemplate				Template;	
	local X2Effect_IRI_CheetahGenes		Effect;
	local X2Effect_PersistentStatChange StatEffect;
	local X2Condition_TimeOfDay			TimeOfDayCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_CheetahGenes');

	Template.IconImage = "img:///IRI_GeneMods.UI.GeneMod_CheetahGenes";
	Template.AbilitySourceName = 'eAbilitySource_Commander';

	SetPassive(Template);

	//	Penalty to Sight Range during the night
	StatEffect = new class'X2Effect_PersistentStatChange';
	StatEffect.BuildPersistentEffect(1, true, true, false);
	StatEffect.AddPersistentStatChange(eStat_SightRadius, default.CHEETAH_GENES_SIGHT_RANGE_PENALTY_NIGHT);
	StatEffect.SetDisplayInfo(ePerkBuff_Passive, default.CheetahSightRangePenaltyTitle, default.CheetahSightRangePenaltyDesc, "img:///IRI_GeneMods.UI.GeneMod_CheetahGenes_SightDebuff", true,, 'eAbilitySource_Commander');
		TimeOfDayCondition = new class'X2Condition_TimeOfDay';
		TimeOfDayCondition.AllowedLighting = "Night";
		StatEffect.TargetConditions.AddItem(TimeOfDayCondition);
	//StatEffect.EffectName = 'IRI_GeneMod_Cheetah_SightDebuff';
	Template.AddTargetEffect(StatEffect);

	//	Bonus to Sight Range during the day
	StatEffect = new class'X2Effect_PersistentStatChange';
	StatEffect.BuildPersistentEffect(1, true, true, false);
	StatEffect.AddPersistentStatChange(eStat_SightRadius, default.CHEETAH_GENES_SIGHT_RANGE_BONUS_DAY);
	StatEffect.SetDisplayInfo(ePerkBuff_Passive, default.CheetahSightRangeBonusTitle, default.CheetahSightRangeBonusDesc, "img:///IRI_GeneMods.UI.GeneMod_CheetahGenes_SightBuff", true,, 'eAbilitySource_Commander');
		TimeOfDayCondition = new class'X2Condition_TimeOfDay';
		TimeOfDayCondition.AllowedLighting = "Day";
		StatEffect.TargetConditions.AddItem(TimeOfDayCondition);
	//StatEffect.EffectName = 'IRI_GeneMod_Cheetah_SightBuff';
	Template.AddTargetEffect(StatEffect);

	//	This contains an Event Listener that tracks the activation of abilities that involve movement.
	Effect = new class'X2Effect_IRI_CheetahGenes';
	Effect.BuildPersistentEffect(1, true, true, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,, Template.AbilitySourceName);
	Effect.DuplicateResponse = eDupe_Ignore;
	Effect.AddPersistentStatChange(eStat_HP, default.CHEETAH_GENES_HP_PENALTY);
	Template.AddShooterEffect(Effect);

	Template.AdditionalAbilities.AddItem('IRI_CheetahGenes_Penalty');

	return Template;	
}

//	This ability triggers at the start of every turn, adding an appropriate penalty caused by moving.
static function X2AbilityTemplate Create_CheetahGenes_Penalty()
{
	local X2AbilityTemplate						Template;	
	local X2Effect_IRI_CheetahGenes_Penalty		MobilityDamageEffect;
	local X2AbilityTrigger_EventListener		Trigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_CheetahGenes_Penalty');

	Template.AbilitySourceName = 'eAbilitySource_Commander';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///IRI_GeneMods.UI.GeneMod_CheetahGenes";

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'PlayerTurnBegun';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Player;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Trigger);

	//	This effect adds a mobility bonus that gets smaller as soldier is taking move actions, and can transform into a penalty.
	MobilityDamageEffect = new class 'X2Effect_IRI_CheetahGenes_Penalty';
	MobilityDamageEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	MobilityDamageEffect.DuplicateResponse = eDupe_Ignore;
	MobilityDamageEffect.EffectName = 'IRI_CheetahGenes_MobilityPenalty_Effect';
	Template.AddShooterEffect(MobilityDamageEffect);

	SetHidden(Template);

	Template.bShowActivation = false;
	Template.bSkipFireAction = true;
	Template.bUniqueSource = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;	
}

//	==========================================
//	******************************************
//				BERSERKER GLANDS
//	******************************************
//	==========================================
// Change Berserk to work like Battlelord?

static function X2AbilityTemplate Create_Berserk()
{
	local X2AbilityTemplate                 Template;	
	local X2Effect_IRI_Berserk				PanickedEffect;
	local X2Effect_IRI_Berserk_ActionPoints	ActionPointsEffect;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_RemoveEffects			RemoveEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_Berserk');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_beserker_rage";
	Template.AbilitySourceName = 'eAbilitySource_Commander';

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	AddCooldown(Template, default.BERSERK_COOLDOWN);

	if (default.BERSERK_TRIGGERED_MANUALLY)
	{
		Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
		Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
		AddFreeCost(Template);
	}

	if (default.BERSERK_TRIGGERED_BY_DAMAGE)
	{
		Trigger = new class'X2AbilityTrigger_EventListener';	
		Trigger.ListenerData.EventID = 'UnitTakeEffectDamage';
		Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
		Trigger.ListenerData.Filter = eFilter_Unit;
		Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
		Template.AbilityTriggers.AddItem(Trigger);
	}
	if (default.BERSERK_REPLACES_PANIC)
	{
		Trigger = new class'X2AbilityTrigger_EventListener';	
		Trigger.ListenerData.EventID = 'UnitPanicked';
		Trigger.ListenerData.Deferral = ELD_OnVisualizationBlockCompleted;
		Trigger.ListenerData.Filter = eFilter_Unit;
		Trigger.ListenerData.EventFn = static.Berserk_EventListener;
		Template.AbilityTriggers.AddItem(Trigger);
	
		RemoveEffects = new class'X2Effect_RemoveEffects';
		RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.PanickedName);
		Template.AddShooterEffect(RemoveEffects);
	}
	//	Makes all actions non turn-ending.
	ActionPointsEffect = new class'X2Effect_IRI_Berserk_ActionPoints';
	ActionPointsEffect.BuildPersistentEffect(1, false, , , eGameRule_PlayerTurnBegin);
	Template.AddTargetEffect(ActionPointsEffect);

	PanickedEffect = new class'X2Effect_IRI_Berserk';
	PanickedEffect.EffectName = 'IRI_Berserk_Effect'; 
	PanickedEffect.BuildPersistentEffect(default.BERSERK_DURATION, , , , eGameRule_PlayerTurnBegin);
	PanickedEffect.EffectHierarchyValue = class'X2StatusEffects'.default.PANICKED_HIERARCHY_VALUE;
	PanickedEffect.EffectAppliedEventName = 'PanickedEffectApplied';
	Template.AddTargetEffect(PanickedEffect);
	
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.Hostility = eHostility_Neutral;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;	

	//	Passive ability is just an icon.
	Template.AdditionalAbilities.AddItem('IRI_Berserk_Passive');

	return Template;	
}

static function EventListenerReturn Berserk_EventListener(Object EventData, Object EventSource, XComGameState NewGameState, name InEventID, Object CallbackData)
{
    local XComGameState_Unit            UnitState;
    local XComGameState_Ability         AbilityState;
		
	UnitState = XComGameState_Unit(EventSource);
	UnitState.bPanicked = false;
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(UnitState.FindAbility('IRI_Berserk').ObjectID));

	//`LOG("Unit panicked: " @ UnitState.GetFullName(),, 'GENEMODS');
	if (AbilityState != none)
	{
		AbilityState.AbilityTriggerAgainstSingleTarget(UnitState.GetReference(), false, NewGameState.HistoryIndex);
		//`LOG("Activated ability: " @ AbilityState.GetMyTemplateName(),, 'GENEMODS');
	}
    return ELR_InterruptEvent;
}


//	==========================================
//	******************************************
//				SECONDARY HEART
//	******************************************
//	==========================================
static function X2AbilityTemplate Create_SecondaryHeart()
{
	local X2AbilityTemplate			Template;	
	local X2Effect_Persistent		Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SecondaryHeart');

	Template.IconImage = "img:///IRI_GeneMods.UI.GeneMod_SecondaryHeart";
	Template.AbilitySourceName = 'eAbilitySource_Commander';

	SetPassive(Template);

	Effect = new class'X2Effect_Persistent';
	Effect.BuildPersistentEffect(1, true, true, false);
	Effect.bEffectForcesBleedout = default.SECONDARY_HEART_FORCES_BLEEDOUT;
	Effect.EffectName='IRI_SecondaryHeart_ForceBleedout_Effect';
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddShooterEffect(Effect);

	if (default.SECONDARY_HEART_SELF_REVIVES)
	{
		Template.AdditionalAbilities.AddItem('IRI_SecondaryHeart_Revive');
	}
	return Template;	
}

static function X2AbilityTemplate Create_SecondaryHeart_Revive()
{
	local X2AbilityTemplate					Template;	
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2Effect_RemoveEffects			RemoveEffects;
	local X2Effect_Persistent				PersistentEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SecondaryHeart_Revive');

	Template.IconImage = "img:///IRI_GeneMods.UI.GeneMod_SecondaryHeart";
	Template.AbilitySourceName = 'eAbilitySource_Commander';

	SetHidden(Template);
	AddCharges(Template, 1);

	//	Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	//Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	
	Trigger = new class'X2AbilityTrigger_EventListener';	
	Trigger.ListenerData.EventID = 'PlayerTurnBegun';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Player;
	Trigger.ListenerData.Priority = 1;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Trigger);

	//	Shooter = Target Conditions
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeAlive = false;
	UnitPropertyCondition.ExcludeHostileToSource = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.IsBleedingOut = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	//	Ability Effects
	//	Stop the real bleedout
	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.BleedingOutName);
	//	This effect should be automatically removed once the soldier starts Bleeding out, but let's add it here just in case
	RemoveEffects.EffectNamesToRemove.AddItem('IRI_SecondaryHeart_ForceBleedout_Effect');	
	Template.AddTargetEffect(RemoveEffects);
	
	//	This effect will make the soldier rise up, and it will also act as a fake bleeding out effect
	PersistentEffect = new class'X2Effect_Persistent';
	PersistentEffect.BuildPersistentEffect(3, false,,, eGameRule_PlayerTurnBegin);

	//	Rise Up
	PersistentEffect.EffectAddedFn = SelfRevivalEffectAdded; 
	PersistentEffect.VisualizationFn = SelfRevivalVisualization; 

	//	Show message that soldier is still bleeding out
	PersistentEffect.EffectTickedVisualizationFn = SelfRevivalVisualizationTicked;
	PersistentEffect.EffectName = class'X2StatusEffects'.default.BleedingOutName;
	PersistentEffect.SetDisplayInfo(ePerkBuff_Penalty, class'X2StatusEffects'.default.BleedingOutFriendlyName, class'X2StatusEffects'.default.BleedingOutFriendlyDesc, "img:///UILibrary_XPACK_Common.UIPerk_bleeding",, "img:///IRI_GeneMods.UI.status_bleedingout_alt", 'eAbilitySource_Debuff');

	//	Kill the soldier or Stabilize them
	PersistentEffect.EffectRemovedFn = class'X2StatusEffects'.static.BleedingOutEffectRemoved;
	PersistentEffect.EffectRemovedVisualizationFn = class'X2StatusEffects'.static.BleedingOutVisualizationRemoved;
	PersistentEffect.CleansedVisualizationFn = class'X2StatusEffects'.static.BleedingOutCleansedVisualization;

	//PersistentEffect.DamageTypes.AddItem('Bleeding'); // This will allow this effect to be automatically removed when healed by a Med Kit
	//	The problem is that if the soldier is immune to bleeding, they won't be able to self revive? That wouldn't make sense.

	PersistentEffect.EffectHierarchyValue = class'X2StatusEffects'.default.UNCONCIOUS_HIERARCHY_VALUE;
	Template.AddTargetEffect(PersistentEffect);

	//	Just a dummy persistent effect that's used for Secondary Heart Stabilize
	PersistentEffect = new class'X2Effect_Persistent';
	PersistentEffect.BuildPersistentEffect(3, false,,, eGameRule_PlayerTurnBegin);
	PersistentEffect.EffectName = 'IRI_SecondaryHeart_BleedingOut_Effect';
	Template.AddTargetEffect(PersistentEffect);

	//  put the unit back to full actions
	Template.AddTargetEffect(new class'X2Effect_RestoreActionPoints'); 
	
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.Hostility = eHostility_Neutral;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;	
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	return Template;	
}


static function SelfRevivalEffectAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit UnitState;
	local X2EventManager EventManager;

	EventManager = `XEVENTMGR;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		UnitState.bUnconscious = true;
		EventManager.TriggerEvent('UnitUnconscious', UnitState, UnitState, NewGameState);
		UnitState.bUnconscious = false;

		UnitState.ClearUnitValue('LadderKilledScored');
		EventManager.TriggerEvent('UnitUnconsciousRemoved', UnitState, UnitState, NewGameState);
	}
}

static function SelfRevivalVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit			UnitState;
	local X2Action_Knockback			KnockBackAction;	
	local XComGameStateVisualizationMgr VisualizationMgr;
	local XGUnit						Unit;
	local X2Action_PlaySoundAndFlyOver	SoundAndFlyOver;

	//	Copied from Unconscious Effect: Removed Viz.
	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	//Don't visualize if the unit is dead or still incapacitated.
	if( UnitState == none || UnitState.IsDead() || UnitState.IsIncapacitated() || UnitState.bRemovedFromPlay )
		return;

	//	Pan camera to unit.
	class'X2StatusEffects'.static.AddEffectCameraPanToAffectedUnitToTrack(ActionMetadata, VisualizeGameState.GetContext());

	//	Show flyover and play heartbeat sound, and hold for a couple of seconds.
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(SoundCue(`CONTENT.RequestGameArchetype("IRI_GeneMods.HeartBeat_Cue")), default.SecondaryHeartFlyover, '', eColor_Good, "img:///IRI_GeneMods.UI.GeneMod_SecondaryHeart", 0, true);
	SoundAndFlyOver.DelayDuration = 2.5f;

	//	Start playing soldier's voice and let viz continue
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'CriticallyWounded', eColor_Good, "");

	//	Green message in lower right corner.
	/*class'X2StatusEffects'.static.AddEffectMessageToTrack(
		ActionMetadata,
		default.SecondaryHeartMessage,
		VisualizeGameState.GetContext(),
		default.SecondaryHeartTitle,
		"img:///IRI_GeneMods.UI.GeneMod_SecondaryHeart",
		eUIState_Good);*/

	//	Make the unit get up.
	//Don't add duplicate knockback actions.
	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	KnockBackAction = X2Action_Knockback(VisualizationMgr.GetNodeOfType(VisualizationMgr.VisualizationTree, class'X2Action_Knockback', ActionMetadata.VisualizeActor));
	if(KnockBackAction == none)
	{
		KnockBackAction = X2Action_Knockback(class'X2Action_Knockback'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	}
	KnockBackAction.OnlyRecover = true;
	
	class'X2StatusEffects'.static.UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());

	// Need to reinit the behavior since this is destroyed upon adding the Unconscious effect (via X2Action_Death).
	Unit = XGUnit(UnitState.GetVisualizer());
	if (Unit != None && Unit.m_kBehavior == None)
	{
		Unit.InitBehavior();
	}
}

static function SelfRevivalVisualizationTicked(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Effect	EffectState;
	local XComGameState_Unit	UnitState;
	local int					iDuration;
	local string				FlyoverMessage;

	//	Similar to original, but we show the remaining bleedout duration in the flyover message.
	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState != none)
	{	
		EffectState = UnitState.GetUnitAffectedByEffectState(class'X2StatusEffects'.default.BleedingOutName);
		if (EffectState != none)
		{
			iDuration = EffectState.iTurnsRemaining;
			iDuration--;
			FlyoverMessage = class'X2StatusEffects'.default.BleedingOutFriendlyName $ ": " $ iDuration;
		}
		else
		{
			FlyoverMessage = class'X2StatusEffects'.default.BleedingOutFriendlyName;
		}
	}
	else
	{
		FlyoverMessage = class'X2StatusEffects'.default.BleedingOutFriendlyName;
	}

	class'X2StatusEffects'.static.AddEffectCameraPanToAffectedUnitToTrack(ActionMetadata, VisualizeGameState.GetContext());
	class'X2StatusEffects'.static.AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), FlyoverMessage, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_BleedingOut);
	class'X2StatusEffects'.static.AddEffectMessageToTrack(
		ActionMetadata,
		class'X2StatusEffects'.default.BleedingOutEffectTickedString,
		VisualizeGameState.GetContext(),
		FlyoverMessage,
		"img:///UILibrary_XPACK_Common.UIPerk_bleeding",
		eUIState_Bad);
	class'X2StatusEffects'.static.UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

//	We create separate Stabilize abilities which have different targeting conditions so that they can be used against soldiers
//	who are bleeding out with Secondary Heart, as they technically have `IsBleedingOut == false`.
//	Also, these Stabilize abilities don't knock the soldier Unconscious.
//	This is a bit redundant and cluttery, but it offers the best compability, as this way we don't have to mess with existing Stabilize abilities.

static function X2AbilityTemplate Create_SecondaryHeart_MedkitStabilize()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityTarget_Single            SingleTarget;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2AbilityTrigger_PlayerInput      InputTrigger;
	local X2Effect_RemoveEffects            RemoveEffects;
	local X2Condition_UnitEffects			EffectsCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SecondaryHeart_MedikitStabilize');

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = class'X2Ability_DefaultAbilitySet'.default.MEDIKIT_STABILIZE_AMMO;
	AmmoCost.bReturnChargesError = true;
	Template.AbilityCosts.AddItem(AmmoCost);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	Template.AbilityToHitCalc = default.DeadEye;
	
	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = true;
	Template.AbilityTargetStyle = SingleTarget;

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	Template.AddShooterEffectExclusions();

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeAlive = false;
	UnitPropertyCondition.ExcludeHostileToSource = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	//UnitPropertyCondition.IsBleedingOut = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	EffectsCondition = new class'X2Condition_UnitEffects';
	EffectsCondition.AddRequireEffect('IRI_SecondaryHeart_BleedingOut_Effect', 'AA_MissingRequiredEffect');
	Template.AbilityTargetConditions.AddItem(EffectsCondition);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.BleedingOutName);
	Template.AddTargetEffect(RemoveEffects);

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_stabilize";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STABILIZE_PRIORITY;
	Template.bUseAmmoAsChargesForHUD = true;
	Template.iAmmoAsChargesDivisor = class'X2Ability_DefaultAbilitySet'.default.MEDIKIT_STABILIZE_AMMO;
	Template.Hostility = eHostility_Defensive;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.bDisplayInUITooltip = false;
	Template.bLimitTargetIcons = true;

	Template.ActivationSpeech = 'StabilizingAlly';

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	return Template;
}

static function X2AbilityTemplate Create_SecondaryHeart_GremlinStabilize()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityCost_Charges             ChargeCost;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2Effect_RemoveEffects            RemoveEffects;
	local X2AbilityCharges_GremlinHeal      Charges;
	local X2Condition_UnitEffects			EffectsCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SecondaryHeart_GremlinStabilize');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Charges = new class'X2AbilityCharges_GremlinHeal';
	Charges.bStabilize = true;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	ChargeCost.SharedAbilityCharges.AddItem('GremlinHeal');
	Template.AbilityCosts.AddItem(ChargeCost);
	
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SingleTargetWithSelf;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeAlive = false;
	UnitPropertyCondition.ExcludeHostileToSource = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	//UnitPropertyCondition.IsBleedingOut = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	EffectsCondition = new class'X2Condition_UnitEffects';
	EffectsCondition.AddRequireEffect('IRI_SecondaryHeart_BleedingOut_Effect', 'AA_MissingRequiredEffect');
	Template.AbilityTargetConditions.AddItem(EffectsCondition);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.BleedingOutName);
	Template.AddTargetEffect(RemoveEffects);
	//Template.AddTargetEffect(class'X2StatusEffects'.static.CreateUnconsciousStatusEffect(, true));

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_gremlinheal";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY;
	Template.Hostility = eHostility_Defensive;
	Template.bDisplayInUITooltip = false;
	Template.bLimitTargetIcons = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;

	Template.bStationaryWeapon = true;
	Template.PostActivationEvents.AddItem('ItemRecalled');
	Template.BuildNewGameStateFn = class'X2Ability_SpecialistAbilitySet'.static.AttachGremlinToTarget_BuildGameState;
	Template.BuildVisualizationFn = class'X2Ability_SpecialistAbilitySet'.static.GremlinSingleTarget_BuildVisualization;
	
	Template.ActivationSpeech = 'MedicalProtocol';

	Template.OverrideAbilities.AddItem('IRI_SecondaryHeart_MedikitStabilize');
	Template.bOverrideWeapon = true;
	Template.CustomSelfFireAnim = 'NO_MedicalProtocol';

	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	return Template;
}


//	==========================================
//	******************************************
//		ADAPTATION / SUPERCOMPENSATION
//	******************************************
//	==========================================
//2 in 1 ability:
//Adaptation -> taking damage permanently reduces damage from this damage type. 
//Supercompensation -> when a soldier recovers from being critically wounded, their Health permanently increases by 1, but the soldier takes longer to recover.
static function X2AbilityTemplate Create_Adaptation()
{
	local X2AbilityTemplate             Template;	
	local X2Effect_SuperCompensation	SuperCompensation;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_Adaptation');

	Template.IconImage = "img:///IRI_GeneMods.UI.GeneMod_SuperCompensation";
	Template.AbilitySourceName = 'eAbilitySource_Commander';
	
	SetPassive(Template);

	SuperCompensation = new class 'X2Effect_SuperCompensation';
	SuperCompensation.BuildPersistentEffect (1, true, false);
	SuperCompensation.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddShooterEffect(SuperCompensation);

	return Template;	
}

//	==========================================
//	******************************************
//				TRANQUIL MIND
//	******************************************
//	==========================================

//	Tranquil mind is a dummy passive ability, the actual function of the ability happens in OPTC.
static function X2AbilityTemplate Create_TranquilMind()
{
	local X2AbilityTemplate                 Template;	

	Template = PurePassive('IRI_TranquilMind', "img:///IRI_GeneMods.UI.GeneMod_TranquilMind",, 'eAbilitySource_Commander');

	// Note: DO NOT color this icon as eAbilitySource_Psionic, or the icon effect will not apply to the soldier
	// due to Condition we add to all psionic abilities in OPTC.
	Template.AbilitySourceName = 'eAbilitySource_Commander';

	return Template;	
}

//	==========================================
//	******************************************
//				CHAOTIC MIND
//	******************************************
//	==========================================

static function X2AbilityTemplate Create_ChaoticMind()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityTrigger_EventListener	TurnEndTrigger;
	local X2Effect_ApplyWeaponDamage        DamageEffect;
	local X2AbilityMultiTarget_Radius       RadiusMultiTarget;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local array<name>                       SkipExclusions;
	local X2Condition_ExcludeSoldierAbility	Condition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_ChaoticMind');

	Template.IconImage = "img:///IRI_GeneMods.UI.GeneMod_ChaoticMind";
	Template.AbilitySourceName = 'eAbilitySource_Commander';

	//	Giving it a 1 turn cooldown so that the Event Listener doesn't activate it more than once per turn,
	//	which can happen if there are several soldiers with this ability.
	AddCooldown(Template, default.CHAOTIC_MIND_COOLDOWN);
	
	//	Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	TurnEndTrigger = new class'X2AbilityTrigger_EventListener';
	TurnEndTrigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	TurnEndTrigger.ListenerData.EventID = 'PlayerTurnEnded';
	TurnEndTrigger.ListenerData.Filter = eFilter_Player;
	TurnEndTrigger.ListenerData.EventFn = static.ChaoticMind_Listener;
	Template.AbilityTriggers.AddItem(TurnEndTrigger);

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';	
	RadiusMultiTarget.fTargetRadius = default.CHAOTIC_MIND_RADIUS_METERS;						
	RadiusMultiTarget.bIgnoreBlockingCover = true; 
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	// Shooter conditions
	//	Apply standard ability restrictions except burning
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	//	Make this ability fail to trigger if soldier has Tranquil Mind
	//	Normally the soldier shouldn't have both, but just in case.
	Condition = new class'X2Condition_ExcludeSoldierAbility';
	Condition.ExcludeAbility = 'IRI_TranquilMind';
	Template.AbilityShooterConditions.AddItem(Condition);

	// Multi Target Conditions
	//	Any living unit can be affected
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	//UnitPropertyCondition.ExcludeRobotic = true;	//	The ability deals mental damage by default, which robots are immune to anyway.
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	// Effects
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.bAllowFreeKill = false;
	DamageEffect.EffectDamageValue = default.CHAOTIC_MIND_DAMAGE;
	Template.AddMultiTargetEffect(DamageEffect);
	Template.bAllowBonusWeaponEffects = false;
	
	Template.bSkipFireAction = false;
	Template.bShowActivation = true;
	Template.bSkipExitCoverWhenFiring = true;
	Template.CustomSelfFireAnim = 'HL_ChaoticMind';
	Template.CinescriptCameraType = "ChaoticMind_Camera";	
	Template.ActivationSpeech = 'SoldierControlled';

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;	

	//	This is an offensive action that can be interrupted
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.Hostility = eHostility_Offensive;
	
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	Template.AdditionalAbilities.AddItem('IRI_ChaoticMind_Passive');
	Template.AssociatedPassives.AddItem('IRI_ChaoticMind_Passive');

	return Template;	
}

//	The PlayerTurnEnded event doesn't provide any information about Units or Abilities, so I don't know how to tie the event activation
//	to any specific unit. So this Event Listener will cycle through all valid Units that have this ability, and activate all of them.
//	The "trick" is that the event listener will trigger once for every soldier with this ability, so basically each soldier with this ability
//	will try to trigger Chaotic Mind on all soldiers that have it. 
//	So if you have X units with Chaotic Mind, each unit would try to activate this ability X times.
//	We give it a 1 turn cooldown to prevent this from happening.
static function EventListenerReturn ChaoticMind_Listener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local array<StateObjectReference>	UnitsOnTile;
	local StateObjectReference			UnitRef;

	local XComGameState_Ability	AbilityState;
	local XComGameStateHistory	History;
	local XComGameState_Unit	UnitState;
	local XComGameState_Unit	PotentialTarget;
	local float					AbilityRadius;
	local XComWorldData			WorldData;
	local vector				TargetLocation;
	local array<TilePosPair>	Tiles;
	local bool					bActivateAbility;
	local int i;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;
	//`LOG("Listener activated.",, 'GENEMODS');

	//	Cycle through all Unit States as they were the moment "Player Turn Ended" event has triggered.
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState,,, GameState.HistoryIndex)
	{
		//`LOG("Player turn ended for unit: " @ UnitState.GetFullName(),, 'GENEMODS');

		//	Try to find the Chaotic Mind ability on the unit.
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitState.FindAbility('IRI_ChaoticMind').ObjectID));

		//	If there is one, and the unit itself is not immune to Mental damage (i.e. doesn't have a Mindshield or affected by Solace)
		if (AbilityState != none && !UnitState.IsImmuneToDamage(default.CHAOTIC_MIND_DAMAGE.DamageType))
		{
			//	Grab tiles in the ability radius
			AbilityRadius = AbilityState.GetAbilityRadius();
			TargetLocation = WorldData.GetPositionFromTileCoordinates(UnitState.TileLocation);
			WorldData.CollectTilesInSphere(Tiles, TargetLocation, AbilityRadius);

			//`LOG("Unit has ability and can activate it, checking if there are targets in range.",, 'GENEMODS');
			//	Cycle through those tiles
			for (i = 0; i < Tiles.Length; i++)
			{
				// For each tile, grab any Units standing on that tile
				UnitsOnTile = WorldData.GetUnitsOnTile(Tiles[i].Tile);
				foreach UnitsOnTile(UnitRef)
				{
					PotentialTarget = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
					//`LOG("Found unit in range:" @ PotentialTarget.GetFullName(),, 'GENEMODS');
					if (PotentialTarget.IsAlive() &&
						!PotentialTarget.IsImmuneToDamage(default.CHAOTIC_MIND_DAMAGE.DamageType) &&	
						PotentialTarget.ObjectID != UnitState.ObjectID)	
					{
						//`LOG("It's a valid target, activating.",, 'GENEMODS');
						bActivateAbility = true;
						break;
					}
				}
				if (bActivateAbility) break;
			}
			if (bActivateAbility)
			{
				//`LOG("Activate, activate, activate.",, 'GENEMODS');
				AbilityState.AbilityTriggerAgainstSingleTarget(UnitState.GetReference(), false);
			}
		}
	}
	return ELR_NoInterrupt;
}

//	Passive component: adds Psi Offense bonus and the ability animation.
static function X2AbilityTemplate Create_ChaoticMind_Passive()
{
	local X2AbilityTemplate                 Template;	
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;
	local X2Effect_AdditionalAnimSets		AnimSetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_ChaoticMind_Passive');

	Template.IconImage = "img:///IRI_GeneMods.UI.GeneMod_ChaoticMind";
	Template.AbilitySourceName = 'eAbilitySource_Commander';

	SetPassive(Template);
	SetHidden(Template);
	
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true, , Template.AbilitySourceName);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_PsiOffense, default.CHAOTIC_MIND_PSI_OFFENSE);
	PersistentStatChangeEffect.EffectName = 'IRI_ChaoticMind_Effect';
	Template.AddTargetEffect(PersistentStatChangeEffect);

	AnimSetEffect = new class'X2Effect_AdditionalAnimSets';
	AnimSetEffect.AddAnimSetWithPath("IRI_GeneMods.Anims.AS_ChaoticMind");
	AnimSetEffect.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(AnimSetEffect);

	return Template;	
}

//	========================================
//				COMMON CODE
//	========================================

static function AddCooldown(out X2AbilityTemplate Template, int Cooldown)
{
	local X2AbilityCooldown AbilityCooldown;

	if (Cooldown > 0)
	{
		AbilityCooldown = new class'X2AbilityCooldown';
		AbilityCooldown.iNumTurns = Cooldown;
		Template.AbilityCooldown = AbilityCooldown;
	}
}

static function AddCharges(out X2AbilityTemplate Template, int InitialCharges)
{
	local X2AbilityCharges		Charges;
	local X2AbilityCost_Charges	ChargeCost;

	if (InitialCharges > 0)
	{
		Charges = new class'X2AbilityCharges';
		Charges.InitialCharges = InitialCharges;
		Template.AbilityCharges = Charges;

		ChargeCost = new class'X2AbilityCost_Charges';
		ChargeCost.NumCharges = 1;
		Template.AbilityCosts.AddItem(ChargeCost);
	}
}

static function AddFreeCost(out X2AbilityTemplate Template)
{
	local X2AbilityCost_ActionPoints ActionPointCost;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);
}

static function SetHidden(out X2AbilityTemplate Template)
{
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.bDisplayInUITacticalText = false;
	Template.bDisplayInUITooltip = false;
	Template.bDontDisplayInAbilitySummary = true;
	Template.bHideOnClassUnlock = true;
}

static function SetPassive(out X2AbilityTemplate Template)
{
	Template.bIsPassive = true;

	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.bDisplayInUITacticalText = true;
	Template.bDisplayInUITooltip = true;
	Template.bDontDisplayInAbilitySummary = false;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Template.Hostility = eHostility_Neutral;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
}


static function RemoveVoiceLines(out X2AbilityTemplate Template)
{
	Template.ActivationSpeech = '';
	Template.SourceHitSpeech = '';
	Template.TargetHitSpeech = '';
	Template.SourceMissSpeech = '';
	Template.TargetMissSpeech = '';
	Template.TargetKilledByAlienSpeech = '';
	Template.TargetKilledByXComSpeech = '';
	Template.MultiTargetsKilledByAlienSpeech = '';
	Template.MultiTargetsKilledByXComSpeech = '';
	Template.TargetWingedSpeech = '';
	Template.TargetArmorHitSpeech = '';
	Template.TargetMissedSpeech = '';
}

static function X2AbilityTemplate Create_AnimSet_Passive(name TemplateName, string AnimSetPath)
{
	local X2AbilityTemplate                 Template;
	local X2Effect_AdditionalAnimSets		AnimSetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	SetPassive(Template);
	SetHidden(Template);
	
	AnimSetEffect = new class'X2Effect_AdditionalAnimSets';
	AnimSetEffect.AddAnimSetWithPath(AnimSetPath);
	AnimSetEffect.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(AnimSetEffect);

	return Template;
}

static function SetAnimation(out X2AbilityTemplate Template, name CustomFireAnim)
{
	Template.CustomFireAnim = CustomFireAnim;
	Template.CustomFireKillAnim = CustomFireAnim;
	Template.CustomMovingFireAnim = CustomFireAnim;
	Template.CustomMovingFireKillAnim = CustomFireAnim;
	Template.CustomMovingTurnLeftFireAnim = CustomFireAnim;
	Template.CustomMovingTurnLeftFireKillAnim = CustomFireAnim;
	Template.CustomMovingTurnRightFireAnim = CustomFireAnim;
	Template.CustomMovingTurnRightFireKillAnim = CustomFireAnim;
}