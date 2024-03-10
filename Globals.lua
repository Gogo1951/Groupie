local addonName, addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale('Groupie')
local GetAddOnMetadata = GetAddOnMetadata or (C_AddOns and C_AddOns.GetAddOnMetadata)

--Update this with each push to curse, this will be used for version checks
addon.version = GetAddOnMetadata(addonName, "Version")
addon.version = tonumber(addon.version:match("%d+%.%d+"))

--Used for storing the merged friend and ignore lists of all characters
addon.friendList = {}
addon.ignoreList = {}

--Sounds for group alerts
addon.sounds = {
    [17318] = "LFG-DungeonReady"
}

--Toggle for 'LFG mode', which disables or enables auto responses and alert sounds
addon.LFGMode = false

--Cached Item level calculations by GUID for current session
addon.ILVLCache = {}
addon.playerILVL = nil
addon.playerGearScore = nil
addon.playerFLOPScore = nil

--Message formats for various checked messages
addon.askForPlayerInfo = format("{rt3} %s : What Role are you?", addonName)
addon.askForInstance = format("{rt3} %s : What are you inviting me to?", addonName)
addon.autoRejectRequestString = "FYI, I have Auto-Reject enabled. Message me back and if it's a good fit I'll send you an invite. Thanks!"
addon.autoRejectInviteString = "FYI, I have Auto-Reject enabled. Message me back and if it's a good fit I'll come. Thanks!"
addon.instanceResetString = format("{rt3} %s : All Instances Have Been Reset!", addonName)
addon.addedNewFriendString = format("{rt3} %s : I added you as a friend! Cheers!", addonName)
addon.PROTECTED_TOKENS = {
    [1] = "%s*{rt3}%s*groupie%s*:",
    [2] = "%s*groupie%s*{rt3}%s*:",
    [3] = "%s*{diamond}%s*groupie%s*:",
    [4] = "%s*groupie%s*{diamond}%s*:",
}
addon.WARNING_MESSAGE = "{rt3} Groupie : Fake News! That is not a real Groupie Message. Quit being shady."

--Supported localizations, we only load the addon for these
addon.validLocales = { "enGB", "enUS" }
--Localizations for which we have all the saved instance data
--shows minimap prompt asking users to submit to the discord if their locale is not here
addon.completedLocales = { "enGB", "enUS" }

addon.groupieSystemColor = "ffd900"
addon.groupieSystemColorR = 255
addon.groupieSystemColorG = 217
addon.groupieSystemColorB = 0

addon.groupieLocaleTable = {
    ["zhCN"] = "Chinese",
    ["zhTW"] = "Chinese",
    ["enGB"] = "English",
    ["enUS"] = "English",
    ["frFR"] = "French",
    ["deDE"] = "German",
    ["itIT"] = "Italian",
    ["koKR"] = "Korean",
    ["ptBR"] = "Portuguese",
    ["ruRU"] = "Russian",
    ["esES"] = "Spanish",
    ["esMX"] = "Spanish",
}

addon.localeCodes = {
    ["zhCN"] = "ZH",
    ["zhTW"] = "ZH",
    ["enGB"] = "EN",
    ["enUS"] = "EN",
    ["frFR"] = "FR",
    ["deDE"] = "DE",
    ["itIT"] = "IT",
    ["koKR"] = "KO",
    ["ptBR"] = "PT",
    ["ruRU"] = "RU",
    ["esES"] = "ES",
    ["esMX"] = "ES",
}

--For now, this only supports English, but implemented such that localization would be easy in the future
--https://en.wikipedia.org/wiki/List_of_ISO_639-2_codes Language Codes
--https://en.wikipedia.org/wiki/ISO_3166-2 Country Codes
addon.groupieUnflippedLanguagePatterns = {
    ["Chinese"]    = "chinese zho chi zh",
    ["English"]    = "english eng en",
    ["French"]     = "french fra fr",
    ["German"]     = "german deu ger de",
    ["Italian"]    = "italian ita it",
    ["Korean"]     = "korean kor ko",
    ["Portuguese"] = "portuguese por pt br",
    ["Russian"]    = "russian rus ru",
    ["Spanish"]    = "spanish spa es",
}

