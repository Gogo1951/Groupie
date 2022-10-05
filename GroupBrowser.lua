local addonName, Groupie = ...
local GroupieGroupBrowser = Groupie:NewModule("GroupieGroupBrowser", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
local L = LibStub('AceLocale-3.0'):GetLocale('Groupie')
local C_LFGList = _G.C_LFGList
local UnitAffectingCombat = _G.UnitAffectingCombat
local GetNormalizedRealmName = _G.GetNormalizedRealmName
local IsInGroup = _G.IsInGroup
local SEARCH_COOLDOWN = 15 -- never lower than 10
local MAX_QUEUE_SIZE = math.ceil(300 / SEARCH_COOLDOWN) -- let's cap queue to 5mins worth of sends
local listingTable
local lfgIconTexture = "Interface\\LFGFRAME\\UI-LFG-PORTRAIT"
local lfgMessagePrefix = CreateTextureMarkup(lfgIconTexture, 32, 32, 16, 16, 0, 1, 0, 1)
local groupieInstanceData = Groupie.groupieInstanceData
local instanceVersions = Groupie.instanceVersions

-- Do not edit these first 3 tables they are generated from game data
GroupieGroupBrowser._categoryMap = {
  [2] = "Dungeons",
  [114] = "Raids",
  [116] = "Quests & Zones",
  [117] = "Heroic Dungeons",
  [118] = "PvP",
  [120] = "Custom",
}
GroupieGroupBrowser._activityGroupMap = {
  [285] = "Dungeons",
  [286] = "Burning Crusade Dungeons",
  [287] = "Lich King Dungeons",
  [288] = "Burning Crusade Heroic Dungeons",
  [289] = "Lich King Heroic Dungeons",
  [290] = "Classic Raids",
  [291] = "Burning Crusade Raids",
  [292] = "Lich King Raids (10)",
  [293] = "Lich King Raids (25)",
  [294] = "Holiday Dungeons",
  [295] = "Eastern Kingdoms",
  [296] = "Kalimdor",
  [297] = "Outland",
  [298] = "Northrend",
  [299] = "Arenas",
  [300] = "Battlegrounds",
  [301] = "World PvP",
}
GroupieGroupBrowser._activityMap = {
  [936] = { name = "2v2 Arena", cat = 118, group = 299, exp_or_honor = 80, mapid = 0, maxsize = 2, minlevel = 80,
    maxlevel = 80, iconfile = 136329 },
  [937] = { name = "3v3 Arena", cat = 118, group = 299, exp_or_honor = 80, mapid = 0, maxsize = 3, minlevel = 80,
    maxlevel = 80, iconfile = 136329 },
  [938] = { name = "5v5 Arena", cat = 118, group = 299, exp_or_honor = 80, mapid = 0, maxsize = 5, minlevel = 80,
    maxlevel = 80, iconfile = 136329 },
  [1149] = { name = "A Game of Towers (Eastern Plaguelands)", cat = 118, group = 301, exp_or_honor = 60, mapid = 0,
    maxsize = 0, minlevel = 55, maxlevel = 0, iconfile = 0 },
  [1072] = { name = "Ahn'kahet: The Old Kingdom", cat = 2, group = 287, exp_or_honor = 78, mapid = 619, maxsize = 5,
    minlevel = 71, maxlevel = 0, iconfile = 237592 },
  [1131] = { name = "Ahn'kahet: The Old Kingdom", cat = 2, group = 289, exp_or_honor = 80, mapid = 619, maxsize = 5,
    minlevel = 80, maxlevel = 0, iconfile = 237592 },
  [842] = { name = "Ahn'Qiraj Ruins", cat = 114, group = 290, exp_or_honor = 69, mapid = 509, maxsize = 20, minlevel = 60,
    maxlevel = 0, iconfile = 136320 },
  [843] = { name = "Ahn'Qiraj Temple", cat = 114, group = 290, exp_or_honor = 69, mapid = 531, maxsize = 40,
    minlevel = 60,
    maxlevel = 0, iconfile = 136321 },
  [873] = { name = "Alterac Mountains", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 28,
    maxlevel = 44, iconfile = 0 },
  [932] = { name = "Alterac Valley", cat = 118, group = 300, exp_or_honor = 60, mapid = 30, maxsize = 5, minlevel = 51,
    maxlevel = 60, iconfile = 136324 },
  [933] = { name = "Alterac Valley", cat = 118, group = 300, exp_or_honor = 70, mapid = 30, maxsize = 5, minlevel = 61,
    maxlevel = 70, iconfile = 136324 },
  [1140] = { name = "Alterac Valley", cat = 118, group = 300, exp_or_honor = 79, mapid = 30, maxsize = 5, minlevel = 71,
    maxlevel = 79, iconfile = 136324 },
  [1141] = { name = "Alterac Valley", cat = 118, group = 300, exp_or_honor = 80, mapid = 30, maxsize = 5, minlevel = 80,
    maxlevel = 80, iconfile = 136324 },
  [926] = { name = "Arathi Basin", cat = 118, group = 300, exp_or_honor = 29, mapid = 529, maxsize = 15, minlevel = 20,
    maxlevel = 29, iconfile = 136322 },
  [927] = { name = "Arathi Basin", cat = 118, group = 300, exp_or_honor = 39, mapid = 529, maxsize = 15, minlevel = 30,
    maxlevel = 39, iconfile = 136322 },
  [928] = { name = "Arathi Basin", cat = 118, group = 300, exp_or_honor = 49, mapid = 529, maxsize = 15, minlevel = 40,
    maxlevel = 49, iconfile = 136322 },
  [929] = { name = "Arathi Basin", cat = 118, group = 300, exp_or_honor = 59, mapid = 529, maxsize = 15, minlevel = 50,
    maxlevel = 59, iconfile = 136322 },
  [930] = { name = "Arathi Basin", cat = 118, group = 300, exp_or_honor = 69, mapid = 529, maxsize = 15, minlevel = 60,
    maxlevel = 69, iconfile = 136322 },
  [931] = { name = "Arathi Basin", cat = 118, group = 300, exp_or_honor = 79, mapid = 529, maxsize = 15, minlevel = 70,
    maxlevel = 79, iconfile = 136322 },
  [1138] = { name = "Arathi Basin", cat = 118, group = 300, exp_or_honor = 80, mapid = 529, maxsize = 15, minlevel = 80,
    maxlevel = 80, iconfile = 136322 },
  [866] = { name = "Arathi Highlands", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 28,
    maxlevel = 44, iconfile = 0 },
  [887] = { name = "Ashenvale", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 18,
    maxlevel = 34, iconfile = 0 },
  [824] = { name = "Auchenai Crypts", cat = 2, group = 286, exp_or_honor = 72, mapid = 558, maxsize = 5, minlevel = 64,
    maxlevel = 0, iconfile = 136323 },
  [903] = { name = "Auchenai Crypts", cat = 2, group = 288, exp_or_honor = 72, mapid = 558, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 136323 },
  [1066] = { name = "Azjol-Nerub", cat = 2, group = 287, exp_or_honor = 77, mapid = 601, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 237593 },
  [1121] = { name = "Azjol-Nerub", cat = 2, group = 289, exp_or_honor = 80, mapid = 601, maxsize = 5, minlevel = 80,
    maxlevel = 0, iconfile = 237593 },
  [889] = { name = "Azshara", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 43,
    maxlevel = 60, iconfile = 0 },
  [899] = { name = "Azuremyst Isle", cat = 116, group = 296, exp_or_honor = 70, mapid = 530, maxsize = 0, minlevel = 1,
    maxlevel = 14, iconfile = 0 },
  [865] = { name = "Badlands", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 33,
    maxlevel = 50, iconfile = 0 },
  [850] = { name = "Black Temple", cat = 114, group = 291, exp_or_honor = 79, mapid = 564, maxsize = 25, minlevel = 70,
    maxlevel = 0, iconfile = 136328 },
  [801] = { name = "Blackfathom Deeps", cat = 2, group = 285, exp_or_honor = 28, mapid = 48, maxsize = 5, minlevel = 20,
    maxlevel = 0, iconfile = 136325 },
  [811] = { name = "Blackrock Depths", cat = 2, group = 285, exp_or_honor = 60, mapid = 230, maxsize = 5, minlevel = 48,
    maxlevel = 0, iconfile = 136326 },
  [840] = { name = "Blackwing Lair", cat = 114, group = 290, exp_or_honor = 69, mapid = 469, maxsize = 40, minlevel = 60,
    maxlevel = 0, iconfile = 136329 },
  [896] = { name = "Blade's Edge Mountains", cat = 116, group = 297, exp_or_honor = 70, mapid = 530, maxsize = 0,
    minlevel = 63, maxlevel = 71, iconfile = 136348 },
  [860] = { name = "Blasted Lands", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 43,
    maxlevel = 60, iconfile = 0 },
  [818] = { name = "Blood Furnace", cat = 2, group = 286, exp_or_honor = 68, mapid = 542, maxsize = 5, minlevel = 60,
    maxlevel = 0, iconfile = 136338 },
  [912] = { name = "Blood Furnace", cat = 2, group = 288, exp_or_honor = 72, mapid = 542, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 136338 },
  [901] = { name = "Bloodmyst Isle", cat = 116, group = 296, exp_or_honor = 70, mapid = 530, maxsize = 0, minlevel = 8,
    maxlevel = 24, iconfile = 0 },
  [1116] = { name = "Borean Tundra", cat = 116, group = 298, exp_or_honor = 80, mapid = 571, maxsize = 0, minlevel = 68,
    maxlevel = 80, iconfile = 0 },
  [863] = { name = "Burning Steppes", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 48,
    maxlevel = 60, iconfile = 0 },
  [821] = { name = "Coilfang - Underbog", cat = 2, group = 286, exp_or_honor = 70, mapid = 546, maxsize = 5,
    minlevel = 62,
    maxlevel = 0, iconfile = 136331 },
  [1083] = { name = "Coren Direbrew", cat = 2, group = 294, exp_or_honor = 80, mapid = 230, maxsize = 5, minlevel = 78,
    maxlevel = 0, iconfile = 368562 },
  [1064] = { name = "Custom", cat = 120, group = 0, exp_or_honor = 0, mapid = 0, maxsize = 0, minlevel = 0, maxlevel = 0,
    iconfile = 0 },
  [1147] = { name = "Custom World PvP", cat = 118, group = 301, exp_or_honor = 0, mapid = 0, maxsize = 0, minlevel = 0,
    maxlevel = 0, iconfile = 0 },
  [886] = { name = "Darkshore", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 8,
    maxlevel = 24, iconfile = 0 },
  [799] = { name = "Deadmines", cat = 2, group = 285, exp_or_honor = 24, mapid = 36, maxsize = 5, minlevel = 16,
    maxlevel = 0, iconfile = 136332 },
  [879] = { name = "Desolace", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 28,
    maxlevel = 44, iconfile = 0 },
  [813] = { name = "Dire Maul - East", cat = 2, group = 285, exp_or_honor = 61, mapid = 429, maxsize = 5, minlevel = 54,
    maxlevel = 0, iconfile = 136333 },
  [815] = { name = "Dire Maul - North", cat = 2, group = 285, exp_or_honor = 61, mapid = 429, maxsize = 5, minlevel = 56,
    maxlevel = 0, iconfile = 136333 },
  [814] = { name = "Dire Maul - West", cat = 2, group = 285, exp_or_honor = 61, mapid = 429, maxsize = 5, minlevel = 56,
    maxlevel = 0, iconfile = 136333 },
  [1112] = { name = "Dragonblight", cat = 116, group = 298, exp_or_honor = 80, mapid = 571, maxsize = 0, minlevel = 71,
    maxlevel = 80, iconfile = 0 },
  [1070] = { name = "Drak'Tharon Keep", cat = 2, group = 287, exp_or_honor = 78, mapid = 600, maxsize = 5, minlevel = 72,
    maxlevel = 0, iconfile = 237595 },
  [1129] = { name = "Drak'Tharon Keep", cat = 2, group = 289, exp_or_honor = 80, mapid = 600, maxsize = 5, minlevel = 80,
    maxlevel = 0, iconfile = 237595 },
  [856] = { name = "Dun Morogh", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 1,
    maxlevel = 14, iconfile = 0 },
  [874] = { name = "Durotar", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 1,
    maxlevel = 14, iconfile = 0 },
  [855] = { name = "Duskwood", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 18,
    maxlevel = 34, iconfile = 0 },
  [881] = { name = "Dustwallow Marsh", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 33,
    maxlevel = 50, iconfile = 0 },
  [870] = { name = "Eastern Plaguelands", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0,
    minlevel = 53,
    maxlevel = 63, iconfile = 0 },
  [853] = { name = "Elwynn Forest", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 1,
    maxlevel = 14, iconfile = 0 },
  [898] = { name = "Eversong Woods", cat = 116, group = 295, exp_or_honor = 70, mapid = 530, maxsize = 0, minlevel = 1,
    maxlevel = 14, iconfile = 0 },
  [934] = { name = "Eye of the Storm", cat = 118, group = 300, exp_or_honor = 69, mapid = 566, maxsize = 15,
    minlevel = 61,
    maxlevel = 69, iconfile = 136362 },
  [935] = { name = "Eye of the Storm", cat = 118, group = 300, exp_or_honor = 79, mapid = 566, maxsize = 15,
    minlevel = 70,
    maxlevel = 79, iconfile = 136362 },
  [1139] = { name = "Eye of the Storm", cat = 118, group = 300, exp_or_honor = 80, mapid = 566, maxsize = 15,
    minlevel = 80,
    maxlevel = 80, iconfile = 136362 },
  [888] = { name = "Felwood", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 46,
    maxlevel = 60, iconfile = 0 },
  [880] = { name = "Feralas", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 38,
    maxlevel = 54, iconfile = 0 },
  [900] = { name = "Ghostlands", cat = 116, group = 295, exp_or_honor = 70, mapid = 530, maxsize = 0, minlevel = 8,
    maxlevel = 24, iconfile = 0 },
  [803] = { name = "Gnomeregan", cat = 2, group = 285, exp_or_honor = 32, mapid = 90, maxsize = 5, minlevel = 24,
    maxlevel = 0, iconfile = 136336 },
  [1118] = { name = "Grizzly Hills", cat = 116, group = 298, exp_or_honor = 80, mapid = 571, maxsize = 0, minlevel = 70,
    maxlevel = 80, iconfile = 0 },
  [846] = { name = "Gruul's Lair", cat = 114, group = 291, exp_or_honor = 79, mapid = 565, maxsize = 25, minlevel = 68,
    maxlevel = 0, iconfile = 136337 },
  [1071] = { name = "Gundrak", cat = 2, group = 287, exp_or_honor = 80, mapid = 604, maxsize = 5, minlevel = 76,
    maxlevel = 0, iconfile = 237596 },
  [1130] = { name = "Gundrak", cat = 2, group = 289, exp_or_honor = 80, mapid = 604, maxsize = 5, minlevel = 80,
    maxlevel = 0, iconfile = 237596 },
  [1153] = { name = "Halaa", cat = 118, group = 301, exp_or_honor = 70, mapid = 0, maxsize = 0, minlevel = 64,
    maxlevel = 0,
    iconfile = 0 },
  [1068] = { name = "Halls of Lightning", cat = 2, group = 287, exp_or_honor = 80, mapid = 602, maxsize = 5,
    minlevel = 78,
    maxlevel = 0, iconfile = 237598 },
  [1127] = { name = "Halls of Lightning", cat = 2, group = 289, exp_or_honor = 80, mapid = 602, maxsize = 5,
    minlevel = 80,
    maxlevel = 0, iconfile = 237598 },
  [1080] = { name = "Halls of Reflection", cat = 2, group = 287, exp_or_honor = 80, mapid = 668, maxsize = 5,
    minlevel = 80,
    maxlevel = 0, iconfile = 336389 },
  [1136] = { name = "Halls of Reflection", cat = 2, group = 289, exp_or_honor = 80, mapid = 668, maxsize = 5,
    minlevel = 80,
    maxlevel = 0, iconfile = 336389 },
  [1069] = { name = "Halls of Stone", cat = 2, group = 287, exp_or_honor = 80, mapid = 599, maxsize = 5, minlevel = 75,
    maxlevel = 0, iconfile = 237599 },
  [1128] = { name = "Halls of Stone", cat = 2, group = 289, exp_or_honor = 80, mapid = 599, maxsize = 5, minlevel = 80,
    maxlevel = 0, iconfile = 237599 },
  [1150] = { name = "Hellfire Fortifications", cat = 118, group = 301, exp_or_honor = 70, mapid = 0, maxsize = 0,
    minlevel = 58, maxlevel = 0, iconfile = 0 },
  [891] = { name = "Hellfire Peninsula", cat = 116, group = 297, exp_or_honor = 70, mapid = 530, maxsize = 0,
    minlevel = 57,
    maxlevel = 70, iconfile = 136348 },
  [817] = { name = "Hellfire Ramparts", cat = 2, group = 286, exp_or_honor = 67, mapid = 543, maxsize = 5, minlevel = 58,
    maxlevel = 0, iconfile = 136338 },
  [913] = { name = "Hellfire Ramparts", cat = 2, group = 288, exp_or_honor = 72, mapid = 543, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 136338 },
  [867] = { name = "Hillsbrad Foothills", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0,
    minlevel = 18,
    maxlevel = 34, iconfile = 0 },
  [868] = { name = "Hinterlands", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 38,
    maxlevel = 54, iconfile = 0 },
  [1120] = { name = "Howling Fjord", cat = 116, group = 298, exp_or_honor = 80, mapid = 571, maxsize = 0, minlevel = 68,
    maxlevel = 80, iconfile = 0 },
  [849] = { name = "Hyjal Past", cat = 114, group = 291, exp_or_honor = 79, mapid = 534, maxsize = 25, minlevel = 70,
    maxlevel = 0, iconfile = 136341 },
  [1119] = { name = "Icecrown", cat = 116, group = 298, exp_or_honor = 80, mapid = 571, maxsize = 0, minlevel = 77,
    maxlevel = 80, iconfile = 0 },
  [1110] = { name = "Icecrown Citadel", cat = 114, group = 292, exp_or_honor = 80, mapid = 631, maxsize = 10,
    minlevel = 80,
    maxlevel = 0, iconfile = 336390 },
  [1111] = { name = "Icecrown Citadel", cat = 114, group = 293, exp_or_honor = 80, mapid = 631, maxsize = 25,
    minlevel = 80,
    maxlevel = 0, iconfile = 336390 },
  [1144] = { name = "Isle of Conquest", cat = 118, group = 300, exp_or_honor = 79, mapid = 628, maxsize = 5,
    minlevel = 71,
    maxlevel = 79, iconfile = 136324 },
  [1145] = { name = "Isle of Conquest", cat = 118, group = 300, exp_or_honor = 80, mapid = 628, maxsize = 5,
    minlevel = 80,
    maxlevel = 80, iconfile = 136324 },
  [902] = { name = "Isle of Quel'Danas", cat = 116, group = 297, exp_or_honor = 70, mapid = 530, maxsize = 0,
    minlevel = 69,
    maxlevel = 73, iconfile = 0 },
  [844] = { name = "Karazhan", cat = 114, group = 291, exp_or_honor = 79, mapid = 532, maxsize = 10, minlevel = 68,
    maxlevel = 0, iconfile = 136343 },
  [857] = { name = "Loch Modan", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 8,
    maxlevel = 24, iconfile = 0 },
  [812] = { name = "Lower Blackrock Spire", cat = 2, group = 285, exp_or_honor = 61, mapid = 229, maxsize = 5,
    minlevel = 53, maxlevel = 0, iconfile = 136327 },
  [835] = { name = "Magisters' Terrace", cat = 2, group = 286, exp_or_honor = 72, mapid = 585, maxsize = 5, minlevel = 69,
    maxlevel = 0, iconfile = 136344 },
  [917] = { name = "Magisters' Terrace", cat = 2, group = 288, exp_or_honor = 72, mapid = 585, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 136344 },
  [845] = { name = "Magtheridon's Lair", cat = 114, group = 291, exp_or_honor = 79, mapid = 544, maxsize = 25,
    minlevel = 68, maxlevel = 0, iconfile = 136340 },
  [823] = { name = "Mana-Tombs", cat = 2, group = 286, exp_or_honor = 71, mapid = 557, maxsize = 5, minlevel = 63,
    maxlevel = 0, iconfile = 136323 },
  [904] = { name = "Mana-Tombs", cat = 2, group = 288, exp_or_honor = 72, mapid = 557, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 136323 },
  [809] = { name = "Maraudon", cat = 2, group = 285, exp_or_honor = 52, mapid = 349, maxsize = 5, minlevel = 40,
    maxlevel = 0, iconfile = 136345 },
  [839] = { name = "Molten Core", cat = 114, group = 290, exp_or_honor = 69, mapid = 409, maxsize = 40, minlevel = 56,
    maxlevel = 0, iconfile = 136346 },
  [875] = { name = "Mulgore", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 1,
    maxlevel = 14, iconfile = 0 },
  [894] = { name = "Nagrand", cat = 116, group = 297, exp_or_honor = 70, mapid = 530, maxsize = 0, minlevel = 62,
    maxlevel = 70, iconfile = 136348 },
  [841] = { name = "Naxxramas", cat = 114, group = 292, exp_or_honor = 80, mapid = 533, maxsize = 10, minlevel = 80,
    maxlevel = 0, iconfile = 136347 },
  [1098] = { name = "Naxxramas", cat = 114, group = 293, exp_or_honor = 80, mapid = 533, maxsize = 25, minlevel = 80,
    maxlevel = 0, iconfile = 136347 },
  [897] = { name = "Netherstorm", cat = 116, group = 297, exp_or_honor = 70, mapid = 530, maxsize = 0, minlevel = 65,
    maxlevel = 73, iconfile = 136348 },
  [838] = { name = "Onyxia's Lair", cat = 114, group = 290, exp_or_honor = 69, mapid = 249, maxsize = 40, minlevel = 56,
    maxlevel = 0, iconfile = 0 },
  [1099] = { name = "Onyxia's Lair", cat = 114, group = 293, exp_or_honor = 80, mapid = 249, maxsize = 25, minlevel = 80,
    maxlevel = 0, iconfile = 0 },
  [1156] = { name = "Onyxia's Lair", cat = 114, group = 292, exp_or_honor = 80, mapid = 249, maxsize = 10, minlevel = 80,
    maxlevel = 0, iconfile = 0 },
  [1079] = { name = "Pit of Saron", cat = 2, group = 287, exp_or_honor = 80, mapid = 658, maxsize = 5, minlevel = 80,
    maxlevel = 0, iconfile = 336391 },
  [1135] = { name = "Pit of Saron", cat = 2, group = 289, exp_or_honor = 80, mapid = 658, maxsize = 5, minlevel = 80,
    maxlevel = 0, iconfile = 336391 },
  [798] = { name = "Ragefire Chasm", cat = 2, group = 285, exp_or_honor = 20, mapid = 389, maxsize = 5, minlevel = 13,
    maxlevel = 0, iconfile = 136350 },
  [806] = { name = "Razorfen Downs", cat = 2, group = 285, exp_or_honor = 41, mapid = 129, maxsize = 5, minlevel = 33,
    maxlevel = 0, iconfile = 136352 },
  [804] = { name = "Razorfen Kraul", cat = 2, group = 285, exp_or_honor = 31, mapid = 47, maxsize = 5, minlevel = 23,
    maxlevel = 0, iconfile = 136353 },
  [862] = { name = "Redridge Mountains", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 13,
    maxlevel = 30, iconfile = 0 },
  [1108] = { name = "Ruby Sanctum", cat = 114, group = 292, exp_or_honor = 80, mapid = 724, maxsize = 10, minlevel = 80,
    maxlevel = 0, iconfile = 366689 },
  [1109] = { name = "Ruby Sanctum", cat = 114, group = 293, exp_or_honor = 80, mapid = 724, maxsize = 25, minlevel = 80,
    maxlevel = 0, iconfile = 366689 },
  [827] = { name = "Scarlet Monastery - Armory", cat = 2, group = 285, exp_or_honor = 41, mapid = 189, maxsize = 5,
    minlevel = 33, maxlevel = 0, iconfile = 136354 },
  [828] = { name = "Scarlet Monastery - Cathedral", cat = 2, group = 285, exp_or_honor = 44, mapid = 189, maxsize = 5,
    minlevel = 36, maxlevel = 0, iconfile = 136354 },
  [805] = { name = "Scarlet Monastery - Graveyard", cat = 2, group = 285, exp_or_honor = 36, mapid = 189, maxsize = 5,
    minlevel = 28, maxlevel = 0, iconfile = 136354 },
  [829] = { name = "Scarlet Monastery - Library", cat = 2, group = 285, exp_or_honor = 39, mapid = 189, maxsize = 5,
    minlevel = 31, maxlevel = 0, iconfile = 136354 },
  [797] = { name = "Scholomance", cat = 2, group = 285, exp_or_honor = 61, mapid = 289, maxsize = 5, minlevel = 56,
    maxlevel = 0, iconfile = 136355 },
  [864] = { name = "Searing Gorge", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 43,
    maxlevel = 60, iconfile = 0 },
  [848] = { name = "Serpentshrine Cavern", cat = 114, group = 291, exp_or_honor = 79, mapid = 548, maxsize = 25,
    minlevel = 70, maxlevel = 0, iconfile = 136356 },
  [825] = { name = "Sethekk Halls", cat = 2, group = 286, exp_or_honor = 72, mapid = 556, maxsize = 5, minlevel = 66,
    maxlevel = 0, iconfile = 136323 },
  [905] = { name = "Sethekk Halls", cat = 2, group = 288, exp_or_honor = 72, mapid = 556, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 136323 },
  [826] = { name = "Shadow Labyrinth", cat = 2, group = 286, exp_or_honor = 72, mapid = 555, maxsize = 5, minlevel = 69,
    maxlevel = 0, iconfile = 136323 },
  [906] = { name = "Shadow Labyrinth", cat = 2, group = 288, exp_or_honor = 72, mapid = 555, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 136323 },
  [800] = { name = "Shadowfang Keep", cat = 2, group = 285, exp_or_honor = 25, mapid = 33, maxsize = 5, minlevel = 17,
    maxlevel = 0, iconfile = 136357 },
  [895] = { name = "Shadowmoon Valley", cat = 116, group = 297, exp_or_honor = 70, mapid = 530, maxsize = 0,
    minlevel = 65,
    maxlevel = 73, iconfile = 136348 },
  [819] = { name = "Shattered Halls", cat = 2, group = 286, exp_or_honor = 72, mapid = 540, maxsize = 5, minlevel = 69,
    maxlevel = 0, iconfile = 136338 },
  [914] = { name = "Shattered Halls", cat = 2, group = 288, exp_or_honor = 72, mapid = 540, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 136338 },
  [1114] = { name = "Sholazar Basin", cat = 116, group = 298, exp_or_honor = 80, mapid = 571, maxsize = 0, minlevel = 75,
    maxlevel = 80, iconfile = 0 },
  [884] = { name = "Silithus", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 53,
    maxlevel = 60, iconfile = 0 },
  [872] = { name = "Silverpine Forest", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 8,
    maxlevel = 24, iconfile = 0 },
  [820] = { name = "Slave Pens", cat = 2, group = 286, exp_or_honor = 69, mapid = 547, maxsize = 5, minlevel = 61,
    maxlevel = 0, iconfile = 136331 },
  [909] = { name = "Slave Pens", cat = 2, group = 288, exp_or_honor = 72, mapid = 547, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 136331 },
  [1152] = { name = "Spirits of Auchindoun", cat = 118, group = 301, exp_or_honor = 70, mapid = 0, maxsize = 0,
    minlevel = 62, maxlevel = 0, iconfile = 0 },
  [877] = { name = "Stonetalon Mountains", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0,
    minlevel = 13,
    maxlevel = 32, iconfile = 0 },
  [802] = { name = "Stormwind Stockades", cat = 2, group = 285, exp_or_honor = 29, mapid = 34, maxsize = 5, minlevel = 21,
    maxlevel = 0, iconfile = 136358 },
  [1142] = { name = "Strand of the Ancients", cat = 118, group = 300, exp_or_honor = 79, mapid = 607, maxsize = 15,
    minlevel = 71, maxlevel = 79, iconfile = 136324 },
  [1143] = { name = "Strand of the Ancients", cat = 118, group = 300, exp_or_honor = 80, mapid = 607, maxsize = 15,
    minlevel = 80, maxlevel = 80, iconfile = 136324 },
  [859] = { name = "Stranglethorn Vale", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 28,
    maxlevel = 50, iconfile = 0 },
  [816] = { name = "Stratholme", cat = 2, group = 285, exp_or_honor = 61, mapid = 329, maxsize = 5, minlevel = 56,
    maxlevel = 0, iconfile = 136359 },
  [810] = { name = "Sunken Temple", cat = 2, group = 285, exp_or_honor = 54, mapid = 109, maxsize = 5, minlevel = 45,
    maxlevel = 0, iconfile = 136360 },
  [861] = { name = "Swamp of Sorrows", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 33,
    maxlevel = 50, iconfile = 0 },
  [882] = { name = "Tanaris", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 38,
    maxlevel = 54, iconfile = 0 },
  [885] = { name = "Teldrassil", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 1,
    maxlevel = 14, iconfile = 0 },
  [847] = { name = "Tempest Keep", cat = 114, group = 291, exp_or_honor = 79, mapid = 550, maxsize = 25, minlevel = 70,
    maxlevel = 0, iconfile = 136362 },
  [893] = { name = "Terokkar Forest", cat = 116, group = 297, exp_or_honor = 70, mapid = 530, maxsize = 0, minlevel = 60,
    maxlevel = 70, iconfile = 136348 },
  [834] = { name = "The Arcatraz", cat = 2, group = 286, exp_or_honor = 72, mapid = 552, maxsize = 5, minlevel = 69,
    maxlevel = 0, iconfile = 136362 },
  [915] = { name = "The Arcatraz", cat = 2, group = 288, exp_or_honor = 72, mapid = 552, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 136362 },
  [876] = { name = "The Barrens", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 8,
    maxlevel = 30, iconfile = 0 },
  [831] = { name = "The Black Morass", cat = 2, group = 286, exp_or_honor = 72, mapid = 269, maxsize = 5, minlevel = 68,
    maxlevel = 0, iconfile = 136330 },
  [907] = { name = "The Black Morass", cat = 2, group = 288, exp_or_honor = 72, mapid = 269, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 136330 },
  [833] = { name = "The Botanica", cat = 2, group = 286, exp_or_honor = 72, mapid = 553, maxsize = 5, minlevel = 69,
    maxlevel = 0, iconfile = 136362 },
  [918] = { name = "The Botanica", cat = 2, group = 288, exp_or_honor = 72, mapid = 553, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 136362 },
  [1084] = { name = "The Crown Chemical Co.", cat = 2, group = 294, exp_or_honor = 80, mapid = 33, maxsize = 5,
    minlevel = 78, maxlevel = 0, iconfile = 368564 },
  [1065] = { name = "The Culling of Stratholme", cat = 2, group = 287, exp_or_honor = 80, mapid = 595, maxsize = 5,
    minlevel = 78, maxlevel = 0, iconfile = 136330 },
  [1126] = { name = "The Culling of Stratholme", cat = 2, group = 289, exp_or_honor = 80, mapid = 595, maxsize = 5,
    minlevel = 80, maxlevel = 0, iconfile = 136330 },
  [830] = { name = "The Escape From Durnholde", cat = 2, group = 286, exp_or_honor = 72, mapid = 560, maxsize = 5,
    minlevel = 66, maxlevel = 0, iconfile = 136330 },
  [908] = { name = "The Escape From Durnholde", cat = 2, group = 288, exp_or_honor = 72, mapid = 560, maxsize = 5,
    minlevel = 70, maxlevel = 0, iconfile = 136330 },
  [1094] = { name = "The Eye of Eternity", cat = 114, group = 293, exp_or_honor = 80, mapid = 616, maxsize = 25,
    minlevel = 80, maxlevel = 0, iconfile = 237600 },
  [1102] = { name = "The Eye of Eternity", cat = 114, group = 292, exp_or_honor = 80, mapid = 616, maxsize = 10,
    minlevel = 80, maxlevel = 0, iconfile = 237600 },
  [1078] = { name = "The Forge of Souls", cat = 2, group = 287, exp_or_honor = 80, mapid = 632, maxsize = 5,
    minlevel = 80,
    maxlevel = 0, iconfile = 336392 },
  [1134] = { name = "The Forge of Souls", cat = 2, group = 289, exp_or_honor = 80, mapid = 632, maxsize = 5,
    minlevel = 80,
    maxlevel = 0, iconfile = 336392 },
  [1082] = { name = "The Frost Lord Ahune", cat = 2, group = 294, exp_or_honor = 80, mapid = 547, maxsize = 5,
    minlevel = 78, maxlevel = 0, iconfile = 368565 },
  [1081] = { name = "The Headless Horseman", cat = 2, group = 294, exp_or_honor = 80, mapid = 189, maxsize = 5,
    minlevel = 78, maxlevel = 0, iconfile = 368563 },
  [832] = { name = "The Mechanar", cat = 2, group = 286, exp_or_honor = 72, mapid = 554, maxsize = 5, minlevel = 68,
    maxlevel = 0, iconfile = 136362 },
  [916] = { name = "The Mechanar", cat = 2, group = 288, exp_or_honor = 72, mapid = 554, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 136362 },
  [1077] = { name = "The Nexus", cat = 2, group = 287, exp_or_honor = 75, mapid = 576, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 237602 },
  [1132] = { name = "The Nexus", cat = 2, group = 289, exp_or_honor = 80, mapid = 576, maxsize = 5, minlevel = 80,
    maxlevel = 0, iconfile = 237602 },
  [1097] = { name = "The Obsidian Sanctum", cat = 114, group = 293, exp_or_honor = 80, mapid = 615, maxsize = 25,
    minlevel = 80, maxlevel = 0, iconfile = 237594 },
  [1101] = { name = "The Obsidian Sanctum", cat = 114, group = 292, exp_or_honor = 80, mapid = 615, maxsize = 10,
    minlevel = 80, maxlevel = 0, iconfile = 237594 },
  [1067] = { name = "The Oculus", cat = 2, group = 287, exp_or_honor = 80, mapid = 578, maxsize = 5, minlevel = 78,
    maxlevel = 0, iconfile = 237603 },
  [1124] = { name = "The Oculus", cat = 2, group = 289, exp_or_honor = 80, mapid = 578, maxsize = 5, minlevel = 80,
    maxlevel = 0, iconfile = 237603 },
  [1148] = { name = "The Silithyst Must Flow (Silithus)", cat = 118, group = 301, exp_or_honor = 60, mapid = 0,
    maxsize = 0,
    minlevel = 55, maxlevel = 0, iconfile = 0 },
  [822] = { name = "The Steamvault", cat = 2, group = 286, exp_or_honor = 72, mapid = 545, maxsize = 5, minlevel = 69,
    maxlevel = 0, iconfile = 136331 },
  [910] = { name = "The Steamvault", cat = 2, group = 288, exp_or_honor = 72, mapid = 545, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 136331 },
  [1115] = { name = "The Storm Peaks", cat = 116, group = 298, exp_or_honor = 80, mapid = 571, maxsize = 0, minlevel = 77,
    maxlevel = 80, iconfile = 0 },
  [852] = { name = "The Sunwell", cat = 114, group = 291, exp_or_honor = 79, mapid = 580, maxsize = 25, minlevel = 70,
    maxlevel = 0, iconfile = 136361 },
  [878] = { name = "Thousand Needles", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 23,
    maxlevel = 40, iconfile = 0 },
  [871] = { name = "Tirisfal Glades", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 1,
    maxlevel = 14, iconfile = 0 },
  [1076] = { name = "Trial of the Champion", cat = 2, group = 287, exp_or_honor = 80, mapid = 650, maxsize = 5,
    minlevel = 80, maxlevel = 0, iconfile = 311220 },
  [1133] = { name = "Trial of the Champion", cat = 2, group = 289, exp_or_honor = 80, mapid = 650, maxsize = 5,
    minlevel = 80, maxlevel = 0, iconfile = 311220 },
  [1100] = { name = "Trial of the Crusader", cat = 114, group = 292, exp_or_honor = 80, mapid = 649, maxsize = 10,
    minlevel = 80, maxlevel = 0, iconfile = 311221 },
  [1104] = { name = "Trial of the Crusader", cat = 114, group = 293, exp_or_honor = 80, mapid = 649, maxsize = 25,
    minlevel = 80, maxlevel = 0, iconfile = 311221 },
  [1103] = { name = "Trial of the Grand Crusader", cat = 114, group = 292, exp_or_honor = 80, mapid = 649, maxsize = 10,
    minlevel = 80, maxlevel = 0, iconfile = 311221 },
  [1105] = { name = "Trial of the Grand Crusader", cat = 114, group = 293, exp_or_honor = 80, mapid = 649, maxsize = 25,
    minlevel = 80, maxlevel = 0, iconfile = 311221 },
  [1151] = { name = "Twin Spire Ruins", cat = 118, group = 301, exp_or_honor = 70, mapid = 0, maxsize = 0, minlevel = 58,
    maxlevel = 0, iconfile = 0 },
  [807] = { name = "Uldaman", cat = 2, group = 285, exp_or_honor = 44, mapid = 70, maxsize = 5, minlevel = 36,
    maxlevel = 0,
    iconfile = 136363 },
  [1106] = { name = "Ulduar", cat = 114, group = 292, exp_or_honor = 80, mapid = 603, maxsize = 10, minlevel = 80,
    maxlevel = 0, iconfile = 304468 },
  [1107] = { name = "Ulduar", cat = 114, group = 293, exp_or_honor = 80, mapid = 603, maxsize = 25, minlevel = 80,
    maxlevel = 0, iconfile = 304468 },
  [911] = { name = "Underbog", cat = 2, group = 288, exp_or_honor = 72, mapid = 546, maxsize = 5, minlevel = 70,
    maxlevel = 0, iconfile = 136331 },
  [883] = { name = "Un'Goro Crater", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 45,
    maxlevel = 60, iconfile = 0 },
  [837] = { name = "Upper Blackrock Spire", cat = 114, group = 290, exp_or_honor = 69, mapid = 229, maxsize = 10,
    minlevel = 56, maxlevel = 0, iconfile = 136327 },
  [1074] = { name = "Utgarde Keep", cat = 2, group = 287, exp_or_honor = 75, mapid = 574, maxsize = 5, minlevel = 68,
    maxlevel = 0, iconfile = 237605 },
  [1122] = { name = "Utgarde Keep", cat = 2, group = 289, exp_or_honor = 80, mapid = 574, maxsize = 5, minlevel = 80,
    maxlevel = 0, iconfile = 237605 },
  [1075] = { name = "Utgarde Pinnacle", cat = 2, group = 287, exp_or_honor = 80, mapid = 575, maxsize = 5, minlevel = 78,
    maxlevel = 0, iconfile = 237606 },
  [1125] = { name = "Utgarde Pinnacle", cat = 2, group = 289, exp_or_honor = 80, mapid = 575, maxsize = 5, minlevel = 80,
    maxlevel = 0, iconfile = 237606 },
  [1095] = { name = "Vault of Archavon", cat = 114, group = 292, exp_or_honor = 80, mapid = 624, maxsize = 10,
    minlevel = 80, maxlevel = 0, iconfile = 303841 },
  [1096] = { name = "Vault of Archavon", cat = 114, group = 293, exp_or_honor = 80, mapid = 624, maxsize = 25,
    minlevel = 80, maxlevel = 0, iconfile = 303841 },
  [1154] = { name = "Venture Bay", cat = 118, group = 301, exp_or_honor = 80, mapid = 0, maxsize = 0, minlevel = 73,
    maxlevel = 0, iconfile = 0 },
  [1073] = { name = "Violet Hold", cat = 2, group = 287, exp_or_honor = 79, mapid = 608, maxsize = 5, minlevel = 73,
    maxlevel = 0, iconfile = 237604 },
  [1123] = { name = "Violet Hold", cat = 2, group = 289, exp_or_honor = 80, mapid = 608, maxsize = 5, minlevel = 80,
    maxlevel = 0, iconfile = 237604 },
  [796] = { name = "Wailing Caverns", cat = 2, group = 285, exp_or_honor = 24, mapid = 43, maxsize = 5, minlevel = 16,
    maxlevel = 0, iconfile = 136364 },
  [919] = { name = "Warsong Gulch", cat = 118, group = 300, exp_or_honor = 19, mapid = 489, maxsize = 10, minlevel = 10,
    maxlevel = 19, iconfile = 136365 },
  [920] = { name = "Warsong Gulch", cat = 118, group = 300, exp_or_honor = 29, mapid = 489, maxsize = 10, minlevel = 20,
    maxlevel = 29, iconfile = 136365 },
  [921] = { name = "Warsong Gulch", cat = 118, group = 300, exp_or_honor = 39, mapid = 489, maxsize = 10, minlevel = 30,
    maxlevel = 39, iconfile = 136365 },
  [922] = { name = "Warsong Gulch", cat = 118, group = 300, exp_or_honor = 49, mapid = 489, maxsize = 10, minlevel = 40,
    maxlevel = 49, iconfile = 136365 },
  [923] = { name = "Warsong Gulch", cat = 118, group = 300, exp_or_honor = 59, mapid = 489, maxsize = 10, minlevel = 50,
    maxlevel = 59, iconfile = 136365 },
  [924] = { name = "Warsong Gulch", cat = 118, group = 300, exp_or_honor = 69, mapid = 489, maxsize = 10, minlevel = 60,
    maxlevel = 69, iconfile = 136365 },
  [925] = { name = "Warsong Gulch", cat = 118, group = 300, exp_or_honor = 79, mapid = 489, maxsize = 10, minlevel = 70,
    maxlevel = 79, iconfile = 136365 },
  [1137] = { name = "Warsong Gulch", cat = 118, group = 300, exp_or_honor = 80, mapid = 489, maxsize = 10, minlevel = 80,
    maxlevel = 80, iconfile = 136365 },
  [869] = { name = "Western Plaguelands", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0,
    minlevel = 48,
    maxlevel = 60, iconfile = 0 },
  [854] = { name = "Westfall", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 8,
    maxlevel = 24, iconfile = 0 },
  [858] = { name = "Wetlands", cat = 116, group = 295, exp_or_honor = 60, mapid = 0, maxsize = 0, minlevel = 18,
    maxlevel = 34, iconfile = 0 },
  [1117] = { name = "Wintergrasp", cat = 118, group = 300, exp_or_honor = 80, mapid = 571, maxsize = 40, minlevel = 77,
    maxlevel = 80, iconfile = 0 },
  [1155] = { name = "Wintergrasp", cat = 118, group = 301, exp_or_honor = 80, mapid = 0, maxsize = 0, minlevel = 77,
    maxlevel = 0, iconfile = 0 },
  [890] = { name = "Winterspring", cat = 116, group = 296, exp_or_honor = 60, mapid = 1, maxsize = 0, minlevel = 53,
    maxlevel = 63, iconfile = 0 },
  [892] = { name = "Zangarmarsh", cat = 116, group = 297, exp_or_honor = 70, mapid = 530, maxsize = 0, minlevel = 58,
    maxlevel = 70, iconfile = 136348 },
  [851] = { name = "Zul'Aman", cat = 114, group = 291, exp_or_honor = 79, mapid = 568, maxsize = 10, minlevel = 70,
    maxlevel = 0, iconfile = 136367 },
  [1113] = { name = "Zul'Drak", cat = 116, group = 298, exp_or_honor = 80, mapid = 571, maxsize = 0, minlevel = 73,
    maxlevel = 80, iconfile = 0 },
  [808] = { name = "Zul'Farrak", cat = 2, group = 285, exp_or_honor = 50, mapid = 209, maxsize = 5, minlevel = 42,
    maxlevel = 0, iconfile = 136368 },
  [836] = { name = "Zul'Gurub", cat = 114, group = 290, exp_or_honor = 69, mapid = 309, maxsize = 20, minlevel = 56,
    maxlevel = 0, iconfile = 136369 },
}

-- this will hold activities accessible to the player. We might need to cross-reference with the static map above
-- to know what info we can query if we cannot query "everything"
GroupieGroupBrowser._playerMapLookup = {}

-----------------------
---Utility Functions---
-----------------------
local function wrapTuple(...)
  return { ... }
end

function GroupieGroupBrowser:dump(data, desc)
  local loaded = UIParentLoadAddOn("Blizzard_DebugTools")
  if loaded then
    local tempKey = (desc or "Groupie") .. "_587CAB235A7742ABAE076F412EA5CB12"
    _G[tempKey] = data
    DevTools_DumpCommand(tempKey)
  end
end

-- don't do potentially expensive stuff in-combat
-- we don't want to hit script execution limits or hit fps
function GroupieGroupBrowser:groupCombat(method)
  GroupieGroupBrowser._combatqueue = GroupieGroupBrowser._combatqueue or {}
  if UnitAffectingCombat("player") and IsInGroup() then
    GroupieGroupBrowser._combatqueue[method] = true
    GroupieGroupBrowser:RegisterEvent("PLAYER_REGEN_ENABLED", "clearCombatQueue")
    return true
  end
  return false
end

function GroupieGroupBrowser:clearCombatQueue()
  for method in self._combatqueue do
    print(method)
    GroupieGroupBrowser[method](GroupieGroupBrowser)
    GroupieGroupBrowser._combatqueue[method] = nil
  end
  self:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

-- this would be used like this in other parts of the addon
--[[ Example: attaching specific queries to Groupie Tabs
local GroupieGroupBrowser = Groupie:GetModule("GroupieGroupBrowser")
if GroupieGroupBrowser then
    GroupieGroupBrowser:AttachLFGToolPreset(GroupieTab1, "Dungeons") -- all dungeons (category level)
    GroupieGroupBrowser:AttachLFGToolPreset(GroupieTab2, nil, "Lich King Heroic Dungeons") -- (LK H only, groupactivity level)
    GroupieGroupBrowser:AttachLFGToolPreset(GroupieTab3, nil, "Lich King Raids (10)")
    GroupieGroupBrowser:AttachLFGToolPreset(GroupieTab5, nil, "Lich King Raids (10)")
    GroupieGroupBrowser:AttachLFGToolPreset(GroupieTab4, nil, "Lich King Raids (25)")
    GroupieGroupBrowser:AttachLFGToolPreset(GroupieTab6, nil, "Lich King Raids (25)")
    GroupieGroupBrowser:AttachLFGToolPreset(GroupieTab7, "PvP") -- all pvp (category level again)
end
]]
-- widget = frame reference or frame name (if globally accessible)
-- category = categoryid or name (pass nil if using group)
-- group = groupid or name (optional if using category)
function GroupieGroupBrowser:AttachLFGToolPreset(widget, category, group)
  local frameRef
  if type(widget) == "string" then
    frameRef = _G[widget].GetName and _G[widget] or nil
  end
  if type(widget) == "table" then
    frameRef = widget:HasScript("OnMouseDown") and widget or nil
  end
  if not frameRef then return end
  local categoryid, activities = GroupieGroupBrowser:GetActivitiesFor(category, group)
  if categoryid > 0 then
    frameRef._preset = { categoryid, activities }
  end
  if not GroupieGroupBrowser:IsHooked(frameRef, "OnMouseDown") then
    GroupieGroupBrowser:SecureHookScript(frameRef, "OnMouseDown", function(self, ...)
      GroupieGroupBrowser:RunQueue(self, ...)
    end)
  end
end

function GroupieGroupBrowser:enableHardwareEvents(enable)
  if enable then
    GroupieGroupBrowser._hwKB:EnableKeyboard(true)
    if not GroupieGroupBrowser:IsHooked(GroupieGroupBrowserKBJobber, "OnKeyDown") then
      GroupieGroupBrowser:SecureHookScript(GroupieGroupBrowserKBJobber, "OnKeyDown", function(self, ...)
        GroupieGroupBrowser:RunQueue(self, ...)
      end)
    end
    if not GroupieGroupBrowser:IsHooked(WorldFrame, "OnMouseUp") then
      GroupieGroupBrowser:SecureHookScript(WorldFrame, "OnMouseUp", function(self, ...)
        GroupieGroupBrowser:RunQueue(self, ...)
      end)
    end
  else
    GroupieGroupBrowser._hwKB:EnableKeyboard(false)
    if GroupieGroupBrowser:IsHooked(GroupieGroupBrowserKBJobber, "OnKeyDown") then
      GroupieGroupBrowser:Unhook(GroupieGroupBrowserKBJobber, "OnKeyDown")
    end
    if GroupieGroupBrowser:IsHooked(WorldFrame, "OnMouseUp") then
      GroupieGroupBrowser:Unhook(WorldFrame, "OnMouseUp")
    end
  end
end

function GroupieGroupBrowser:PlayerActivitiesMap(event)
  if not GroupieGroupBrowser:groupCombat("PlayerActivitiesMap") then
    -- do stuff
    local all_categories = C_LFGList.GetAvailableCategories() -- {catid1,catid2,catid3,...}
    for _, cat in pairs(all_categories) do
      local name = C_LFGList.GetCategoryInfo(cat)
      local cat_groups = C_LFGList.GetAvailableActivityGroups(cat)
      for _, group in pairs(cat_groups) do
        local name, groupOrder = C_LFGList.GetActivityGroupInfo(group)
        local activities = C_LFGList.GetAvailableActivities(cat, group)
        for _, activity in pairs(activities) do
          local info = C_LFGList.GetActivityInfoTable(activity)
          self._playerMapLookup[activity] = { group = group, cat = cat, info = info }
        end
      end
    end
  end
end

--------------------
--- Data Helpers ---
--------------------
function GroupieGroupBrowser:populatePresets()
  GroupieGroupBrowser._categoryActivities = GroupieGroupBrowser._categoryActivities or {}
  GroupieGroupBrowser._groupActivities = GroupieGroupBrowser._groupActivities or {}
  GroupieGroupBrowser._categoryGroups = GroupieGroupBrowser._categoryGroups or {}
  GroupieGroupBrowser._groupCategory = GroupieGroupBrowser._groupCategory or {}
  for activity, data in pairs(GroupieGroupBrowser._activityMap) do
    local cat, group = data.cat, data.group
    GroupieGroupBrowser._categoryActivities[cat] = GroupieGroupBrowser._categoryActivities[cat] or {}
    GroupieGroupBrowser._groupActivities[group] = GroupieGroupBrowser._groupActivities[group] or {}
    GroupieGroupBrowser._categoryGroups[cat] = GroupieGroupBrowser._categoryGroups[cat] or {}
    tinsert(GroupieGroupBrowser._categoryActivities[cat], activity)
    tinsert(GroupieGroupBrowser._groupActivities[group], activity)
    tinsert(GroupieGroupBrowser._categoryGroups[cat], group)
    GroupieGroupBrowser._groupCategory[group] = cat
  end
  for category, description in pairs(GroupieGroupBrowser._categoryMap) do
    GroupieGroupBrowser._reverse_categoryMap = GroupieGroupBrowser._reverse_categoryMap or {}
    GroupieGroupBrowser._reverse_categoryMap[description] = category
  end
  for group, description in pairs(GroupieGroupBrowser._activityGroupMap) do
    GroupieGroupBrowser._reverse_activityGroupMap = GroupieGroupBrowser._reverse_activityGroupMap or {}
    GroupieGroupBrowser._reverse_activityGroupMap[description] = group
  end
  for fullName, data in pairs(groupieInstanceData) do
    -- unique keys in groupieInstanceData the key (fullName) and Order
    local instance = fullName:gsub("Heroic ", ""):gsub("( %- %d+)", "") -- these will need to match the constructor at Listener to reverse it
    GroupieGroupBrowser._lfgname_to_instance = GroupieGroupBrowser._lfgname_to_instance or {}
    if data.ActivityID > 0 then -- we have a matching entry
      local entry = GroupieGroupBrowser._activityMap[data.ActivityID]
      GroupieGroupBrowser._lfgname_to_instance[entry.name] = instance
    end
  end
end

-- attempt to find an entry in groupieInstanceData that matches the Group Browser entry
function GroupieGroupBrowser:FindInstanceData(activityid, instancename, instanceid, groupsize, isheroic)
  local groupieInstanceName = GroupieGroupBrowser._lfgname_to_instance[instancename]
  if not groupieInstanceName then
    return instancename, instancename, false
  end
  local fullName = groupieInstanceName

  local possibleVersions = instanceVersions[groupieInstanceName]
  local validVersionFlag = false
  --Check that the found instance version is a valid version
  for version = 1, #possibleVersions do
    if isheroic == possibleVersions[version][2] then
      if groupsize == possibleVersions[version][1] then
        validVersionFlag = true
      elseif groupsize == nil then
        groupsize = possibleVersions[version][1]
        validVersionFlag = true
      end
    end
  end

  --If the instance version is invalid, default to lowest size and normal mode
  if not validVersionFlag then
    groupsize = possibleVersions[1][1]
    isheroic = possibleVersions[1][2]
  end

  if #possibleVersions > 1 then
    if isheroic then
      fullName = format("Heroic %s", fullName)
    end
    if groupsize and (groupsize == 10 or groupsize == 25) then
      fullName = format("%s - %d", fullName, groupsize)
    end
  end

  local data = groupieInstanceData[fullName]
  if data then
    return fullName, groupieInstanceName, data
  else
    return instancename, groupieInstanceName, false
  end
end

-- in: category = categoryid or description, group = activitygroupid or description
-- out: category, activities for feeding to :Queue()
local emptyTbl = {}
function GroupieGroupBrowser:GetActivitiesFor(category, group)
  if group then
    local groupid = tonumber(group) or GroupieGroupBrowser._reverse_activityGroupMap[group]
    if groupid then
      return GroupieGroupBrowser._groupCategory[groupid], GroupieGroupBrowser._groupActivities[groupid]
    end
  elseif category then
    local categoryid = tonumber(category) or GroupieGroupBrowser._reverse_categoryMap[category]
    if categoryid then
      return categoryid, GroupieGroupBrowser._categoryActivities[categoryid]
    end
  end
  return 0, emptyTbl
end

---------------------------
--- Core Module Methods ---
---------------------------
function GroupieGroupBrowser:OnEnable()
  if C_LFGList.IsLookingForGroupEnabled and (UIParentLoadAddOn("Blizzard_LookingForGroupUI")) then
    self:populatePresets()
    self:RegisterEvent("LFG_LIST_AVAILABILITY_UPDATE", "PlayerActivitiesMap")
    self:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED", "GetResults")
    self:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED", "GetResult")
    self:RegisterEvent("LFG_LIST_SEARCH_FAILED")
    --C_LFGList.RequestAvailableActivities()
    self._hwKB = CreateFrame("Frame", "GroupieGroupBrowserKBJobber", UIParent)
    self._hwKB:SetPoint("TOPLEFT")
    self._hwKB:SetPoint("BOTTOMRIGHT")
    self._hwKB:EnableMouse(false)
    self._hwKB:SetPropagateKeyboardInput(true)
    self._hwKB:SetFrameStrata("TOOLTIP")
    self._hwKB:SetToplevel(true)
    self._hwKB:Show()
    self:enableHardwareEvents(true) -- make this option friendly in case we want to control it that way
    GroupieGroupBrowser._realmName = GetNormalizedRealmName()
    if not GroupieGroupBrowser._realmName or GroupieGroupBrowser._realmName:trim() == "" then
      self:RegisterEvent("LOADING_SCREEN_DISABLED")
    end
    listingTable = Groupie.db.global.listingTable
  end
end

function GroupieGroupBrowser:LOADING_SCREEN_DISABLED()
  GroupieGroupBrowser._realmName = GetNormalizedRealmName()
  self:UnregisterEvent("LOADING_SCREEN_DISABLED")
end

function GroupieGroupBrowser:LFG_LIST_SEARCH_FAILED(event, ...)
  local payload = wrapTuple(...)
  -- see if we can figure out if this returns more than reason, like which search failed
  print(table.concat(payload, ";")) -- DEBUG, comment out before packaging
end

function GroupieGroupBrowser:GetResults(event)
  local numResults, results = C_LFGList.GetSearchResults()
  if numResults > 0 then
    for _, resultID in pairs(results) do
      GroupieGroupBrowser:GetResult(nil, resultID)
    end
  end
end

function GroupieGroupBrowser:GetResult(event, resultID)
  if not resultID then return end
  local hasData = C_LFGList.HasSearchResultInfo(resultID)
  if hasData then
    local resultData = C_LFGList.GetSearchResultInfo(resultID)
    local leader = wrapTuple(C_LFGList.GetSearchResultLeaderInfo(resultID))
    --GroupieGroupBrowser:dump(leader,"leader") -- DEBUG, comment out before package
    local membercounts = C_LFGList.GetSearchResultMemberCounts(resultID)
    local numMembers = resultData.numMembers or nil
    self:MapResultToListing(resultID, resultData, leader, membercounts, numMembers)
    if numMembers and numMembers > 0 then -- not used anywhere at the moment
      for i = 1, numMembers do
        local member = wrapTuple(C_LFGList.GetSearchResultMemberInfo(resultID, i))
        --GroupieGroupBrowser:dump(member,"member") -- DEBUG, comment out before package
      end
    end
    local friends = C_LFGList.GetSearchResultFriends(resultID) -- not used anywhere at the moment
  end
end

-- PUBLIC: Always use this method to send queries to the Group Browser
-- This will queue them and use the next available hardware event
-- spec: category=number, ... = {array} or act1, act2, act3, etc
function GroupieGroupBrowser:Queue(category, ...)
  if not GroupieGroupBrowser._categoryMap[category] then
    print(tostring(category) .. " is not a valid category")
    return
  end
  local arg = ...
  local activities
  if type(arg) == "table" then
    activities = ...
  elseif type(arg) == "number" then
    activities = wrapTuple(...)
  end
  for k, v in pairs(activities) do
    if not GroupieGroupBrowser._activityMap[v] then
      activities[k] = nil
    end
  end
  GroupieGroupBrowser._searchqueue = GroupieGroupBrowser._searchqueue or {}
  -- Don't let our queue grow indefinitely. Cap it to N entries and if new one would overcap remove the oldest
  local queue_len = #GroupieGroupBrowser._searchqueue
  if queue_len > MAX_QUEUE_SIZE then
    for i = 1, (queue_len - MAX_QUEUE_SIZE) do
      table.remove(GroupieGroupBrowser._searchqueue, 1) -- trash oldest
    end
  end
  table.insert(GroupieGroupBrowser._searchqueue, { category, activities })
end

function GroupieGroupBrowser:RunQueue(fromWidget)
  if fromWidget and fromWidget._preset then
    local category, activities = fromWidget._preset[1], fromWidget._preset[2]
    GroupieGroupBrowser:Search(category, activities)
  else
    if not GroupieGroupBrowser._searchqueue or #GroupieGroupBrowser._searchqueue == 0 then
      return
    end
    if #GroupieGroupBrowser._searchqueue > 0 then
      local search = table.remove(GroupieGroupBrowser._searchqueue, 1) -- run the oldest
      local category, activities = search[1], search[2]
      GroupieGroupBrowser:Search(category, activities)
    end
  end
end

-- INTERNAL: Always use the Queue method to submit queries.
-- this needs to be called in response to a hardware event (click or keypress)
-- it also needs to have a cooldown, if we show up on Blizz network metrics they'll break it
-- ATT: You can run this directly for test with /run but otherwise use :Queue
function GroupieGroupBrowser:Search(category, ...)
  -- let's not clobber ongoing searches from the tool either
  if LFGBrowseFrame.searching then return end
  local now = GetTime()
  local onCD = true
  if not self._lastSearch then
    onCD = false
  elseif now - self._lastSearch > SEARCH_COOLDOWN then
    onCD = false
  end
  if onCD then return end
  self._lastSearch = now
  local arg = ...
  local activities
  if type(arg) == "table" then
    activities = ...
  elseif type(arg) == "number" then
    activities = wrapTuple(...)
  end
  local retOK, err = pcall(C_LFGList.Search, category, activities)
  if not retOK then
    print(tostring(err))
  end
end

------------------------------------
--- Groupie listingTable Mapping ---
------------------------------------
-- We have no access to GroupBrowser Comment fields so we have to construct a msg from available info
function GroupieGroupBrowser:CreateMsg(isLFM, isLFG, instanceName, isHeroic, groupSize, numMembers, lootType, minlevel,
                                       maxlevel, tankSpots, healerSpots, damageSpots, leaderRole)
  local action = isLFM and "LFM" or "LFG"
  local forwhat = format("%s%s", (isHeroic and "Heroic " or ""), instanceName)

  local groupStatus = groupSize > numMembers and format("%s in Group", numMembers) or ""
  if (groupSize == 10 or groupSize == 25) and addon.groupieInstanceData[instanceName] ~= nil then
    forwhat = forwhat .. " " .. tonumber(groupSize)
    groupStatus = groupSize > numMembers and format("%s/%s in Group", numMembers, groupSize) or ""
  end

  local roleStatus = ""
  if tankSpots > 0 then
    roleStatus = roleStatus .. "Tank "
  end
  if healerSpots > 0 then
    roleStatus = roleStatus .. "Heals "
  end
  if damageSpots > 0 then
    roleStatus = roleStatus .. "DPS "
  end
  roleStatus = roleStatus:trim()
  roleStatus = roleStatus:gsub(" ", ", ")
  if tankSpots > 0 or healerSpots > 0 or damageSpots > 0 then
    roleStatus = "Need " .. roleStatus
    roleStatus = roleStatus:gsub("DPS", " DPS")
  end

  local rolelfg = leaderRole == "NOROLE" and "" or (leaderRole == "DAMAGER" and "DPS" or _G[leaderRole])

  local msg
  if isLFM then
    if groupSize == 5 then
      msg = action .. " " .. forwhat .. " | " .. roleStatus
    elseif groupSize == 10 or groupSize == 25 then
      msg = action .. " " .. forwhat .. " | " .. groupStatus
    else
      msg = action .. " " .. forwhat .. " | " .. groupStatus
    end
  else
    msg = rolelfg .. " " .. action .. " " .. forwhat
  end
  msg = msg:gsub("  ", " ")
  msg = msg:trim()
  return format("%s %s", lfgMessagePrefix, msg)
end

-- At the moment of implementing this Groupie has no unique key in listingTable.
-- only the last message posted by an author is retained so we arbitrarily show
-- only the first activity they are listed for in Group Browser.
function GroupieGroupBrowser:MapResultToListing(resultID, resultData, leader, membercounts, numMembers)
  -- variables for all the listingTable members, update as necessary if the spec changes
  local isLFM, isLFG, createdat, timestamp, language, instanceName, fullName, isHeroic, groupSize, lootType, rolesNeeded, author, msg, words, minLevel, maxLevel, order, instanceID, icon, classColor
  if resultData.isDelisted then -- if in listingTable previously find it and expire it
    GroupieGroupBrowser:SendMessage("GROUPIE_GROUPBROWSER_REMOVE", resultID) -- Use :RegisterMessage("GROUPIE_GROUPBROWSER_REMOVE", function(resultID, event) -- find the listingTable entry and remove it end)
    -- we could also just remove it here.
    for author, listing in pairs(listingTable) do
      if listing.resultID == resultID then
        listingTable[author] = nil
      end
    end
  else
    if leader and leader[1] then
      if not GroupieGroupBrowser._realmName or GroupieGroupBrowser._realmName == "" then GroupieGroupBrowser._realmName = GetNormalizedRealmName() end
      author, classColor = leader[1] .. "-" .. GroupieGroupBrowser._realmName,
          RAID_CLASS_COLORS[leader[3]].colorStr:sub(3)
      if listingTable[author] ~= nil and listingTable[author].resultID == nil then
        return
      end
      if numMembers and numMembers > 1 then
        isLFM = true
        isLFG = false
      else
        isLFG = true
        isLFM = false
      end
      timestamp = time()
      if resultData.age then
        createdat = timestamp - resultData.age
      end
      local activityID = resultData.activityIDs[1]
      instanceName = GroupieGroupBrowser._activityMap[activityID].name
      isHeroic = GroupieGroupBrowser._activityMap[activityID].group == 288 or
          GroupieGroupBrowser._activityMap[activityID].group == 289
      groupSize = GroupieGroupBrowser._activityMap[activityID].maxsize
      instanceID = GroupieGroupBrowser._activityMap[activityID].mapid
      minLevel = GroupieGroupBrowser._activityMap[activityID].minlevel
      maxLevel = GroupieGroupBrowser._activityMap[activityID].maxlevel > 0 and
          GroupieGroupBrowser._activityMap[activityID].maxlevel or
          GroupieGroupBrowser._activityMap[activityID].exp_or_honor
      local fullName, groupieInstanceName, groupieDataEntry = GroupieGroupBrowser:FindInstanceData(activityID,
        instanceName,
        instanceID,
        groupSize, isHeroic)
      if groupieDataEntry then
        order = groupieDataEntry.Order
        icon = groupieDataEntry.Icon
      else
        order = -1
        if GroupieGroupBrowser._activityMap[activityID].iconfile > 0 then
          icon = GroupieGroupBrowser._activityMap[activityID].iconfile
        else
          icon = "Other.tga"
        end
      end
      lootType = L["Filters"].Loot_Styles.MSOS
      if GroupieGroupBrowser._activityMap[activityID].cat == 118 then -- PVP related activity
        lootType = L["Filters"].Loot_Styles.PVP
      end
      if membercounts then
        local tankneed = membercounts.TANK_REMAINING > 0
        local healerneed = membercounts.HEALER_REMAINING > 0
        local damageneed = membercounts.DAMAGER_REMAINING > 0
        rolesNeeded = {}
        if tankneed then
          tinsert(rolesNeeded, 1)
        end
        if healerneed then
          tinsert(rolesNeeded, 2)
        end
        if damageneed then
          tinsert(rolesNeeded, 3)
          tinsert(rolesNeeded, 4)
        end
      end
      if isLFM and not rolesNeeded then
        rolesNeeded = { 1, 2, 3, 4 }
      end
      words = {}
      msg = self:CreateMsg(isLFM, isLFG, groupieInstanceName, isHeroic, groupSize, numMembers, lootType, minLevel,
        maxLevel,
        membercounts.TANK_REMAINING, membercounts.HEALER_REMAINING, membercounts.DAMAGER_REMAINING, leader[2])
      listingTable[author] = listingTable[author] or {}
      listingTable[author].isLFM = isLFM
      listingTable[author].isLFG = isLFG
      listingTable[author].createdat = createdat
      listingTable[author].timestamp = timestamp
      listingTable[author].instanceName = groupieInstanceName
      listingTable[author].fullName = fullName
      listingTable[author].isHeroic = isHeroic
      listingTable[author].groupSize = groupSize
      listingTable[author].lootType = lootType
      listingTable[author].rolesNeeded = rolesNeeded
      listingTable[author].msg = msg
      listingTable[author].author = author
      listingTable[author].words = words
      listingTable[author].minLevel = minLevel
      listingTable[author].maxLevel = maxLevel
      listingTable[author].order = order
      listingTable[author].instanceID = instanceID
      listingTable[author].icon = icon
      listingTable[author].classColor = classColor
      listingTable[author].resultID = resultID -- new field only for GroupBrowser listings, we can use it to add C_LFGList.RequestInvite(resultID) functionality to the LFG button for those listings.
      GroupieGroupBrowser:SendMessage("GROUPIE_GROUPBROWSER_UPDATE", resultID)
      -- We can Groupie:RegisterMessage("GROUPIE_GROUPBROWSER_UPDATE", callback) and do something in our callback function when a listing is added from this module
    end
  end
end

--[[
TODO:
1. C_LFGList.RequestInvite(resultID) (could probably have this on the LFG button or the listing context menu when a Group Browser source listing to request an invite)
2. Use the :Queue with pre-buit queries to lazily queue searches automatically when the addon boots up (for example query all Dungeons, then few seconds later all Raids,  all PvP, all Quests etc)
   Make it an option default it to false(?)
3. Call :AttachLFGToolPreset() from other parts of Groupie to set preset queries to queue when the player clicks on Tabs etc. Needs to get a reference to this module first
   local GroupieGroupBrowser = Groupie:GetModule("GroupieGroupBrowser")
   GroupieGroupBrowser:AttachLFGToolPreset(ButtonReference, category, group) -- see comment at the function definition
   Make it an option default it to true(?)
   Without 2 or 3 the module is still functional but will only harvest Group Browser data passively; when the player uses the Blizzard tool to select a category
]]


--[[
/run LibStub"AceAddon-3.0":GetAddon"Groupie":GetModule"GroupieGroupBrowser":Queue(2,{799})
/run LibStub"AceAddon-3.0":GetAddon"Groupie":GetModule"GroupieGroupBrowser":Search(2,{906})
]]

--[[ --listing spec
    addon.db.global.listingTable[author].isLFM = isLFM
    addon.db.global.listingTable[author].isLFG = isLFG
    addon.db.global.listingTable[author].createdat = createdat
    addon.db.global.listingTable[author].timestamp = groupTimestamp
    addon.db.global.listingTable[author].language = groupLanguage
    addon.db.global.listingTable[author].instanceName = groupDungeon
    addon.db.global.listingTable[author].fullName = fullName
    addon.db.global.listingTable[author].isHeroic = isHeroic
    addon.db.global.listingTable[author].groupSize = groupSize
    addon.db.global.listingTable[author].lootType = lootType
    addon.db.global.listingTable[author].rolesNeeded = rolesNeeded
    addon.db.global.listingTable[author].author = author
    addon.db.global.listingTable[author].msg = msg
    addon.db.global.listingTable[author].words = messageWords
    addon.db.global.listingTable[author].minLevel = minLevel or 0
    addon.db.global.listingTable[author].maxLevel = maxLevel or 1000
    addon.db.global.listingTable[author].order = instanceOrder or -1
    addon.db.global.listingTable[author].instanceID = instanceID
    addon.db.global.listingTable[author].icon = icon
    addon.db.global.listingTable[author].classColor = classColor
]]

--[[ --Group Browser Specs
local resultData = C_LFGList.GetSearchResultInfo(resultID) -- table
-- essential --
leaderName="Jambu",
numMembers=1, -- in combination with leader to know if it's LFG or LFM
autoAccept=false, -- maybe we track?
searchResultID=43,
activityIDs={ -- what they're listed for
  [1]=917
},
age=337, -- in seconds
isDelisted=false, -- need to read to know if the player or group has been delisted (status update is sent on removal)
-- optional --
hasSelf=false, -- are we in this result?
newPlayerFriendly=false, -- social stuff maybe we track
numGuildMates=0, -- social stuff maybe we track
numCharFriends=0, -- social stuff maybe we track
requiredItemLevel=0, -- maybe we track?
-- ignored --
requiredHonorLevel=0 -- maybe we track?
comment="|Kr2|k", -- protected string, can't be read
name="", -- protected string
voiceChat="", -- we can ignore
isWarMode=false, -- we can ignore
numBNetFriends=0, -- we can ignore

local membercounts = C_LFGList.GetSearchResultMemberCounts(resultID) -- table
NOROLE=0,
DAMAGER=0,
HEALER=0,
TANK=1,
LEADER_ROLE_DAMAGER=true,
LEADER_ROLE_HEALER=false,
LEADER_ROLE_TANK=false
DAMAGER_REMAINING=3,
HEALER_REMAINING=1,
TANK_REMAINING=0,
DEATHKNIGHT=1,
DRUID=0,
HUNTER=0,
MAGE=0,
PALADIN=0,
PRIEST=0,
ROGUE=0,
SHAMAN=0,
WARLOCK=0,
WARRIOR=0,

local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 = C_LFGList.GetSearchResultLeaderInfo(resultID)
arg1 = Name
arg2 = roleToken
arg3 = EN_CLASS
arg4 = locale_class
arg5 = level
arg6 = Zone
arg7 = boolean ?? auto-accept / newbiefriendly / what else and which is which
arg8 = boolean ??
arg9 = boolean ??

local arg1, arg2, arg3, arg4, arg5, arg6 = C_LFGList.GetSearchResultMemberInfo(resultID,i)
arg1 = Name
arg2 = roleToken
arg3 = EN_CLASS
arg4 = locale_class
arg5 = Level
arg6 = boolean ??
]]
