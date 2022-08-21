local AceGUI = LibStub("AceGUI-3.0")
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
BuildOptionsTable()

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

        local tabTitle = AceGUI:Create("Label")
        tabTitle:SetText("Groupie-LFG | "..playerName.." Options")
        tabTitle:SetFontObject(GameFontHighlightHuge)
        tabTitle:SetFullWidth(true)
        container:AddChild(tabTitle)

        local spec1Title = AceGUI:Create("Label")
        spec1Title:SetText("Main Spec Role")
        spec1Title:SetFontObject(GameFontHighlightLarge)
        spec1Title:SetFullWidth(true)
        container:AddChild(spec1Title)

        local spec1Desc = AceGUI:Create("Label")
        local spec1Name = GetSpecByGroupNum(1)
        spec1Desc:SetText(spec1Name)
        spec1Desc:SetFontObject(GameFontHighlight)
        container:AddChild(spec1Desc)
        local spec1Dropdown = AceGUI:Create("Dropdown")
        spec1Dropdown:AddItem(1, "Tank")
        spec1Dropdown:AddItem(2, "Healer")
        spec1Dropdown:AddItem(3, "DPS")
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
        spec2Title:SetFontObject(GameFontHighlightLarge)
        spec2Title:SetFullWidth(true)
        container:AddChild(spec2Title)

        local spec2Desc = AceGUI:Create("Label")
        local spec2Name = GetSpecByGroupNum(2)
        spec2Desc:SetText(spec2Name)
        spec2Desc:SetFontObject(GameFontHighlight)
        container:AddChild(spec2Desc)
        local spec2Dropdown = AceGUI:Create("Dropdown")
        spec2Dropdown:AddItem(1, "Tank")
        spec2Dropdown:AddItem(2, "Healer")
        spec2Dropdown:AddItem(3, "DPS")
        spec2Dropdown:SetCallback("OnValueChanged", function()
            if spec2Dropdown:GetValue() then
                groupielfg_db.groupieSpec2Role = spec2Dropdown:GetValue()
            end
        end)
        if groupielfg_db.groupieSpec2Role ~= nil then
            spec2Dropdown:SetValue(groupielfg_db.groupieSpec2Role)
        end
        container:AddChild(spec2Dropdown)
    end

    --Global Options Tab
    local function DrawGlobalOptions(container)
        local desc = AceGUI:Create("Label")
        desc:SetText("Global options tab.")
        container:AddChild(desc)
    end

    --About Tab
    local function DrawAbout(container)
        local tabTitle = AceGUI:Create("Label")
        tabTitle:SetText("Groupie-LFG | About")
        tabTitle:SetFontObject(GameFontHighlightHuge)
        tabTitle:SetFullWidth(true)
        container:AddChild(tabTitle)
        

        local curseLabel = AceGUI:Create("Label")
        curseLabel:SetText("Groupie-LFG on CurseForge")
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
        discordLabel:SetText("Groupie-LFG on Discord")
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
        githubLabel:SetText("Groupie-LFG on GitHub")
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
    frame:SetTitle("Groupie-LFG")
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    frame:SetLayout("Fill")

    --Creating Tabgroup
    local tab = AceGUI:Create("TabGroup")
    tab:SetLayout("Flow")
    tab:SetTabs({{text="Groupie-LFG", value="maintab"},
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

SLASH_GROUPIE1, SLASH_GROUPIE2= "/groupie", "/groupielfg"
SlashCmdList["GROUPIE"] = BuildGroupieWindow