addon.groupieLangList = {
    [1] = "Chinese",
    [2] = "English",
    [3] = "French",
    [4] = "German",
    [5] = "Italian",
    [6] = "Korean",
    [7] = "Portuguese",
    [8] = "Russian",
    [9] = "Spanish",
}

addon.groupieRoleTable = {
    [1] = "Tank",
    [2] = "Healer",
    [3] = "Ranged DPS",
    [4] = "Melee DPS"
}

addon.groupieClassRoleTable = {
    ["DEATHKNIGHT"] = {
        [L["DeathKnight"].Blood] = { [1] = "Tank" },
        [L["DeathKnight"].Frost] = { [1] = "Tank", [4] = "Melee DPS" },
        [L["DeathKnight"].Unholy] = { [4] = "Melee DPS" }
    },
    ["DRUID"] = {
        [L["Druid"].Balance] = { [3] = "Ranged DPS" },
        [L["Druid"].Feral] = { [1] = "Tank", [4] = "Melee DPS" },
        [L["Druid"].Restoration] = { [2] = "Healer" }
    },
    ["HUNTER"] = {
        [L["Hunter"].BM] = { [3] = "Ranged DPS" },
        [L["Hunter"].MM] = { [3] = "Ranged DPS" },
        [L["Hunter"].Survival] = { [3] = "Ranged DPS" }
    },
    ["MAGE"] = {
        [L["Mage"].Arcane] = { [3] = "Ranged DPS" },
        [L["Mage"].Fire] = { [3] = "Ranged DPS" },
        [L["Mage"].Frost] = { [3] = "Ranged DPS" }
    },
    ["PALADIN"] = {
        [L["Paladin"].Holy] = { [2] = "Healer" },
        [L["Paladin"].Protection] = { [1] = "Tank" },
        [L["Paladin"].Retribution] = { [4] = "Melee DPS" }
    },
    ["PRIEST"] = {
        [L["Priest"].Discipline] = { [2] = "Healer" },
        [L["Priest"].Holy] = { [2] = "Healer" },
        [L["Priest"].Shadow] = { [3] = "Ranged DPS" }
    },
    ["ROGUE"] = {
        [L["Rogue"].Assassination] = { [4] = "Melee DPS" },
        [L["Rogue"].Combat] = { [4] = "Melee DPS" },
        [L["Rogue"].Subtlety] = { [4] = "Melee DPS" }
    },
    ["SHAMAN"] = {
        [L["Shaman"].Elemental] = { [3] = "Ranged DPS" },
        [L["Shaman"].Enhancement] = { [4] = "Melee DPS" },
        [L["Shaman"].Restoration] = { [2] = "Healer" }
    },
    ["WARLOCK"] = {
        [L["Warlock"].Affliction] = { [3] = "Ranged DPS" },
        [L["Warlock"].Demonology] = { [3] = "Ranged DPS" },
        [L["Warlock"].Destruction] = { [3] = "Ranged DPS" }
    },
    ["WARRIOR"] = {
        [L["Warrior"].Arms] = { [1] = "Tank", [4] = "Melee DPS" },
        [L["Warrior"].Fury] = { [4] = "Melee DPS" },
        [L["Warrior"].Protection] = { [1] = "Tank" }
    }
}

addon.groupieInstanceTypes = {
    "Wrath of the Lich King Heroic Raids - 25",
    "Wrath of the Lich King Heroic Raids - 10",
    "Wrath of the Lich King Raids - 25",
    "Wrath of the Lich King Raids - 10",
    "Wrath of the Lich King Heroic Dungeons",
    "Wrath of the Lich King Dungeons",
    "The Burning Crusade Raids",
    "The Burning Crusade Heroic Dungeons",
    "The Burning Crusade Dungeons",
    "Classic Raids",
    "Classic Dungeons",
}

