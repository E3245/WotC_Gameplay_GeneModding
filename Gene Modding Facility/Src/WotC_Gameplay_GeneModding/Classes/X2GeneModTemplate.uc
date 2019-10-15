class X2GeneModTemplate extends X2StrategyElementTemplate config(GameData);

struct GeneModStatModifiers
{
	var ECharStatType StatName;
	var int StatModValue;
	var bool bUICosmetic;

	structdefaultproperties
	{
		StatName = eStat_Invalid;
		StatModValue = 0;
		bUICosmetic = false;
	}
};

struct BodyParts
{
	//	For each of these bool values,
	//	if "true" it means this body part has been either damaged beyond repair or Augmented
    var bool Head;	//    Severed Body Part #: 0
    var bool Torso;	//    Severed Body Part #: 1
    var bool Arms;	//    Severed Body Part #: 2
    var bool Legs;	//    Severed Body Part #: 3
};

var localized string DisplayName;
var protectedwrite localized string Summary;

//	Used in UICommodity_GeneModUpgrade when building Gene Mod description.
//	Informs the player that this Gene Mod cannot be added to the soldier because the limb is currently Augmented.
var localized string					m_str_GMPrevented_ByAugmentation_Eyes;
var localized string					m_str_GMPrevented_ByAugmentation_Torso;
var localized string					m_str_GMPrevented_ByAugmentation_Arms;
var localized string					m_str_GMPrevented_ByAugmentation_Legs;
var localized string					m_str_GMPrevented_ByAugmentation_Skin;

//	Used in warning popups that inform the player that this Gene Mod can be potentially disabled if they choose to Augment this soldier.
var localized string					m_strCanBeDisabledByAugment_Eyes;
var localized string					m_strCanBeDisabledByAugment_Torso;
var localized string					m_strCanBeDisabledByAugment_Arms;
var localized string					m_strCanBeDisabledByAugment_Legs;
var localized string					m_strCanBeDisabledByAugment_Skin;

//	Used in warning popups that inform the player that this Gene Mod HAS BEEN disabled due to a grave wound they sustained in combat.
var localized string					m_strHasBeenDisabledByWound_Eyes;
var localized string					m_strHasBeenDisabledByWound_Torso;
var localized string					m_strHasBeenDisabledByWound_Arms;
var localized string					m_strHasBeenDisabledByWound_Legs;
var localized string					m_strHasBeenDisabledByWound_Skin;

//	Used in warning popups that inform the player that this Gene Mod HAS BEEN disabled due to Augmentation.
var localized string					m_strHasBeenDisabledByAugment_Eyes;
var localized string					m_strHasBeenDisabledByAugment_Torso;
var localized string					m_strHasBeenDisabledByAugment_Arms;
var localized string					m_strHasBeenDisabledByAugment_Legs;
var localized string					m_strHasBeenDisabledByAugment_Skin;

var config string strImage;						 //  image associated with this Gene Mod, used in popups.
var config string strAbilityImage;				 //	 image used by automatically created pure passives.

var config name AbilityName;
var protected name AbilityStatMod;
var config array<GeneModStatModifiers>    StatChanges;
var config StrategyCost Cost;
var config StrategyRequirement Requirements;
var config int SoldierAPCost;
var config array<name> AllowedClasses;

var config name RequiresExistingGeneMod;
var config array<name> RestrictGeneModsIfInstalled;
var config int BaseTimeToCompletion;
var config name GeneCategory;

function string GetDisplayName() 
{ 
	local X2AbilityTemplate Template;

	if (DisplayName == "")
	{
		Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
		return Template.LocFriendlyName;
	}
	else
	{
		return DisplayName; 
	}
}

