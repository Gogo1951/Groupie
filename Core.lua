local addonName, Groupie = ...

local addon = LibStub("AceAddon-3.0"):NewAddon(Groupie, addonName,
    "AceEvent-3.0", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")

--------------------
-- User Interface --
--------------------
local function BuildGroupieWindow()
    --Dont open a new frame if already open
    if addon._frame and addon._frame.frame:IsShown() then
        return
    end

    --Groupie Main Tab
    local function DrawMainTab(container)
        local desc = AceGUI:Create("Label")
        desc:SetText("Main tab showing group listing.")
        container:AddChild(desc)
    end

    --Group Builder Tab
    local function DrawGroupBuilder(container)
        local desc = AceGUI:Create("Label")
        desc:SetText("Group builder tab.")
        container:AddChild(desc)
    end

    --Group Filter Tab
    local function DrawGroupFilter(container)
        local desc = AceGUI:Create("Label")
        desc:SetText("Group filters tab.")
        container:AddChild(desc)
    end

    --Instance Filter Tab
    local function DrawInstanceFilter(container)
        local desc = AceGUI:Create("Label")
        desc:SetText("Instance filters tab.")
        container:AddChild(desc)
    end

    --About Tab
    local function DrawAbout(container)
        local tabTitle = AceGUI:Create("Label")
        tabTitle:SetText("Groupie | About")
        tabTitle:SetColor(0.88, 0.73, 0)
        tabTitle:SetFontObject(GameFontHighlightHuge)
        tabTitle:SetFullWidth(true)
        container:AddChild(tabTitle)


        local curseLabel = AceGUI:Create("Label")
        curseLabel:SetText("Groupie on CurseForge")
        curseLabel:SetFullWidth(true)
        container:AddChild(curseLabel)
        local curseEditBox = AceGUI:Create("EditBox")
        curseEditBox:SetText("https://www.curseforge.com/wow/addons/groupie")
        curseEditBox:DisableButton(true)
        curseEditBox:SetWidth(350)
        curseEditBox:SetCallback("OnTextChanged", function()
            curseEditBox:SetText("https://www.curseforge.com/wow/addons/groupie")
        end)
        curseEditBox:SetCallback("OnEnterPressed", function()
            curseEditBox.editbox:ClearFocus()
        end)
        curseEditBox.editbox:SetScript("OnCursorChanged", function()
            curseEditBox:HighlightText()
        end)
        container:AddChild(curseEditBox)

        local discordLabel = AceGUI:Create("Label")
        discordLabel:SetText("Groupie on Discord")
        discordLabel:SetFullWidth(true)
        container:AddChild(discordLabel)
        local discordEditBox = AceGUI:Create("EditBox")
        discordEditBox:SetText("https://discord.gg/p68QgZ8uqF")
        discordEditBox:DisableButton(true)
        discordEditBox:SetWidth(350)
        discordEditBox:SetCallback("OnTextChanged", function()
            discordEditBox:SetText("https://discord.gg/p68QgZ8uqF")
        end)
        discordEditBox:SetCallback("OnEnterPressed", function()
            discordEditBox.editbox:ClearFocus()
        end)
        discordEditBox.editbox:SetScript("OnCursorChanged", function()
            discordEditBox:HighlightText()
        end)
        container:AddChild(discordEditBox)

        local githubLabel = AceGUI:Create("Label")
        githubLabel:SetText("Groupie on GitHub")
        githubLabel:SetFullWidth(true)
        container:AddChild(githubLabel)
        local githubEditBox = AceGUI:Create("EditBox")
        githubEditBox:SetText("https://github.com/Gogo1951/Groupie")
        githubEditBox:DisableButton(true)
        githubEditBox:SetWidth(350)
        githubEditBox:SetCallback("OnTextChanged", function()
            githubEditBox:SetText("https://github.com/Gogo1951/Groupie")
        end)
        githubEditBox:SetCallback("OnEnterPressed", function()
            githubEditBox.editbox:ClearFocus()
        end)
        githubEditBox.editbox:SetScript("OnCursorChanged", function()
            githubEditBox:HighlightText()
        end)
        container:AddChild(githubEditBox)
    end

    -- Callback function for OnGroupSelected
    local function SelectGroup(container, event, group)
        container:ReleaseChildren()
        if group == "maintab" then
            DrawMainTab(container)
        elseif group == "groupbuilder" then
            DrawGroupBuilder(container)
        elseif group == "groupfilter" then
            DrawGroupFilter(container)
        elseif group == "instancefilter" then
            DrawInstanceFilter(container)
        elseif group == "about" then
            DrawAbout(container)
        end
    end

    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Groupie")
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    frame:SetLayout("Fill")

    --Creating Tabgroup
    local tab = AceGUI:Create("TabGroup")
    tab:SetLayout("Flow")
    tab:SetTabs({ { text = "Groupie", value = "maintab" },
        { text = "Group Builder", value = "groupbuilder" },
        { text = "Group Filters", value = "groupfilter" },
        { text = "Instance Filters", value = "instancefilter" },
        { text = "About", value = "about" }
    })
    tab:SetCallback("OnGroupSelected", SelectGroup)
    tab:SelectTab("maintab")
    frame:AddChild(tab)

    --Allow the frame to close when ESC is pressed
    _G["GroupieFrame"] = frame.frame
    tinsert(UISpecialFrames, "GroupieFrame")
    --Store a global reference to the frame
    addon._frame = frame
end

--Minimap Icon Creation
addon.groupieLDB = LibStub("LibDataBroker-1.1"):NewDataObject("Groupie", {
    type = "data source",
    text = "Groupie",
    icon = "Interface\\AddOns\\Groupie\\Images\\icon64.tga",
    OnClick = BuildGroupieWindow,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Groupie")
        tooltip:AddLine("A better LFG tool for Classic WoW.", 255, 255, 255, false)
        tooltip:AddLine("Click to open Groupie", 255, 255, 255, false)
    end
})

--------------------------
-- Addon Initialization --
--------------------------
function addon:OnInitialize()
    local defaults = {
        char = {
            groupieSpec1Role = nil,
            groupieSpec2Role = nil,
            recommendedLevelRange = 1,
            autoRespondFriends = false,
            autoRespondGuild = false,
            afterParty = true,
            useChannels = {
                ["Guild"] = true,
                ["General"] = true,
                ["Trade"] = true,
                ["LocalDefense"] = true,
                ["LookingForGroup"] = true,
                ["5"] = true,
            }
        },
        global = {
            preserveData = true,
            minsToPreserve = 2,
            font = "Arial Narrow",
            fontSize = 8,
            debugData = {},
            showMinimap = false,
        }
    }

    addon.db = LibStub("AceDB-3.0"):New("GroupieDB", defaults)
    addon.icon = LibStub("LibDBIcon-1.0")
    addon.icon:Register("GroupieLDB", addon.groupieLDB, addon.db.global)
    --addon.icon:Show()
    addon.icon:Hide("GroupieLDB")


    addon.debugMenus = true
    --Setup Slash Commands
    SLASH_GROUPIE1 = "/groupie"
    SlashCmdList["GROUPIE"] = BuildGroupieWindow
    SLASH_GROUPIECFG1 = "/groupiecfg"
    SlashCmdList["GROUPIECFG"] = addon.OpenConfig
    addon.isInitialized = true
end

---------------------
-- AceConfig Setup --
---------------------
function addon.SetupConfig()
    local options = {
        name = addonName,
        desc = "Optional description? for the group of options",
        descStyle = "inline",
        handler = addon,
        type = 'group',
        args = {
            charoptions = {
                name = "Character Options",
                desc = "Change Character-Specific Settings",
                type = "group",
                width = "double",
                inline = false,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cffffd900Groupie | " .. UnitName("player") .. " Options",
                        order = 0,
                        fontSize = "large"
                    },
                    spacerdesc1 = { type = "description", name = " ", width = "full", order = 1 },
                    header2 = {
                        type = "description",
                        name = "|cffffd900Spec 1 Role - " .. addon.GetSpecByGroupNum(1),
                        order = 2,
                        fontSize = "medium"
                    },
                    spec1Dropdown = {
                        type = "select",
                        style = "dropdown",
                        name = "",
                        order = 3,
                        width = 1.4,
                        values = addon.groupieClassRoleTable[UnitClass("player")][addon.GetSpecByGroupNum(1)],
                        set = function(info, val) addon.db.char.groupieSpec1Role = val end,
                        get = function(info) return addon.db.char.groupieSpec1Role end,
                    },
                    spacerdesc2 = { type = "description", name = " ", width = "full", order = 4 },
                    header3 = {
                        type = "description",
                        name = "|cffffd900Spec 2 Role - " .. addon.GetSpecByGroupNum(1),
                        order = 5,
                        fontSize = "medium"
                    },
                    spec2Dropdown = {
                        type = "select",
                        style = "dropdown",
                        name = "",
                        order = 6,
                        width = 1.4,
                        values = addon.groupieClassRoleTable[UnitClass("player")][addon.GetSpecByGroupNum(2)],
                        set = function(info, val) addon.db.char.groupieSpec2Role = val end,
                        get = function(info) return addon.db.char.groupieSpec2Role end,
                    },
                    spacerdesc3 = { type = "description", name = " ", width = "full", order = 7 },
                    header4 = {
                        type = "description",
                        name = "|cffffd900Recommended Dungeon Level Range",
                        order = 8,
                        fontSize = "medium"
                    },
                    recLevelDropdown = {
                        type = "select",
                        style = "dropdown",
                        name = "",
                        order = 9,
                        width = 1.4,
                        values = {
                            [0] = "+0 - I'm new to this",
                            [1] = "+1 - I've Done This Before",
                            [2] = "+2 - This is a Geared Alt",
                            [3] = "+3 - With Heirlooms",
                            [4] = "+4 - With Heirlooms & Consumes"
                        },
                        set = function(info, val) addon.db.char.recommendedLevelRange = val end,
                        get = function(info) return addon.db.char.recommendedLevelRange end,
                    },
                    spacerdesc4 = { type = "description", name = " ", width = "full", order = 10 },
                    header5 = {
                        type = "description",
                        name = "|cffffd900Groupie Auto-Response",
                        order = 11,
                        fontSize = "medium"
                    },
                    autoFriendsToggle = {
                        type = "toggle",
                        name = "Enable Auto-Respond to Friends",
                        order = 12,
                        width = "full",
                        get = function(info) return addon.db.char.autoRespondFriends end,
                        set = function(info, val) addon.db.char.autoRespondFriends = val end,
                    },
                    autoGuildToggle = {
                        type = "toggle",
                        name = "Enable Auto-Respond to Guild Members",
                        order = 13,
                        width = "full",
                        get = function(info) return addon.db.char.autoRespondGuild end,
                        set = function(info, val) addon.db.char.autoRespondGuild = val end,
                    },
                    spacerdesc5 = { type = "description", name = " ", width = "full", order = 14 },
                    header6 = {
                        type = "description",
                        name = "|cffffd900Groupie After-Party Tool",
                        order = 15,
                        fontSize = "medium"
                    },
                    afterPartyToggle = {
                        type = "toggle",
                        name = "Enable Groupie After-Party Tool",
                        order = 16,
                        width = "full",
                        get = function(info) return addon.db.char.afterParty end,
                        set = function(info, val) addon.db.char.afterParty = val end,
                    },
                    spacerdesc6 = { type = "description", name = " ", width = "full", order = 17 },
                    header7 = {
                        type = "description",
                        name = "|cffffd900Pull Groups From These Channels",
                        order = 18,
                        fontSize = "medium"
                    },
                    channelGuildToggle = {
                        type = "toggle",
                        name = "Guild",
                        order = 19,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels["Guild"] end,
                        set = function(info, val) addon.db.char.useChannels["Guild"] = val end,
                    },
                    channelGeneralToggle = {
                        type = "toggle",
                        name = "General",
                        order = 20,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels["General"] end,
                        set = function(info, val) addon.db.char.useChannels["General"] = val end,
                    },
                    channelTradeToggle = {
                        type = "toggle",
                        name = "Trade",
                        order = 21,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels["Trade"] end,
                        set = function(info, val) addon.db.char.useChannels["Trade"] = val end,
                    },
                    channelLocalDefenseToggle = {
                        type = "toggle",
                        name = "LocalDefense",
                        order = 22,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels["LocalDefense"] end,
                        set = function(info, val) addon.db.char.useChannels["LocalDefense"] = val end,
                    },
                    channelLookingForGroupToggle = {
                        type = "toggle",
                        name = "LookingForGroup",
                        order = 23,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels["LookingForGroup"] end,
                        set = function(info, val) addon.db.char.useChannels["LookingForGroup"] = val end,
                    },
                    channel5Toggle = {
                        type = "toggle",
                        name = "5",
                        order = 24,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels["5"] end,
                        set = function(info, val) addon.db.char.useChannels["5"] = val end,
                    }
                },
            },
            globaloptions = {
                name = "Global Options",
                desc = "Change Account-Wide Settings",
                type = "group",
                width = "double",
                inline = false,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cffffd900Groupie | Global Options",
                        order = 0,
                        fontSize = "large"
                    },
                    spacerdesc1 = { type = "description", name = " ", width = "full", order = 1 },
                    minimapToggle = {
                        type = "toggle",
                        name = "Enable Minimap Button",
                        order = 2,
                        width = "full",
                        get = function(info) return addon.db.global.showMinimap end,
                        set = function(info, val)
                            addon.db.global.showMinimap = val
                            if val == true then
                                addon.icon:Show("GroupieLDB")
                            else
                                addon.icon:Hide("GroupieLDB")
                            end
                        end,
                    },
                    --spacerdesc2 = { type = "description", name = " ", width = "full", order = 3 },
                    preserveDataToggle = {
                        type = "toggle",
                        name = "Preserve Looking for Group Data When Switching Characters",
                        order = 4,
                        width = "full",
                        get = function(info) return addon.db.global.preserveData end,
                        set = function(info, val) addon.db.global.preserveData = val end,
                    },
                    spacerdesc3 = { type = "description", name = " ", width = "full", order = 5 },
                    header2 = {
                        type = "description",
                        name = "|cffffd900Preserve Looking for Group Data Duration",
                        order = 6,
                        fontSize = "medium"
                    },
                    preserveDurationDropdown = {
                        type = "select",
                        style = "dropdown",
                        name = "",
                        order = 7,
                        width = 1.4,
                        values = { [2] = "2 Minutes", [3] = "3 Minutes", [4] = "4 Minutes", [5] = "5 Minutes" },
                        set = function(info, val) addon.db.global.minsToPreserve = val end,
                        get = function(info) return addon.db.global.minsToPreserve end,
                    },
                    spacerdesc4 = { type = "description", name = " ", width = "full", order = 8 },
                    header3 = {
                        type = "description",
                        name = "|cffffd900Font",
                        order = 9,
                        fontSize = "medium"
                    },
                    fontDropdown = {
                        type = "select",
                        style = "dropdown",
                        name = "",
                        order = 10,
                        width = 1.4,
                        values = addon.TableFlip(SharedMedia:HashTable("font")),
                        set = function(info, val) addon.db.global.font = val end,
                        get = function(info) return addon.db.global.font end,
                    },
                    spacerdesc5 = { type = "description", name = " ", width = "full", order = 11 },
                    header4 = {
                        type = "description",
                        name = "|cffffd900Base Font Size",
                        order = 12,
                        fontSize = "medium"
                    },
                    fontSizeDropdown = {
                        type = "select",
                        style = "dropdown",
                        name = "",
                        order = 13,
                        width = 1.4,
                        values = {
                            [8] = "8 pt",
                            [10] = "10 pt",
                            [12] = "12 pt",
                            [14] = "14 pt",
                            [16] = "16 pt",
                            [18] = "18 pt",
                            [20] = "20 pt",
                        },
                        set = function(info, val) addon.db.global.fontSize = val end,
                        get = function(info) return addon.db.global.fontSize end,
                    },
                },
            },
        },
    }
    addon.optionsTable = LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options)
    addon.AceConfigDialog = LibStub("AceConfigDialog-3.0")
    addon.optionsFrame = addon.AceConfigDialog:AddToBlizOptions(addonName, addonName)
    if addon.db.global.showMinimap == false then
        addon.icon:Hide("GroupieLDB")
    end
end

--This must be done after player entering world event so that we can pull spec
addon:RegisterEvent("PLAYER_ENTERING_WORLD", addon.SetupConfig)

function addon:OpenConfig()
    InterfaceOptionsFrame_OpenToCategory(addonName)
    -- need to call it a second time as there is a bug where the first time it won't switch !BlizzBugsSuck has a fix
    InterfaceOptionsFrame_OpenToCategory(addonName)
end