--0 - Heroic
--1 - 10 Normal
--2 - 25 Normal
--3 - Heroic 10
--4 - Heroic 25
addon.groupieVersionPatterns = {
    ["h"] = 0,
    ["hc"] = 0,
    ["heroic"] = 0,
    ["heroics"] = 0,
    ["hero"] = 0,
    ["10"] = 1,
    ["n10"] = 1,
    ["10n"] = 1,
    ["10man"] = 1,
    ["10m"] = 1,
    ["25"] = 2,
    ["n25"] = 2,
    ["25n"] = 2,
    ["25man"] = 2,
    ["25m"] = 2,
    ["h10"] = 3,
    ["h10man"] = 3,
    ["h10m"] = 3,
    ["10h"] = 3,
    ["h25"] = 4,
    ["h25man"] = 4,
    ["h25m"] = 4,
    ["25h"] = 4,
}

--0 - Generic group
--1 - Looking for Tank
--2 - Looking for Healer
--3 - Looking for DPS
--4 - LFG
--5 - boost runs
addon.groupieLFPatterns = {
    ["group"] = 0,
    ["lf"] = 0,
    ["lfm"] = 0,
    ["run"] = 0,
    ["runs"] = 0,
    ["running"] = 0,

    ["lftank"] = 1,
    ["lftanks"] = 1,
    ["tank"] = 1,
    ["tanks"] = 1,

    ["lfheal"] = 2,
    ["lfhealer"] = 2,
    ["lfheals"] = 2,
    ["lfhealers"] = 2,
    ["heal"] = 2,
    ["heals"] = 2,
    ["healer"] = 2,
    ["healers"] = 2,

    ["lfdps"] = 3,
    ["dps"] = 3,
    ["melee"] = 3,
    ["ranged"] = 3,
    ["lfmelee"] = 3,
    ["lfranged"] = 3,

    ["lfg"] = 4,

    ["boost"] = 5,
    ["boosts"] = 5,
    ["boosting"] = 5,
    ["wts"] = 5,
}

addon.groupieUnflippedLootPatterns = {
    [L["Filters"].Loot_Styles.Ticket] = "ticket",
    [L["Filters"].Loot_Styles.GDKP] = "gdkp bid buyer",
    [L["Filters"].Loot_Styles.SoftRes] = "2sr 1sr sr softres softreserve soft",
    [L["Filters"].Loot_Styles.MSOS] = "msos",
    [L["Filters"].Loot_Styles.Other] = "afk boost boosting boosts exp mob mobs recruit recruiting recruits roster selling wts xp layer hire"
}

addon.lootTypeColors = {
    [L["Filters"].Loot_Styles.Ticket] = "FFC107",
    [L["Filters"].Loot_Styles.GDKP] = "4CAF50",
    [L["Filters"].Loot_Styles.SoftRes] = "9C27B0",
    [L["Filters"].Loot_Styles.MSOS] = "2196F3",
    [L["Filters"].Loot_Styles.Other] = "FFFFFF",
    [L["Filters"].Loot_Styles.PVP] = "F44336",
}

addon.classColors = {
    ["DEATHKNIGHT"] = "C41F3B",
    ["DRUID"] = "FF7D0A",
    ["HUNTER"] = "ABD473",
    ["MAGE"] = "69CCF0",
    ["MONK"] = "00FF96",
    ["PALADIN"] = "F58CBA",
    ["PRIEST"] = "FFFFFF",
    ["ROGUE"] = "FFF569",
    ["SHAMAN"] = "0070DE",
    ["WARLOCK"] = "9482C9",
    ["WARRIOR"] = "C79C6E",
}

addon.edgeCasePatterns = { "mt", "os", "up", "dk", "eye", "st", "mh", "an" }

