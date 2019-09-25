class X2Effect_IRI_CheetahGenes_Penalty extends X2Effect_ModifyStats config(GeneMods);

var localized string CheetahPenaltyFlyover;
var localized string CheetahRecoveryFlyover;
var localized string CheetahFullRecoveryFlyover;

var config int InitialMobility_LightArmor;
var config int InitialMobility_MediumArmor;
var config int InitialMobility_HeavyArmor;

var config int CHEETAH_GENES_MOBILITY_LOST_PER_TURN;
var config int CHEETAH_GENES_MOBILITY_RESTORED_PER_TURN;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local StatChange			NewChange;
	local XComGameState_Unit	UnitState;
	local int					InitialMobilityBonus;
	local int					CurrentMobilityPenalty;
	local UnitValue				MovesLastTurn;
	local UnitValue				MobilityPenaltyValue;

	//	Grab the Unit State of the soldier we're applying effect to
	UnitState = XComGameState_Unit(kNewTargetState);

	//	=== Calculate initial mobility bonus granted by this effect, before any accumulated penalties.
	//	Initial bonus depends on equipped armor.
	InitialMobilityBonus = GetInitialMobilityBonus(UnitState);

	//	=== Calculate accumulated mobility penalty.
	//	Since we're checking On Turn Begin, MovesThisTurn actually means "moves last turn".
	UnitState.GetUnitValue('IRI_CheetahGenes_UnitMovedThisTurn', MovesLastTurn);
	UnitState.GetUnitValue('IRI_CheetahGenes_PenaltyValue', MobilityPenaltyValue);

	CurrentMobilityPenalty = MobilityPenaltyValue.fValue;

	`LOG("Cheetah Genes effect applied to: " @ UnitState.GetFullName(), class'X2Effect_IRI_CheetahGenes'.default.ENABLE_LOGGING, 'GENEMODS');
	`LOG("MovesLastTurn: " @ MovesLastTurn.fValue, class'X2Effect_IRI_CheetahGenes'.default.ENABLE_LOGGING, 'GENEMODS');
	`LOG("InitialMobilityBonus: " @ InitialMobilityBonus, class'X2Effect_IRI_CheetahGenes'.default.ENABLE_LOGGING, 'GENEMODS');
	`LOG("CurrentMobilityPenalty: " @ MobilityPenaltyValue.fValue, class'X2Effect_IRI_CheetahGenes'.default.ENABLE_LOGGING, 'GENEMODS');

	if (MovesLastTurn.fValue > 0)
	{
		CurrentMobilityPenalty += default.CHEETAH_GENES_MOBILITY_LOST_PER_TURN;
		`LOG("Soldier moved last turn, increasing penalty to : " @ CurrentMobilityPenalty, class'X2Effect_IRI_CheetahGenes'.default.ENABLE_LOGGING, 'GENEMODS');
		UnitState.SetUnitFloatValue('IRI_CheetahGenes_Penalty_Increased', 1, eCleanup_BeginTurn);
	}
	else
	{
		CurrentMobilityPenalty += default.CHEETAH_GENES_MOBILITY_RESTORED_PER_TURN;
		`LOG("Soldier didn't move last turn, reducing penalty to : " @ CurrentMobilityPenalty, class'X2Effect_IRI_CheetahGenes'.default.ENABLE_LOGGING, 'GENEMODS');
		UnitState.SetUnitFloatValue('IRI_CheetahGenes_Penalty_Reduced', 1, eCleanup_BeginTurn);
	}

	if (CurrentMobilityPenalty > 0) 
	{
		CurrentMobilityPenalty = 0;
		`LOG("Penalty fully compensated, soldier is rested.", class'X2Effect_IRI_CheetahGenes'.default.ENABLE_LOGGING, 'GENEMODS');
	}

	//	Record the penalty to use again next turn.
	UnitState.SetUnitFloatValue('IRI_CheetahGenes_PenaltyValue', CurrentMobilityPenalty, eCleanup_BeginTactical);

	//	=== Calculate resulting mobility change and apply it.

	`LOG("Applying final mobility change: " @ InitialMobilityBonus + CurrentMobilityPenalty, class'X2Effect_IRI_CheetahGenes'.default.ENABLE_LOGGING, 'GENEMODS');

	NewChange.StatType = eStat_Mobility;
	NewChange.StatAmount = InitialMobilityBonus + CurrentMobilityPenalty;	
	NewChange.ModOp = MODOP_Addition;				
	NewEffectState.StatChanges.AddItem(NewChange);

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

static function int GetFinalMobilityChange(XComGameState_Unit UnitState)
{
	return GetInitialMobilityBonus(UnitState) + GetCurrentMobilityPenalty(UnitState);
}

static function int GetCurrentMobilityPenalty(XComGameState_Unit UnitState)
{
	local UnitValue	MobilityPenaltyValue;
	local int		CurrentMobilityPenalty;

	UnitState.GetUnitValue('IRI_CheetahGenes_PenaltyValue', MobilityPenaltyValue);
	CurrentMobilityPenalty = MobilityPenaltyValue.fValue;

	if (CurrentMobilityPenalty > 0) 
	{
		CurrentMobilityPenalty = 0;
	}

	return CurrentMobilityPenalty;
}

static function int GetInitialMobilityBonus(XComGameState_Unit UnitState)
{
	local name EquippedArmorClass;

	EquippedArmorClass = GetEquippedArmorClass(UnitState);

	switch (EquippedArmorClass)
	{
		case 'light':
			return default.InitialMobility_LightArmor;
		case 'heavy':
			return default.InitialMobility_HeavyArmor;
		case 'basic': 
			return default.InitialMobility_MediumArmor;
		case 'medium':
			return default.InitialMobility_MediumArmor;
		case 'unknown':
			return default.InitialMobility_MediumArmor;
		default:
			return default.InitialMobility_MediumArmor;
	}
}

static function name GetEquippedArmorClass(XComGameState_Unit UnitState)
{
	local XComGameState_Item ItemState;
	local X2ArmorTemplate ArmorTemplate;

	ItemState = UnitState.GetItemInSlot(eInvSlot_Armor);

	if (ItemState != none) ArmorTemplate = X2ArmorTemplate(ItemState.GetMyTemplate());

	if (ArmorTemplate != none) return ArmorTemplate.ArmorClass;

	return '';
}

//	Just in case, reset soldier animation speed when the effect is removed.
simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit UnitState;

	if (class'X2Effect_IRI_CheetahGenes'.default.CHEETAH_GENES_SPEED_UP_RUN_ANIMATION)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));

		XComHumanPawn(XGUnit(UnitState.GetVisualizer()).GetPawn()).Mesh.GlobalAnimRateScale = 1;
		XComHumanPawn(XGUnit(UnitState.GetVisualizer()).GetPawn()).Mesh.bPerBoneMotionBlur = false;
	}
	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver	SoundAndFlyOver;
	local XComGameState_Unit			UnitState;
	local UnitValue						PenaltyStatus;
	local int							InitialMobilityBonus;
	local int							CurrentMobilityBonus;
	local string						FlyoverText;

	if (EffectApplyResult == 'AA_Success')
	{
		UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

		InitialMobilityBonus = GetInitialMobilityBonus(UnitState);
		CurrentMobilityBonus = GetFinalMobilityChange(UnitState);

		`LOG("Cheetah Genes displaying flyover for: " @ UnitState.GetFullName(), class'X2Effect_IRI_CheetahGenes'.default.ENABLE_LOGGING, 'GENEMODS');
		`LOG("InitialMobilityBonus: " @ InitialMobilityBonus, class'X2Effect_IRI_CheetahGenes'.default.ENABLE_LOGGING, 'GENEMODS');
		`LOG("CurrentMobilityBonus: " @ CurrentMobilityBonus, class'X2Effect_IRI_CheetahGenes'.default.ENABLE_LOGGING, 'GENEMODS');

		//	Display Flyover for Cheetah's mobility bonus/penalty

		//	Show "Well Rested" flyover.
		if (CurrentMobilityBonus == InitialMobilityBonus)
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, default.CheetahFullRecoveryFlyover, '', eColor_Good, "img:///IRI_GeneMods.UI.GeneMod_CheetahGenes");
		}
		else
		{
			//	Mobility got worse this turn, so whow red flyover with current mobility bonus/penalty.
			if (UnitState.GetUnitValue('IRI_CheetahGenes_Penalty_Increased', PenaltyStatus))
			{
				if (CurrentMobilityBonus > 0)
				{
					FlyoverText = default.CheetahPenaltyFlyover $ "+" $ CurrentMobilityBonus;
				}
				else
				{
					FlyoverText = default.CheetahPenaltyFlyover $ CurrentMobilityBonus;
				}

				SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
				SoundAndFlyOver.SetSoundAndFlyOverParameters(None, FlyoverText, '', eColor_Bad, "img:///IRI_GeneMods.UI.GeneMod_CheetahGenes");
			}

			//	Mobility got better this turn, so show green flyover.
			if (UnitState.GetUnitValue('IRI_CheetahGenes_Penalty_Reduced', PenaltyStatus))
			{
				if (CurrentMobilityBonus > 0)
				{
					FlyoverText = default.CheetahRecoveryFlyover $ "+" $ CurrentMobilityBonus;
				}
				else
				{
					FlyoverText = default.CheetahRecoveryFlyover $ CurrentMobilityBonus;
				}
				SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
				SoundAndFlyOver.SetSoundAndFlyOverParameters(None, FlyoverText, '', eColor_Good, "img:///IRI_GeneMods.UI.GeneMod_CheetahGenes"); //, `DEFAULTFLYOVERLOOKATTIME, true
			}
		}
	}

	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}