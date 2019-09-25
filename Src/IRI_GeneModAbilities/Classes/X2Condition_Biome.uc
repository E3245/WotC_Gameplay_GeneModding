class X2Condition_Biome extends X2Condition;

// This condition SUCCEEDS if the current tactical mission has specified lighting

var string AllowedBiome;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_BattleData BattleData;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
	if (BattleData != none)
	{
		If (InStr(BattleData.MapData.Biome, AllowedBiome) != -1)
		{
			`LOG("Lizard Reflex -> Condition success: " @ BattleData.MapData.Biome,, 'GENEMODS');
			return 'AA_Success';
		}
	}
	else
	{
		`LOG("Lizard Reflex -> Could not get Battle Data for current mission.",, 'GENEMODS');
	}

	`LOG("Lizard Reflex -> Condition fails: "  @ BattleData.MapData.Biome,, 'GENEMODS');

	return 'AA_AbilityUnavailable';
}

/*
331 BiomeTypeNames[0]=Temperate
332 BiomeTypeNames[1]=Arid
333 BiomeTypeNames[2]=Tundra
334 BiomeTypeNames[3]=Xenoform
*/