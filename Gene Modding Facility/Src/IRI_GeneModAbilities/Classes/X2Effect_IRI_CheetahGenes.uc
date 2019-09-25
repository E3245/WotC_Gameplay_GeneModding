class X2Effect_IRI_CheetahGenes extends X2Effect_PersistentStatChange config(GeneMods);

var localized string CheetahSightRangePenaltyFlyover;
var localized string CheetahSightRangeBonusFlyover;

var config bool ENABLE_LOGGING;
var config bool CHEETAH_GENES_SPEED_UP_RUN_ANIMATION;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;
    local XComGameState_Unit UnitState;
    
	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

    EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', CheckForMovingAbility_Listener, ELD_OnStateSubmitted,, UnitState);	

	super.RegisterForEvents(EffectGameState);
}

static function EventListenerReturn CheckForMovingAbility_Listener(Object EventData, Object EventSource, XComGameState NewGameState, name InEventID, Object CallbackData)
{
    local XComGameState_Unit            UnitState;
    local XComGameState_Ability         AbilityState;
	local X2AbilityTemplate				AbilityTemplate;
	local float							CurrentMobilityBonus;
		
	AbilityState = XComGameState_Ability(EventData);
	UnitState = XComGameState_Unit(EventSource);
	AbilityTemplate = AbilityState.GetMyTemplate();

	CurrentMobilityBonus = class'X2Effect_IRI_CheetahGenes_Penalty'.static.GetFinalMobilityChange(UnitState);

	//	Clamp the effect so we don't end up slowing down soldier animations.
	if (CurrentMobilityBonus < 0) CurrentMobilityBonus = 0;

	if (AbilityTemplate.TargetingMethod.Class == class'X2TargetingMethod_PathTarget' ||
		AbilityTemplate.TargetingMethod.Class == class'X2TargetingMethod_MeleePath' ||
		AbilityTemplate.AbilityTargetStyle.Class == class'X2AbilityTarget_MovingMelee' ||
		AbilityTemplate.AbilityTargetStyle.Class == class'X2AbilityTarget_Path')
	{
		`LOG("Cheetah Genes -> detecting movement, unit: " @ UnitState.GetFullName() @ "ability: " @ AbilityTemplate.DataName, default.ENABLE_LOGGING, 'GENEMODS');
		UnitState.SetUnitFloatValue('IRI_CheetahGenes_UnitMovedThisTurn', 1, eCleanup_BeginTurn);

		if (default.CHEETAH_GENES_SPEED_UP_RUN_ANIMATION)
		{
			//	Increase animation speed for movement actions
			XComHumanPawn(XGUnit(UnitState.GetVisualizer()).GetPawn()).Mesh.GlobalAnimRateScale = 1 + CurrentMobilityBonus / 10;
			XComHumanPawn(XGUnit(UnitState.GetVisualizer()).GetPawn()).Mesh.bPerBoneMotionBlur = true;
		}
	}
	else
	{
		if (default.CHEETAH_GENES_SPEED_UP_RUN_ANIMATION)
		{
			//	Reset animation speed for other actions
			XComHumanPawn(XGUnit(UnitState.GetVisualizer()).GetPawn()).Mesh.GlobalAnimRateScale = 1;
			XComHumanPawn(XGUnit(UnitState.GetVisualizer()).GetPawn()).Mesh.bPerBoneMotionBlur = false;
		}
	}
	
    return ELR_NoInterrupt;
}

//	Just in case, reset soldier animation speed when the effect is removed.
simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit UnitState;

	if (default.CHEETAH_GENES_SPEED_UP_RUN_ANIMATION)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));

		XComHumanPawn(XGUnit(UnitState.GetVisualizer()).GetPawn()).Mesh.GlobalAnimRateScale = 1;
		XComHumanPawn(XGUnit(UnitState.GetVisualizer()).GetPawn()).Mesh.bPerBoneMotionBlur = false;
	}
	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);
}

/*
simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver	SoundAndFlyOver;
	local XComGameState_Unit			UnitState;

	if (EffectApplyResult == 'AA_Success')
	{
		UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

		// Display flyover for Cheetah's sight range bonus/penalty

		if (UnitState.IsUnitAffectedByEffectName('IRI_GeneMod_Cheetah_SightBuff'))
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, default.CheetahSightRangeBonusFlyover, '', eColor_Good, "img:///IRI_GeneMods.UI.GeneMod_CheetahGenes_SightBuff", `DEFAULTFLYOVERLOOKATTIME, true);
		}
		if (UnitState.IsUnitAffectedByEffectName('IRI_GeneMod_Cheetah_SightDebuff'))
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, default.CheetahSightRangePenaltyFlyover, '', eColor_Bad, "img:///IRI_GeneMods.UI.GeneMod_CheetahGenes_SightDebuff", `DEFAULTFLYOVERLOOKATTIME, true);
		}
	}

	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}*/