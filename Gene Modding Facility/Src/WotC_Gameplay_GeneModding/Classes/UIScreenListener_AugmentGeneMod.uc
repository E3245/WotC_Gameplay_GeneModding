class UIScreenListener_AugmentGeneMod extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UIArmory_Loadout			LoadoutScreen;
	local XComGameState_Unit		UnitState;
	local X2GeneModTemplate			GeneModTemplate;
	local array<X2GeneModTemplate>	GeneModTemplates;

	`LOG("Gene Mod UISL Triggered by screen: " @  Screen.Class,, 'GMUISL');

	if (Screen.IsA('UIArmory_Augmentations'))
	{
		LoadoutScreen = UIArmory_Loadout(Screen);
		UnitState = LoadoutScreen.GetUnit();
		GeneModTemplates = class'X2GeneModTemplate'.static.GetGeneModTemplates();

		foreach GeneModTemplates(GeneModTemplate)
		{
			if (GeneModTemplate.GetDisabledByAugmentWarningMessage(UnitState) != "")
			{
				`LOG("Displaying popup for soldier: " @  UnitState.GetFullName(),, 'GMUISL');
				class'X2Helpers_BuildAlert_GeneMod'.static.GM_UINewGeneModAvailable(GeneModTemplate);
			}
		}
	}
}