--[[
	Groupie Localization Information: English Language
		This file must be present to have partial translations
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Groupie', 'frFR')

if not L then return end
L["slogan"] = "Un meilleur outil de Recherche de Groupe pour WoW Classic"
L["LocalizationStatus"] = 'La traduction est en cours'
L["TeamMember"] = "Membre de l'équipe"

-- tabs
L["Dungeons"] = "Donjons"
L["Raid"] = "Raids"
L["ShortHeroic"] = "H"
L["PVP"] = "JcJ"
L["Other"] = "Autre"
L["All"] = "Tous"

-- UI Columns
L["Created"] = "Crée"
L["Updated"] = "Mis à jour"
L["Leader"] = "Chef"
L["InstanceName"] = "Instance"
L["LootType"] = "Butin"
L["Message"] = "Message"


-- filters
    --- Roles
L["LookingFor"] = "LF"
L["Any"] = "Tous Role"
L["Tank"] = "Tank"
L["Healer"] = "Soigneur"
L["DPS"] = "DPS"
    --- Loot Types
L["AnyLoot"] = "Tous types de butins"
L["MSOS"] = "Spé principale > Secondaire"
L["SoftRes"] = "SoftRes"
L["GDKP"] = "GDKP"
L["Ticket"] = "Ticket"
L["Other"] = "Autre"
L["PVP"] = "JcJ"
    --- Languages
L["AnyLanguage"] = "Toutes langues"
    --- Dungeons
L["AnyDungeon"] = "Tous les donjons"
L["RecommendedDungeon"] = "Donjons recommandés"

-- Global
L["ShowingLabel"] = "Afficher"
L["SettingsButton"] = "Réglages & Filtres"
L["Click"] = "Clic"
L["RightClick"] = "Clic droit"
L["Settings"] = "Réglages"
L["BulletinBoard"] = "Tableau d'affichage"
L["Reset"] = "Réinitialiser"
L["Options"] = "Options"
-- Channels Name /!\ VERY IMPORTANT, THE ADDON PARSES DEPENDING ON THE CHANNEL NAME
L["Guild"] = "Guilde"
L["General"] = "Général"
L["Trade"] = "Commerce"
L["LocalDefense"] = "DéfenseLocale"
L["LFG"] = "RechercheDeGroupe"
L["World"] = "5"
-- Spec Names /!\ Must be implemented. This is the base requirement for the
--- Death Knight
L["DeathKnight"] = {
    ["Blood"] = "Sang",
    ["Frost"] = "Givre",
    ["Unholy"] = "Impie"
}
--- Druid
L["Druid"] = {
    ["Balance"] = "Équilibre",
    ["Feral"] = "Farouche",
    ["Restoration"] = "Restauration"
}
--- Hunter
L["Hunter"] = {
    ["BM"] = "Maîtrise des bêtes",
    ["MM"] = "Précision",
    ["Survival"] = "Survie"
}
--- Mage
L["Mage"] = {
    ["Arcane"] = "Arcanes",
    ["Fire"] = "Feu",
    ["Frost"] = "Givre"
}
--- Paladin
L["Paladin"] = {
    ["Holy"] = "Sacré",
    ["Protection"] = "Protection",
    ["Retribution"] = "Vindicte"
}
--- Priest
L["Priest"] = {
    ["Discipline"] = "Discipline",
    ["Holy"] = "Sacré",
    ["Shadow"] = "Ombre"
}
-- Rogue
L["Rogue"] = {
    ["Assassination"] = "Assassinat",
    ["Combat"] = "Combat", --need to check to see if this errors
    ["Subtlety"] = "Finesse"
}
--- Shaman
L["Shaman"] = {
    ["Elemental"] = "Elémentaire",
    ["Enhancement"] = "Amélioration",
    ["Restoration"] = "Restauration"
}
--- Warlock
L["Warlock"] = {
    ["Affliction"] = "Affliction",
    ["Demonology"] = "Démonologie",
    ["Destruction"] = "Destruction"
}
--- Warrior
L["Warrior"] = {
    ["Arms"] = "Armes",
    ["Fury"] = "Fureur",
    ["Protection"] = "Protection",
}

L["ShortLocalizedInstances"] = {
    ["Zul'Gurub"]           = "Gurub",
    ["Ruins of Ahn'Qiraj"]  = "Ruines d'Ahn'Qiraj",
    ["Onyxia's Lair"]       = "Onyxia",
    ["Molten Core"]         = "Coeur de magma",
    ["Blackwing Lair"]      = "Aile noire",
    ["Temple of Ahn'Qiraj"] = "Temple d'Ahn'Qiraj",
    --["Naxxramas"]             = { { 40, false } },

    ["Hellfire Ramparts"]       = "Remparts",
    ["Blood Furnace"]           = "Fournaise de sang",
    ["Slave Pens"]              = "Enclos",
    ["Underbog"]                = "Basse Tourbière",
    ["Mana-Tombs"]              = "Tombe-Mana",
    ["Auchenai Crypts"]         = "Auchenai",
    ["Sethekk Halls"]           = "Sethekk",
    ["Old Hillsbrad Foothills"] = "Durnholde",
    ["Shadow Labyrinth"]        = "Labyrinthe des ombres",
    ["Mechanar"]                = "Mechanar",
    ["Shattered Halls"]         = "Salles brisées",
    ["Steamvault"]              = "Caveau de la vapeur",
    ["Botanica"]                = "Botanica",
    ["Arcatraz"]                = "Arcatraz",
    ["Black Morass"]            = "Noir Marécage",
    ["Magisters' Terrace"]      = "Terrasse des magistères",

    ["Karazhan"]             = "Karazhan",
    ["Zul'Aman"]             = "Zul'Aman",
    ["Gruul's Lair"]         = "Gruul",
    ["Magtheridon's Lair"]   = "Magtheridon",
    ["Serpentshrine Cavern"] = "Caverne du sanctuaire du Serpent",
    ["Tempest Keep"]         = "Tempête",
    ["Mount Hyjal"]          = "Hyjal",
    ["Black Temple"]         = "Temple noir",
    ["Sunwell Plateau"]      = "Puits de soleil",

    ["Utgarde Keep"]          = "Donjon d'Utgarde",
    ["Nexus"]                 = "Nexus",
    ["Azjol-Nerub"]           = "Azjol",
    ["Old Kingdom"]           = "Ancien royaume",
    ["Drak'Tharon Keep"]      = "Drak'Tharon",
    ["Violet Hold"]           = "Fort Pourpre",
    ["Gundrak"]               = "Gundrak",
    ["Halls of Stone"]        = "Salles de Pierre",
    ["Culling of Stratholme"] = "GT4",
    ["Halls of Lightning"]    = "Salles de Foudre",
    ["Utgarde Pinnacle"]      = "Cime d'Utgarde",
    ["Oculus"]                = "Oculus",
    ["Trial of the Champion"] = "Epreuve du Champion",
    ["Forge of Souls"]        = "Forge des Ames",
    ["Pit of Saron"]          = "Fosse de Saron",
    ["Halls of Reflection"]   = "Salles des Reflets",

    ["Naxxramas"]         = "Naxxramas",
    ["Obsidian Sanctum"]  = "Obsidian",
    ["Vault of Archavon"] = "Archavon",
    ["Eye of Eternity"]   = "Eternité",
    --["Onyxia's Lair"]        = { { 10, false }, { 25, false } },
    ["Ulduar"]            = "Ulduar",

    ["Trial of the Crusader"]       = "Epreuve du Croisé",
    ["Icecrown Citadel"]            = "Citadelle de la Couronne de Glace",
    ["Ruby Sanctum"]                = "Rubis",
    ["Trial of the Grand Crusader"] = "Epreuve du Grand Croisé",
}
L["Instance Filters - Wrath"] = "Filtres Instance - Wrath"
L["Instance Filters - TBC"] = "Filtres Instance - TBC"
L["Instance Filters - Classic"] = "Filtres Instance - Classic"
L["Filter Groups by Instance"] = "Filtrer les Groupes par Instance"
-- Group Filters
L["Group Filters"] = "Filtres Groupes"
L["Filter Groups by Other Properties"] = "Filtrer les Groupes par Autres Propriétés"
L["General Filters"] = "Filtres Généraux"
L["savedToggle"] = "Ignorer les instances où vous avez déjà ID sur ce personnage"
L["ignoreLFG"] = "Ignorer les Messages \"LFG\" des Personnes Recherchant un Groupe"
L["ignoreLFM"] = "Ignorer les Messages \"LFM\" des Personnes Créant un Groupe"
L["keyword"] = "Filtrer par mot clé"
L["keyword_desc"] = "Séparer les mots et phrases d'un ; toute proposition correspondante sera ignorée\nExemple: \"swp trash, Selling, Boost\""
--Character Options
L["Character Options"] = "Options du Personnage"
L["Change Character-Specific Settings"] = "Modifier les options de ce Personnage"
L["Spec 1 Role"] = "Role Spécialisation 1"
L["Spec 2 Role"] = "Role Spécialisation 2"
L["OtherRole"] = "Inclure votre autre Spécialisation dans les messages Groupie"
L["DungeonLevelRange"] = "Donjons recommandés pour votre niveau"
L["recLevelDropdown"] = {
        ["0"] = "Niveaux Recommandés par défaut",
        ["1"] = "+1 - J'ai déjà fait ça avant",
        ["2"] = "+2 - J'ai des objets Héritage",
        ["3"] = "+3 - Je suis soigneur"
}
L["Auto-Response"] = "Réponse automatique"
L["AutoFriends"] = "Activer la Réponse automatique aux amis"
L["AutoGuild"] = "Activer la Réponse automatique à la guilde"
L["AfterParty"] = "Outil 'Après la Fête'"
L["PullGroups"] = "Obtenir les groupes de ces Canaux"
--Global Options
L["Global Options"] = "Options Globales"
L["Change Account-Wide Settings"] = "Modifier les paramètres globaux"
L["MiniMapButton"] = "Activer le bouton de la Mini-carte"
L["LFGData"] = "Conserver la durée de rétention des données LFG"
L["UI Scale"] = "Echelle de l'interface"
L["DurationDropdown"] = {
    ["1"] = "1 Minute",
    ["2"] = "2 Minutes",
    ["5"] = "5 Minutes",
    ["10"] = "10 Minutes",
    ["20"] = "20 Minutes",
}
--RightClickMenu
L["SendInfo"] = "Envoyer mes informations ..."
L["Current"] = "Actuel"
L["WCL"] = "Lien Warcraft Logs"
L["Ignore"] = "Ignorer"
L["StopIgnore"] = "Arrêter d'Ignorer"
L["Invite"] = "Inviter"
L["Whisper"] = "Chuchoter"

--minimap
L["lowerOr"] = "ou"
L["Update1"] = "VEUILLEZ METTRE A JOUR VOS ADDON"
L["Update2"] = "VERSION DE GROUPIE PERIMEE !"
L["HelpUs"] = "Groupie a besoin de vous ! Allez dans\nOptions Groupie > Journal d'Instance et\ntéléchargez les valeurs sur le Discord Groupie\nCe message disparaitra la prochaine fois\nque vous mettrez à jour Groupie. Merci !"
--Instance Log
L["Instance Log"] = "Journal d'Instances"
L["Help Groupie"] = "Aidez Groupie !"
--About
L["About Groupie"] = "A Propos de Groupie"
L["About Paragraph"] = "Un meilleur outil de Recherche de Groupe pour WoW Classic.\n\n\nGroupie a été crée par Gogo, LemonDrake, Kynura, and Raegen...\n\n...avec l'aide de Katz, Aevala, et Fathom."
L["lowerOn"] = "on"

--VersionChecking
L["JoinRaid"] = "a rejoint le groupe de raid"
L["JoinParty"] = "rejoint le groupe"

L["AutoRequestResponse"] = "Activer Groupie Réponse Automatique quand on demande à rejoindre mon groupe"
L["AutoInviteResponse"] = "Activer Groupie Réponse Automatique quand on m'invite à rejoindre un groupe"
L["CommunityLabel"] = "Communauté Groupie"
L["GlobalFriendsLabel"] = "Liste d'Amis Globale"
L["GeneralOptionslabel"] = "Options Générales"
L["KeywordFilters"] = "Filtres de Mots Clés"
L["Enable"] = "Enable"