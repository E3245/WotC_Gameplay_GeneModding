class UIScreenListener_AugmentGeneMod extends UIScreenListener;


var localized string sWarnTitle;

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
	local TDialogueBoxData			DialogData;

	//	If Biosynthesis SWO is enabled, Augmentations do not prevent Gene Modification.
	if (`SecondWaveEnabled('GM_SWO_Biosynthesis')) return;

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

				//	Display a popup here, warning the soldier that this particular Gene Mod can be potentially disabled by Augmentation.
				DialogData.eType = eDialog_Normal;
				DialogData.strTitle = sWarnTitle;
				DialogData.strText = `XEXPAND.ExpandString(sWarnMsg);

				DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericContinue;

				`PRESBASE.UIRaiseDialog(DialogData);
			}
		}
	}
}

event OnRemoved(UIScreen Screen)
{
	local UIArmory_Loadout LoadoutScreen;

	//	If Biosynthesis SWO is enabled, Augmentations do not prevent Gene Modification.
	if (`SecondWaveEnabled('GM_SWO_Biosynthesis')) return;

	if (Screen.IsA('UIArmory_Augmentations'))
	{
		LoadoutScreen = UIArmory_Loadout(Screen);

		//`LOG("Calling DisableGeneModsForAugmentedSoldier",, 'GMUISL');
		class'X2GeneModTemplate'.static.DisableGeneModsForAugmentedSoldier(LoadoutScreen.GetUnit(), false);
		return;
	}
}