function string GetSummary() 
{ 
	local X2AbilityTemplate Template;

	//	If this Gene Mod is missing separate localization
	if (Summary == "" && AbilityName != '') 
	{
		Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
		return Template.GetMyLongDescription();
	}
	else
	{
		return `XEXPAND.ExpandString(Summary); 
	}
}
function string GetImage() { return strImage; }


//function StatBoostUnit(XComGameState_Unit UnitState)
//{
//	local int MaxStat;
//
//	MaxStat = UnitState.GetMaxStat(BoostStat) + BoostMaxValue;
//	UnitState.SetBaseMaxStat(BoostStat, MaxStat);
//	UnitState.SetCurrentStat(BoostStat, MaxStat);
//}

public static function array<X2GeneModTemplate> GetGeneModTemplates()
{	
	local X2StrategyElementTemplateManager  StrategyElementTemplateMgr;
	local X2StrategyElementTemplate			StrategyElementTemplate;
	local array<X2StrategyElementTemplate>	StrategyElementTemplates;
	local array<X2GeneModTemplate>			ReturnArray;

	StrategyElementTemplateMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	StrategyElementTemplates = StrategyElementTemplateMgr.GetAllTemplatesOfClass(class'X2GeneModTemplate');

	foreach StrategyElementTemplates(StrategyElementTemplate)
	{
		ReturnArray.AddItem(X2GeneModTemplate(StrategyElementTemplate));
	}
	return ReturnArray;
}

private static function bool DisableGeneModForUnit(XComGameState_Unit NewUnitState)
{
	local int j;

	for (j = 0; j < NewUnitState.AWCAbilities.Length; j++)
	{
		if (NewUnitState.AWCAbilities[j].AbilityType.AbilityName == default.AbilityName)
		{
			//	When this is set to "false", the soldier will not receive this ability when going on a mission
			//	nor any AdditionalAbilities associated with it.
			//NewUnitState.AWCAbilities[j].bUnlocked = false;

			NewUnitState.AWCAbilities.Remove(j, 1);

			NewUnitState.ClearUnitValue(default.GeneCategory);

			return true;
		}
	}
	return false;
}

//	Returns 1 if Gene Mod is present and active.
//	Returns 0 if the soldier doesn't have Gene Mod at all.
//	Returns -1 if Gene Mod is present, but was disabled.
public static function int UnitHasGeneMod(const XComGameState_Unit UnitState)
{
	local int j;

	for (j = 0; j < UnitState.AWCAbilities.Length; j++)
	{
		if (UnitState.AWCAbilities[j].AbilityType.AbilityName == default.AbilityName)
		{
			if (UnitState.AWCAbilities[j].bUnlocked)
			{
				return 1;
			}
			else
			{
				return -1;
			}
		}
	}
	return 0;
}

//	Returns the integer value used by Severed Body Part Unit Value in Augments mod for a limb associated with this Gene Mod.
public static function int GetMyLimbIndex()
{
	switch (default.GeneCategory)
	{
		case 'GMCat_brain':
			return -1;
		case 'GMCat_eyes':
			return 0;
		case 'GMCat_chest':
			return 1;
		case 'GMCat_arms':
			return 2;
		case 'GMCat_legs':
			return 3;
		case 'GMCat_skin':
			return -1;
		default:
			return -1;
	}
}

public static function BodyParts GetAugmentedOrGeneModdedBodyParts(const XComGameState_Unit Unit)
{
    local BodyParts					Parts;
	local array<X2GeneModTemplate>	GeneModTemplates;
	local X2GeneModTemplate			GeneModTemplate;

	Parts = GetAugmentedBodyParts(Unit);

	GeneModTemplates = GetGeneModTemplates();

	foreach GeneModTemplates(GeneModTemplate)
	{
		if (GeneModTemplate.UnitHasGeneMod(Unit) > 0)
		{
			switch (GeneModTemplate.GeneCategory)
			{
				case 'GMCat_brain':
					break;
				case 'GMCat_eyes':
					Parts.Head = true;
					break;
				case 'GMCat_chest':
					Parts.Torso = true;
					break;
				case 'GMCat_arms':
					Parts.Arms = true;
					break;
				case 'GMCat_legs':
					Parts.Legs = true;
					break;
				case 'GMCat_skin':
					break;
				default:
					break;
			}
		}
	}
    return Parts;
}

//	Use this function when displaying the list of potential Gene Mods for the soldier in UICommodity_GeneModUpgrade.
//	If this function returns "" then the Gene Mod can be used.
//	Otherwise this function returns the localized string that you need to add to Gene Mod's description.
public static function string GetGMPreventedByAugmentationMessage(const XComGameState_Unit Unit)
{
	local BodyParts Parts;

	//	If Biosynthesis SWO is enabled, Augmentations do not prevent Gene Modification.
	if (`SecondWaveEnabled('GM_SWO_Biosynthesis')) return "";

	Parts = GetAugmentedBodyParts(Unit);

	switch (default.GeneCategory)
	{
		case 'GMCat_brain':
			return "";
		case 'GMCat_eyes':
			if (Parts.Head) return default.m_str_GMPrevented_ByAugmentation_Eyes;
			else return "";
		case 'GMCat_chest':
			if (Parts.Torso) return default.m_str_GMPrevented_ByAugmentation_Torso;
			else return "";
		case 'GMCat_arms':
			if (Parts.Arms) return default.m_str_GMPrevented_ByAugmentation_Arms;
			else return "";
		case 'GMCat_legs':
			if (Parts.Legs) return default.m_str_GMPrevented_ByAugmentation_Legs;
			else return "";
		case 'GMCat_skin':
			if (GetAugmentedBodyPercent(Parts) > 0.5f) return default.m_str_GMPrevented_ByAugmentation_Skin;
			else return "";
		default:
			return "";	//	Gene Mods with unknown category are allowed by default.
	}
	return "";
}

