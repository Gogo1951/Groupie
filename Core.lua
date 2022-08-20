local AceGUI = LibStub("AceGUI-3.0")

local function BuildGroupieWindow()
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
        local desc = AceGUI:Create("Label")
        desc:SetText("Character options tab.")
        container:AddChild(desc)
    end

    --Global Options Tab
    local function DrawGlobalOptions(container)
        local desc = AceGUI:Create("Label")
        desc:SetText("Global options tab.")
        container:AddChild(desc)
    end

    --About Tab
    local function DrawAbout(container)
        local desc = AceGUI:Create("Label")
        desc:SetText("About tab.")
        container:AddChild(desc)
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
    frame:SetStatusText("Groupie LFG - Party Listing")
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    frame:SetLayout("Fill")

    --Creating Tabgroup
    local tab =  AceGUI:Create("TabGroup")
    tab:SetLayout("Flow")
    tab:SetTabs({{text="Groupie", value="maintab"},
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
end

SLASH_GROUPIE1, SLASH_GROUPIE2= "/groupie", "/groupielfg"
SlashCmdList["GROUPIE"] = BuildGroupieWindow
