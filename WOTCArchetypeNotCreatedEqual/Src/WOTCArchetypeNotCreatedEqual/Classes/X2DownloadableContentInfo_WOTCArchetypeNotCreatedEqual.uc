//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_WOTCArchetypeNotCreatedEqual.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

/// Class: X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual
/// Purpose: Main DLC info class for "Archetype: Not Created Equal" mod.
/// Handles mod initialization, soldier stat generation, archetype system, and configuration.
/// Features tier-based stat assignment with weighted probability distribution and optional archetype bonuses.
class X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual extends X2DownloadableContentInfo config(ATNCE);

enum ATNCE_StatGroupType
{
	ATNCE_Primary,
	ATNCE_Secondary,
	ATNCE_OtherDefence,
	ATNCE_OtherOffence,
	ATNCE_Other
};

// Supported Weighted Tiers
// Critica: Enum order is used in weighting logic, do not change order without reviewing weighting functions.
enum ATNCE_TierType
{
	ATNCE_TierD,
	ATNCE_TierC,
	ATNCE_TierB,
	ATNCE_TierA
};

enum ATNCE_StatRangeType
{
	ATNCE_RangeLow,
	ATNCE_RangeMid,
	ATNCE_RangeHigh
};

struct ATNCE_StatRanges
{
	var int RangeLow;
	var int RangeMid;
	var int RangeHigh;

	structdefaultproperties
	{
        RangeLow=50;
        RangeMid=65;
        RangeHigh=70;
    }
};

struct ATNCE_TierWeights
{
	var int WeightD;
	var int WeightC;
	var int WeightB;
	var int WeightA;

	structdefaultproperties
    {
        WeightD=20;
        WeightC=50;
        WeightB=25;
		WeightA=5;
    }
};

struct ATNCE_SelectTierRanges
{
	var ATNCE_TierType minSelectTier;
	var ATNCE_TierType maxSelectTier;

	structdefaultproperties
    {
		minSelectTier = ATNCE_TierD;
		maxSelectTier = ATNCE_TierA;
	}
};

struct ATNCE_MaxNextTierOverlap
{
	var int DtoCPercent;
	var int CtoBPercent;
	var int BtoAPercent;
	
	structdefaultproperties
    {
        DtoCPercent=25;
        CtoBPercent=20;
        BtoAPercent=15;
    }
};

struct ATNCE_StatConfig
{
	var ECharStatType CharStatType;
	var ATNCE_StatGroupType StatGroupType;
	var ATNCE_StatRanges StatRanges;
	var ATNCE_TierWeights TierWeights;
	
	structdefaultproperties
	{
		CharStatType = eStat_Invalid;
		StatGroupType = ATNCE_Other;
		StatRanges = (RangeLow=0, RangeMid=0, RangeHigh=0);
		TierWeights = (WeightD=0, WeightC=0, WeightB=0, WeightA=0);
	}
};

struct ATNCE_TierRanges
{
	var int TierDLow, TierDHigh;
    var int TierCLow, TierCHigh;
    var int TierBLow, TierBHigh;
    var int TierALow, TierAHigh;

	structdefaultproperties
	{	TierDLow=0; TierDHigh=0;
		TierCLow=0; TierCHigh=0;
		TierBLow=0; TierBHigh=0;
		TierALow=0; TierAHigh=0;
	}
};

struct ATNCE_ArchetypeStatConfig
{	
	var ECharStatType primaryCharStatType;
	var ECharStatType secondaryCharStatType;

	structdefaultproperties
	{
		primaryCharStatType = eStat_Invalid;
		secondaryCharStatType = eStat_Invalid;
	}
};

struct ATNCE_SoldierStat 
{
	var ECharStatType CharStatType;
	var int StatValue;
	var ATNCE_StatGroupType StatGroupType;
	var ATNCE_TierType Tier;
	var ATNCE_TierRanges TierRanges;
	var string StatMessage;
	var bool isArchetypeStat;
	var bool isStatRefined;

