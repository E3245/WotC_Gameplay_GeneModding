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

struct AugmentedBodyParts
{
    var bool Head;	//    Severed Body Part #: 0
    var bool Torso;	//    Severed Body Part #: 1
    var bool Arms;	//    Severed Body Part #: 2
    var bool Legs;	//    Severed Body Part #: 3
};

var localized string DisplayName;
var protected localized string Summary;

var localized string					m_strErrorEyesAugmented;
var localized string					m_strErrorTorsoAugmented;
var localized string					m_strErrorArmsAugmented;
var localized string					m_strErrorLegsAugmented;
var localized string					m_strErrorSkinAugmented;

var localized string					m_strDisabledByAugment_Eyes;
var localized string					m_strDisabledByAugment_Torso;
var localized string					m_strDisabledByAugment_Arms;
var localized string					m_strDisabledByAugment_Legs;
var localized string					m_strDisabledByAugment_Skin;

var config string strImage;						 //  image associated with this ability

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

function string GetDisplayName() { return DisplayName; }
function string GetSummary() { return `XEXPAND.ExpandString(Summary); }
function string GetImage() { return strImage; }


//function StatBoostUnit(XComGameState_Unit UnitState)
//{
//	local int MaxStat;
//
//	MaxStat = UnitState.GetMaxStat(BoostStat) + BoostMaxValue;
//	UnitState.SetBaseMaxStat(BoostStat, MaxStat);
//	UnitState.SetCurrentStat(BoostStat, MaxStat);
//}

static function bool DisableGeneModForUnit(XComGameState_Unit NewUnitState)
{
	local int j;

	for (j = 0; j < NewUnitState.AWCAbilities.Length; j++)
	{
		if (NewUnitState.AWCAbilities[j].AbilityType.AbilityName == default.AbilityName)
		{
			NewUnitState.AWCAbilities[j].bUnlocked = false;
			return true;
		}
	}
	return false;
}

//	Returns 0 if the soldier doesn't have Gene Mod at all.
//	Returns 1 if Gene Mod is present and active.
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

//	TODO for E3245: Use this function when displaying the list of potential Gene Mods for the soldier. 
//	If this function returns "" then the Gene Mod can be used.
//	Otherwise this function returns the localized string that you need to add to Gene Mod's description.
public static function string GetAugmentedErrorMessage(const XComGameState_Unit Unit)
{
	local AugmentedBodyParts    Parts;

	Parts = GetAugmentedBodyParts(Unit);

	switch (default.GeneCategory)
	{
		case 'GMCat_brain':
			return "";
		case 'GMCat_eyes':
			if (Parts.Head) return default.m_strErrorEyesAugmented;
			else return "";
		case 'GMCat_chest':
			if (Parts.Torso) return default.m_strErrorTorsoAugmented;
			else return "";
		case 'GMCat_arms':
			if (Parts.Arms) return default.m_strErrorArmsAugmented;
			else return "";
		case 'GMCat_legs':
			if (Parts.Legs) return default.m_strErrorLegsAugmented;
			else return "";
		case 'GMCat_skin':
			if (GetAugmentedBodyPercent(Parts) > 0.5f) return default.m_strErrorSkinAugmented;
			else return "";
		default:
			return "";	//	Gene Mods with unknown category are allowed by default.
	}
	return "";
}

public static function string GetDisabledByAugmentWarningMessage(const XComGameState_Unit Unit)
{
	local AugmentedBodyParts Parts;

	if (static.UnitHasGeneMod(Unit) > 0)	//	Display warning only if the soldier has this Gene Mod and it's active.
	{
		Parts = GetAugmentedBodyParts(Unit);

		switch (default.GeneCategory)
		{
			case 'GMCat_brain':
				return "";
			case 'GMCat_eyes':
				if (!Parts.Head) return default.m_strDisabledByAugment_Eyes;	//	Display warning ONLY if the soldier does not have Eyes already augmented or damaged.
				else return "";
			case 'GMCat_chest':
				if (!Parts.Torso) return default.m_strDisabledByAugment_Torso;
				else return "";
			case 'GMCat_arms':
				if (!Parts.Arms) return default.m_strDisabledByAugment_Arms;
				else return "";
			case 'GMCat_legs':
				if (!Parts.Legs) return default.m_strDisabledByAugment_Legs;
				else return "";
			case 'GMCat_skin':
				if (GetAugmentedBodyPercent(Parts) == 0.25f) return default.m_strDisabledByAugment_Skin;	//	Display warning for Skin Gene Mods if the soldier already has at least one Augment
			default:
				return "";
		}
	}
	return "";
}

public static function bool DisableGeneModsForAugmentedSoldier(XComGameState_Unit NewUnitState)
{
	local array<X2GeneModTemplate>	GeneModTemplates;
	local X2GeneModTemplate			GeneModTemplate;
	local bool						bChangedSomething;

	GeneModTemplates = GetGeneModTemplates();

	foreach GeneModTemplates(GeneModTemplate)
	{
		if (GeneModTemplate.UnitHasGeneMod(NewUnitState) > 1)
		{
			//	This function will return a non-empty string if the soldier now has Augments that prevent them from using this Gene Mod
			if (GeneModTemplate.GetAugmentedErrorMessage(NewUnitState) != "")
			{
				//	TODO for E3245
				//	Show popup here informing the player that this Gene Mod has been disabled due to Augmentation or loss of limb.

				GeneModTemplate.DisableGeneModForUnit(NewUnitState);
				bChangedSomething = true;
			}
		}
	}
	//	Return bool value informing the calling function whether we've changed the Unit State object or not (so it can submit or cleanup NewGameState).
	return bChangedSomething;
}

//	Calcualte the perecent of the body that was augmented and return it as a value between 0 and 1.
private static function float GetAugmentedBodyPercent(const AugmentedBodyParts Parts)
{
	return float(int(Parts.Head) + int(Parts.Torso) + int(Parts.Arms) + int(Parts.Legs)) / 4;
}

private static function AugmentedBodyParts GetAugmentedBodyParts(XComGameState_Unit Unit)
{
    local XComGameState_Item    ItemState;
    local AugmentedBodyParts    Parts;
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

DefaultProperties
{
	bShouldCreateDifficultyVariants = true
}