groupieLocaleTable = {
    ["frFR"] = "French",
    ["deDE"] = "German",
    ["enGB"] = "English",
    ["enUS"] = "English",
    ["itIT"] = "Italian",
    ["koKR"] = "Korean",
    ["zhCN"] = "Chinese",
    ["zhTW"] = "Chinese",
    ["ruRU"] = "Russian",
    ["esES"] = "Spanish",
    ["esMX"] = "Spanish",
    ["ptBR"] = "Portuguese",
}

groupieRoleTable = {
    [1] = "Tank",
    [2] = "Healer",
    [3] = "Ranged DPS",
    [4] = "Melee DPS"
}

groupieClassRoleTable = {
    ["Death Knight"] = {
        ["Blood"] = {1},
        ["Frost"] = {1, 4},
        ["Unholy"] = {4}
    },
    ["Druid"] = {
        ["Balance"] = {3},
        ["Feral Combat"] = {1, 4},
        ["Restoration"] = {2}
    },
    ["Hunter"] = {
        ["Beast Mastery"] = {3},
        ["Marksmanship"] = {3},
        ["Survival"] = {3}
    },
    ["Mage"] = {
        ["Arcane"] = {},
        ["Fire"] = {},
        ["Frost"] = {}
    },
    ["Paladin"] = {
        ["Holy"] = {2},
        ["Protection"] = {1},
        ["Retribution"] = {4}
    },
    ["Priest"] = {
        ["Discipline"] = {2},
        ["Holy"] = {2},
        ["Shadow"] = {3}
    },
    ["Rogue"] = {
        ["Assassination"] = {4},
        ["Combat"] = {4},
        ["Subtlety"] = {4}
    },
    ["Shaman"] = {
        ["Elemental"] = {3},
        ["Enhancement"] = {4},
        ["Restoration"] = {2}
    },
    ["Warlock"] = {
        ["Affliction"] = {3},
        ["Demonology"] = {3},
        ["Destruction"] = {3}
    },
    ["Warrior"] = {
        ["Arms"] = {4},
        ["Fury"] = {4},
        ["Protection"] = {1}
    }
}