--instanceVersions[instance] = {{size, isHeroic}, ...}
addon.instanceVersions = addon.instanceVersions or {}
addon.instanceVersions["Ragefire Chasm"]        = { { 5, false } }
addon.instanceVersions["Wailing Caverns"]       = { { 5, false } }
addon.instanceVersions["Deadmines"]             = { { 5, false } }
addon.instanceVersions["Shadowfang Keep"]       = { { 5, false } }
addon.instanceVersions["Stormwind Stockades"]   = { { 5, false } }
addon.instanceVersions["Blackfathom Deeps"]     = addon.instanceVersions["Blackfathom Deeps"] or { { 5, false } }
addon.instanceVersions["Gnomeregan"]            = addon.instanceVersions["Gnomeregan"] or { { 5, false } }
addon.instanceVersions["Razorfen Kraul"]        = { { 5, false } }
addon.instanceVersions["Scarlet Graveyard"]     = { { 5, false } }
addon.instanceVersions["Scarlet Library"]       = { { 5, false } }
addon.instanceVersions["Scarlet Armory"]        = { { 5, false } }
addon.instanceVersions["Scarlet Cathedral"]     = { { 5, false } }
addon.instanceVersions["Razorfen Downs"]        = { { 5, false } }
addon.instanceVersions["Uldaman"]               = { { 5, false } }
addon.instanceVersions["Zul'Farrak"]            = { { 5, false } }
addon.instanceVersions["Maraudon"]              = { { 5, false } }
addon.instanceVersions["Sunken Temple"]         = { { 5, false } }
addon.instanceVersions["Blackrock Depths"]      = { { 5, false } }
addon.instanceVersions["Dire Maul East"]        = { { 5, false } }
addon.instanceVersions["Dire Maul North"]       = { { 5, false } }
addon.instanceVersions["Dire Maul West"]        = { { 5, false } }
addon.instanceVersions["Lower Blackrock Spire"] = { { 5, false } }
addon.instanceVersions["Stratholme"]            = { { 5, false } }
addon.instanceVersions["Scholomance"]           = { { 5, false } }

addon.instanceVersions["Upper Blackrock Spire"] = { { 10, false } }
addon.instanceVersions["Zul'Gurub"]             = { { 20, false } }
addon.instanceVersions["Ruins of Ahn'Qiraj"]    = { { 20, false } }
addon.instanceVersions["Onyxia's Lair"]         = { { 40, false } }
addon.instanceVersions["Molten Core"]           = { { 40, false } }
addon.instanceVersions["Blackwing Lair"]        = { { 40, false } }
addon.instanceVersions["Temple of Ahn'Qiraj"]   = { { 40, false } }
    --["Naxxramas"]             = { { 40, false } },

addon.instanceVersions["Hellfire Ramparts"]       = { { 5, false }, { 5, true } }
addon.instanceVersions["Blood Furnace"]           = { { 5, false }, { 5, true } }
addon.instanceVersions["Slave Pens"]              = { { 5, false }, { 5, true } }
addon.instanceVersions["Underbog"]                = { { 5, false }, { 5, true } }
addon.instanceVersions["Mana-Tombs"]              = { { 5, false }, { 5, true } }
addon.instanceVersions["Auchenai Crypts"]         = { { 5, false }, { 5, true } }
addon.instanceVersions["Sethekk Halls"]           = { { 5, false }, { 5, true } }
addon.instanceVersions["Old Hillsbrad Foothills"] = { { 5, false }, { 5, true } }
addon.instanceVersions["Shadow Labyrinth"]        = { { 5, false }, { 5, true } }
addon.instanceVersions["Mechanar"]                = { { 5, false }, { 5, true } }
addon.instanceVersions["Shattered Halls"]         = { { 5, false }, { 5, true } }
addon.instanceVersions["Steamvault"]              = { { 5, false }, { 5, true } }
addon.instanceVersions["Botanica"]                = { { 5, false }, { 5, true } }
addon.instanceVersions["Arcatraz"]                = { { 5, false }, { 5, true } }
addon.instanceVersions["Black Morass"]            = { { 5, false }, { 5, true } }
addon.instanceVersions["Magisters' Terrace"]      = { { 5, false }, { 5, true } }

addon.instanceVersions["Karazhan"]             = { { 10, false } }
addon.instanceVersions["Zul'Aman"]             = { { 10, false } }
addon.instanceVersions["Gruul's Lair"]         = { { 25, false } }
addon.instanceVersions["Magtheridon's Lair"]   = { { 25, false } }
addon.instanceVersions["Serpentshrine Cavern"] = { { 25, false } }
addon.instanceVersions["Tempest Keep"]         = { { 25, false } }
addon.instanceVersions["Mount Hyjal"]          = { { 25, false } }
addon.instanceVersions["Black Temple"]         = { { 25, false } }
addon.instanceVersions["Sunwell Plateau"]      = { { 25, false } }