	structdefaultproperties
	{
		CharStatType = eStat_Invalid;
		StatValue = 0;
		StatGroupType = ATNCE_Other;
		Tier = ATNCE_TierD;
		StatMessage = "Normal";
		isArchetypeStat = false;
		isStatRefined = false;
	}
};

struct ATNCE_SoldierDetail
{	
	var int SelectedArchetypeIndex;
	var ATNCE_ArchetypeStatConfig ArchetypeStatConfig;
	var int HighTierStatsCount;
	var int MaxHighTierStatsAllowed;
	var array<ATNCE_SoldierStat> SoldierStats;

	structdefaultproperties
	{
		SelectedArchetypeIndex = -1;
		HighTierStatsCount = 0;
		MaxHighTierStatsAllowed = 2;
	}
};

struct ATNCE_CoreConfig
{
	var array<name> ATNCE_ExcludedTemplates;
	var bool ATNCE_EnableLogging;
	var bool ATNCE_EnableArchetypeSoldiers;
	var ATNCE_MaxNextTierOverlap ATNCE_TierMaxOverlaps;
	var array<ATNCE_StatConfig> ATNCE_StatTierWeights;
	var array<ATNCE_ArchetypeStatConfig> ATNCE_ArchetypeSoldiers;
	var int ATNCE_ArchetypeChancePercent;
};

var localized string ATNCE_Description;
var localized string ATNCE_Tooltip;

var config array<name> ATNCE_ExcludedTemplates;
var config bool ATNCE_EnableLogging;
var config bool ATNCE_EnableArchetypeSoldiers;
var config ATNCE_MaxNextTierOverlap ATNCE_TierMaxOverlaps;
var config array<ATNCE_StatConfig> ATNCE_StatTierWeights;
var config array<ATNCE_ArchetypeStatConfig> ATNCE_ArchetypeSoldiers;
var config int ATNCE_ArchetypeChancePercent;

/// Function: ATNCE_GetCoreConfig
/// Purpose: Returns a copy of the core mod configuration from the class defaults.
/// Returns: ATNCE_CoreConfig structure containing all mod settings from config files
static function ATNCE_CoreConfig ATNCE_GetCoreConfig()
{
	local ATNCE_CoreConfig config;
	
	config.ATNCE_ExcludedTemplates = default.ATNCE_ExcludedTemplates;
	config.ATNCE_EnableLogging = default.ATNCE_EnableLogging;
	config.ATNCE_EnableArchetypeSoldiers = default.ATNCE_EnableArchetypeSoldiers;
	config.ATNCE_TierMaxOverlaps = default.ATNCE_TierMaxOverlaps;
	config.ATNCE_StatTierWeights = default.ATNCE_StatTierWeights;
	config.ATNCE_ArchetypeSoldiers = default.ATNCE_ArchetypeSoldiers;
	config.ATNCE_ArchetypeChancePercent = default.ATNCE_ArchetypeChancePercent;

	return config;
}