//	This message is displayed when the squad returns to Avenger from a tactical mission
//	if a Grave Wound sustaind by the soldier has destroyed the limb associated with this Gene Mod.
public static function string GetGMDisabledByWoundMessage(const XComGameState_Unit Unit)
{
	local BodyParts Parts;

	Parts = GetDestroyedBodyParts(Unit);

	switch (default.GeneCategory)
	{
		case 'GMCat_brain':
			return "";
		case 'GMCat_eyes':
			if (Parts.Head) return default.m_strHasBeenDisabledByWound_Eyes;
			else return "";
		case 'GMCat_chest':
			if (Parts.Torso) return default.m_strHasBeenDisabledByWound_Torso;
			else return "";
		case 'GMCat_arms':
			if (Parts.Arms) return default.m_strHasBeenDisabledByWound_Arms;
			else return "";
		case 'GMCat_legs':
			if (Parts.Legs) return default.m_strHasBeenDisabledByWound_Legs;
			else return "";
		case 'GMCat_skin':
			if (GetAugmentedBodyPercent(Parts) > 0.5f) return default.m_strHasBeenDisabledByWound_Skin;
			else return "";
		default:
			return "";
	}
	return "";
}

//	This message is displayed when the player Augments a limb associated with this Gene Mod,
//	informing the player that this Gene Mod has now been disabled.
public static function string GetGMDisabledByAugmentMessage(const XComGameState_Unit Unit)
{
	local BodyParts Parts;

	Parts = GetAugmentedBodyParts(Unit);

	switch (default.GeneCategory)
	{
		case 'GMCat_brain':
			return "";
		case 'GMCat_eyes':
			if (Parts.Head) return default.m_strHasBeenDisabledByAugment_Eyes;
			else return "";
		case 'GMCat_chest':
			if (Parts.Torso) return default.m_strHasBeenDisabledByAugment_Torso;
			else return "";
		case 'GMCat_arms':
			if (Parts.Arms) return default.m_strHasBeenDisabledByAugment_Arms;
			else return "";
		case 'GMCat_legs':
			if (Parts.Legs) return default.m_strHasBeenDisabledByAugment_Legs;
			else return "";
		case 'GMCat_skin':
			if (GetAugmentedBodyPercent(Parts) > 0.5f) return default.m_strHasBeenDisabledByAugment_Skin;
			else return "";
		default:
			return "";
	}
	return "";
}

