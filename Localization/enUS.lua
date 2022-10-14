--[[
	Groupie Localization Information: English Language
		This file must be present to have partial translations
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Groupie', 'enUS', true)


L["slogan"] = "A better LFG tool for Classic WoW."
L["LocalizationStatus"] = 'Localization is on the work'
L["TeamMember"] = "Team Member"

-- tabs
L["Dungeons"] = "Dungeons"
L["Raid"] = "Raids"
L["ShortHeroic"] = "H"
L["PVP"] = "PVP"
L["Other"] = "Other"
L["All"] = "All"

-- UI Columns
L["Created"] = "Created"
L["Updated"] = "Updated"
L["Leader"] = "Leader"
L["InstanceName"] = "Instance"
L["LootType"] = "Loot"
L["Message"] = "Message"


-- filters
    --- Roles
L["LookingFor"] = "LF"
L["Any"] = "Any Role"
L["Tank"] = "Tank"
L["Healer"] = "Healer"
L["DPS"] = "DPS"
    --- Loot Types
L["AnyLoot"] = "All Loot Styles"
L["MSOS"] = "MS > OS"
L["SoftRes"] = "SoftRes"
L["GDKP"] = "GDKP"
L["Ticket"] = "Ticket"
L["Other"] = "Other"
L["PVP"] = "PVP"
    --- Languages
L["AnyLanguage"] = "All Languages"
    --- Dungeons
L["AnyDungeon"] = "All Dungeons"
L["RecommendedDungeon"] = "Recommended Level Dungeons"

-- Global
L["ShowingLabel"] = "Showing"
L["SettingsButton"] = "Settings & Filters"
L["Click"] = "Click"
L["RightClick"] = "Right Click"
L["Settings"] = "Settings"
L["BulletinBoard"] = "Bulletin Board"
L["Reset"] = "Reset"
L["Options"] = "Options"
-- Channels Name /!\ VERY IMPORTANT, THE ADDON PARSES DEPENDING ON THE CHANNEL NAME
L["Guild"] = "Guild"
L["General"] = "General"
L["Trade"] = "Trade"
L["LocalDefense"] = "LocalDefense"
L["LFG"] = "LookingForGroup"
L["World"] = "5"
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
L["Instance Filters - Wrath"] = "Instance Filters - Wrath"
L["Instance Filters - TBC"] = "Instance Filters - TBC"
L["Instance Filters - Classic"] = "Instance Filters - Classic"
L["Filter Groups by Instance"] = "Filter Groups by Instance"
-- Group Filters
L["Group Filters"] = "Group Filters"
L["Filter Groups by Other Properties"] = "Filter Groups by Other Properties"
L["General Filters"] = "General Filters"
L["savedToggle"] = "Ignore Instances You Are Already Saved To on Current Character"
L["ignoreLFG"] = "Ignore \"LFG\" Messages from People Looking for a Group"
L["ignoreLFM"] = "Ignore \"LFM\" Messages from People Making a Group"
L["keyword"] = "Filter By Keyword"
L["keyword_desc"] = "Separate words or phrases using a comma; any post matching any keyword will be ignored.\nExample: \"swp trash, Selling, Boost\""
--Character Options
L["Character Options"] = "Character Options"
L["Change Character-Specific Settings"] = "Change Character-Specific Settings"
L["Spec 1 Role"] = "Spec 1 Role"
L["Spec 2 Role"] = "Spec 2 Role"
L["OtherRole"] = "Include Non-Current Spec in LFG Messages."
L["DungeonLevelRange"] = "Recommended Dungeon Level Range"
L["recLevelDropdown"] = {
        ["0"] = "Default Suggested Levels",
        ["1"] = "+1 - I've Done This Before",
        ["2"] = "+2 - I've Got Enchanted Heirlooms",
        ["3"] = "+3 - I'm Playing a Healer"
}
L["Auto-Response"] = "Auto-Response"
L["AutoFriends"] = "Enable Auto-Respond to Friends"
L["AutoGuild"] = "Enable Auto-Respond to Guild Members"
L["AfterParty"] = "After-Party Tool"
L["PullGroups"] = "Pull Groups From These Channels"
--Global Options
L["Global Options"] = "Global Options"
L["Change Account-Wide Settings"] = "Change Account-Wide Settings"
L["MiniMapButton"] = "Enable Mini-Map Button"
L["LFGData"] = "Preserve Looking for Group Data Duration"
L["UI Scale"] = "UI Scale"
L["DurationDropdown"] = {
    ["1"] = "1 Minute",
    ["2"] = "2 Minutes",
    ["5"] = "5 Minutes",
    ["10"] = "10 Minutes",
    ["20"] = "20 Minutes",
}
L["Role for Spec 1"] = "Role for Spec 1"
L["Role for Spec 2"] = "Role for Spec 2"
--RightClickMenu
L["SendInfo"] = "Send my info..."
L["Current"] = "Current"
L["WCL"] = "Warcraft Logs Link"
L["Ignore"] = "Ignore"
L["StopIgnore"] = "Stop Ignoring"
L["Invite"] = "Invite"
L["Whisper"] = "Whisper"

--minimap
L["lowerOr"] = "or"
L["Update1"] = "PLEASE UPDATE YOUR ADD-ONS ASAP!"
L["Update2"] = "GROUPIE IS OUT OF DATE!"
L["HelpUs"] = "Groupie needs your help! Please go to\nGroupie Settings > Instance Log and\nupload the values to Groupie Discord.\nThis message will go away next time\nyou update Groupie. Thanks!"
--Instance Log
L["Instance Log"] = "Instance Log"
L["Help Groupie"] = "Help Groupie!"
--About
L["About Groupie"] = "About Groupie"
L["About Paragraph"] = "A better LFG tool for Classic WoW.\n\n\nGroupie was created by Gogo, LemonDrake, Kynura, and Raegen...\n\n...with help from Katz, Aevala, and Fathom."
L["lowerOn"] = "on"

--VersionChecking
L["JoinRaid"] = "has joined the raid group"
L["JoinParty"] = "joins the party"

L["AutoRequestResponse"] = "Enable Groupie Auto Response when People Request to Join Your Group"
L["AutoInviteResponse"] = "Enable Groupie Auto Response when Being Invited to Groups"
L["CommunityLabel"] = "Groupie Community"
L["GlobalFriendsLabel"] = "Global Friends List"
L["GeneralOptionslabel"] = "General Options"
L["KeywordFilters"] = "Keyword FIlters"
L["InstanceLogInfo"] = "You can help improve Groupie by sharing the data here on our Discord, if promoted to. Thanks!"
L["Enable"] = "Enable"