addon.instanceVersions["Utgarde Keep"]          = { { 5, false }, { 5, true } }
addon.instanceVersions["Nexus"]                 = { { 5, false }, { 5, true } }
addon.instanceVersions["Azjol-Nerub"]           = { { 5, false }, { 5, true } }
addon.instanceVersions["Old Kingdom"]           = { { 5, false }, { 5, true } }
addon.instanceVersions["Drak'Tharon Keep"]      = { { 5, false }, { 5, true } }
addon.instanceVersions["Violet Hold"]           = { { 5, false }, { 5, true } }
addon.instanceVersions["Gundrak"]               = { { 5, false }, { 5, true } }
addon.instanceVersions["Halls of Stone"]        = { { 5, false }, { 5, true } }
addon.instanceVersions["Culling of Stratholme"] = { { 5, false }, { 5, true } }
addon.instanceVersions["Halls of Lightning"]    = { { 5, false }, { 5, true } }
addon.instanceVersions["Utgarde Pinnacle"]      = { { 5, false }, { 5, true } }
addon.instanceVersions["Oculus"]                = { { 5, false }, { 5, true } }
addon.instanceVersions["Trial of the Champion"] = { { 5, false }, { 5, true } }
addon.instanceVersions["Forge of Souls"]        = { { 5, false }, { 5, true } }
addon.instanceVersions["Pit of Saron"]          = { { 5, false }, { 5, true } }
addon.instanceVersions["Halls of Reflection"]   = { { 5, false }, { 5, true } }

addon.instanceVersions["Naxxramas"]         = { { 25, false }, { 10, false } }
addon.instanceVersions["Obsidian Sanctum"]  = { { 25, false }, { 10, false } }
addon.instanceVersions["Vault of Archavon"] = { { 25, false }, { 10, false } }
addon.instanceVersions["Eye of Eternity"]   = { { 25, false }, { 10, false } }
    --["Onyxia's Lair"]        = { { 10, false }, { 25, false } },
addon.instanceVersions["Ulduar"]            = { { 25, false }, { 10, false } }

addon.instanceVersions["Trial of the Crusader"]       = { { 25, false }, { 10, false }, { 25, true }, { 10, true } }
addon.instanceVersions["Icecrown Citadel"]            = { { 25, false }, { 10, false }, { 25, true }, { 10, true } }
addon.instanceVersions["Ruby Sanctum"]                = { { 25, false }, { 10, false }, { 25, true }, { 10, true } }
addon.instanceVersions["Trial of the Grand Crusader"] = { { 25, true }, { 10, true } }

addon.instanceVersions["Coren Direbrew"]    = { { 5, false } }
addon.instanceVersions["Ahune"]             = { { 5, false }, { 5, true } }
addon.instanceVersions["Headless Horseman"] = { { 5, false } }
addon.instanceVersions["Apothecary Hummel"] = { { 5, false } }


--For use in generating config controls, get all instance orders in order
addon.instanceOrders = {}
addon.instanceConfigData = {}
for key, val in pairs(addon.groupieInstanceData) do
    tinsert(addon.instanceOrders, val.Order)
    addon.instanceConfigData[val.Order] = {
        Name = key,
        InstanceType = val.InstanceType,
        MinLevel = val.MinLevel,
        MaxLevel = val.MaxLevel,
        GroupSize = val.GroupSize,
        IsHeroic = false
    }
    if strmatch(addon.instanceConfigData[val.Order].Name, "Heroic") then
        addon.instanceConfigData[val.Order].IsHeroic = true
    end
end
sort(addon.instanceOrders, function(a, b) return a > b end)

