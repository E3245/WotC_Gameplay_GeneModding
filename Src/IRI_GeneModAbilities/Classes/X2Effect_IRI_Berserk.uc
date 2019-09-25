class X2Effect_IRI_Berserk extends X2Effect_Berserk config(GeneMods);

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> InActionPoints, XComGameState_Effect EffectState)
{
	// Disable player control while panic is in effect.
	InActionPoints.Length = 0;
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	local Name PanicBehaviorTree;
	local int Point;
	
	UnitState = XComGameState_Unit(kNewTargetState);
	/*
	if (m_aStatChanges.Length > 0)
	{
		NewEffectState.StatChanges = m_aStatChanges;

		//  Civilian panic does not modify stats and does not need to call the parent functions (which will result in a RedScreen for having no stats!)
		super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
	}*/

	for( Point = 0; Point < ActionPoints; ++Point )
	{
		if( Point < UnitState.ActionPoints.Length )
		{
			if( UnitState.ActionPoints[Point] != class'X2CharacterTemplateManager'.default.StandardActionPoint )
			{
				UnitState.ActionPoints[Point] = class'X2CharacterTemplateManager'.default.StandardActionPoint;
			}
		}
		else
		{
			UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
		}
	}
	
	//	don't set Panickd state so that the soldier doesn't consider allies as hostile
	//UnitState.bPanicked = true;

	//`XEVENTMGR.TriggerEvent('UnitPanicked', UnitState, UnitState, NewGameState);

	PanicBehaviorTree = Name(BehaviorTreeRoot);

	// Delayed behavior tree kick-off.  Points must be added and game state submitted before the behavior tree can 
	// update, since it requires the ability cache to be refreshed with the new action points.
	UnitState.AutoRunBehaviorTree(PanicBehaviorTree, BTRunCount, `XCOMHISTORY.GetCurrentHistoryIndex() + 1, true);
	
}

//	Copy of the original so that voiceline can be replaced
simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata BuildTrack, name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	//super.AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, EffectApplyResult);

	if( EffectApplyResult != 'AA_Success' )
	{
		return;
	}

	// pan to the panicking unit (but only if it isn't a civilian)
	UnitState = XComGameState_Unit(BuildTrack.StateObject_NewState);
	if (UnitState == none)
		return;

	if(!UnitState.IsCivilian())

	class'X2StatusEffects'.static.AddEffectCameraPanToAffectedUnitToTrack(BuildTrack, VisualizeGameState.GetContext());
	class'X2StatusEffects'.static.AddEffectSoundAndFlyOverToTrack(BuildTrack, VisualizeGameState.GetContext(), EffectFriendlyName, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Panicked); //PanicScream'
	class'X2StatusEffects'.static.AddEffectMessageToTrack(BuildTrack,
															default.EffectAcquiredString,
															VisualizeGameState.GetContext(),
															class'UIEventNoticesTactical'.default.PanickedTitle,
															"img:///UILibrary_PerkIcons.UIPerk_panic",
															eUIState_Bad,
															true); // no audio event for panic, since the will test audio would overlap
	

	class'X2StatusEffects'.static.UpdateUnitFlag(BuildTrack, VisualizeGameState.GetContext());
}

DefaultProperties
{

}