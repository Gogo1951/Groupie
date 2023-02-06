local addonName, addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale('Groupie')

--Update this with each push to curse, this will be used for version checks
addon.version = tonumber(GetAddOnMetadata(addonName, "Version"))

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
addon.playerGearScoreColor = nil

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
addon.instanceVersions = {
    ["Ragefire Chasm"]        = { { 5, false } },
    ["Wailing Caverns"]       = { { 5, false } },
    ["Deadmines"]             = { { 5, false } },
    ["Shadowfang Keep"]       = { { 5, false } },
    ["Stormwind Stockades"]   = { { 5, false } },
    ["Blackfathom Deeps"]     = { { 5, false } },
    ["Gnomeregan"]            = { { 5, false } },
    ["Razorfen Kraul"]        = { { 5, false } },
    ["Scarlet Graveyard"]     = { { 5, false } },
    ["Scarlet Library"]       = { { 5, false } },
    ["Scarlet Armory"]        = { { 5, false } },
    ["Scarlet Cathedral"]     = { { 5, false } },
    ["Razorfen Downs"]        = { { 5, false } },
    ["Uldaman"]               = { { 5, false } },
    ["Zul'Farrak"]            = { { 5, false } },
    ["Maraudon"]              = { { 5, false } },
    ["Sunken Temple"]         = { { 5, false } },
    ["Blackrock Depths"]      = { { 5, false } },
    ["Dire Maul East"]        = { { 5, false } },
    ["Dire Maul North"]       = { { 5, false } },
    ["Dire Maul West"]        = { { 5, false } },
    ["Lower Blackrock Spire"] = { { 5, false } },
    ["Stratholme"]            = { { 5, false } },
    ["Scholomance"]           = { { 5, false } },

    ["Upper Blackrock Spire"] = { { 10, false } },
    ["Zul'Gurub"]             = { { 20, false } },
    ["Ruins of Ahn'Qiraj"]    = { { 20, false } },
    ["Onyxia's Lair"]         = { { 40, false } },
    ["Molten Core"]           = { { 40, false } },
    ["Blackwing Lair"]        = { { 40, false } },
    ["Temple of Ahn'Qiraj"]   = { { 40, false } },
    --["Naxxramas"]             = { { 40, false } },

    ["Hellfire Ramparts"]       = { { 5, false }, { 5, true } },
    ["Blood Furnace"]           = { { 5, false }, { 5, true } },
    ["Slave Pens"]              = { { 5, false }, { 5, true } },
    ["Underbog"]                = { { 5, false }, { 5, true } },
    ["Mana-Tombs"]              = { { 5, false }, { 5, true } },
    ["Auchenai Crypts"]         = { { 5, false }, { 5, true } },
    ["Sethekk Halls"]           = { { 5, false }, { 5, true } },
    ["Old Hillsbrad Foothills"] = { { 5, false }, { 5, true } },
    ["Shadow Labyrinth"]        = { { 5, false }, { 5, true } },
    ["Mechanar"]                = { { 5, false }, { 5, true } },
    ["Shattered Halls"]         = { { 5, false }, { 5, true } },
    ["Steamvault"]              = { { 5, false }, { 5, true } },
    ["Botanica"]                = { { 5, false }, { 5, true } },
    ["Arcatraz"]                = { { 5, false }, { 5, true } },
    ["Black Morass"]            = { { 5, false }, { 5, true } },
    ["Magisters' Terrace"]      = { { 5, false }, { 5, true } },

    ["Karazhan"]             = { { 10, false } },
    ["Zul'Aman"]             = { { 10, false } },
    ["Gruul's Lair"]         = { { 25, false } },
    ["Magtheridon's Lair"]   = { { 25, false } },
    ["Serpentshrine Cavern"] = { { 25, false } },
    ["Tempest Keep"]         = { { 25, false } },
    ["Mount Hyjal"]          = { { 25, false } },
    ["Black Temple"]         = { { 25, false } },
    ["Sunwell Plateau"]      = { { 25, false } },

    ["Utgarde Keep"]          = { { 5, false }, { 5, true } },
    ["Nexus"]                 = { { 5, false }, { 5, true } },
    ["Azjol-Nerub"]           = { { 5, false }, { 5, true } },
    ["Old Kingdom"]           = { { 5, false }, { 5, true } },
    ["Drak'Tharon Keep"]      = { { 5, false }, { 5, true } },
    ["Violet Hold"]           = { { 5, false }, { 5, true } },
    ["Gundrak"]               = { { 5, false }, { 5, true } },
    ["Halls of Stone"]        = { { 5, false }, { 5, true } },
    ["Culling of Stratholme"] = { { 5, false }, { 5, true } },
    ["Halls of Lightning"]    = { { 5, false }, { 5, true } },
    ["Utgarde Pinnacle"]      = { { 5, false }, { 5, true } },
    ["Oculus"]                = { { 5, false }, { 5, true } },
    ["Trial of the Champion"] = { { 5, false }, { 5, true } },
    ["Forge of Souls"]        = { { 5, false }, { 5, true } },
    ["Pit of Saron"]          = { { 5, false }, { 5, true } },
    ["Halls of Reflection"]   = { { 5, false }, { 5, true } },

    ["Naxxramas"]         = { { 25, false }, { 10, false } },
    ["Obsidian Sanctum"]  = { { 25, false }, { 10, false } },
    ["Vault of Archavon"] = { { 25, false }, { 10, false } },
    ["Eye of Eternity"]   = { { 25, false }, { 10, false } },
    --["Onyxia's Lair"]        = { { 10, false }, { 25, false } },
    ["Ulduar"]            = { { 25, false }, { 10, false } },

    ["Trial of the Crusader"]       = { { 25, false }, { 10, false }, { 25, true }, { 10, true } },
    ["Icecrown Citadel"]            = { { 25, false }, { 10, false }, { 25, true }, { 10, true } },
    ["Ruby Sanctum"]                = { { 25, false }, { 10, false }, { 25, true }, { 10, true } },
    ["Trial of the Grand Crusader"] = { { 25, true }, { 10, true } },

    ["Coren Direbrew"]    = { { 5, false } },
    ["Ahune"]             = { { 5, false }, { 5, true } },
    ["Headless Horseman"] = { { 5, false } },
    ["Apothecary Hummel"] = { { 5, false } },
}


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
<<<<<<< HEAD
=======

