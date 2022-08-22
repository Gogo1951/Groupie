local AceGUI = LibStub("AceGUI-3.0")
local AceAddon = LibStub("AceAddon-3.0"):NewAddon("Groupie", "AceConsole-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")
GroupieLFG = {}

local function BuildOptionsTable()
    if groupielfg_db == nil then
        --Character Options
        groupielfg_db = {}
        groupielfg_db.groupieSpec1Role = nil
        groupielfg_db.groupieSpec2Role = nil
        groupielfg_db.recommendedLevelRange = 1
        groupielfg_db.autoRespondFriends = false
        groupielfg_db.autoRespondGuild = false
        groupielfg_db.afterParty = true
        groupielfg_db.useChannels = {
            ["Guild"] = true,
            ["General"] = true,
            ["Trade"] = true,
            ["LocalDefense"] = true,
            ["LookingForGroup"] = true,
            ["5"] = true,
        }
    end

    --Global Options
    if groupielfg_global == nil then
        groupielfg_global = {}
        groupielfg_global.preserveData = true
        groupielfg_global.minsToPreserve = 2
        groupielfg_global.font = "Arial Narrow"
        groupielfg_global.fontSize = 8
    end
end


local function BuildGroupieWindow()
    --Dont open a new frame if already open
    if 
    GroupieLFG._frame and GroupieLFG._frame.frame:IsShown() then
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
        local spec1 = GetSpecByGroupNum(1)
        local spec2 = GetSpecByGroupNum(2)
        local playerClass = UnitClass("player")

        local tabTitle = AceGUI:Create("Label")
        tabTitle:SetText("Groupie LFG | "..playerName.." Options")
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
        local spec1Name = GetSpecByGroupNum(1)
        spec1Desc:SetText(spec1Name)
        spec1Desc:SetFontObject(GameFontNormal)
        container:AddChild(spec1Desc)
        local spec1Dropdown = AceGUI:Create("Dropdown")
        --Only populate the list with valid roles
        for roleNum = 1, 4 do
            if tableContains(groupieClassRoleTable[playerClass][spec1], roleNum) then
                spec1Dropdown:AddItem(roleNum, groupieRoleTable[roleNum])
            end
        end
        spec1Dropdown:SetWidth(125)
        spec1Dropdown:SetCallback("OnValueChanged", function()
            if spec1Dropdown:GetValue() then
                groupielfg_db.groupieSpec1Role = spec1Dropdown:GetValue()
            end
        end)
        if groupielfg_db.groupieSpec1Role ~= nil then
            spec1Dropdown:SetValue(groupielfg_db.groupieSpec1Role)
        end
        container:AddChild(spec1Dropdown)


        local spec2Title = AceGUI:Create("Label")
        spec2Title:SetText("Alternate Spec Role")
        spec2Title:SetFontObject(GameFontNormalMed2)
        spec2Title:SetFullWidth(true)
        container:AddChild(spec2Title)

        local spec2Desc = AceGUI:Create("Label")
        local spec2Name = GetSpecByGroupNum(2)
        spec2Desc:SetText(spec2Name)
        spec2Desc:SetFontObject(GameFontNormal)
        container:AddChild(spec2Desc)
        local spec2Dropdown = AceGUI:Create("Dropdown")
        --Only populate the list with valid roles
        for roleNum = 1, 4 do
            if tableContains(groupieClassRoleTable[playerClass][spec2], roleNum) then
                spec2Dropdown:AddItem(roleNum, groupieRoleTable[roleNum])
            end
        end
        spec2Dropdown:SetWidth(125)
        spec2Dropdown:SetCallback("OnValueChanged", function()
            if spec2Dropdown:GetValue() then
                groupielfg_db.groupieSpec2Role = spec2Dropdown:GetValue()
            end
        end)
        if groupielfg_db.groupieSpec2Role ~= nil then
            spec2Dropdown:SetValue(groupielfg_db.groupieSpec2Role)
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
                groupielfg_db.recommendedLevelRange = recLevelDropdown:GetValue()
            end
        end)
        if groupielfg_db.recommendedLevelRange ~= nil then
            recLevelDropdown:SetValue(groupielfg_db.recommendedLevelRange)
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
        autoRespFriendsBox:SetValue(groupielfg_db.autoRespondFriends)
        autoRespFriendsBox:SetCallback("OnValueChanged", function()
            groupielfg_db.autoRespondFriends = autoRespFriendsBox:GetValue()
        end)
        container:AddChild(autoRespFriendsBox)

        local autoRespGuildBox = AceGUI:Create("CheckBox")
        autoRespGuildBox:SetLabel("Enable Auto-Respond to Guild Members")
        autoRespGuildBox:SetFullWidth(true)
        autoRespGuildBox:SetValue(groupielfg_db.autoRespondGuild)
        autoRespGuildBox:SetCallback("OnValueChanged", function()
            groupielfg_db.autoRespondGuild = autoRespGuildBox:GetValue()
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
        afterPartyBox:SetValue(groupielfg_db.afterParty)
        afterPartyBox:SetCallback("OnValueChanged", function()
            groupielfg_db.afterParty = afterPartyBox:GetValue()
        end)
        container:AddChild(afterPartyBox)

        local groupChannelsTitle = AceGUI:Create("Label")
        groupChannelsTitle:SetText("Pull Groups from Available Channels")
        groupChannelsTitle:SetFontObject(GameFontNormalMed2)
        groupChannelsTitle:SetFullWidth(true)
        container:AddChild(groupChannelsTitle)

        local channelGuildBox = AceGUI:Create("CheckBox")
        channelGuildBox:SetLabel("Guild")
        channelGuildBox:SetValue(groupielfg_db.useChannels["Guild"])
        channelGuildBox:SetCallback("OnValueChanged", function()
            groupielfg_db.useChannels["Guild"] = channelGuildBox:GetValue()
        end)
        container:AddChild(channelGuildBox)

        local channelGeneralBox = AceGUI:Create("CheckBox")
        channelGeneralBox:SetLabel("General")
        channelGeneralBox:SetValue(groupielfg_db.useChannels["General"])
        channelGeneralBox:SetCallback("OnValueChanged", function()
            groupielfg_db.useChannels["General"] = channelGeneralBox:GetValue()
        end)
        container:AddChild(channelGeneralBox)

        local channelTradeBox = AceGUI:Create("CheckBox")
        channelTradeBox:SetLabel("Trade")
        channelTradeBox:SetValue(groupielfg_db.useChannels["Trade"])
        channelTradeBox:SetCallback("OnValueChanged", function()
            groupielfg_db.useChannels["Trade"] = channelTradeBox:GetValue()
        end)
        container:AddChild(channelTradeBox)

        local channelLocDefBox = AceGUI:Create("CheckBox")
        channelLocDefBox:SetLabel("LocalDefense")
        channelLocDefBox:SetValue(groupielfg_db.useChannels["LocalDefense"])
        channelLocDefBox:SetCallback("OnValueChanged", function()
            groupielfg_db.useChannels["LocalDefense"] = channelLocDefBox:GetValue()
        end)
        container:AddChild(channelLocDefBox)

        local channelLFGBox = AceGUI:Create("CheckBox")
        channelLFGBox:SetLabel("LookingForGroup")
        channelLFGBox:SetValue(groupielfg_db.useChannels["LookingForGroup"])
        channelLFGBox:SetCallback("OnValueChanged", function()
            groupielfg_db.useChannels["LookingForGroup"] = channelLFGBox:GetValue()
        end)
        container:AddChild(channelLFGBox)

        local channel5Box = AceGUI:Create("CheckBox")
        channel5Box:SetLabel("5")
        channel5Box:SetValue(groupielfg_db.useChannels["5"])
        channel5Box:SetCallback("OnValueChanged", function()
            groupielfg_db.useChannels["5"] = channel5Box:GetValue()
        end)
        container:AddChild(channel5Box)
        
    end

    --Global Options Tab
    local function DrawGlobalOptions(container)
        local tabTitle = AceGUI:Create("Label")
        tabTitle:SetText("Groupie LFG | Global Options")
        tabTitle:SetColor(0.88, 0.73, 0)
        tabTitle:SetFontObject(GameFontHighlightHuge)
        tabTitle:SetFullWidth(true)
        container:AddChild(tabTitle)

        local preserveBox = AceGUI:Create("CheckBox")
        preserveBox:SetLabel("Enable Auto-Respond to Guild Members")
        preserveBox:SetFullWidth(true)
        preserveBox:SetValue(groupielfg_global.preserveData)
        preserveBox:SetCallback("OnValueChanged", function()
            groupielfg_global.preserveData = preserveBox:GetValue()
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
            preserveDropdown:AddItem(durationTemp, tostring(durationTemp).." Minutes")
        end
        preserveDropdown:SetCallback("OnValueChanged", function()
            if preserveDropdown:GetValue() then
                groupielfg_global.minsToPreserve = preserveDropdown:GetValue()
            end
        end)
        if groupielfg_global.minsToPreserve ~= nil then
            preserveDropdown:SetValue(groupielfg_global.minsToPreserve)
        end
        container:AddChild(preserveDropdown)

        local fontTitle = AceGUI:Create("Label")
        fontTitle:SetText("Font")
        fontTitle:SetFontObject(GameFontNormalMed2)
        fontTitle:SetFullWidth(true)
        container:AddChild(fontTitle)

        local fontDropdown = AceGUI:Create("Dropdown")
        fontDropdown:SetWidth(250)
        for key,val in pairs(SharedMedia:HashTable("font")) do
            fontDropdown:AddItem(key, key)
        end
        fontDropdown:SetCallback("OnValueChanged", function()
            if fontDropdown:GetValue() then
                groupielfg_global.font = fontDropdown:GetValue()
            end
        end)
        if groupielfg_global.font ~= nil then
            fontDropdown:SetValue(groupielfg_global.font)
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
            fontSizeDropdown:AddItem(fontSizeTemp, tostring(fontSizeTemp).." pt")
        end
        fontSizeDropdown:SetCallback("OnValueChanged", function()
            if fontSizeDropdown:GetValue() then
                groupielfg_global.fontSize = fontSizeDropdown:GetValue()
            end
        end)
        if groupielfg_global.fontSize ~= nil then
            fontSizeDropdown:SetValue(groupielfg_global.fontSize)
        end
        container:AddChild(fontSizeDropdown)
    end

    --About Tab
    local function DrawAbout(container)
        local tabTitle = AceGUI:Create("Label")
        tabTitle:SetText("Groupie LFG | About")
        tabTitle:SetColor(0.88, 0.73, 0)
        tabTitle:SetFontObject(GameFontHighlightHuge)
        tabTitle:SetFullWidth(true)
        container:AddChild(tabTitle)
        

        local curseLabel = AceGUI:Create("Label")
        curseLabel:SetText("Groupie LFG on CurseForge")
        curseLabel:SetFullWidth(true)
        container:AddChild(curseLabel)
        local curseEditBox = AceGUI:Create("EditBox")
        curseEditBox:SetText("https://www.curseforge.com/wow/addons/groupie-lfg")
        curseEditBox:DisableButton(true)
        curseEditBox:SetWidth(350)
        curseEditBox:SetCallback("OnTextChanged", function()
            curseEditBox:SetText("https://www.curseforge.com/wow/addons/groupie-lfg")
        end)
        curseEditBox:SetCallback("OnEnterPressed", function()
            curseEditBox.editbox:ClearFocus()
        end)
        curseEditBox.editbox:SetScript("OnCursorChanged", function()
            curseEditBox:HighlightText()
        end)
        container:AddChild(curseEditBox)

        local discordLabel = AceGUI:Create("Label")
        discordLabel:SetText("Groupie LFG on Discord")
        discordLabel:SetFullWidth(true)
        container:AddChild(discordLabel)
        local discordEditBox = AceGUI:Create("EditBox")
        discordEditBox:SetText("https://discord.gg/6xccnxcRbt")
        discordEditBox:DisableButton(true)
        discordEditBox:SetWidth(350)
        discordEditBox:SetCallback("OnTextChanged", function()
            discordEditBox:SetText("https://discord.gg/6xccnxcRbt")
        end)
        discordEditBox:SetCallback("OnEnterPressed", function()
            discordEditBox.editbox:ClearFocus()
        end)
        discordEditBox.editbox:SetScript("OnCursorChanged", function()
            discordEditBox:HighlightText()
        end)
        container:AddChild(discordEditBox)
        
        local githubLabel = AceGUI:Create("Label")
        githubLabel:SetText("Groupie LFG on GitHub")
        githubLabel:SetFullWidth(true)
        container:AddChild(githubLabel)
        local githubEditBox = AceGUI:Create("EditBox")
        githubEditBox:SetText("https://github.com/Gogo1951/Groupie-LFG")
        githubEditBox:DisableButton(true)
        githubEditBox:SetWidth(350)
        githubEditBox:SetCallback("OnTextChanged", function()
            githubEditBox:SetText("https://github.com/Gogo1951/Groupie-LFG")
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
    frame:SetTitle("Groupie LFG")
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    frame:SetLayout("Fill")

    --Creating Tabgroup
    local tab = AceGUI:Create("TabGroup")
    tab:SetLayout("Flow")
    tab:SetTabs({{text="Groupie LFG", value="maintab"},
        {text="Group Builder", value="groupbuilder"},
        {text="Group Filters", value="groupfilter"},
        {text="Instance Filters", value="instancefilter"},
        {text="Character Options", value="charoption"},
        {text="Global Options", value="globaloption"},
        {text="About", value="about"}
    })
    tab:SetCallback("OnGroupSelected", SelectGroup)
    tab:SelectTab("maintab")
    frame:AddChild(tab)

    --Allow the frame to close when ESC is pressed
    _G["GroupieFrame"] = frame.frame
    tinsert(UISpecialFrames, "GroupieFrame")
    --Store a global reference to the frame
    GroupieLFG._frame = frame
end


--Minimap Icon Creation
local groupieLDB = LibStub("LibDataBroker-1.1"):NewDataObject("Groupie", {
    type = "data source",
    text = "Groupie",
    icon = "Interface\\AddOns\\Groupie-LFG\\Images\\icon32.blp",
    OnClick = BuildGroupieWindow,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Groupie LFG")
        tooltip:AddLine("A better LFG tool for Classic WoW.", 255, 255, 255, false)
        tooltip:AddLine("Click to open Groupie", 255, 255, 255, false)
    end
})
local icon = LibStub("LibDBIcon-1.0")


--Load minimap icon and saved options
function AceAddon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("GroupieDB", { profile = { minimap = { hide = false, }, }, }) 
    icon:Register("Groupie", groupieLDB, self.db.profile.minimap)
    BuildOptionsTable()
end

--Setup Slash Command
SLASH_GROUPIE1, SLASH_GROUPIE2= "/groupie", "/groupielfg"
SlashCmdList["GROUPIE"] = BuildGroupieWindow
