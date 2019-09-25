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


var localized string DisplayName;
var protected localized string Summary;

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

DefaultProperties
{
	bShouldCreateDifficultyVariants = true
}