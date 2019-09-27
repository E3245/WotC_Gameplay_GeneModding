class UIScreenListener_AugmentGeneMod extends UIScreenListener;

//	This function triggers when the player enters Augmentation Screen for a soldier.
//	It will cycle through all Gene Mods currently active on the soldier, and if any of them can be potentially disabled by Augmentation,
//	we display a popup with a warning message for each individual Gene Mod.
event OnInit(UIScreen Screen)
{
	local UIArmory_Loadout			LoadoutScreen;
	local XComGameState_Unit		UnitState;
	local X2GeneModTemplate			GeneModTemplate;
	local array<X2GeneModTemplate>	GeneModTemplates;
	local string					sWarnMsg;

	//`LOG("Gene Mod UISL Triggered by screen: " @  Screen.Class,, 'GMUISL');

	if (Screen.IsA('UIArmory_Augmentations'))
	{
		LoadoutScreen = UIArmory_Loadout(Screen);
		UnitState = LoadoutScreen.GetUnit();
		GeneModTemplates = class'X2GeneModTemplate'.static.GetGeneModTemplates();

		foreach GeneModTemplates(GeneModTemplate)
		{
			sWarnMsg = GeneModTemplate.GetGMCanBeDisabledByAugmentWarningMessage(UnitState);
			if (sWarnMsg != "")
			{
				//	TODO for E3245
				//	Display a popup here, warning the soldier that this particular Gene Mod can be potentially disabled by Augmentation.
				//	ShowPopup(sWarnMsg);

				//	Placeholder popup
				//`LOG("Displaying popup for soldier: " @  UnitState.GetFullName(),, 'IRIPOPUP');
				//`LOG("CAN BE DISABLED BY AUGMENTATION",, 'IRIPOPUP');
				//`LOG("===" @ sWarnMsg,, 'IRIPOPUP');
				//class'X2Helpers_BuildAlert_GeneMod'.static.GM_UINewGeneModAvailable(GeneModTemplate);
			}
		}
	}
}

event OnRemoved(UIScreen Screen)
{
	local UIArmory_Loadout LoadoutScreen;

	//`LOG("Gene Mod UISL Triggered by OnRemoved: " @  Screen.Class,, 'GMUISL');

	if (Screen.IsA('UIArmory_Augmentations'))
	{
		LoadoutScreen = UIArmory_Loadout(Screen);

		//`LOG("Calling DisableGeneModsForAugmentedSoldier",, 'GMUISL');
		class'X2GeneModTemplate'.static.DisableGeneModsForAugmentedSoldier(LoadoutScreen.GetUnit(), false);
		return;
	}
}
