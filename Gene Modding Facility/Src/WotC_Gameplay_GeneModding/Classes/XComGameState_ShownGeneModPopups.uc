class XComGameState_ShownGeneModPopups extends XComGameState_BaseObject;

struct UnitNegativeTraitsStruct
{
	var int ObjectID;
	var array<name> TraitTemplateNames;
};

var array<UnitNegativeTraitsStruct> UnitNegativeTraits;

var array<Name> DisplayedPopups;

const bLog = false;

private static function XComGameState_ShownGeneModPopups GetOrCreate(out XComGameState NewGameState)
{
	local XComGameStateHistory				History;
	local XComGameState_ShownGeneModPopups	StateObject;

	History = `XCOMHISTORY;

	`LOG("Get or create XComGameState_ShownGeneModPopups", bLog, 'IRIGENEPOP');
	
	StateObject = XComGameState_ShownGeneModPopups(History.GetSingleGameStateObjectForClass(class'XComGameState_ShownGeneModPopups', true));

	if (StateObject == none)
	{
		`LOG("State object doesn't exist, creating new one", bLog, 'IRIGENEPOP');
		
		StateObject = XComGameState_ShownGeneModPopups(NewGameState.CreateNewStateObject(class'XComGameState_ShownGeneModPopups'));
	}
	else 
	{
		`LOG("State object already exists, returning reference", bLog, 'IRIGENEPOP');
		StateObject = XComGameState_ShownGeneModPopups(NewGameState.ModifyStateObject(class'XComGameState_ShownGeneModPopups', StateObject.ObjectID));
	}

	return StateObject; 
}

private function bool WasPopupDisplayedAlready(name GeneModTemplateName)
{
	`LOG("Checking if the popup was already shown for " @ GeneModTemplateName, bLog, 'IRIGENEPOP');

	if (DisplayedPopups.Find(GeneModTemplateName) != INDEX_NONE)
	{
		`LOG("It was.", bLog, 'IRIGENEPOP');
		return true;
	}
	`LOG("It was NOT.", bLog, 'IRIGENEPOP');
	return false;
}

public static function DisplayPopupOnce(X2GeneModTemplate GeneModTemplate)
{
	local XComGameState_ShownGeneModPopups	NewStateObject;
	local XComGameState						NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Displaying popup for: " @ GeneModTemplate.DataName);
	NewStateObject = static.GetOrCreate(NewGameState);

	//	If the popup has been displayed already
	if (NewStateObject.WasPopupDisplayedAlready(GeneModTemplate.DataName))
	{
		// Don't do anything
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}
	else
	{
		`LOG("Displaying popup for" @ GeneModTemplate.DataName, bLog, 'IRIGENEPOP');
		class'X2Helpers_BuildAlert_GeneMod'.static.GM_UINewGeneModAvailable(GeneModTemplate);

		NewStateObject.DisplayedPopups.AddItem(GeneModTemplate.DataName);

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

//===============================================================================================================
//===============================================================================================================
//	Functions for handling negative traits acquired by soldiers as the result of cancelling the Gene Modding process.


public static function TrackAddedNegativeTraitForUnit(out XComGameState NewGameState, const out XComGameState_Unit UnitState, const name TraitTemplateName)
{
	local XComGameState_ShownGeneModPopups	NewStateObject;

	NewStateObject = static.GetOrCreate(NewGameState);

	NewStateObject.TrackNegativeTraitForUnit(UnitState, TraitTemplateName);
}


//	Removes from the specified unit negative traits acquired due to cancelling the Gene Modding process.
//	Note: requires unprotecting these arrays in XComGameState_Unit in order for the mod to compile.
//var() /*protectedwrite*/ array<name> AcquiredTraits;
//var() /*protectedwrite*/ array<name> CuredTraits;	
//var() /*protectedwrite*/ array<NegativeTraitRecoveryInfo> NegativeTraits;

public static function CureNegativeTraitsForUnit(out XComGameState_Unit NewUnitState, out XComGameState NewGameState)
{
	local XComGameState_ShownGeneModPopups	NewStateObject;
	local int								CurrentTraitIndex;
	local X2TraitTemplate					CurrentTraitTemplate;
	local X2EventListenerTemplateManager	EventTemplateManager;

	NewStateObject = static.GetOrCreate(NewGameState);

	EventTemplateManager = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();

	for( CurrentTraitIndex = NewUnitState.NegativeTraits.Length - 1; CurrentTraitIndex >= 0; --CurrentTraitIndex )
	{
		if (NewStateObject.IsTrackingNegativeTraitForUnit(NewUnitState, CurrentTraitTemplate.DataName))
		{
			// cure the trait
			CurrentTraitTemplate = X2TraitTemplate(EventTemplateManager.FindEventListenerTemplate(NewUnitState.NegativeTraits[CurrentTraitIndex].TraitName));

			NewUnitState.AcquiredTraits.Remove(CurrentTraitIndex, 1);

			NewUnitState.NegativeTraits.Remove(CurrentTraitIndex, 1);

			NewUnitState.CuredTraits.AddItem(CurrentTraitTemplate.DataName);

			NewStateObject.StopTrackingNegativeTraitForUnit(NewUnitState, CurrentTraitTemplate.DataName);
		}
	}

	// Show popup here?

	`XEVENTMGR.TriggerEvent( 'UnitTraitsChanged', NewUnitState, , NewGameState );
}

//	A host of helper functions used to track which negative traits have been acquired by the unit as the result of cancelling Gene Modding process.
private simulated function TrackNegativeTraitForUnit(const XComGameState_Unit UnitState, const name TraitTemplateName)
{
	local UnitNegativeTraitsStruct NewNegativeTrait;
	local int i;

	for (i = 0; i < UnitNegativeTraits.Length; i++)
	{
		if (UnitNegativeTraits[i].ObjectID == UnitState.ObjectID)
		{
			UnitNegativeTraits[i].TraitTemplateNames.AddItem(TraitTemplateName);
			return;
		}
	}

	NewNegativeTrait.ObjectID = UnitState.ObjectID;
	NewNegativeTrait.TraitTemplateNames.AddItem(TraitTemplateName);
	UnitNegativeTraits.AddItem(NewNegativeTrait);
}

private simulated function bool IsTrackingNegativeTraitForUnit(const XComGameState_Unit UnitState, const name TraitTemplateName)
{
	local int i;

	for (i = 0; i < UnitNegativeTraits.Length; i++)
	{
		if (UnitNegativeTraits[i].ObjectID == UnitState.ObjectID)
		{
			return UnitNegativeTraits[i].TraitTemplateNames.Find(TraitTemplateName) != INDEX_NONE;
		}
	}
	return false;
}

private simulated function StopTrackingNegativeTraitForUnit(const XComGameState_Unit UnitState, const name TraitTemplateName)
{
	local int i;

	for (i = 0; i < UnitNegativeTraits.Length; i++)
	{
		if (UnitNegativeTraits[i].ObjectID == UnitState.ObjectID)
		{
			UnitNegativeTraits[i].TraitTemplateNames.RemoveItem(TraitTemplateName);

			if (UnitNegativeTraits[i].TraitTemplateNames.Length == 0)
			{
				UnitNegativeTraits.Remove(i, 1);
			}

			return;
		}
	}
}