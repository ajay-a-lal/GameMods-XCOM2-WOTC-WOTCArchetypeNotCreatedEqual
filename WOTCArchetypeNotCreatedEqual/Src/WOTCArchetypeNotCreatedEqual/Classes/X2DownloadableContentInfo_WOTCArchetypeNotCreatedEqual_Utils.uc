
/// Class: X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_Utils
/// Purpose: Utility functions for the Archetype Not Created Equal mod.
/// Contains configuration validation, testing functions, and helper methods
/// for stat type lookups and configuration verification.
class X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_Utils extends X2DownloadableContentInfo config(ATNCE);

var config int ATNCE_TestSolderGenerationCount;

/// Function: ATNCE_TestGenerateSoldierStats
/// Purpose: Test function that generates and logs stats for multiple soldiers.
/// Useful for debugging and validating stat generation output.
/// Number of soldiers generated is controlled by ATNCE_TestSolderGenerationCount config variable.
/// For each soldier, logs initial stats and refined stats with archetype assignments if applicable.
static function ATNCE_TestGenerateSoldierStats()
{
	local int numberOfSoldiers;
	local int i;
	local int j;
	local ATNCE_SoldierDetail soldierDetails;

	numberOfSoldiers = default.ATNCE_TestSolderGenerationCount;

	if (numberOfSoldiers <= 0)
	{
		return;
	}
	
	for (i = 0; i < numberOfSoldiers; ++i)
	{	
		`LOG("[SOLDIER_" @ i @ "]", true, 'WOTCArchetype_ATNCE');
		
		soldierDetails = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual'.static.ATNCE_GenerateSoldier(true);
		`LOG("[SOLDIER_" @ i @ "] Initial Stats: " @ soldierDetails.SoldierStats.Length, true, 'WOTCArchetype_ATNCE');

		soldierDetails.SoldierStats = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual'.static.ATNCE_RefineSoldierStats(soldierDetails, true);
		`LOG("[SOLDIER_" @ i @ "] Refine Stats: " @ soldierDetails.SoldierStats.Length, true, 'WOTCArchetype_ATNCE');

		for (j = 0; j < soldierDetails.SoldierStats.Length; ++j)
		{
			`LOG("[SOLDIER_" @ i @ "] " @ soldierDetails.SoldierStats[j].CharStatType @ " = " @ soldierDetails.SoldierStats[j].StatValue @ " Tier" @ soldierDetails.SoldierStats[j].Tier @ soldierDetails.SoldierStats[j].StatMessage, true, 'WOTCArchetype_ATNCE');
		}	
	}
}

