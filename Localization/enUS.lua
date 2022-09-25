--[[
	Groupie Localization Information: English Language
		This file must be present to have partial translations
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Groupie', 'enUS', true)


L["slogan"] = "A better LFG tool for Classic WoW."
L["LocalizationStatus"] = 'Localization is on the work'

-- tabs
L["UI_tabs"] = {
    ["Dungeon"] = "Dungeons",
    ["Raid"] = "Raids",
    ["ShortHeroic"] = "H",
    ["PVP"] = "PVP",
    ["Other"] = "Other",
    ["All"] = "All"
}
-- Columns
L["UI_columns"] = {
    ["Created"] = "Created",
    ["Updated"] = "Updated",
    ["Leader"] = "Leader",
    ["InstanceName"] = "Instance",
    ["LootType"] = "Loot",
    ["Message"] = "Message"
}

-- filters
L["Filters"] = {
    --- Roles
    ["Roles"] = {
        ["LookingFor"] = "LF",
        ["Any"] = "Any Role",
        ["Tank"] = "Tank",
        ["Healer"] = "Healer",
        ["DPS"] = "DPS"
    },
    --- Loot Types
    ["Loot_Styles"] = {
        ["AnyLoot"] = "All Loot Styles",
        ["MSOS"] = "MS > OS",
        ["SoftRes"] = "SoftRes",
        ["GDKP"] = "GDKP",
        ["Ticket"] = "TICKET"
    },
    --- Languages
    ["AnyLanguage"] = "All Languages",

    --- Dungeons
    ["Dungeons"] = {
        ["AnyDungeon"] = "All Dungeons",
        ["RecommendedDungeon"] = "Recommended Level Dungeons"
    }
}

-- Global
L["ShowingLabel"] = "Showing"
L["SettingsButton"] = "Settings & Filters"
L["Click"] = "Click"
L["RightClick"] = "Right Click"
L["Settings"] = "Settings"
L["BulletinBoard"] = "Bulletin Board"
L["Reset"] = "Reset"

-- Channels Name /!\ VERY IMPORTANT, THE ADDON PARSES DEPENDING ON THE CHANNEL NAME
L["text_channels"] = {
    ["Guild"] = "Guild",
    ["General"] = "General",
    ["Trade"] = "Trade",
    ["LocalDefense"] = "LocalDefense",
    ["LFG"] = "LookingForGroup",
    ["World"] = "5",
}
-- Spec Names /!\ Must be implemented. This is the base requirement for the
--- Death Knight
L["DeathKnight"] = {
    ["Blood"] = "Blood",
    ["Frost"] = "Frost",
    ["Unholy"] = "Unholy"
}
--- Druid
L["Druid"] = {
    ["Balance"] = "Balance",
    ["Feral"] = "Feral Combat",
    ["Restoration"] = "Restoration"
}
--- Hunter
L["Hunter"] = {
    ["BM"] = "Beast Mastery",
    ["MM"] = "Marksmanship",
    ["Survival"] = "Survival"
}
--- Mage
L["Mage"] = {
    ["Arcane"] = "Arcane",
    ["Fire"] = "Fire",
    ["Frost"] = "Frost"
}
--- Paladin
L["Paladin"] = {
    ["Holy"] = "Holy",
    ["Protection"] = "Protection",
    ["Retribution"] = "Retribution"
}
--- Priest
L["Priest"] = {
    ["Discipline"] = "Discipline",
    ["Holy"] = "Holy",
    ["Shadow"] = "Shadow"
}
-- Rogue
L["Rogue"] = {
    ["Assassination"] = "Assassination",
    ["Combat"] = "Combat",
    ["Subtlety"] = "Subtlety"
}
--- Shaman
L["Shaman"] = {
    ["Elemental"] = "Elemental",
    ["Enhancement"] = "Enhancement",
    ["Restoration"] = "Restoration"
}
--- Warlock
L["Warlock"] = {
    ["Affliction"] = "Affliction",
    ["Demonology"] = "Demonology",
    ["Destruction"] = "Destruction"
}
--- Warrior
L["Warrior"] = {
    ["Arms"] = "Arms",
    ["Fury"] = "Fury",
    ["Protection"] = "Protection",
}

L["ShortLocalizedInstances"] = {
    ["Zul'Gurub"]           = "Gurub",
    ["Ruins of Ahn'Qiraj"]  = "Ruins of Ahn'Qiraj",
    ["Onyxia's Lair"]       = "Onyxia",
    ["Molten Core"]         = "Molten Core",
    ["Blackwing Lair"]      = "Blackwing",
    ["Temple of Ahn'Qiraj"] = "Temple of Ahn'Qiraj",
    --["Naxxramas"]             = { { 40, false } },

    ["Hellfire Ramparts"]       = "Ramparts",
    ["Blood Furnace"]           = "Blood Furnace",
    ["Slave Pens"]              = "Slave Pens",
    ["Underbog"]                = "Underbog",
    ["Mana-Tombs"]              = "Mana-Tombs",
    ["Auchenai Crypts"]         = "Auchenai",
    ["Sethekk Halls"]           = "Sethekk",
    ["Old Hillsbrad Foothills"] = "Durnholde",
    ["Shadow Labyrinth"]        = "Shadow Labyrinth",
    ["Mechanar"]                = "Mechanar",
    ["Shattered Halls"]         = "Shattered",
    ["Steamvault"]              = "Steamvault",
    ["Botanica"]                = "Botanica",
    ["Arcatraz"]                = "Arcatraz",
    ["Black Morass"]            = "Dark Portal",
    ["Magisters' Terrace"]      = "Magister",

    ["Karazhan"]             = "Karazhan",
    ["Zul'Aman"]             = "Zul'Aman",
    ["Gruul's Lair"]         = "Gruul",
    ["Magtheridon's Lair"]   = "Magtheridon",
    ["Serpentshrine Cavern"] = "Serpentshrine",
    ["Tempest Keep"]         = "Tempest",
    ["Mount Hyjal"]          = "Hyjal",
    ["Black Temple"]         = "Black Temple",
    ["Sunwell Plateau"]      = "Sunwell",

    ["Utgarde Keep"]          = "Utgarde Keep",
    ["Nexus"]                 = "Nexus",
    ["Ajzol-Nerub"]           = "Ajzol",
    ["Old Kingdom"]           = "Old Kingdom",
    ["Drak'Tharon Keep"]      = "Drak'Tharon",
    ["Violet Hold"]           = "Violet Hold",
    ["Gundrak"]               = "Gundrak",
    ["Halls of Stone"]        = "Stone",
    ["Culling of Stratholme"] = "Culling",
    ["Halls of Lightning"]    = "Lightning",
    ["Utgarde Pinnacle"]      = "Utgarde Pinnacle",
    ["Oculus"]                = "Oculus",
    ["Trial of the Champion"] = "Trial of the Champion",
    ["Forge of Souls"]        = "Forge of Souls",
    ["Pit of Saron"]          = "Pit of Saron",
    ["Halls of Reflection"]   = "Reflection",

    ["Naxxramas"]         = "Naxxramas",
    ["Obsidian Sanctum"]  = "Obsidian",
    ["Vault of Archavon"] = "Archavon",
    ["Eye of Eternity"]   = "Eternity",
    --["Onyxia's Lair"]        = { { 10, false }, { 25, false } },
    ["Ulduar"]            = "Ulduar",

    ["Trial of the Crusader"]       = "Trial of the Crusader",
    ["Icecrown Citadel"]            = "Icecrown Citadel",
    ["Ruby Sanctum"]                = "Ruby",
    ["Trial of the Grand Crusader"] = "Trial of the Grand Crusader",
}