addon.groupieUnflippedDungeonPatterns = {
    ["Ragefire Chasm"]        = "rfc ragefire chasm",
    ["Wailing Caverns"]       = "wc wailing caverns",
    ["Deadmines"]             = "deadmines vc vancleef dead mines mine",
    ["Shadowfang Keep"]       = "sfk shadowfang",
    ["Stormwind Stockades"]   = "stk stock stockade stockades",
    ["Blackfathom Deeps"]     = "bfd blackfathom fathom",
    ["Gnomeregan"]            = "gnomer gnomeregan",
    ["Razorfen Kraul"]        = "rfk kraul",
    ["Scarlet Graveyard"]     = "smgy smg gy graveyard",
    ["Scarlet Library"]       = "smlib sml lib library",
    ["Scarlet Armory"]        = "smarm sma arm armory herod armoury arms",
    ["Scarlet Cathedral"]     = "smcath smc cath cathedral",
    ["Razorfen Downs"]        = "rfd downs",
    ["Uldaman"]               = "ulda uldaman",
    ["Zul'Farrak"]            = "zf zulfarrak farrak",
    ["Maraudon"]              = "mara maraudon princessrun princess",
    ["Sunken Temple"]         = "st sunken atal",
    ["Blackrock Depths"]      = "brd emperor emp",
    ["Dire Maul East"]        = "dme dmeast east puzilin jumprun",
    ["Dire Maul North"]       = "dmn dmnorth north tribute",
    ["Dire Maul West"]        = "dmw dmwest west",
    ["Lower Blackrock Spire"] = "lower lbrs lrbs",
    ["Stratholme"]            = "stratlive live living stratud undead ud baron stratholme stath stratholm strah strath strat starth",
    ["Scholomance"]           = "scholomance scholo sholo sholomance",

    ["Upper Blackrock Spire"] = "upper ubrs urbs rend",
    ["Zul'Gurub"]             = "zg gurub zulgurub",
    ["Ruins of Ahn'Qiraj"]    = "ruins aq20",
    ["Onyxia's Lair"]         = "onyxia ony",
    ["Molten Core"]           = "molten mc",
    ["Blackwing Lair"]        = "blackwing bwl",
    ["Temple of Ahn'Qiraj"]   = "aq40",
    ["Naxxramas"]             = "naxxramas nax naxx nx",

    ["Hellfire Ramparts"]       = "ramparts rampart ramp ramps",
    ["Blood Furnace"]           = "furnace furn bf",
    ["Slave Pens"]              = "slavepens pens sp",
    ["Underbog"]                = "underbog ub",
    ["Mana-Tombs"]              = "manatombs manatomb mana mt tomb tombs",
    ["Auchenai Crypts"]         = "crypts crypt auchenai ac acrypts acrypt",
    ["Sethekk Halls"]           = "sethekk seth anzu sethek",
    ["Old Hillsbrad Foothills"] = "ohb durnholde ohf",
    ["Shadow Labyrinth"]        = "sl slab labs labyrinth slabs",
    ["Mechanar"]                = "mech mechanar",
    ["Shattered Halls"]         = "sh shh shattered",
    ["Steamvault"]              = "sv steamvault steamvaults steam valts",
    ["Botanica"]                = "botanica bot",
    ["Arcatraz"]                = "arc arcatraz alcatraz",
    ["Black Morass"]            = "bm morass",
    ["Magisters' Terrace"]      = "mgt terrace magisters magister",

    ["Karazhan"]             = "kara karazhan karazan",
    ["Zul'Aman"]             = "za zulaman aman hsh", --hexshrunken head
    ["Gruul's Lair"]         = "gl gruul gruuls",
    ["Magtheridon's Lair"]   = "mag magtheridon magth mags",
    ["Serpentshrine Cavern"] = "ssc serpentshrine",
    ["Tempest Keep"]         = "tk tempest tempestkeep",
    ["Mount Hyjal"]          = "hyjal hs hyj mh",
    ["Black Temple"]         = "bt blacktemple glaive",
    ["Sunwell Plateau"]      = "swp sunwell plateau plataeu sunwel",

    ["Utgarde Keep"]          = "uk utgardekeep",
    ["Nexus"]                 = "nexus nex",
    ["Azjol-Nerub"]           = "an azjol nerub",
    ["Old Kingdom"]           = "ok atok ahnkahet ankahet kahet kingdom ak ank ahk",
    ["Drak'Tharon Keep"]      = "dtk tharon drak",
    ["Violet Hold"]           = "vh violet violethold",
    ["Gundrak"]               = "gundrak gd gdk",
    ["Halls of Stone"]        = "hos stone",
    ["Culling of Stratholme"] = "cos culling bronze",
    ["Halls of Lightning"]    = "hol lightning",
    ["Utgarde Pinnacle"]      = "up pinnacle",
    ["Oculus"]                = "oculus occulus oc occ ocu occu",
    --["Trial of the Champion"]      = "",
    ["Forge of Souls"]        = "forge fos forgeofsouls",
    ["Pit of Saron"]          = "pit pos pitofsaron",
    ["Halls of Reflection"]   = "hor reflection",

    --["Naxxramas"]            = "",
    ["Obsidian Sanctum"]  = "os obsidian obssanc obsanc obsidiansanctum os0d os1d os2d os3d",
    ["Vault of Archavon"] = "voa archavon vault",
    ["Eye of Eternity"]   = "eoe eye maly malygos",
    --["Onyxia's Lair"]        = "",
    ["Ulduar"]            = "uld uldu ulduar",

    ["TOC-SPECIALCASE"]             = "toc trial tocr",
    ["Icecrown Citadel"]            = "icc",
    ["Ruby Sanctum"]                = "rs rubysanctum rubysanc ruby halion",
    ["Trial of the Grand Crusader"] = "togc grand",

    ["Coren Direbrew"]    = "coren direbrew brewfest",
    ["Ahune"]             = "ahune",
    ["Headless Horseman"] = "headless horseman hh",
    ["Apothecary Hummel"] = "apothecary hummel loverocket chemical crownchemical chemicalco crownchemicalco",

    ["PVP"] = "2s 2v2 3s 3v3 5s 5v5 ab alterac arena arenas av basin challenger conquest cta duelist eots fta fth glad gladiator gulch gurubashi ioc premade PVP rival sota storm strand warsong wg wintergrasp wsg",
}


