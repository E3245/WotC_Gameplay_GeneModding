class X2EventListener_GeneMods extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateListenerTemplateOnCleanupTacticalMission());

	return Templates;
}

static function CHEventListenerTemplate CreateListenerTemplateOnCleanupTacticalMission()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'GeneMods_CleanupTacticalMission');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = false;

	Template.AddCHEvent('CleanupTacticalMission', OnCleanupTacticalMission, ELD_OnStateSubmitted);

	return Template;
}

static function EventListenerReturn OnCleanupTacticalMission(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_BattleData BattleData;
	local XComGameState_Unit Unit;
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;

    History = `XCOMHISTORY;
    BattleData = XComGameState_BattleData(EventData);
    BattleData = XComGameState_BattleData(GameState.GetGameStateForObjectID(BattleData.ObjectID));

	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if(Unit.IsAlive() && !Unit.bCaptured)
		{
			foreach Unit.AffectedByEffects(EffectRef)
			{
				EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
				if (EffectState.GetX2Effect().EffectName == class'X2Effect_SuperCompensation'.default.EffectName)
				{
					X2Effect_SuperCompensation(EffectState.GetX2Effect()).ApplySupercompensation(EffectState, Unit, GameState);
				}
			}
		}
	}

	return ELR_NoInterrupt;
}