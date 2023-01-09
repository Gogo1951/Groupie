--[[
	Groupie Localization Information: English Language
		This file must be present to have partial translations
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Groupie', 'enUS', true)


L["slogan"] = "A better LFG tool for Classic WoW."
L["LocalizationStatus"] = 'Localization is on the work'
L["TeamMember"] = "Team Member"

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
        ["Ticket"] = "Ticket",
        ["Other"] = "Other",
        ["PVP"] = "PVP",
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
L["Options"] = "Options"
L["ClickSend"] = "Send this Message"
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
    ["Azjol-Nerub"]           = "Azjol",
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
L["InstanceFilters"] = {
    ["Wrath"] = {
        ["Name"] = "Instance Filters - Wrath",
        ["Desc"] = "Filter Groups by Instance"
    },
    ["TBC"] = {
        ["Name"] = "Instance Filters - TBC",
        ["Desc"] = "Filter Groups by Instance"
    },
    ["Classic"] = {
        ["Name"] = "Instance Filters - Classic",
        ["Desc"] = "Filter Groups by Instance"
    }
}
L["GroupFilters"] = {
    ["Name"] = "Group Filters",
    ["Desc"] = "Filter Groups by Other Properties",
    ["General"] = "General Filters",
    ["savedToggle"] = "Ignore Instances You Are Already Saved To on Current Character",
    ["ignoreLFG"] = "Include \"LFG\" Messages from People Looking for a Group",
    ["ignoreLFM"] = "Include \"LFM\" Messages from People Making a Group",
    ["keyword"] = "Filter By Keyword",
    ["keyword_desc"] = "Separate words or phrases using a comma; any post matching any keyword will be ignored.\n\nExample: \"swp trash, Selling, Boost\""
}
L["CharOptions"] = {
    ["Name"] = "Character Options",
    ["Desc"] = "Change Character-Specific Settings",
    ["Spec1"] = "Spec 1 Role",
    ["Spec2"] = "Spec 2 Role",
    ["OtherRole"] = "Include Non-Current Spec in LFG Messages.",
    ["DungeonLevelRange"] = "Recommended Dungeon Level Range",
    ["recLevelDropdown"] = {
        ["0"] = "Default Suggested Levels",
        ["1"] = "+1 - I've Done This Before",
        ["2"] = "+2 - I've Got Enchanted Heirlooms",
        ["3"] = "+3 - I'm Playing a Healer"
    },
    ["AutoResponse"] = "Auto-Response",
    ["AutoFriends"] = "Enable Auto-Respond to Friends",
    ["AutoGuild"] = "Enable Auto-Respond to Guild Members",
    ["AfterParty"] = "After-Party Tool",
    ["PullGroups"] = "Pull Groups From These Channels"
}
L["GlobalOptions"] = {
    ["Name"] = "Global Options",
    ["Desc"] = "Change Account-Wide Settings",
    ["MiniMapButton"] = "Enable Mini-Map Button",
    ["LFGData"] = "Preserve Looking for Group Data Duration",
    ["UIScale"] = "UI Scale",
    ["DurationDropdown"] = {
        ["1"] = "1 Minute",
        ["2"] = "2 Minutes",
        ["5"] = "5 Minutes",
        ["10"] = "10 Minutes",
        ["20"] = "20 Minutes",
    },
}
L["UpdateSpec"] = {
    ["Spec1"] = "Role for Spec 1",
    ["Spec2"] = "Role for Spec 2"
}
L["RightClickMenu"] = {
    ["SendInfo"] = "Send my info...",
    ["Current"] = "Current",
    ["WCL"] = "Warcraft Logs Link",
    ["Ignore"] = "Ignore",
    ["StopIgnore"] = "Stop Ignoring",
    ["Invite"] = "Invite",
    ["Whisper"] = "Whisper",
}
L["MiniMap"] = {
    ["lowerOr"] = "or",
    ["Update1"] = "PLEASE UPDATE YOUR ADD-ONS ASAP!",
    ["Update2"] = "GROUPIE IS OUT OF DATE!",
    ["HelpUs"] = "Groupie needs your help! Please go to\nGroupie Settings > Instance Log and\nupload the values to Groupie Discord.\nThis message will go away next time\nyou update Groupie. Thanks!",

}
L["InstanceLog"] = {
    ["Name"] = "Missing Data Log",
    ["Desc"] = "Help Groupie!",
}
L["InstanceLogInfo"] = "You can help improve Groupie by sharing the data here on our Discord, if prompted to. Thanks!"
L["About"] = {
    ["Desc"] = "About Groupie",
    ["Paragraph"] = "A better LFG tool for Classic WoW.\n\n\nGroupie was created by Gogo, LemonDrake, Kynura, and Raegen...\n\n...with help from Katz, Aevala, and Fathom.",
    ["lowerOn"] = "on",
}

L["VersionChecking"] = {
    ["JoinRaid"] = "has joined the raid group",
    ["JoinParty"] = "joins the party",
}

L["AutoRequestResponse"] = "Enable Groupie Auto Response when People Request to Join Your Group"
L["AutoInviteResponse"] = "Enable Groupie Auto Response when Being Invited to Groups"
L["CommunityLabel"] = "Groupie Community"
L["GlobalFriendsLabel"] = "Global Friends List"
L["GeneralOptionslabel"] = "General Options"
L["KeywordFilters"] = "Keyword FIlters"