addon.groupieInstancePatterns = addon.TableFlip(addon.groupieUnflippedDungeonPatterns)
addon.groupieLootPatterns = addon.TableFlip(addon.groupieUnflippedLootPatterns)
addon.groupieLanguagePatterns = addon.TableFlip(addon.groupieUnflippedLanguagePatterns)

--Script to generate GUID for a player
--/run local name = UnitName("player"); local guid = UnitGUID("player"); ChatFrame1:AddMessage(name.." has the GUID: "..guid);
addon.GroupieDevs = {
    -- Groupie Team
    ["Player-4408-039B90A8"] = L["TeamMember"], -- Aevala-Faerlina
    ["Player-4800-048C8808"] = L["TeamMember"], -- Gogodeekay-Eranikus
    ["Player-4800-048C887A"] = L["TeamMember"], -- Gogodruid-Eranikus
    ["Player-4800-048C87ED"] = L["TeamMember"], -- Gogohunter-Eranikus
    ["Player-4800-048C88C6"] = L["TeamMember"], -- Gogomage-Eranikus
    ["Player-4800-048C88F0"] = L["TeamMember"], -- Gogopaladin-Eranikus
    ["Player-4800-048C87F8"] = L["TeamMember"], -- Gogopriest-Eranikus
    ["Player-4800-04942199"] = L["TeamMember"], -- Gogorogue-Eranikus
    ["Player-4800-048C8800"] = L["TeamMember"], -- Gogoshaman-Eranikus
    ["Player-4800-048C88CD"] = L["TeamMember"], -- Gogowarlock-Eranikus
    ["Player-4800-048C87E4"] = L["TeamMember"], -- Gogowarrior-Eranikus
    ["Player-4408-04867AC4"] = L["TeamMember"], -- Jarsjarsdk-Faerlina
    ["Player-4408-03AA25B2"] = L["TeamMember"], -- Kattz-Faerlina
    ["Player-4647-023571C6"] = L["TeamMember"], -- Kynura-Grobbulus
    ["Player-4467-02AB80C7"] = L["TeamMember"], -- Raegen-Firemaw

    -- Special Thanks
    -- TODO

    -- Test Accounts
    ["Player-4395-034E469C"] = L["TeamMember"], -- Cooltestguy-Benediction
}
