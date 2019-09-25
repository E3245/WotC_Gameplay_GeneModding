class X2StrategyElement_DefaultGeneMods extends X2StrategyElement
	dependson(X2GeneModTemplate)
	config(GameData);

var config array<name> GeneMods;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2GeneModTemplate> Templates;
	local X2GeneModTemplate Template;
	local name GeneModName;

	foreach default.GeneMods(GeneModName)
	{
		`CREATE_X2TEMPLATE(class'X2GeneModTemplate', Template, GeneModName);
		Templates.AddItem(Template);
	}

	return Templates;
}

