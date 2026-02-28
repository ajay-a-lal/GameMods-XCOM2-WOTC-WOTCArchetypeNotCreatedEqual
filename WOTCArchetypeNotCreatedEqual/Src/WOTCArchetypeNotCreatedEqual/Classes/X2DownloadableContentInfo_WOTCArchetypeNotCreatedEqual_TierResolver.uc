
/// Class X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_TierResolver
/// Handles tier-based stat value resolution for the Archetype Not Created Equal mod.
/// Contains static functions for resolving soldier stats by weighted tier selection,
/// generating tier ranges, and calculating maximum high-tier stats allowed per soldier.
class X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_TierResolver extends X2DownloadableContentInfo config(ATNCE);

/// Function: ATNCE_ResolveStatValueByTierWeight
/// Purpose: Resolves a stat value based on selected tier weighting and tier range configurations.
/// Params:
///   config - The stat configuration containing tier weights and stat type
///   tierRanges - The tier range definitions (min/max values for each tier)
///   minRefineTier - The minimum tier that should be refined (prevents lower tiers from being selected)
///   statStateDetails - Internal soldier stat state and archetype information
///   enableLogging - Whether to enable debug logging
///   selectedTier - Output parameter containing the selected tier type
/// Returns: The resolved stat value based on the selected tier's range
static function int ATNCE_ResolveStatValueByTierWeight(
	ATNCE_StatConfig config, 
	ATNCE_TierRanges tierRanges,
    ATNCE_TierType selectedTier,
	bool enableLogging)
{
	local int setStatValue, rangeDiff;

	switch (selectedTier)
    {
        case ATNCE_TierC:
            rangeDiff = tierRanges.TierCHigh - tierRanges.TierCLow + 1;
            setStatValue = tierRanges.TierCLow + `SYNC_RAND_STATIC(Max(1, rangeDiff));
            break;
        case ATNCE_TierB:
            rangeDiff = tierRanges.TierBHigh - tierRanges.TierBLow + 1;
            setStatValue = tierRanges.TierBLow + `SYNC_RAND_STATIC(Max(1, rangeDiff));
            break;
        case ATNCE_TierA:
            rangeDiff = tierRanges.TierAHigh - tierRanges.TierALow + 1;
            setStatValue = tierRanges.TierALow + `SYNC_RAND_STATIC(Max(1, rangeDiff));
            break;
        default:
            rangeDiff = tierRanges.TierDHigh - tierRanges.TierDLow + 1;
            setStatValue = tierRanges.TierDLow + `SYNC_RAND_STATIC(Max(1, rangeDiff));
            break;
    }

	return setStatValue;
}