//	This function is used to determine whether this Gene Mod can be potentially disabled by Augmentation.
//	It is used whenever the soldier enters the Augmentation screen.
public static function string GetGMCanBeDisabledByAugmentWarningMessage(const XComGameState_Unit Unit)
{
	local BodyParts Parts;

	if (static.UnitHasGeneMod(Unit) > 0 &&					//	Display warning only if the soldier has this Gene Mod and it's active.
		static.DoesHQHaveAugmentsThatDisableThisGeneMod())	//	Display warning only if HQ inventory has an Augment in the inventory that can disable this Gene Mod.
	{
		Parts = GetAugmentedBodyParts(Unit);

		switch (default.GeneCategory)
		{
			case 'GMCat_brain':
				return "";
			case 'GMCat_eyes':	//	Display warning if the soldier does not have this body part already augmented.
				if (!Parts.Head) return default.m_strCanBeDisabledByAugment_Eyes;	
				else return "";
			case 'GMCat_chest':
				if (!Parts.Torso) return default.m_strCanBeDisabledByAugment_Torso;
				else return "";
			case 'GMCat_arms':
				if (!Parts.Arms) return default.m_strCanBeDisabledByAugment_Arms;
				else return "";
			case 'GMCat_legs':
				if (!Parts.Legs) return default.m_strCanBeDisabledByAugment_Legs;
				else return "";
			case 'GMCat_skin':
				/*if (GetAugmentedBodyPercent(Parts) >= 0.25f) */ //	Display warning for Skin Gene Mods if the soldier already has at least one Augment
				return default.m_strCanBeDisabledByAugment_Skin;	
			default:
				return "";
		}
	}
	return "";
}

//	This function cycles through Gene Mods applied to the soldier, disables any Gene Mods that should be disabled due to recent loss of limb or augmentation.
//	bWounded == true if Gene Mod was disabled due to loss of limb.
//	bWounded == false if Gene Mod was disabled because the player manually installed an Augment on a healthy soldier.
public static function DisableGeneModsForAugmentedSoldier(const XComGameState_Unit UnitState, const bool bWounded)
{
	local array<X2GeneModTemplate>	GeneModTemplates;
	local X2GeneModTemplate			GeneModTemplate;
	local bool						bChangedSomething;
	local XComGameState				NewGameState;
	local XComGameState_Unit 		NewUnitState;
	local string					sErrMsg;

	GeneModTemplates = GetGeneModTemplates();
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Remove Gene Mods due to loss of limb or Augmentation from" @ UnitState.GetFullName());
	NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

	foreach GeneModTemplates(GeneModTemplate)
	{
		//	If soldier has this Gene Mod and it's active
		if (GeneModTemplate.UnitHasGeneMod(NewUnitState) > 0)
		{
			if (bWounded)
			{
				//	This function will return a non-empty string if the soldier's limb associated with this Gene Mod has been destroyed.
				sErrMsg = GeneModTemplate.GetGMDisabledByWoundMessage(NewUnitState);
			}
			else
			{
				//	This function will return a non-empty string if the soldier now has Augments that prevent them from using this Gene Mod
				sErrMsg = GeneModTemplate.GetGMDisabledByAugmentMessage(NewUnitState);
			}

			if (sErrMsg != "")
			{
				//	Show popup here informing the player that this Gene Mod has been disabled due to Augmentation or loss of limb.

				class'X2Helpers_BuildAlert_GeneMod'.static.GM_UIGeneModDestroyed(NewUnitState, sErrMsg);

				GeneModTemplate.DisableGeneModForUnit(NewUnitState);
				bChangedSomething = true;
			}
		}
	}

	if (bChangedSomething) 
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else 
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}
}

//	Note: currently unused
private static function BodyParts GetAugmentedOrDestroyedBodyParts(XComGameState_Unit Unit)
{
    local XComGameState_Item    ItemState;
    local BodyParts				Parts;
    local UnitValue             SeveredBodyPart;

    //    Try to get the Unit Value that's responsible for tracking which body parts were damaged beyond repair
    //    and now need to be Augmented.
    if (!Unit.GetUnitValue('SeveredBodyPart', SeveredBodyPart)) // if we fail to get the Unit Value
    {
        //    Set the value to -1, because "0" would be the default value
        //    so even if the soldier's Head was fine
        //    we'd think that it was damaged and the soldier needs a Head augmentation.
        SeveredBodyPart.fValue = -1;
    }
    //    The Unit Value is removed from the soldier by the Augments mod once their respective body part is augmented,
    //    so we check the soldier's Inventory Slots as well.
    ItemState = Unit.GetItemInSlot(eInvSlot_AugmentationHead);
    if (ItemState != none || SeveredBodyPart.fValue == 0)
    {
        Parts.Head = true;
    }

    ItemState = Unit.GetItemInSlot(eInvSlot_AugmentationTorso);
    if (ItemState != none || SeveredBodyPart.fValue == 1)
    {
        Parts.Torso = true;
    }

    ItemState = Unit.GetItemInSlot(eInvSlot_AugmentationArms);
    if (ItemState != none || SeveredBodyPart.fValue == 2)
    {
        Parts.Arms = true;
    }

    ItemState = Unit.GetItemInSlot(eInvSlot_AugmentationLegs);
    if (ItemState != none || SeveredBodyPart.fValue == 3)
    {
        Parts.Legs = true;
    }
    return Parts;
}