/// Function: OnPostTemplatesCreated
/// Purpose: Called after all character templates are created. Initializes the mod:
///   - Validates configuration
///   - Updates Second Wave options list
///   - Modifies character templates to use mod stat assignment
///   - Runs configuration tests if enabled
static event OnPostTemplatesCreated()
{	
	`LOG("Initialising WOTC Archetype NCE Mod", true, 'WOTCArchetype_ATNCE');

	if (!class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_Utils'.static.ATNCE_IsConfigurationValid(true))
	{
		`REDSCREEN("ATNCE ERROR: Invalid Configuration! ATNCE Soldier stat generation will be disabled. Check the logs for errors.");
		return;
	}

	ATNCE_UpdateSecondWaveOptionsList();

	ATNCE_UpdateCharacterTemplates();

	`LOG("[INFO] Archetype Not Created Equal (ATNCE) configuration is valid. Mod has been integrated and can be enabled via SecondWave options. ", true, 'WOTCArchetype_ATNCE');

	class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_Utils'.static.ATNCE_TestGenerateSoldierStats();
}

/// Function: ATNCE_UpdateSecondWaveOptionsList
/// Purpose: Registers this mod's Second Wave option in the difficulty UI.
/// Adds ATNCE option, description, and tooltip to all UI difficulty settings.
static function ATNCE_UpdateSecondWaveOptionsList()
{
	local array<Object> uIShellDifficultyArray;
	local Object arrayObject;
	local UIShellDifficulty uIShellDifficulty;
    local SecondWaveOption atnceSecondWaveOption;
	
	atnceSecondWaveOption.ID = 'ATNCE';
	atnceSecondWaveOption.DifficultyValue = 0;

	uIShellDifficultyArray = class'XComEngine'.static.GetClassDefaultObjects(class'uIShellDifficulty');

	foreach uIShellDifficultyArray(arrayObject)
	{
		uIShellDifficulty = uIShellDifficulty(arrayObject);
		uIShellDifficulty.SecondWaveOptions.AddItem(atnceSecondWaveOption);
		uIShellDifficulty.SecondWaveDescriptions.AddItem(default.ATNCE_Description);
		uIShellDifficulty.SecondWaveToolTips.AddItem(default.ATNCE_Tooltip);
	}
}

/// Function: ATNCE_UpdateCharacterTemplates
/// Purpose: Iterates through all character templates (for all difficulties)
/// and binds the stat assignment callback to soldier templates that are not excluded.
/// Excludes robotic units and templates that already have a stat assignment callback.
static function ATNCE_UpdateCharacterTemplates()
{
	local X2CharacterTemplateManager characterTemplateManager;
    local X2CharacterTemplate charTemplate;
    local array<X2DataTemplate> dataTemplates;
    local X2DataTemplate template, diffTemplate;
	
    characterTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	foreach characterTemplateManager.IterateTemplates(template, None)
    {
		if (default.ATNCE_ExcludedTemplates.Find(template.DataName) != INDEX_NONE)
		{
			continue;
		}

		characterTemplateManager.FindDataTemplateAllDifficulties(template.DataName, dataTemplates);
        foreach dataTemplates(diffTemplate)
        {
			charTemplate = X2CharacterTemplate(diffTemplate);
            if (charTemplate.bIsSoldier && !charTemplate.bIsRobotic && charTemplate.OnStatAssignmentCompleteFn == None)
            {
				charTemplate.OnStatAssignmentCompleteFn = ATNCE_OnStatAssignmentCompleteFn;
				`LOG("charTemplate.OnStatAssignmentCompleteFn = ATNCE_OnStatAssignmentCompleteFn", default.ATNCE_EnableLogging, 'WOTCArchetype_ATNCE');
			}
		}
	}
}

function ATNCE_OnStatAssignmentCompleteFn_ErrorStub(XComGameState_Unit unit)
{
}