/// Function: ATNCE_SelectTierByWeighting
/// Purpose: Selects a tier (D, C, B, or A) based on weighted probability distribution.
/// Adjusts weights based on archetype bonuses and high-tier stat limits.
/// Params:
///   statType - The character stat type being evaluated
///   weights - The weight configuration for each tier
///   minRefineTier - The minimum tier that should be refined (prevents lower tiers from being selected)
///   statStateDetails - Internal soldier stat state and archetype information
/// Returns: The selected tier type (ATNCE_TierA, B, C, or D)
static function ATNCE_TierType ATNCE_SelectTierByWeighting(
	ATNCE_StatConfig config,
	ATNCE_SelectTierRanges selectTierRanges, 
	ATNCE_SoldierDetail statStateDetails)
{
    local int setWeightD, setWeightC, setWeightB, setWeightA;
    local int totalWeight, roll, cumulative;
    local ATNCE_CoreConfig coreConfig;

    coreConfig = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual'.static.ATNCE_GetCoreConfig();

    `LOG("The Select Tier Ranges are: Min" @ selectTierRanges.minSelectTier @ "to" @ selectTierRanges.maxSelectTier, coreConfig.ATNCE_EnableLogging, 'WOTCArchetype_ATNCE');

    setWeightD = config.TierWeights.WeightD;
    setWeightC = config.TierWeights.WeightC;
    setWeightB = config.TierWeights.WeightB;
    setWeightA = config.TierWeights.WeightA;

    if (selectTierRanges.minSelectTier > ATNCE_TierD || selectTierRanges.maxSelectTier < ATNCE_TierD) setWeightD = 0;
    if (selectTierRanges.minSelectTier > ATNCE_TierC || selectTierRanges.maxSelectTier < ATNCE_TierC) setWeightC = 0;
    if (selectTierRanges.minSelectTier > ATNCE_TierB || selectTierRanges.maxSelectTier < ATNCE_TierB) setWeightB = 0;
    if (selectTierRanges.minSelectTier > ATNCE_TierA || selectTierRanges.maxSelectTier < ATNCE_TierA) setWeightA = 0;

    `LOG("The SET select Tier Values are: D=" @ setWeightD @ "C=" @ setWeightC @ "B=" @ setWeightB @ "A=" @ setWeightA, coreConfig.ATNCE_EnableLogging, 'WOTCArchetype_ATNCE');

    if (statStateDetails.SelectedArchetypeIndex >= 0)
    {
        if (config.CharStatType == statStateDetails.ArchetypeStatConfig.primaryCharStatType)
        {
            setWeightD = 0; 
            setWeightC = 0;
        }
        else if (config.CharStatType == statStateDetails.ArchetypeStatConfig.secondaryCharStatType)
        {
            setWeightD = 0;
        }
    }

    if (statStateDetails.HighTierStatsCount >= statStateDetails.MaxHighTierStatsAllowed)
    {   
        setWeightA = 0;
        setWeightB = 0;
    }   

    totalWeight = setWeightD + setWeightC + setWeightB + setWeightA;

    if (totalWeight <= 0)
    {
        if (statStateDetails.HighTierStatsCount >= statStateDetails.MaxHighTierStatsAllowed)
        {
            if (selectTierRanges.maxSelectTier >= ATNCE_TierC) return ATNCE_TierC;
        }
        return selectTierRanges.minSelectTier;
    }

    roll = `SYNC_RAND_STATIC(totalWeight);
    cumulative = 0;

    cumulative += setWeightD;
    if (roll < cumulative) return ATNCE_TierD;

    cumulative += setWeightC;
    if (roll < cumulative) return ATNCE_TierC;

    cumulative += setWeightB;
    if (roll < cumulative) return ATNCE_TierB;

    return ATNCE_TierA;
}

/// Function: ATNCE_GenerateTierRangesByArchetype
/// Purpose: Generates tier range (min/max values) for each tier based on stat configuration.
/// Divides the stat range into four tiers with configurable overlap regions.
/// Applies adjustments to prevent narrow ranges and overlapping tier boundaries.
/// Params:
///   config - The stat configuration containing base stat ranges and tier parameters
/// Returns: ATNCE_TierRanges structure with min/max values for tiers D, C, B, and A
static function ATNCE_TierRanges ATNCE_GenerateTierRangesByArchetype(const ATNCE_StatConfig config)
{
	local ATNCE_TierRanges returnTierRanges;
    local float midLow, midHigh;
    local float baseMins[4], baseMaxs[4], tierSizes[4];
    local float useShifts[3];
    local int tier;
    local int outMins[4], outMaxs[4];
	local bool bIsNarrowLowerHalf;
	local int prevMax, thisMin, overlapSize;
    local ATNCE_CoreConfig coreConfig;

    coreConfig = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual'.static.ATNCE_GetCoreConfig();

    useShifts[0] = coreConfig.ATNCE_TierMaxOverlaps.DtoCPercent / 100.0f;
    useShifts[1] = coreConfig.ATNCE_TierMaxOverlaps.CtoBPercent / 100.0f;
    useShifts[2] = coreConfig.ATNCE_TierMaxOverlaps.BtoAPercent / 100.0f;

    midLow = (config.StatRanges.RangeLow + config.StatRanges.RangeMid) / 2.0f;
    midHigh = (config.StatRanges.RangeMid + config.StatRanges.RangeHigh) / 2.0f;

    baseMins[0] = config.StatRanges.RangeLow;
    baseMaxs[0] = midLow;
    baseMins[1] = midLow;
    baseMaxs[1] = config.StatRanges.RangeMid;
    baseMins[2] = config.StatRanges.RangeMid;
    baseMaxs[2] = midHigh;
    baseMins[3] = midHigh;
    baseMaxs[3] = config.StatRanges.RangeHigh;

    for (tier = 0; tier < 4; tier++)
    {
        tierSizes[tier] = baseMaxs[tier] - baseMins[tier];
    }

    for (tier = 0; tier < 3; tier++)
    {
        baseMaxs[tier] += useShifts[tier] * tierSizes[tier + 1];
    }

    for (tier = 0; tier < 4; tier++)
    {
        outMins[tier] = Round(baseMins[tier]);
        outMaxs[tier] = Round(baseMaxs[tier]);

		if (outMins[tier] < config.StatRanges.RangeLow)
		{
			outMins[tier] = config.StatRanges.RangeLow;
		}
    }

	bIsNarrowLowerHalf = (config.StatRanges.RangeMid - config.StatRanges.RangeLow) <= 5;

	if (bIsNarrowLowerHalf)
	{
		for (tier = 1; tier < 4; tier++)
		{
			prevMax = outMaxs[tier-1];
			thisMin  = outMins[tier];

			overlapSize = prevMax - thisMin + 1;
			if (thisMin <= prevMax && overlapSize >= 1)
			{
				outMins[tier] = Min(outMaxs[tier], prevMax + 1);
				if (outMins[tier] > outMaxs[tier])
				{
					outMins[tier] = outMaxs[tier];
				}
			}
			else if (thisMin == prevMax && `SYNC_RAND_STATIC(2) == 0)
			{
				outMins[tier] = Min(outMaxs[tier], prevMax + 1);
				if (outMins[tier] > outMaxs[tier])
				{
					outMins[tier] = outMaxs[tier];
				}
			}
		}
	}

    returnTierRanges.TierDLow = outMins[0];
    returnTierRanges.TierDHigh = outMaxs[0];
    returnTierRanges.TierCLow = outMins[1];
    returnTierRanges.TierCHigh = outMaxs[1];
    returnTierRanges.TierBLow = outMins[2];
    returnTierRanges.TierBHigh = outMaxs[2];
    returnTierRanges.TierALow = outMins[3];
    returnTierRanges.TierAHigh = outMaxs[3];

	if (returnTierRanges.TierAHigh > config.StatRanges.RangeHigh)
	{
		returnTierRanges.TierAHigh = config.StatRanges.RangeHigh;
	}

	return returnTierRanges;
}

/// Function: ATNCE_CalculateMaxHighTierStatsAllowed
/// Purpose: Calculates the maximum number of high-tier (A and B) stats allowed for a soldier.
/// Based on the number of available archetypes, with a random variance to create diversity.
/// Returns: The maximum count of high-tier stats this soldier can have
// Examples
/*
    - <= 7 Stats 2-3
    - 
 */
static function int ATNCE_CalculateMaxHighTierStatsAllowed()
{
    local int arrayLen;
    local int minCeiling;
    local int maxCeiling;
    local int randomOffset;
    local ATNCE_CoreConfig coreConfig;

    coreConfig = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual'.static.ATNCE_GetCoreConfig();

    arrayLen = coreConfig.ATNCE_StatTierWeights.Length;

    if(arrayLen < 7) return 2;

    minCeiling = Max(2, arrayLen / 3); 
    maxCeiling = Max(3, (arrayLen / 2));

    randomOffset = `SYNC_RAND_STATIC(maxCeiling - minCeiling + 1);

    return minCeiling + randomOffset;
}

