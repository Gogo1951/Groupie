--[[
	Groupie Localization Information: English Language
		This file must be present to have partial translations
--]] 

local L = LibStub('AceLocale-3.0'):NewLocale('Groupie', 'enUS', true)

if L then

    L["slogan"] = "A better LFG tool for Classic WoW."
    L["LocalizationStatus"] = 'Localization is on the work'

    -- tabs
    L["DungeonLabel"] = "Dungeons"
    L["RaidLabel"] = "Raids"
    L["ShortHeroicLabel"] = "H"
    L["PVP"] = "PVP"
    L["Other"] = "Other"
    L["All"] = "All"

    -- Columns
    L["CreatedLabel"] = "Created"
    L["UpdatedLabel"] = "Updated"
    L["LeaderLabel"] = "Leader"
    L["InstanceNameLabel"] = "Instance"
    L["LootTypeLabel"] = "Loot Type"
    L["MessageLabel"] = "Message"

    -- filters
    --- Roles
    L["LookingForShortLabel"] = "LF"
    L["AnyRoleLabel"] = "Any Role"
    L["TankRoleLabel"] = "Tank"
    L["HealerRoleLabel"] = "Healer"
    L["DPSRoleLabels"] = "DPS"
    
    --- Loot Types
    L["AnyLootStyleLabel"] = "All Loot Styles"
    L["MSOSLootStyleLabel"] = "MS > OS"
    L["SoftResLootStyleLabel"] = "SoftRes"
    L["GDKPLootStyleLabel"] = "GDKP"
    L["TicketLootStyleLabel"] = "TICKET"

    --- Languages
    L["AnyLanguageLabel"] = "All Languages"

    --- Dungeons
    L["AnyDungeonLabel"] = "All Dungeons"
    L["RecommendedDungeonLabel"] = "Recommended Level Dungeons"


    -- Global
    L["ShowingLabel"] = "Showing"
    L["SettingsButton"] = "Settings & Filters"
    L["Click"] = "Click"
    L["RightClick"] = "Right Click"
    L["Settings"] = "Settings"
    L["BulletinBoard"] = "Bulletin Board"
    L["Reset"] = "Reset"

    -- Channels Name /!\ VERY IMPORTANT, THE ADDON PARSES DEPENDING ON THE CHANNEL NAME
    L["GuildChannel"] = "Guild"
    L["GeneralChannel"] = "General"
    L["TradeChannel"] = "Trade"
    L["LocalDefenseChannel"] = "LocalDefense"
    L["LookingForGroupChannel"] = "LookingForGroup"
    L["WorldChannel"] = "5"

    -- Spec Names /!\ Must be implemented. This is the base requirement for the 
    --- Death Knight
    L["BloodDK"] = "Blood"
    L["FrostDK"] = "Frost"
    L["UnholyDK"] = "Unholy"

    --- Druid
    L["BalanceDruid"] = "Balance"
    L["FeralDruid"] = "Feral Combat"
    L["RestorationDruid"] = "Restoration"

    --- Hunter
    L["BMHunter"] = "Beast Mastery"
    L["MMHunter"] = "Marksmanship"
    L["SurvivalHunter"] = "Survival"

    --- Mage
    L["ArcaneMage"] = "Arcane"
    L["FireMage"] = "Fire"
    L["FrostMage"] = "Frost"

    --- Paladin
    L["HolyPaladin"] = "Holy"
    L["ProtectionPaladin"] = "Protection"
    L["RetributionPaladin"] = "Retribution"

    --- Priest
    L["DisciplinePriest"] = "Discipline"
    L["HolyPriest"] = "Holy"
    L["ShadowPriest"] = "Shadow"

    -- Rogue
    L["AssassinationRogue"] = "Assassination"
    L["CombatRogue"] = "Combat"
    L["SubtletyRogue"] = "Subtlety"

    --- Shaman
    L["ElementalShaman"] = "Elemental"
    L["EnhancementShaman"] = "Enhancement"
    L["RestorationShaman"] = "Restoration"

    --- Warlock
    L["AfflictionWarlock"] = "Affliction"
    L["DemonologyWarlock"] = "Demonology"
    L["DestructionWarlock"] = "Destruction"
    
    --- Warrior 
    L["ArmsWarrior"] = "Arms"
    L["FuryWarrior"] = "Fury"
    L["ProtectionWarrior"] = "Protection"
end