static function bool ATNCE_IsConfigurationValid(bool enableErrorLogOverride)
{
    local int i;
    local ATNCE_StatConfig statConfig;
    local ATNCE_CoreConfig coreConfig;
    local int primaryStatCount;
	local bool enableLogging;

    coreConfig = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual'.static.ATNCE_GetCoreConfig();

	enableLogging = coreConfig.ATNCE_EnableLogging || enableErrorLogOverride;

    if (coreConfig.ATNCE_StatTierWeights.Length < 3)
    {
        `LOG("[ERROR] Minimum ATNCE_StatTierWeights must be at least 3. Found:" @ coreConfig.ATNCE_StatTierWeights.Length, enableLogging, 'WOTCArchetype_ATNCE');
        return false;
    }

    for (i = 0; i < coreConfig.ATNCE_StatTierWeights.Length; ++i)
    {
        statConfig = coreConfig.ATNCE_StatTierWeights[i];
        if (statConfig.CharStatType == eStat_Invalid)
        {
            `LOG("[ERROR] StatTierWeights[" @ i @ "] has eStat_Invalid", enableLogging, 'WOTCArchetype_ATNCE');
            return false;
        }

        if (statConfig.StatGroupType == ATNCE_Primary) primaryStatCount++;
    }

    if (primaryStatCount < 2) 
    {
        `LOG("[ERROR] At least 2 stats must be flagged as ATNCE_Primary. Found:" @ primaryStatCount, enableLogging, 'WOTCArchetype_ATNCE');
        return false;
    }

    return ATNCE_IsArchetypeConfigValid(enableErrorLogOverride);
}

static function bool ATNCE_IsArchetypeConfigValid(bool enableErrorLogOverride)
{
    local int i, j;
    local bool doesPrimaryArchStatExist, doesSecondaryArchStatExist;
	local array<string> errorMessages;
    local ATNCE_CoreConfig coreConfig;
	local bool enableLogging;

    coreConfig = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual'.static.ATNCE_GetCoreConfig();

	enableLogging = coreConfig.ATNCE_EnableLogging || enableErrorLogOverride;

    if (!coreConfig.ATNCE_EnableArchetypeSoldiers) return true;

    if (coreConfig.ATNCE_ArchetypeSoldiers.Length == 0)
    {
        `LOG("[ERROR] Archetype Soldiers enabled but list is empty", enableLogging, 'WOTCArchetype_ATNCE');
        return false;
    }   

    for(i = 0; i < coreConfig.ATNCE_ArchetypeSoldiers.Length; ++i)
    {
        doesPrimaryArchStatExist = false;
        doesSecondaryArchStatExist = false;

		if (coreConfig.ATNCE_ArchetypeSoldiers[i].primaryCharStatType == coreConfig.ATNCE_ArchetypeSoldiers[i].secondaryCharStatType)
        {
            errorMessages.AddItem("[ERROR] ArchetypeSoldiers[" @ i @ "] has the same stat assigned to both Primary and Secondary slots.");
        }

        for (j = 0; j < coreConfig.ATNCE_StatTierWeights.Length; ++j)
        {
            if (coreConfig.ATNCE_StatTierWeights[j].CharStatType == coreConfig.ATNCE_ArchetypeSoldiers[i].primaryCharStatType)
			{
                doesPrimaryArchStatExist = true;
			}

            if (coreConfig.ATNCE_StatTierWeights[j].CharStatType == coreConfig.ATNCE_ArchetypeSoldiers[i].secondaryCharStatType)
			{
                doesSecondaryArchStatExist = true;
			}
        }

        if (!doesPrimaryArchStatExist || !doesSecondaryArchStatExist)
        {
            errorMessages.AddItem("[ERROR] ArchetypeSoldiers[" @ i @ "] references a StatType not found in StatTierWeights");
        }
    }

	for(i = 0; i < errorMessages.length; i++)
	{
		`LOG(errorMessages[i], enableLogging, 'WOTCArchetype_ATNCE');
	}

    return errorMessages.length == 0;
}

/// Function: ATNCE_GetConfigForStatType
/// Purpose: Looks up and returns the ATNCE_StatConfig for a given character stat type.
/// Params:
///   statType - The character stat type to find configuration for
/// Returns: ATNCE_StatConfig containing tier weights and ranges for the stat type,
///          or empty config if stat type not found
static function ATNCE_StatConfig ATNCE_GetConfigForStatType(ECharStatType statType)
{
	local ATNCE_StatConfig config;
	local int i;
	local ATNCE_CoreConfig coreConfig;
	coreConfig = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual'.static.ATNCE_GetCoreConfig();

	for (i = 0; i < coreConfig.ATNCE_StatTierWeights.Length; ++i)
	{
		if (coreConfig.ATNCE_StatTierWeights[i].CharStatType == statType)
		{
			config = coreConfig.ATNCE_StatTierWeights[i];
			break;
		}
	}

	return config;
}

static function int ATNCE_RandomArchetypeSoldier()
{
	local int archetypeRoll;
	local int selectedArchetypeIndex;
	local ATNCE_CoreConfig coreConfig;

	coreConfig = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual'.static.ATNCE_GetCoreConfig();
	
	selectedArchetypeIndex = -1;
	
	archetypeRoll = coreConfig.ATNCE_EnableArchetypeSoldiers ? `SYNC_RAND_STATIC(100) : 100;
	if (archetypeRoll < coreConfig.ATNCE_ArchetypeChancePercent)
	{
		selectedArchetypeIndex = `SYNC_RAND_STATIC(coreConfig.ATNCE_ArchetypeSoldiers.Length);
		`LOG("    [ARCHETYPE] In the darkess times, a Hero will emerge" @ selectedArchetypeIndex, coreConfig.ATNCE_EnableLogging, 'WOTCArchetype_ATNCE');
	}

	return selectedArchetypeIndex;
}