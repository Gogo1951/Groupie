local addonName, Groupie = ...

local addon = LibStub("AceAddon-3.0"):NewAddon(Groupie, addonName,
    "AceEvent-3.0", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")

---------------------
-- AceConfig Setup --
---------------------
local options = {
    name = addonName,
    desc = "Optional description? for the group of options",
    descStyle = "inline",
    icon = "Interface/icons/inv_helmet_50", -- this doesn't seem to show on the top level
    handler = addon,
    type = 'group',
    args = {
        msg = {
            type = 'input',
            name = 'My Message',
            desc = 'The message for my addon',
            set = 'SetMyMessage',
            get = 'GetMyMessage',
            order = 90, -- default is 100 so this will put it at the top of non-ordered ones?
        },
        flag1 = {
            type = 'toggle',
            name = 'First flag for my addon',
            desc = 'This can show as a tooltip for the input?',
            set = 'SetFlag1',
            get = 'GetFlag1',
            width = 'full', -- this keeps the checkboxes on one line each
        },
        flag2 = {
            type = 'toggle',
            name = 'Second flag for my addon',
            desc = 'This can show as a tooltip for the input?',
            set = 'SetFlag2',
            get = 'GetFlag2',
            width = 'full',
        },
        rangetest = {
            type = 'range',
            name = 'Range Test',
            desc = 'A range of values - displayed as a slider?',
            min = 10,
            max = 42,
            step = 1,
            set = function(info, val) addon.db.profile.rangetest = val end,
            get = function(info) return addon.db.profile.rangetest end,
            width = 'double',
            order = 110,
        },
        moreoptions = {
            name = "More options",
            desc = "Description of the other options",
            icon = "Interface/icons/inv_helmet_51",
            type = "group",
            width = "double",
            args = {
                -- more options go here
                --   this post helped http://forums.wowace.com/showthread.php?t=13755
                selecttest = {
                    type = "select",
                    name = "Select Test Greetings",
                    desc = "Should be rendered as a dropdown box?",
                    style = "dropdown",
                    values = { ["A"] = "Hi", ["B"] = "Bye", ["Z"] = "Omega" },
                    set = function(info, val) addon.db.profile.selecttest = val end,
                    get = function(info) return addon.db.profile.selecttest end,
                },
                selectradiotest = {
                    type = "select",
                    name = "Which station?",
                    desc = "Should be rendered as a radiobuttions?",
                    style = "radio",
                    values = { [1] = "107.1", [2] = "Chez 102", [3] = "The Rock" },
                    set = function(info, val) addon.db.profile.selectradiotest = val end,
                    get = function(info) return addon.db.profile.selectradiotest end,
                },
            },
        },
    },
}

local optionsTable = LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options, { "groupiecfg" })
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
function addon:OnEnable()
    -- Called when the addon is enabled
end

function addon:OnDisable()
    -- Called when the addon is disabled
end

-- There is no magic connecting the options and the db.  You need to reference the fields directly in the get and sets.
function addon:GetMyMessage(info)
    return "test message :)"
end

function addon:SetMyMessage(info, input)

end

function addon:GetFlag1(info)
    return addon.db.global.showMinimap
end

function addon:SetFlag1(info, input)
    addon.db.global.showMinimap = not addon.db.global.showMinimap
    print(addon.db.global.showMinimap)
    if addon.db.global.showMinimap then
        addon.icon:Show()
    else
        addon.icon:Hide()
    end
end

function addon:GetFlag2(info)
    return true
end

function addon:SetFlag2(info, input)

end

function addon:OpenConfig()
    InterfaceOptionsFrame_OpenToCategory(addonName)
    -- need to call it a second time as there is a bug where the first time it won't switch !BlizzBugsSuck has a fix
    InterfaceOptionsFrame_OpenToCategory(addonName)