/// Function: ATNCE_OnStatAssignmentCompleteFn
/// Purpose: Callback invoked when a unit's stats are being assigned.
/// Checks if mod is enabled, potentially assigns archetype bonus stats, generates and applies new stat values.
/// Params:
///   unit - The soldier unit receiving stat assignment
function ATNCE_OnStatAssignmentCompleteFn(XComGameState_Unit unit)
{
	local X2CharacterTemplate unitTemplate;
	local ATNCE_SoldierDetail soldierDetail;
	local int i;
	local bool isAtnceSecondWaveEnabled;
	local int selectedArchetypeIndex;

	isAtnceSecondWaveEnabled = `SecondWaveEnabled('ATNCE');

	// Exit if Point-Based Not Created Equal is not enabled
	if (!isAtnceSecondWaveEnabled || unit.bEverAppliedFirstTimeStatModifiers)
	{
		`LOG("ATNCE IS DISABLED: isAtnceSecondWaveEnabled=" @ isAtnceSecondWaveEnabled, default.ATNCE_EnableLogging, 'WOTCArchetype_ATNCE');
		return;
	}

	if (!class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_Utils'.static.ATNCE_IsConfigurationValid(false))
	{
		`LOG("[ERROR] Invalid Configuration! Soldier stat generation has been DISABLED. Enabled logging via the XcomATNCE.ini => ATNCE_EnableLogging=true", true, 'WOTCArchetype_ATNCE');
		`LOG("[ERROR] Setting unit.GetMyTemplate().OnStatAssignmentCompleteFn to ATNCE_OnStatAssignmentCompleteFn_ErrorStub", true, 'WOTCArchetype_ATNCE');

		unitTemplate = unit.GetMyTemplate();
		unitTemplate.OnStatAssignmentCompleteFn = ATNCE_OnStatAssignmentCompleteFn_ErrorStub;

		return;
	}

	`LOG("Generate Soldier Stats: " @ unit.GetMyTemplateName() @ " (" @ unit.ObjectID @ ")", default.ATNCE_EnableLogging, 'WOTCArchetype_ATNCE');

	selectedArchetypeIndex = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_Utils'.static.ATNCE_RandomArchetypeSoldier();

	soldierDetail = ATNCE_GenerateSoldier(selectedArchetypeIndex, false);

	if (soldierDetail.SoldierStats.Length == 0)
	{
		`LOG("[ERROR] No Soldier Stats generated for " @ unit.GetMyTemplateName() @ " (" @ unit.ObjectID @ ")", true, 'WOTCArchetype_ATNCE');
		return;
	}

	soldierDetail.SoldierStats = ATNCE_RefineSoldierStats(soldierDetail, false);
	
	`LOG("    Apply Stats: " @ unit.GetMyTemplateName() @ " (" @ unit.ObjectID @ ")", default.ATNCE_EnableLogging, 'WOTCArchetype_ATNCE');

	for (i = 0; i < soldierDetail.SoldierStats.Length; ++i)
	{	
		if(soldierDetail.SoldierStats[i].isStatRefined && soldierDetail.SoldierStats[i].Tier > ATNCE_TierC) {
			soldierDetail.HighTierStatsCount++;
		}

		unit.setBaseMaxStat(soldierDetail.SoldierStats[i].CharStatType, soldierDetail.SoldierStats[i].StatValue);
		unit.setCurrentStat(soldierDetail.SoldierStats[i].CharStatType, soldierDetail.SoldierStats[i].StatValue);

		`LOG("    :" @ soldierDetail.SoldierStats[i].CharStatType @ " = " @ soldierDetail.SoldierStats[i].StatValue @ " Tier: " @ soldierDetail.SoldierStats[i].Tier @ "->" @ soldierDetail.SoldierStats[i].StatMessage, default.ATNCE_EnableLogging, 'WOTCArchetype_ATNCE');
	}
	
	SyncCombatIntelligence(unit);

	unit.bEverAppliedFirstTimeStatModifiers = true;

	if(soldierDetail.HighTierStatsCount >= soldierDetail.MaxHighTierStatsAllowed) {
		`LOG("    Maximum number of High Tier Stats was reached. Max=" @ soldierDetail.MaxHighTierStatsAllowed, default.ATNCE_EnableLogging, 'WOTCArchetype_ATNCE');
	}

}

/// Function: ATNCE_GenerateSoldier
/// Purpose: Generates initial stat values for a soldier based on tier weights and ranges.
/// Optionally assigns archetype bonuses if selectedArchetypeIndex >= 0.
/// Orders stat processing to apply archetype primary/secondary stats first.
/// Params:
///   selectedArchetypeIndex - Index of archetype (-1 for no archetype)
///   enableLogging - Whether to enable debug logging
/// Returns: Array of ATNCE_SoldierStat containing generated stats for all configured stat types
static function ATNCE_SoldierDetail ATNCE_GenerateSoldier(int selectedArchetypeIndex, bool enableLogging)
{
	local ATNCE_StatConfig config;
	local int i;
	local ATNCE_TierRanges tierRanges;
	local ATNCE_TierType selectedTier;
	local int setStatValue;
	local ATNCE_SoldierStat soldierStat;
	local array<ATNCE_StatConfig> orderedArcheConfigs;
	local ATNCE_SoldierDetail soldierDetail;
	local ATNCE_SelectTierRanges selectTierRanges;
	local array<int> ordereStatFreeIndices;
	local int randomStatFreeIndex, targetInsertStatIndex;

	if (default.ATNCE_StatTierWeights.Length == 0)
	{
		`LOG("[INFO] No Archetypes defined, exiting", true, 'WOTCArchetype_ATNCE');
		return soldierDetail;
	}

	soldierDetail.SelectedArchetypeIndex = selectedArchetypeIndex;
	if(selectedArchetypeIndex >= 0)
	{
		soldierDetail.ArchetypeStatConfig = default.ATNCE_ArchetypeSoldiers[selectedArchetypeIndex];
	}

	// Order the archetypes so that if we have an archetype soldier, we will process their primary stat first, then secondary stat, then the rest.
	// This allows us to apply the weighting rules for hero stats first before filling in other stats. 
	// CRITICAL: Used in NCE calculation which need archetypeSoldier to be processed first to ensure correct weighting is applied to other stats.
	orderedArcheConfigs.length = default.ATNCE_StatTierWeights.Length;

	for (i = (soldierDetail.SelectedArchetypeIndex >= 0 ? 2 : 0); i < default.ATNCE_StatTierWeights.Length; ++i)
	{
		ordereStatFreeIndices.AddItem(i);
	}

	for (i = 0; i < default.ATNCE_StatTierWeights.Length; ++i)
	{
		if (selectedArchetypeIndex >= 0 && default.ATNCE_StatTierWeights[i].CharStatType == soldierDetail.ArchetypeStatConfig.primaryCharStatType)
		{
			orderedArcheConfigs[0] = default.ATNCE_StatTierWeights[i];
		}
		else if (selectedArchetypeIndex >= 0 && default.ATNCE_StatTierWeights[i].CharStatType == soldierDetail.ArchetypeStatConfig.secondaryCharStatType)
		{
			orderedArcheConfigs[1] = default.ATNCE_StatTierWeights[i];
		}
		else if (ordereStatFreeIndices.Length > 0)
		{
			randomStatFreeIndex = Rand(ordereStatFreeIndices.Length); 
			targetInsertStatIndex = ordereStatFreeIndices[randomStatFreeIndex];

			orderedArcheConfigs[targetInsertStatIndex] = default.ATNCE_StatTierWeights[i];
			
			ordereStatFreeIndices.Remove(randomStatFreeIndex, 1);
    	}
	}

	soldierDetail.HighTierStatsCount = 0;
	soldierDetail.MaxHighTierStatsAllowed = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_TierResolver'
	.static.ATNCE_CalculateMaxHighTierStatsAllowed();

	for (i = 0; i < orderedArcheConfigs.Length; ++i)
	{
		config = orderedArcheConfigs[i];

		`LOG("    Stat" @ Config.CharStatType @ "-> D/C/B/A weights:" 
		     @ Config.TierWeights.WeightD @ Config.TierWeights.WeightC 
		     @ Config.TierWeights.WeightB @ Config.TierWeights.WeightA, 
		     enableLogging, 'WOTCArchetype_ATNCE');
			 
		tierRanges = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_TierResolver'
		.static.ATNCE_GenerateTierRangesByArchetype(config);

        `LOG("    Ranges for " @ Config.CharStatType 
             @ " D: " @ TierRanges.TierDLow @ "-" @ TierRanges.TierDHigh 
             @ " C: " @ TierRanges.TierCLow @ "-" @ TierRanges.TierCHigh 
             @ " B: " @ TierRanges.TierBLow @ "-" @ TierRanges.TierBHigh 
             @ " A: " @ TierRanges.TierALow @ "-" @ TierRanges.TierAHigh,
			 enableLogging, 'WOTCArchetype_ATNCE');

		selectedTier = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_TierResolver'
		.static.ATNCE_SelectTierByWeighting(config, selectTierRanges, soldierDetail);
		
		`LOG("    Stat" @ Config.CharStatType @ "selected band:" @ SelectedTier, enableLogging, 'WOTCArchetype_ATNCE');

		setStatValue = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_TierResolver'
		.static.ATNCE_ResolveStatValueByTierWeight(config, tierRanges, selectedTier, enableLogging);

		`LOG("    Stat" @ Config.CharStatType @ "selected value:" @ SetStatValue, enableLogging, 'WOTCArchetype_ATNCE');

		soldierStat.CharStatType = config.CharStatType;
        soldierStat.StatValue = setStatValue;
		soldierStat.StatGroupType = config.StatGroupType;
		soldierStat.Tier = selectedTier;
		soldierStat.TierRanges = tierRanges;
		soldierStat.StatMessage = "Normal";

		if (selectedArchetypeIndex >= 0)
		{
			if (config.CharStatType == soldierDetail.ArchetypeStatConfig.primaryCharStatType)
			{
				soldierStat.isArchetypeStat = true;
				soldierStat.StatMessage = "AT Primary";
			}
			else if (config.CharStatType == soldierDetail.ArchetypeStatConfig.secondaryCharStatType)
			{
				soldierStat.isArchetypeStat = true;
				soldierStat.StatMessage = "AT Secondary";
			}
		}

		if (selectedTier == ATNCE_TierB || selectedTier == ATNCE_TierA)
		{
			soldierDetail.HighTierStatsCount++;
		}
			
        soldierDetail.SoldierStats.AddItem(soldierStat);
	}

	return soldierDetail;
}