private static function BodyParts GetAugmentedBodyParts(XComGameState_Unit Unit)
{
    local XComGameState_Item    ItemState;
    local BodyParts				Parts;

    //    The Unit Value is removed from the soldier by the Augments mod once their respective body part is augmented,
    //    so we check the soldier's Inventory Slots as well.
    ItemState = Unit.GetItemInSlot(eInvSlot_AugmentationHead);
    if (ItemState != none)
    {
        Parts.Head = true;
    }

    ItemState = Unit.GetItemInSlot(eInvSlot_AugmentationTorso);
    if (ItemState != none)
    {
        Parts.Torso = true;
    }

    ItemState = Unit.GetItemInSlot(eInvSlot_AugmentationArms);
    if (ItemState != none)
    {
        Parts.Arms = true;
    }

    ItemState = Unit.GetItemInSlot(eInvSlot_AugmentationLegs);
    if (ItemState != none)
    {
        Parts.Legs = true;
    }
    return Parts;
}

public static function BodyParts GetDestroyedBodyParts(XComGameState_Unit Unit)
{
    local BodyParts				Parts;
    local UnitValue             SeveredBodyPart;

    //    Try to get the Unit Value that's responsible for tracking which body parts were damaged beyond repair.
    if (Unit.GetUnitValue('SeveredBodyPart', SeveredBodyPart))
    {
		switch (int(SeveredBodyPart.fValue))
		{
			case 0:
				Parts.Head = true;
				return Parts;
			case 1:
				Parts.Torso = true;
				return Parts;
			case 2:
				Parts.Arms = true;
				return Parts;
			case 3:
				Parts.Legs = true;
				return Parts;
		}
	}
    return Parts;
}

//	Calcualte the perecent of the body that was augmented and return it as a value between 0 and 1.
private static function float GetAugmentedBodyPercent(const BodyParts Parts)
{
	return float(int(Parts.Head) + int(Parts.Torso) + int(Parts.Arms) + int(Parts.Legs)) / 4;
}

private static function bool DoesHQHaveAugmentsThatDisableThisGeneMod()
{
	local XComGameState_HeadquartersXCom	XComHQ;
	local XComGameState_Item				ItemState;
	local string							AugItemCat;
	local int								idx;

	XComHQ = `XCOMHQ;
	AugItemCat = GetAugmentationItemCatThatDisablesThisGeneMod();

	if (AugItemCat == "augmentation_none") return false;

	for(idx = 0; idx < XComHQ.Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));

		if(ItemState != none)
		{
			//	If the Item Category contains at least a part of the Item Cat of Augments that disable this Gene Mod
			if(InStr(ItemState.GetMyTemplate().ItemCat, AugItemCat) != INDEX_NONE)
			{
				return true;
			}
		}
	}

	return false;
}

private static function string GetAugmentationItemCatThatDisablesThisGeneMod()
{
	switch (default.GeneCategory)
	{
		case 'GMCat_brain':
			return "augmentation_none";
		case 'GMCat_eyes': 
			 return "augmentation_head";
		case 'GMCat_chest':
			return "augmentation_torso";
		case 'GMCat_arms':
			return "augmentation_arms";
		case 'GMCat_legs':
			return "augmentation_legs";
		case 'GMCat_skin':
			return "augmentation_";
		default:
			return "augmentation_none";
	}
}

DefaultProperties
{
	bShouldCreateDifficultyVariants = true
}