addon.groupieAchievementPriorities = {
    ["Arcatraz"] = {
        [1] = 1287,
        [2] = 681,
        [3] = 1284,
        [4] = 660,
    },
    ["Auchenai Crypts"] = {
        [1] = 1287,
        [2] = 672,
        [3] = 1284,
        [4] = 666,
    },
    ["Azjol-Nerub"] = {
        [1] = 17304,
        [2] = 17285,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 491,
        [7] = 1288,
        [8] = 480,
    },
    ["Black Morass"] = {
        [1] = 1287,
        [2] = 676,
        [3] = 1284,
        [4] = 655,
    },
    ["Black Temple"] = {
        [1] = 1286,
        [2] = 697,
    },
    ["Blackfathom Deeps"] = {
        [1] = 1283,
        [2] = 632,
    },
    ["Blackrock Depths"] = {
        [1] = 1283,
        [2] = 642,
    },
    ["Blackwing Lair"] = {
        [1] = 1285,
        [2] = 685,
    },
    ["Blood Furnace"] = {
        [1] = 1287,
        [2] = 668,
        [3] = 1284,
        [4] = 648,
    },
    ["Botanica"] = {
        [1] = 1287,
        [2] = 680,
        [3] = 1284,
        [4] = 659,
    },
    ["Culling of Stratholme"] = {
        [1] = 17304,
        [2] = 17302,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 500,
        [7] = 1288,
        [8] = 479,
    },
    ["Deadmines"] = {
        [1] = 1283,
        [2] = 628,
    },
    ["Dire Maul East"] = {
        [1] = 1283,
        [2] = 644,
    },
    ["Dire Maul North"] = {
        [1] = 1283,
        [2] = 644,
    },
    ["Dire Maul West"] = {
        [1] = 1283,
        [2] = 644,
    },
    ["Drak'Tharon Keep"] = {
        [1] = 17304,
        [2] = 17292,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 493,
        [7] = 1288,
        [8] = 482,
    },
    ["Eye of Eternity - 10"] = {
        [1] = 1400,
        [2] = 2138,
        [3] = 2137,
        [4] = 1870,
        [5] = 1869,
        [6] = 1875,
        [7] = 1874,
        [8] = 623,
        [9] = 622,
    },
    ["Eye of Eternity - 25"] = {
        [1] = 1400,
        [2] = 2138,
        [3] = 2137,
        [4] = 1870,
        [5] = 1869,
        [6] = 1875,
        [7] = 1874,
        [8] = 623,
        [9] = 622,
    },
    ["Forge of Souls"] = {
        [1] = 2136,
        [2] = 1289,
        [3] = 4519,
        [4] = 1288,
        [5] = 4516,
    },
    ["Gnomeregan"] = {
        [1] = 1283,
        [2] = 634,
    },
    ["Gruul's Lair"] = {
        [1] = 1286,
        [2] = 692,
    },
    ["Gundrak"] = {
        [1] = 17304,
        [2] = 17295,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 495,
        [7] = 1288,
        [8] = 484,
    },
    ["Halls of Lightning"] = {
        [1] = 17304,
        [2] = 17299,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 497,
        [7] = 1288,
        [8] = 486,
    },
    ["Halls of Reflection"] = {
        [1] = 2136,
        [2] = 1289,
        [3] = 4521,
        [4] = 1288,
        [5] = 4518,
    },
    ["Halls of Stone"] = {
        [1] = 17304,
        [2] = 17297,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 496,
        [7] = 1288,
        [8] = 485,
    },
    ["Hellfire Ramparts"] = {
        [1] = 1287,
        [2] = 667,
        [3] = 1284,
        [4] = 647,
    },
    ["Heroic Arcatraz"] = {
        [1] = 1287,
        [2] = 681,
        [3] = 1284,
        [4] = 660,
    },
    ["Heroic Auchenai Crypts"] = {
        [1] = 1287,
        [2] = 672,
        [3] = 1284,
        [4] = 666,
    },
    ["Heroic Azjol-Nerub"] = {
        [1] = 17304,
        [2] = 17285,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 491,
        [7] = 1288,
        [8] = 480,
    },
    ["Heroic Black Morass"] = {
        [1] = 1287,
        [2] = 676,
        [3] = 1284,
        [4] = 655,
    },
    ["Heroic Blood Furnace"] = {
        [1] = 1287,
        [2] = 668,
        [3] = 1284,
        [4] = 648,
    },
    ["Heroic Botanica"] = {
        [1] = 1287,
        [2] = 680,
        [3] = 1284,
        [4] = 659,
    },
    ["Heroic Culling of Stratholme"] = {
        [1] = 17304,
        [2] = 17302,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 500,
        [7] = 1288,
        [8] = 479,
    },
    ["Heroic Drak'Tharon Keep"] = {
        [1] = 17304,
        [2] = 17292,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 493,
        [7] = 1288,
        [8] = 482,
    },
    ["Heroic Forge of Souls"] = {
        [1] = 2136,
        [2] = 1289,
        [3] = 4519,
        [4] = 1288,
        [5] = 4516,
    },
    ["Heroic Gundrak"] = {
        [1] = 17304,
        [2] = 17295,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 495,
        [7] = 1288,
        [8] = 484,
    },
    ["Heroic Halls of Lightning"] = {
        [1] = 17304,
        [2] = 17299,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 497,
        [7] = 1288,
        [8] = 486,
    },
    ["Heroic Halls of Reflection"] = {
        [1] = 2136,
        [2] = 1289,
        [3] = 4521,
        [4] = 1288,
        [5] = 4518,
    },
    ["Heroic Halls of Stone"] = {
        [1] = 17304,
        [2] = 17297,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 496,
        [7] = 1288,
        [8] = 485,
    },
    ["Heroic Hellfire Ramparts"] = {
        [1] = 1287,
        [2] = 667,
        [3] = 1284,
        [4] = 647,
    },
    ["Heroic Magisters' Terrace"] = {
        [1] = 1287,
        [2] = 682,
        [3] = 1284,
        [4] = 661,
    },
    ["Heroic Mana-Tombs"] = {
        [1] = 1287,
        [2] = 671,
        [3] = 1284,
        [4] = 651,
    },
    ["Heroic Mechanar"] = {
        [1] = 1287,
        [2] = 679,
        [3] = 1284,
        [4] = 658,
    },
    ["Heroic Nexus"] = {
        [1] = 17304,
        [2] = 17283,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 490,
        [7] = 1288,
        [8] = 478,
    },
    ["Heroic Oculus"] = {
        [1] = 17304,
        [2] = 17300,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 498,
        [7] = 1288,
        [8] = 487,
    },
    ["Heroic Old Hillsbrad Foothills"] = {
        [1] = 1287,
        [2] = 673,
        [3] = 1284,
        [4] = 652,
    },
    ["Heroic Old Kingdom"] = {
        [1] = 17304,
        [2] = 17291,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 492,
        [7] = 1288,
        [8] = 481,
    },
    ["Heroic Pit of Saron"] = {
        [1] = 2136,
        [2] = 1289,
        [3] = 4520,
        [4] = 1288,
        [5] = 4517,
    },
    ["Heroic Sethekk Halls"] = {
        [1] = 1287,
        [2] = 674,
        [3] = 1284,
        [4] = 653,
    },
    ["Heroic Shadow Labyrinth"] = {
        [1] = 1287,
        [2] = 675,
        [3] = 1284,
        [4] = 654,
    },
    ["Heroic Shattered Halls"] = {
        [1] = 1287,
        [2] = 678,
        [3] = 1284,
        [4] = 657,
    },
    ["Heroic Slave Pens"] = {
        [1] = 1287,
        [2] = 669,
        [3] = 1284,
        [4] = 649,
    },
    ["Heroic Steamvault"] = {
        [1] = 1287,
        [2] = 677,
        [3] = 1284,
        [4] = 656,
    },
    ["Heroic Trial of the Champion"] = {
        [1] = 2136,
        [2] = 1289,
        [3] = 4297,
        [4] = 4298,
        [5] = 1288,
        [6] = 4296,
        [7] = 3778,
    },
    ["Heroic Underbog"] = {
        [1] = 1287,
        [2] = 670,
        [3] = 1284,
        [4] = 650,
    },
    ["Heroic Utgarde Keep"] = {
        [1] = 17304,
        [2] = 17213,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 489,
        [7] = 1288,
        [8] = 477,
    },
    ["Heroic Utgarde Pinnacle"] = {
        [1] = 17304,
        [2] = 17301,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 499,
        [7] = 1288,
        [8] = 488,
    },
    ["Heroic Violet Hold"] = {
        [1] = 17304,
        [2] = 17293,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 494,
        [7] = 1288,
        [8] = 483,
    },
    ["Karazhan"] = {
        [1] = 1286,
        [2] = 690,
    },
    ["Lower Blackrock Spire"] = {
        [1] = 1283,
        [2] = 643,
    },
    ["Magisters' Terrace"] = {
        [1] = 1287,
        [2] = 682,
        [3] = 1284,
        [4] = 661,
    },
    ["Magtheridon's Lair"] = {
        [1] = 1286,
        [2] = 693,
    },
    ["Mana-Tombs"] = {
        [1] = 1287,
        [2] = 671,
        [3] = 1284,
        [4] = 651,
    },
    ["Maraudon"] = {
        [1] = 1283,
        [2] = 640,
    },
    ["Mechanar"] = {
        [1] = 1287,
        [2] = 679,
        [3] = 1284,
        [4] = 658,
    },
    ["Molten Core"] = {
        [1] = 1285,
        [2] = 686,
    },
    ["Mount Hyjal"] = {
        [1] = 1286,
        [2] = 695,
    },
    ["Naxxramas - 10"] = {
        [1] = 1402,
        [2] = 2138,
        [3] = 2137,
        [4] = 2186,
        [5] = 2187,
        [12] = 579,
        [13] = 578,
        [14] = 577,
        [17] = 576,
    },
    ["Naxxramas - 25"] = {
        [1] = 1402,
        [2] = 2138,
        [3] = 2137,
        [4] = 2186,
        [5] = 2187,
        [12] = 579,
        [13] = 578,
        [14] = 577,
        [17] = 576,
    },
    ["Nexus"] = {
        [1] = 17304,
        [2] = 17283,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 490,
        [7] = 1288,
        [8] = 478,
    },
    ["Obsidian Sanctum - 10"] = {
        [1] = 456,
        [2] = 2138,
        [3] = 2137,
        [4] = 2054,
        [5] = 2051,
        [6] = 2053,
        [7] = 2050,
        [8] = 2052,
        [9] = 2049,
        [10] = 2048,
        [11] = 2047,
        [12] = 1877,
        [13] = 624,
        [14] = 625,
        [15] = 1876,
    },
    ["Obsidian Sanctum - 25"] = {
        [1] = 456,
        [2] = 2138,
        [3] = 2137,
        [4] = 2054,
        [5] = 2051,
        [6] = 2053,
        [7] = 2050,
        [8] = 2052,
        [9] = 2049,
        [10] = 2048,
        [11] = 2047,
        [12] = 1877,
        [13] = 624,
        [14] = 625,
        [15] = 1876,
    },
    ["Oculus"] = {
        [1] = 17304,
        [2] = 17300,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 498,
        [7] = 1288,
        [8] = 487,
    },
    ["Old Hillsbrad Foothills"] = {
        [1] = 1287,
        [2] = 673,
        [3] = 1284,
        [4] = 652,
    },
    ["Old Kingdom"] = {
        [1] = 17304,
        [2] = 17291,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 492,
        [7] = 1288,
        [8] = 481,
    },
    ["Onyxia's Lair - 10"] = {
        [1] = 4407,
        [2] = 4404,
        [3] = 4406,
        [4] = 4403,
        [5] = 4405,
        [6] = 4402,
        [7] = 4397,
        [8] = 4396,
    },
    ["Onyxia's Lair - 25"] = {
        [1] = 4407,
        [2] = 4404,
        [3] = 4406,
        [4] = 4403,
        [5] = 4405,
        [6] = 4402,
        [7] = 4397,
        [8] = 4396,
    },
    ["Pit of Saron"] = {
        [1] = 2136,
        [2] = 1289,
        [3] = 4520,
        [4] = 1288,
        [5] = 4517,
    },
    ["Ragefire Chasm"] = {
        [1] = 1283,
        [2] = 629,
    },
    ["Razorfen Downs"] = {
        [1] = 1283,
        [2] = 636,
    },
    ["Razorfen Kraul"] = {
        [1] = 1283,
        [2] = 635,
    },
    ["Ruins of Ahn'Qiraj"] = {
        [1] = 1285,
        [2] = 689,
    },
    ["Scarlet Armory"] = {
        [1] = 1283,
        [2] = 637,
    },
    ["Scarlet Cathedral"] = {
        [1] = 1283,
        [2] = 637,
    },
    ["Scarlet Graveyard"] = {
        [1] = 1283,
        [2] = 637,
    },
    ["Scarlet Library"] = {
        [1] = 1283,
        [2] = 637,
    },
    ["Scholomance"] = {
        [1] = 1283,
        [2] = 645,
    },
    ["Serpentshrine Cavern"] = {
        [1] = 1286,
        [2] = 694,
    },
    ["Sethekk Halls"] = {
        [1] = 1287,
        [2] = 674,
        [3] = 1284,
        [4] = 653,
    },
    ["Shadow Labyrinth"] = {
        [1] = 1287,
        [2] = 675,
        [3] = 1284,
        [4] = 654,
    },
    ["Shadowfang Keep"] = {
        [1] = 1283,
        [2] = 631,
    },
    ["Shattered Halls"] = {
        [1] = 1287,
        [2] = 678,
        [3] = 1284,
        [4] = 657,
    },
    ["Slave Pens"] = {
        [1] = 1287,
        [2] = 669,
        [3] = 1284,
        [4] = 649,
    },
    ["Steamvault"] = {
        [1] = 1287,
        [2] = 677,
        [3] = 1284,
        [4] = 656,
    },
    ["Stormwind Stockades"] = {
        [1] = 1283,
        [2] = 633,
    },
    ["Stratholme"] = {
        [1] = 1283,
        [2] = 646,
    },
    ["Sunken Temple"] = {
        [1] = 1283,
        [2] = 641,
    },
    ["Sunwell Plateau"] = {
        [1] = 1286,
        [2] = 698,
    },
    ["Tempest Keep"] = {
        [1] = 1286,
        [2] = 696,
    },
    ["Temple of Ahn'Qiraj"] = {
        [1] = 1285,
        [2] = 687,
    },
    ["Trial of the Champion"] = {
        [1] = 2136,
        [2] = 1289,
        [3] = 4297,
        [4] = 4298,
        [5] = 1288,
        [6] = 4296,
        [7] = 3778,
    },
    ["Uldaman"] = {
        [1] = 1283,
        [2] = 638,
    },
    ["Ulduar - 10"] = {
        [1] = 3117,
        [2] = 3259,
        [3] = 3164,
        [4] = 3159,
        [5] = 2958,
        [6] = 2957,
        [7] = 3163,
        [8] = 3158,
        [9] = 3162,
        [10] = 3141,
        [11] = 3161,
        [12] = 3157,
        [13] = 2903,
        [14] = 2904,
        [15] = 3316,
        [16] = 3005,
        [17] = 3004,
        [18] = 3016,
        [19] = 3015,
        [20] = 3037,
        [21] = 3036,
        [22] = 2893,
        [23] = 2892,
        [24] = 2891,
        [25] = 2890,
        [26] = 2889,
        [27] = 2888,
        [28] = 2887,
        [29] = 2886,
    },
    ["Ulduar - 25"] = {
        [1] = 3117,
        [2] = 3259,
        [3] = 3164,
        [4] = 3159,
        [5] = 2958,
        [6] = 2957,
        [7] = 3163,
        [8] = 3158,
        [9] = 3162,
        [10] = 3141,
        [11] = 3161,
        [12] = 3157,
        [13] = 2903,
        [14] = 2904,
        [15] = 3316,
        [16] = 3005,
        [17] = 3004,
        [18] = 3016,
        [19] = 3015,
        [20] = 3037,
        [21] = 3036,
        [22] = 2893,
        [23] = 2892,
        [24] = 2891,
        [25] = 2890,
        [26] = 2889,
        [27] = 2888,
        [28] = 2887,
        [29] = 2886,
    },
    ["Underbog"] = {
        [1] = 1287,
        [2] = 670,
        [3] = 1284,
        [4] = 650,
    },
    ["Utgarde Keep"] = {
        [1] = 17304,
        [2] = 17213,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 489,
        [7] = 1288,
        [8] = 477,
    },
    ["Utgarde Pinnacle"] = {
        [1] = 17304,
        [2] = 17301,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 499,
        [7] = 1288,
        [8] = 488,
    },
    ["Vault of Archavon - 10"] = {
        [1] = 4017,
        [2] = 4016,
        [3] = 4586,
        [4] = 4585,
        [5] = 3837,
        [6] = 3836,
        [7] = 3137,
        [8] = 3136,
        [9] = 1721,
        [10] = 1722,
    },
    ["Vault of Archavon - 25"] = {
        [1] = 4017,
        [2] = 4016,
        [3] = 4586,
        [4] = 4585,
        [5] = 3837,
        [6] = 3836,
        [7] = 3137,
        [8] = 3136,
        [9] = 1721,
        [10] = 1722,
    },
    ["Violet Hold"] = {
        [1] = 17304,
        [2] = 17293,
        [3] = 2136,
        [4] = 1658,
        [5] = 1289,
        [6] = 494,
        [7] = 1288,
        [8] = 483,
    },
    ["Wailing Caverns"] = {
        [1] = 1283,
        [2] = 630,
    },
    ["Zul'Aman"] = {
        [1] = 1286,
        [2] = 691,
    },
    ["Zul'Farrak"] = {
        [1] = 1283,
        [2] = 639,
    },
    ["Zul'Gurub"] = {
        [1] = 1285,
        [2] = 688,
    },
}
>>>>>>> 7678c6531c958ec5b86d1f57315ccfb9c221d33c
