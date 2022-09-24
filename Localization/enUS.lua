--[[
	Groupie Localization Information: English Language
		This file must be present to have partial translations
--]] 

local L = LibStub('AceLocale-3.0'):NewLocale('Groupie', 'enUS', true)


    L["slogan"] = "A better LFG tool for Classic WoW."
    L["LocalizationStatus"] = 'Localization is on the work'

    -- tabs
    L["UI_tabs"]={
        ["Dungeon"] = "Dungeons",
        ["Raid"] = "Raids",
        ["ShortHeroic"] = "H",
        ["PVP"] = "PVP",
        ["Other"] = "Other",
        ["All"] = "All"
    }
    -- Columns
    L["UI_columns"]={
        ["Created"] = "Created",
        ["Updated"] = "Updated",
        ["Leader"] = "Leader",
        ["InstanceName"] = "Instance",
        ["LootType"] = "Loot",
        ["Message"] = "Message"
    }

    -- filters
    L["Filters"]={
        --- Roles
        ["Roles"]={
            ["LookingFor"] = "LF",
            ["Any"] = "Any Role",
            ["Tank"] = "Tank",
            ["Healer"] = "Healer",
            ["DPS"] = "DPS"
        },
        --- Loot Types
        ["Loot_Styles"]={
            ["AnyLoot"] = "All Loot Styles",
            ["MSOS"] = "MS > OS",
            ["SoftRes"] = "SoftRes",
            ["GDKP"] = "GDKP",
            ["Ticket"] = "TICKET"
        },
        --- Languages
        ["AnyLanguage"] = "All Languages",

        --- Dungeons
        ["Dungeons"]={
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
    L["text_channels"]={
        ["Guild"] = "Guild" ,
        ["General"] = "General",
        ["Trade"] = "Trade",
        ["LocalDefense"] = "LocalDefense",
        ["LFG"] = "LookingForGroup",
        ["World"] = "5",
    }
    -- Spec Names /!\ Must be implemented. This is the base requirement for the 
    --- Death Knight
    L["DeathKnight"]={
        ["Blood"] = "Blood",
        ["Frost"] = "Frost",
        ["Unholy"] = "Unholy"
    }
    --- Druid
    L["Druid"]={
        ["Balance"] = "Balance",
        ["Feral"] = "Feral Combat",
        ["Restoration"] = "Restoration"
    }
    --- Hunter
    L["Hunter"]={
        ["BM"] = "Beast Mastery",
        ["MM"] = "Marksmanship",
        ["Survival"] = "Survival"
    }
    --- Mage
    L["Mage"]={
        ["Arcane"] = "Arcane",
        ["Fire"] = "Fire",
        ["Frost"] = "Frost"
    }
    --- Paladin
    L["Paladin"]={
        ["Holy"] = "Holy",
        ["Protection"] = "Protection",
        ["Retribution"] = "Retribution"
    }
    --- Priest
    L["Priest"]={
        ["Discipline"] = "Discipline",
        ["Holy"] = "Holy",
        ["Shadow"] = "Shadow"
    }
    -- Rogue
    L["Rogue"]={
        ["Assassination"] = "Assassination",
        ["Combat"] = "Combat",
        ["Subtlety"] = "Subtlety"
    }
    --- Shaman
    L["Shaman"]={
        ["Elemental"] = "Elemental",
        ["Enhancement"] = "Enhancement",
        ["Restoration"] = "Restoration"
    }
    --- Warlock
    L["AfflictionWarlock"] = "Affliction"
    L["DemonologyWarlock"] = "Demonology"
    L["DestructionWarlock"] = "Destruction"
    
    --- Warrior 
    L["ArmsWarrior"] = "Arms"
    L["FuryWarrior"] = "Fury"
    L["ProtectionWarrior"] = "Protection"

