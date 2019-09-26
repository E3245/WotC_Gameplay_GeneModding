class XComGameState_ShownGeneModPopups extends XComGameState_BaseObject;

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
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Creating Gene Mod Popups State Object");
		StateObject = XComGameState_ShownGeneModPopups(NewGameState.CreateNewStateObject(class'XComGameState_ShownGeneModPopups'));
	}
	else `LOG("State object already exists, returning reference", bLog, 'IRIGENEPOP');

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
	local XComGameState_ShownGeneModPopups	StateObject;
	local XComGameState						NewGameState;

	StateObject = static.GetOrCreate(NewGameState);

	if (!StateObject.WasPopupDisplayedAlready(GeneModTemplate.DataName))
	{
		`LOG("Displaying popup for" @ GeneModTemplate.DataName, bLog, 'IRIGENEPOP');
		class'X2Helpers_BuildAlert_GeneMod'.static.GM_UINewGeneModAvailable(GeneModTemplate);
		if (NewGameState == none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Creating Gene Mod Popups State Object");
		}
		StateObject = XComGameState_ShownGeneModPopups(NewGameState.ModifyStateObject(class'XComGameState_ShownGeneModPopups', StateObject.ObjectID));
		StateObject.DisplayedPopups.AddItem(GeneModTemplate.DataName);

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}