/// Function: ATNCE_RefineSoldierStats
/// Purpose: Refines soldier stats to ensure a minimum quality threshold.
/// If all primary stats rolled tier D, randomly selects one primary stat and rerolls it to guarantee C or above.
/// Params:
///   enableLogging - Whether to enable debug logging
/// Returns: Array of refined ATNCE_SoldierStat
static function array<ATNCE_SoldierStat> ATNCE_RefineSoldierStats(ATNCE_SoldierDetail soldierDetail, bool enableLogging)
{
	local int countPrimaryLowTiers;
	local int countAllLowTiers;
	local int numberOfPrimaryStats;
	local array<int> primaryStatIndexes;
	local int randomPrimaryIndex;
	local ATNCE_SoldierStat selectedPrimaryStat;
	local int i;
	local int refinedStatValue;
	local array<ATNCE_SoldierStat> returnRefinedSoldierStats;
	local ATNCE_StatConfig archetypeConfig;
	local ATNCE_TierType selectedTier;
	local ATNCE_SelectTierRanges selectTierRanges;

	for (i = 0; i < soldierDetail.soldierStats.Length; ++i)
	{
		if (soldierDetail.soldierStats[i].StatGroupType == ATNCE_Primary)
		{
			numberOfPrimaryStats++;
			primaryStatIndexes.AddItem(i);
			if (soldierDetail.soldierStats[i].Tier == ATNCE_TierD)
			{
				countPrimaryLowTiers++;
			}
		}

		if (soldierDetail.soldierStats[i].Tier == ATNCE_TierD || soldierDetail.soldierStats[i].Tier == ATNCE_TierC)
		{
			countAllLowTiers++;
		}

		returnRefinedSoldierStats.AddItem(soldierDetail.soldierStats[i]);
	}

	if (numberOfPrimaryStats > 0 && (countPrimaryLowTiers == numberOfPrimaryStats || countAllLowTiers == soldierDetail.soldierStats.Length))
	{
		randomPrimaryIndex = `SYNC_RAND_STATIC(numberOfPrimaryStats);
		selectedPrimaryStat = returnRefinedSoldierStats[primaryStatIndexes[randomPrimaryIndex]];

		archetypeConfig = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_Utils'
		.static.ATNCE_GetConfigForStatType(selectedPrimaryStat.CharStatType);

		if(soldierDetail.SelectedArchetypeIndex >= 0 && soldierDetail.HighTierStatsCount == soldierDetail.MaxHighTierStatsAllowed) {
			selectedTier = ATNCE_TierC;
		}
		else
		{
			selectTierRanges.minSelectTier = countAllLowTiers == soldierDetail.soldierStats.Length ? ATNCE_TierB : ATNCE_TierC;
			selectedTier = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_TierResolver'
			.static.ATNCE_SelectTierByWeighting(archetypeConfig, selectTierRanges, soldierDetail);
		}

		refinedStatValue = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_TierResolver'
			.static.ATNCE_ResolveStatValueByTierWeight(
			archetypeConfig,
			selectedPrimaryStat.tierRanges, 
			selectedTier, 
			enableLogging);

		selectedPrimaryStat.StatValue = refinedStatValue;
		selectedPrimaryStat.StatMessage = "Refined" @ selectedPrimaryStat.Tier;
		selectedPrimaryStat.Tier = selectedTier;
		selectedPrimaryStat.isStatRefined = true;
		returnRefinedSoldierStats[primaryStatIndexes[randomPrimaryIndex]] = selectedPrimaryStat;
	}

	return returnRefinedSoldierStats;
}

/// Function: SyncCombatIntelligence
/// Purpose: Syncs a unit's combat intelligence based on changes to PSI Offense, AIm and Mobility stat.
/// Maps stat deltas to combat intelligence modifiers:
///   >= 12: +2 CI, 6-11: +1 CI, -6 to -5: -1 CI, <= -6: -2 CI
/// Clamps result between eComInt_Standard and eComInt_Savant.
/// Params:
///   unit - The soldier unit to modify
static function SyncCombatIntelligence(XcomGameState_Unit unit)
{
    local int aimDelta, mobDelta, psiDelta, totalDelta;
    local int ciAdjustment, currentComInt;
    local int midAim, midMob, midPsi;
    

	midAim = ATNCE_GetRangeValue(eStat_Offense, ATNCE_RangeMid, 65);
    midMob = ATNCE_GetRangeValue(eStat_Mobility, ATNCE_RangeMid, 14);
    midPsi = ATNCE_GetRangeValue(eStat_PsiOffense, ATNCE_RangeMid, 20); 

    aimDelta = int(unit.GetBaseStat(eStat_Offense)) - midAim;
    mobDelta = (int(unit.GetBaseStat(eStat_Mobility)) - midMob) * 4; 
    psiDelta = int(unit.GetBaseStat(eStat_PsiOffense)) - midPsi;

    totalDelta = aimDelta + mobDelta + psiDelta;

    ciAdjustment = 0;

    if (totalDelta >= 24)       ciAdjustment = 2; 
    else if (totalDelta >= 12)  ciAdjustment = 1; 
    else if (totalDelta <= -24) ciAdjustment = -2;
    else if (totalDelta <= -12) ciAdjustment = -1;

    currentComInt = unit.ComInt;
    currentComInt += ciAdjustment;

    if (currentComInt < eComInt_Standard) currentComInt = eComInt_Standard;
    if (currentComInt > eComInt_Savant)   currentComInt = eComInt_Savant;

    unit.ComInt = ECombatIntelligence(currentComInt);

	`LOG("    CI Sync: Delta=" @ totalDelta @ " | Adj=" @ ciAdjustment @ " | Final CI=" @ int(unit.ComInt), default.ATNCE_EnableLogging, 'WOTCArchetype_ATNCE');
}

static function int ATNCE_GetRangeValue(ECharStatType statType, ATNCE_StatRangeType rangeType, int defaultStatValue)
{
	local ATNCE_StatConfig config;
	local int returnStatValue;

	config = class'X2DownloadableContentInfo_WOTCArchetypeNotCreatedEqual_Utils'.static.ATNCE_GetConfigForStatType(statType);

	if (config.CharStatType == eStat_Invalid)
	{
		return defaultStatValue;
	}

	switch (rangeType)
	{
		case ATNCE_RangeLow:
			returnStatValue = config.StatRanges.RangeLow;
			break;
		case ATNCE_RangeMid:
			returnStatValue = config.StatRanges.RangeMid;
			break;
		case ATNCE_RangeHigh:
			returnStatValue = config.StatRanges.RangeHigh;
			break;
	}

	return returnStatValue;
}



