class X2Ability_PurePassives extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local name GeneModName;

	//	This will create a PurePassive for EVERY Gene Mod. Sort of spammy.
	foreach class'X2StrategyElement_DefaultGeneMods'.default.GeneMods(GeneModName)
	{
		Templates.AddItem(PurePassive(name(String(GeneModName) $ "_GMPassive"), "img:///IRI_GeneMods.UI.UIPerk_DefaultGeneMod",, 'eAbilitySource_Commander', true));
	}

	return Templates;
}