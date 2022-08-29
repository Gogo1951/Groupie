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

    --Global Options Tab
    local function DrawGlobalOptions(container)
        local tabTitle = AceGUI:Create("Label")
        tabTitle:SetText("Groupie | Global Options")
        tabTitle:SetColor(0.88, 0.73, 0)
        tabTitle:SetFontObject(GameFontHighlightHuge)
        tabTitle:SetFullWidth(true)
        container:AddChild(tabTitle)

        local preserveBox = AceGUI:Create("CheckBox")
        preserveBox:SetLabel("Preserve Looking for Group Data When Switching Characters")
        preserveBox:SetFullWidth(true)
        preserveBox:SetValue(addon.db.global.preserveData)
        preserveBox:SetCallback("OnValueChanged", function()
            addon.db.global.preserveData = preserveBox:GetValue()
        end)
        container:AddChild(preserveBox)

        local preserveTitle = AceGUI:Create("Label")
        preserveTitle:SetText("Preserve Looking For Group Data Duration")
        preserveTitle:SetFontObject(GameFontNormalMed2)
        preserveTitle:SetFullWidth(true)
        container:AddChild(preserveTitle)

        local preserveDropdown = AceGUI:Create("Dropdown")
        preserveDropdown:SetWidth(125)
        for durationTemp = 2, 5 do
            preserveDropdown:AddItem(durationTemp, tostring(durationTemp) .. " Minutes")
        end
        preserveDropdown:SetCallback("OnValueChanged", function()
            if preserveDropdown:GetValue() then
                addon.db.global.minsToPreserve = preserveDropdown:GetValue()
            end
        end)
        if addon.db.global.minsToPreserve ~= nil then
            preserveDropdown:SetValue(addon.db.global.minsToPreserve)
        end
        container:AddChild(preserveDropdown)

        local fontTitle = AceGUI:Create("Label")
        fontTitle:SetText("Font")
        fontTitle:SetFontObject(GameFontNormalMed2)
        fontTitle:SetFullWidth(true)
        container:AddChild(fontTitle)

        local fontDropdown = AceGUI:Create("Dropdown")
        fontDropdown:SetWidth(250)
        for key, val in pairs(SharedMedia:HashTable("font")) do
            fontDropdown:AddItem(key, key)
        end
        fontDropdown:SetCallback("OnValueChanged", function()
            if fontDropdown:GetValue() then
                addon.db.global.font = fontDropdown:GetValue()
            end
        end)
        if addon.db.global.font ~= nil then
            fontDropdown:SetValue(addon.db.global.font)
        end
        container:AddChild(fontDropdown)

        local fontSizeTitle = AceGUI:Create("Label")
        fontSizeTitle:SetText("Base Font Size")
        fontSizeTitle:SetFontObject(GameFontNormalMed2)
        fontSizeTitle:SetFullWidth(true)
        container:AddChild(fontSizeTitle)

        local fontSizeDropdown = AceGUI:Create("Dropdown")
        fontSizeDropdown:SetWidth(75)
        for fontSizeTemp = 8, 20, 2 do
            fontSizeDropdown:AddItem(fontSizeTemp, tostring(fontSizeTemp) .. " pt")
        end
        fontSizeDropdown:SetCallback("OnValueChanged", function()
            if fontSizeDropdown:GetValue() then
                addon.db.global.fontSize = fontSizeDropdown:GetValue()
            end
        end)
        if addon.db.global.fontSize ~= nil then
            fontSizeDropdown:SetValue(addon.db.global.fontSize)
        end
        container:AddChild(fontSizeDropdown)
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
        elseif group == "globaloption" then
            DrawGlobalOptions(container)
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
        { text = "Global Options", value = "globaloption" },
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
local groupieLDB = LibStub("LibDataBroker-1.1"):NewDataObject("Groupie", {
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
addon.icon = LibStub("LibDBIcon-1.0")
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
            showMinimap = false
        }
    }

    addon.db = LibStub("AceDB-3.0"):New("GroupieDB", defaults)
    addon.icon:Register("Groupie", groupieLDB, addon.db.global.showMinimap)
    if addon.db.global.showMinimap then
        addon.icon:Show()
    else
        addon.icon:Hide()
    end


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
                        type = "header",
                        name = "Groupie | " .. UnitName("player") .. " Options",
                        order = 0,
                    },
                },
            },
        },
    }
    addon.optionsTable = LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options)
    addon.AceConfigDialog = LibStub("AceConfigDialog-3.0")
    addon.AceConfigDialog:AddToBlizOptions(addonName, addonName)
end

--This must be done after player entering world event so that we can pull spec
addon:RegisterEvent("PLAYER_ENTERING_WORLD", addon.SetupConfig)

function addon:OpenConfig()
    InterfaceOptionsFrame_OpenToCategory(addonName)
    -- need to call it a second time as there is a bug where the first time it won't switch !BlizzBugsSuck has a fix
    InterfaceOptionsFrame_OpenToCategory(addonName)
end