end

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

    --Character Options Tab
    local function DrawCharOptions(container)
        local playerName = UnitName("player")
        local realmName = GetRealmName()
        local spec1 = addon.GetSpecByGroupNum(1)
        local spec2 = addon.GetSpecByGroupNum(2)
        local playerClass = UnitClass("player")

        local tabTitle = AceGUI:Create("Label")
        tabTitle:SetText("Groupie | " .. playerName .. " Options")
        tabTitle:SetColor(0.88, 0.73, 0)
        tabTitle:SetFontObject(GameFontHighlightHuge)
        tabTitle:SetFullWidth(true)
        container:AddChild(tabTitle)

        local spec1Title = AceGUI:Create("Label")
        spec1Title:SetText("Main Spec Role")
        spec1Title:SetFontObject(GameFontNormalMed2)
        spec1Title:SetFullWidth(true)
        container:AddChild(spec1Title)

        local spec1Desc = AceGUI:Create("Label")
        local spec1Name = addon.GetSpecByGroupNum(1)
        spec1Desc:SetText(spec1Name)
        spec1Desc:SetFontObject(GameFontNormal)
        container:AddChild(spec1Desc)
        local spec1Dropdown = AceGUI:Create("Dropdown")
        --Only populate the list with valid roles
        for roleNum = 1, 4 do
            if addon.tableContains(addon.groupieClassRoleTable[playerClass][spec1], roleNum) then
                spec1Dropdown:AddItem(roleNum, addon.groupieRoleTable[roleNum])
            end
        end
        spec1Dropdown:SetWidth(125)
        spec1Dropdown:SetCallback("OnValueChanged", function()
            if spec1Dropdown:GetValue() then
                addon.db.char.groupieSpec1Role = spec1Dropdown:GetValue()
            end
        end)
        if addon.db.char.groupieSpec1Role ~= nil then
            spec1Dropdown:SetValue(addon.db.char.groupieSpec1Role)
        end
        container:AddChild(spec1Dropdown)


        local spec2Title = AceGUI:Create("Label")
        spec2Title:SetText("Alternate Spec Role")
        spec2Title:SetFontObject(GameFontNormalMed2)
        spec2Title:SetFullWidth(true)
        container:AddChild(spec2Title)

        local spec2Desc = AceGUI:Create("Label")
        local spec2Name = addon.GetSpecByGroupNum(2)
        spec2Desc:SetText(spec2Name)
        spec2Desc:SetFontObject(GameFontNormal)
        container:AddChild(spec2Desc)
        local spec2Dropdown = AceGUI:Create("Dropdown")
        --Only populate the list with valid roles
        for roleNum = 1, 4 do
            if addon.tableContains(addon.groupieClassRoleTable[playerClass][spec2], roleNum) then
                spec2Dropdown:AddItem(roleNum, addon.groupieRoleTable[roleNum])
            end
        end
        spec2Dropdown:SetWidth(125)
        spec2Dropdown:SetCallback("OnValueChanged", function()
            if spec2Dropdown:GetValue() then
                addon.db.char.groupieSpec2Role = spec2Dropdown:GetValue()
            end
        end)
        if addon.db.char.groupieSpec2Role ~= nil then
            spec2Dropdown:SetValue(addon.db.char.groupieSpec2Role)
        end
        container:AddChild(spec2Dropdown)


        local recLevelTitle = AceGUI:Create("Label")
        recLevelTitle:SetText("Recommended Dungeon Level Range")
        recLevelTitle:SetFontObject(GameFontNormalMed2)
        recLevelTitle:SetFullWidth(true)
        container:AddChild(recLevelTitle)

        local recLevelDropdown = AceGUI:Create("Dropdown")
        --Only populate the list with valid roles
        recLevelDropdown:AddItem(0, "+0 - I'm new to this")
        recLevelDropdown:AddItem(1, "+1 - I've Done This Before")
        recLevelDropdown:AddItem(2, "+2 - This is a Geared Alt")
        recLevelDropdown:AddItem(3, "+3 - With Heirlooms")
        recLevelDropdown:AddItem(4, "+4 - With Heirlooms & Consumes")
        recLevelDropdown:SetWidth(220)
        recLevelDropdown:SetCallback("OnValueChanged", function()
            if recLevelDropdown:GetValue() then
                addon.db.char.recommendedLevelRange = recLevelDropdown:GetValue()
            end
        end)
        if addon.db.char.recommendedLevelRange ~= nil then
            recLevelDropdown:SetValue(addon.db.char.recommendedLevelRange)
        end
        container:AddChild(recLevelDropdown)

        local autoResponseTitle = AceGUI:Create("Label")
        autoResponseTitle:SetText("Groupie Auto-Response")
        autoResponseTitle:SetFontObject(GameFontNormalMed2)
        autoResponseTitle:SetFullWidth(true)
        container:AddChild(autoResponseTitle)

        local autoRespFriendsBox = AceGUI:Create("CheckBox")
        autoRespFriendsBox:SetLabel("Enable Auto-Respond to Friends")
        autoRespFriendsBox:SetFullWidth(true)
        autoRespFriendsBox:SetValue(addon.db.char.autoRespondFriends)
        autoRespFriendsBox:SetCallback("OnValueChanged", function()
            addon.db.char.autoRespondFriends = autoRespFriendsBox:GetValue()
        end)
        container:AddChild(autoRespFriendsBox)

        local autoRespGuildBox = AceGUI:Create("CheckBox")
        autoRespGuildBox:SetLabel("Enable Auto-Respond to Guild Members")
        autoRespGuildBox:SetFullWidth(true)
        autoRespGuildBox:SetValue(addon.db.char.autoRespondGuild)
        autoRespGuildBox:SetCallback("OnValueChanged", function()
            addon.db.char.autoRespondGuild = autoRespGuildBox:GetValue()
        end)
        container:AddChild(autoRespGuildBox)

        local afterPartyTitle = AceGUI:Create("Label")
        afterPartyTitle:SetText("Groupie After-Party Tool")
        afterPartyTitle:SetFontObject(GameFontNormalMed2)
        afterPartyTitle:SetFullWidth(true)
        container:AddChild(afterPartyTitle)

        local afterPartyBox = AceGUI:Create("CheckBox")
        afterPartyBox:SetLabel("Enable Groupie After-Party Tool")
        afterPartyBox:SetFullWidth(true)
        afterPartyBox:SetValue(addon.db.char.afterParty)
        afterPartyBox:SetCallback("OnValueChanged", function()
            addon.db.char.afterParty = afterPartyBox:GetValue()
        end)
        container:AddChild(afterPartyBox)

        local groupChannelsTitle = AceGUI:Create("Label")
        groupChannelsTitle:SetText("Pull Groups from Available Channels")
        groupChannelsTitle:SetFontObject(GameFontNormalMed2)
        groupChannelsTitle:SetFullWidth(true)
        container:AddChild(groupChannelsTitle)

        local channelGuildBox = AceGUI:Create("CheckBox")
        channelGuildBox:SetLabel("Guild")
        channelGuildBox:SetValue(addon.db.char.useChannels["Guild"])
        channelGuildBox:SetCallback("OnValueChanged", function()
            addon.db.char.useChannels["Guild"] = channelGuildBox:GetValue()
        end)
        container:AddChild(channelGuildBox)

        local channelGeneralBox = AceGUI:Create("CheckBox")
        channelGeneralBox:SetLabel("General")
        channelGeneralBox:SetValue(addon.db.char.useChannels["General"])
        channelGeneralBox:SetCallback("OnValueChanged", function()
            addon.db.char.useChannels["General"] = channelGeneralBox:GetValue()
        end)
        container:AddChild(channelGeneralBox)

        local channelTradeBox = AceGUI:Create("CheckBox")
        channelTradeBox:SetLabel("Trade")
        channelTradeBox:SetValue(addon.db.char.useChannels["Trade"])
        channelTradeBox:SetCallback("OnValueChanged", function()
            addon.db.char.useChannels["Trade"] = channelTradeBox:GetValue()
        end)
        container:AddChild(channelTradeBox)

        local channelLocDefBox = AceGUI:Create("CheckBox")
        channelLocDefBox:SetLabel("LocalDefense")
        channelLocDefBox:SetValue(addon.db.char.useChannels["LocalDefense"])
        channelLocDefBox:SetCallback("OnValueChanged", function()
            addon.db.char.useChannels["LocalDefense"] = channelLocDefBox:GetValue()
        end)
        container:AddChild(channelLocDefBox)

        local channelLFGBox = AceGUI:Create("CheckBox")
        channelLFGBox:SetLabel("LookingForGroup")
        channelLFGBox:SetValue(addon.db.char.useChannels["LookingForGroup"])
        channelLFGBox:SetCallback("OnValueChanged", function()
            addon.db.char.useChannels["LookingForGroup"] = channelLFGBox:GetValue()
        end)
        container:AddChild(channelLFGBox)

        local channel5Box = AceGUI:Create("CheckBox")
        channel5Box:SetLabel("5")
        channel5Box:SetValue(addon.db.char.useChannels["5"])
        channel5Box:SetCallback("OnValueChanged", function()
            addon.db.char.useChannels["5"] = channel5Box:GetValue()
        end)
        container:AddChild(channel5Box)

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
        elseif group == "charoption" then
            DrawCharOptions(container)
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
        { text = "Character Options", value = "charoption" },
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
    AceConfigDialog:AddToBlizOptions(addonName, "Groupie")
    addon.debugMenus = true
    --Setup Slash Command
    SLASH_GROUPIE1, SLASH_GROUPIE2 = "/groupie"
    SlashCmdList["GROUPIE"] = BuildGroupieWindow
    addon.isInitialized = true
end
