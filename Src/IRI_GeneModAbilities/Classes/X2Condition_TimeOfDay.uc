class X2Condition_TimeOfDay extends X2Condition;

// This condition SUCCEEDS if the current tactical mission has specified lighting

var string AllowedLighting;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_BattleData BattleData;
	local string sEnvironmentLightingMapName;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
	if (BattleData != none)
	{
		sEnvironmentLightingMapName = BattleData.MapData.EnvironmentLightingMapName;

		If (InStr(sEnvironmentLightingMapName, AllowedLighting) != -1)
		{
			`LOG("Condition success: " @ sEnvironmentLightingMapName,, 'GENEMODS');
			return 'AA_Success';
		}
	}
	else
	{
		`LOG("Cheetah Genes -> Could not get Battle Data for current mission.",, 'GENEMODS');
	}

	`LOG("Condition fails: "  @ sEnvironmentLightingMapName,, 'GENEMODS');

	return 'AA_AbilityUnavailable';
}

/*
		case "EnvLighting_Sunrise":            return 'Sunrise';
		case "EnvLighting_Shanty_Sunrise":     return 'Sunrise';
		case "EnvLighting_Day":                return 'Day';
		case "EnvLighting_Shanty_Day":         return 'Day';
		case "EnvLighting_Rain":               return 'Rain';
		case "EnvLighting_Sunset":             return 'Sunset';
		case "EnvLighting_NatureNight":        return 'NatureNight';
		case "EnvLighting_Shanty_NatureNight": return 'NatureNight';
		case "EnvLighting_Day_Arid":           return 'Day_Arid';
		case "EnvLighting_Shanty_Day_Arid":    return 'Day_Arid';
		case "EnvLighting_Sunset":             return 'Sunset';
		case "EnvLighting_Shanty_Sunset":      return 'Sunset';
		case "EnvLighting_Day_Tundra":         return 'Day_Tundra';
		case "EnvLighting_NatureNight_Tundra": return 'NatureNight_Tundra';
		case "EnvLighting_UrbanNight":         return 'UrbanNight';
		case "EnvLighting_Facility":           return 'Facility';
*/