local addonName, Groupie = ...
--Main UI variables
local GroupieFrame       = nil
local MainTabFrame       = nil
local columnCount        = 0
local LFGScrollFrame     = nil
local WINDOW_WIDTH       = 1200
local WINDOW_HEIGHT      = 719
local WINDOW_OFFSET      = 113
local BUTTON_HEIGHT      = 30
local BUTTON_TOTAL       = math.floor((WINDOW_HEIGHT - WINDOW_OFFSET) / BUTTON_HEIGHT)
local BUTTON_WIDTH       = WINDOW_WIDTH - 44
local COL_TIME           = 75
local COL_LEADER         = 100
local COL_INSTANCE       = 175
local COL_LOOT           = 76
local COL_MSG            = WINDOW_WIDTH - COL_TIME - COL_LEADER - COL_INSTANCE - COL_LOOT - 44


local addon = LibStub("AceAddon-3.0"):NewAddon(Groupie, addonName, "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0")

local SharedMedia         = LibStub("LibSharedMedia-3.0")
local gsub                = gsub
addon.groupieBoardButtons = {}
addon.filteredListings    = {}
addon.selectedListing     = nil

IgnoreListButtonMixin = {}
function IgnoreListButtonMixin:OnClick()
    return
end

--------------------
-- User Interface --
--------------------
--Create a numerically indexed table of listings for use in the scroller
local function filterListings()
    addon.filteredListings = {}
    local idx = 1
    local total = 0
    if MainTabFrame.isOther then
        for author, listing in pairs(addon.db.global.listingTable) do
            if (MainTabFrame.isOther and listing.lootType ~= "Other") then
                --Wrong tab
                --Other tab shows groups with 'other' loot type, and 40 man raids
                --Loot type filters therefore dont apply to this tab
            elseif addon.db.global.ignoreWrongLvl ~= false and listing.minLevel and
                listing.minLevel > (UnitLevel("player") + addon.db.char.recommendedLevelRange) then
            elseif addon.db.global.ignoreWrongLvl ~= false and listing.maxLevel and
                listing.maxLevel < UnitLevel("player") then
                --Instance is outside of level range
            elseif addon.db.global.ignoreLFM and listing.isLFM then
                --Ignoring LFM groups
            elseif addon.db.global.ignoreLFG and listing.isLFG then
                --Ignoring LFG groups
            elseif addon.db.global.ignoreWrongRole and
                (not addon.tableContains(listing.rolesNeeded, addon.db.char.groupieSpec1Role) and
                    not addon.tableContains(listing.rolesNeeded, addon.db.char.groupieSpec2Role)) then
                --Roles the player can play arent needed
            elseif addon.db.global.ignoreAmbiguousLanguage and listing.language ~= addon.groupieLocaleTable[GetLocale()] then
                --Ignoring groups not explicitly labeled with player's language
            elseif addon.db.char.hideInstances[listing.order] == true then
                --Ignoring specifically hidden instances
            else
                local keywordBlacklistHit = false
                for k, word in pairs(addon.db.global.keywordBlacklist) do
                    if addon.tableContains(listing.words, word) then
                        keywordBlacklistHit = true
                    end
                end
                if not keywordBlacklistHit then
                    addon.filteredListings[idx] = listing
                    idx = idx + 1
                end
            end
            total = total + 1
        end
        MainTabFrame.infotext:SetText(format(
            "Showing %d of %d possible groups. To see more groups adjust your [Group Filters] or [Instance Filters] under Groupie > Settings."
            , idx - 1, total))
    else
        for author, listing in pairs(addon.db.global.listingTable) do
            if listing.isHeroic ~= MainTabFrame.isHeroic and not MainTabFrame.isOther then
                --Wrong tab
            elseif listing.groupSize ~= MainTabFrame.size then
                --Wrong tab
            elseif listing.lootType == "Other" then
                --Only show these groups in 'Other' tab
            elseif addon.db.global.ignoreWrongLvl ~= false and listing.minLevel and
                listing.minLevel > (UnitLevel("player") + addon.db.char.recommendedLevelRange) then
            elseif addon.db.global.ignoreWrongLvl ~= false and listing.maxLevel and
                listing.maxLevel < UnitLevel("player") then
                --Instance is outside of level range
            elseif addon.db.global.ignoreLFM and listing.isLFM then
                --Ignoring LFM groups
            elseif addon.db.global.ignoreLFG and listing.isLFG then
                --Ignoring LFG groups
            elseif addon.db.global.ignoreGDKP and listing.lootType == "GDKP" then
            elseif addon.db.global.ignoreTicket and listing.lootType == "Ticket" then
            elseif addon.db.global.ignoreMSOS and listing.lootType == "MS > OS" then
            elseif addon.db.global.ignoreSoftRes and listing.lootType == "SoftRes" then
                --Ignoring certain loot styles
            elseif addon.db.global.ignoreWrongRole and
                (not addon.tableContains(listing.rolesNeeded, addon.db.char.groupieSpec1Role) and
                    not addon.tableContains(listing.rolesNeeded, addon.db.char.groupieSpec2Role)) then
                --Roles the player can play arent needed
            elseif addon.db.global.ignoreAmbiguousLanguage and listing.language ~= addon.groupieLocaleTable[GetLocale()] then
                --Ignoring groups not explicitly labeled with player's language
            elseif addon.db.char.hideInstances[listing.order] == true then
                --Ignoring specifically hidden instances
            else
                local keywordBlacklistHit = false
                for k, word in pairs(addon.db.global.keywordBlacklist) do
                    if addon.tableContains(listing.words, word) then
                        keywordBlacklistHit = true
                    end
                end
                if not keywordBlacklistHit then
                    addon.filteredListings[idx] = listing
                    idx = idx + 1
                end
            end
            total = total + 1
        end
        MainTabFrame.infotext:SetText(format(
            "Showing %d of %d possible groups. To see more groups adjust your [Group Filters] or [Instance Filters] under Groupie > Settings."
            , idx - 1, total))
    end
end

--Apply filters and draw matching listings in the LFG board
local function DrawListings(self)
    --Create a numerical index for use populating the table
    filterListings()

    FauxScrollFrame_Update(self, #addon.filteredListings, BUTTON_TOTAL, BUTTON_HEIGHT)

    if addon.selectedListing then
        if addon.selectedListing > #addon.filteredListings then
            addon.selectedListing = nil
        end
    end

    local offset = FauxScrollFrame_GetOffset(self)

    local idx = 0
    for btnNum = 1, BUTTON_TOTAL do
        idx = btnNum + offset
        local button = addon.groupieBoardButtons[btnNum]
        local listing = addon.filteredListings[idx]
        if idx <= #addon.filteredListings then
            if btnNum == addon.selectedListing then
                button:LockHighlight()
            else
                button:UnlockHighlight()
            end
            button.listing = listing
            button.time:SetText(addon.GetTimeSinceString(listing.timestamp))
            button.leader:SetText(gsub(listing.author, "-.+", ""))
            button.instance:SetText(listing.instanceName)
            button.loot:SetText(listing.lootType)
            button.msg:SetText(gsub(gsub(listing.msg, "%{%w+%}", ""), "%s+", " "))
            button:SetID(idx)
            button:Show()
            btnNum = btnNum + 1
        else
            button:Hide()
        end
    end

    --Hide remaining buttons?
    --update every 1sec?
    --ensure select works right
end

--Onclick for group listings, highlights the selected listing
local function ListingOnClick(self, button, down)
    if button == "LeftButton" then
        if addon.selectedListing then
            addon.groupieBoardButtons[addon.selectedListing]:UnlockHighlight()
        end
        addon.selectedListing = self.id
        addon.groupieBoardButtons[addon.selectedListing]:LockHighlight()
        DrawListings(LFGScrollFrame)
        if addon.debugMenus then
            print(addon.selectedListing)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.author)
        end
    end
end

--Create entries in the LFG board for each group listing
local function CreateListingButtons()
    addon.groupieBoardButtons = {}
    local currentListing
    for listcount = 1, BUTTON_TOTAL do
        addon.groupieBoardButtons[listcount] = CreateFrame(
            "Button",
            "ListingBtn" .. tostring(listcount),
            LFGScrollFrame:GetParent(),
            "IgnoreListButtonTemplate"
        )
        currentListing = addon.groupieBoardButtons[listcount]
        if listcount == 1 then
            currentListing:SetPoint("TOPLEFT", LFGScrollFrame, -1, 0)
        else
            currentListing:SetPoint("TOP", addon.groupieBoardButtons[listcount - 1], "BOTTOM", 0, 0)
        end
        currentListing:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
        currentListing:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        currentListing:SetScript("OnClick", ListingOnClick)

        --Time column
        currentListing.time:SetWidth(COL_TIME)

        --Leader name column
        currentListing.leader = currentListing:CreateFontString("FontString", "OVERLAY", "GameFontNormal")
        currentListing.leader:SetPoint("LEFT", currentListing.time, "RIGHT", 0, 0)
        currentListing.leader:SetWidth(COL_LEADER)
        currentListing.leader:SetJustifyH("LEFT")
        currentListing.leader:SetJustifyV("MIDDLE")

        --Instance name column
        currentListing.instance = currentListing:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
        currentListing.instance:SetPoint("LEFT", currentListing.leader, "RIGHT", 0, 0)
        currentListing.instance:SetWidth(COL_INSTANCE)
        currentListing.instance:SetJustifyH("LEFT")
        currentListing.instance:SetJustifyV("MIDDLE")

        --Loot type column
        currentListing.loot = currentListing:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
        currentListing.loot:SetPoint("LEFT", currentListing.instance, "RIGHT", 2, 0)
        currentListing.loot:SetWidth(COL_LOOT)
        currentListing.loot:SetJustifyH("LEFT")
        currentListing.loot:SetJustifyV("MIDDLE")
        currentListing.loot:SetTextColor(0, 173, 239)

        --Posting message column
        currentListing.msg = currentListing:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
        currentListing.msg:SetPoint("LEFT", currentListing.loot, "RIGHT", -4, 0)
        currentListing.msg:SetWidth(COL_MSG)
        currentListing.msg:SetJustifyH("LEFT")
        currentListing.msg:SetJustifyV("MIDDLE")
        currentListing.msg:SetWordWrap(true)
        currentListing.msg:SetMaxLines(2)

        currentListing.id = listcount
        listcount = listcount + 1
    end
    DrawListings(LFGScrollFrame)
end

--Create column headers for the main tab
local function createColumn(text, width, parent)
    columnCount = columnCount + 1
    local Header = CreateFrame("Button", parent:GetName() .. "Header" .. columnCount, parent,
        "WhoFrameColumnHeaderTemplate")
    Header:SetWidth(width)
    _G[parent:GetName() .. "Header" .. columnCount .. "Middle"]:SetWidth(width - 9)
    Header:SetText(text)
    Header:SetNormalFontObject("GameFontHighlight")
    Header:SetID(columnCount)

    if columnCount == 1 then
        Header:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, 22)
    else
        Header:SetPoint("LEFT", parent:GetName() .. "Header" .. columnCount - 1, "RIGHT", 0, 0)
    end
    Header:SetScript("OnClick", function() return end)
end

--Listing update timer
function addon.TimerListingUpdate()
    if not addon.lastUpdate then
        addon.lastUpdate = time()
    end

    if time() - addon.lastUpdate > 1 then
        DrawListings(LFGScrollFrame)
    end
end

--Set environment variables when switching group tabs
function addon.TabSwap(isHeroic, size, isOther, tabNum)
    addon.ExpireListings()
    MainTabFrame:Show()
    MainTabFrame.isHeroic = isHeroic
    MainTabFrame.size = size
    MainTabFrame.isOther = isOther
    if addon.selectedListing then
        addon.groupieBoardButtons[addon.selectedListing]:UnlockHighlight()
    end
    addon.selectedListing = nil
    DrawListings(LFGScrollFrame)
    PanelTemplates_SetTab(GroupieFrame, tabNum)
end

--Build and show the main LFG board window
local function BuildGroupieWindow()
    if GroupieFrame ~= nil then
        addon.ExpireListings()
        GroupieFrame:Show()
        return
    end

    --------------
    --Main Frame--
    --------------
    GroupieFrame = CreateFrame("Frame", "Groupie", UIParent, "PortraitFrameTemplate")
    GroupieFrame:Hide()
    --Allow the frame to close when ESC is pressed
    tinsert(UISpecialFrames, "Groupie")
    --Store reference to frame
    addon._frame = GroupieFrame
    GroupieFrame:SetFrameStrata("DIALOG")
    GroupieFrame:SetWidth(WINDOW_WIDTH)
    GroupieFrame:SetHeight(WINDOW_HEIGHT)
    GroupieFrame:SetPoint("CENTER", UIParent)
    GroupieFrame:SetMovable(true)
    GroupieFrame:EnableMouse(true)
    GroupieFrame:RegisterForDrag("LeftButton", "RightButton")
    GroupieFrame:SetClampedToScreen(true)
    GroupieFrame.title = _G["GroupieTitleText"]
    GroupieFrame.title:SetText("Groupie")
    GroupieFrame:SetScript("OnMouseDown",
        function(self)
            self:StartMoving()
            self.isMoving = true
        end)
    GroupieFrame:SetScript("OnMouseUp",
        function(self)
            if self.isMoving then
                self:StopMovingOrSizing()
                self.isMoving = false
            end
        end)
    GroupieFrame:SetScript("OnShow", function() return end)

    --------
    --Icon--
    --------
    local icon = GroupieFrame:CreateTexture("$parentIcon", "OVERLAY", nil, -8)
    icon:SetSize(60, 60)
    icon:SetPoint("TOPLEFT", -5, 7)
    icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Images\\icon64.tga")

    ------------------------
    --Category Tab Buttons--
    ------------------------
    local DungeonTabButton = CreateFrame("Button", "GroupieTab1", GroupieFrame, "CharacterFrameTabButtonTemplate")
    DungeonTabButton:SetPoint("TOPLEFT", GroupieFrame, "BOTTOMLEFT", 20, 1)
    DungeonTabButton:SetText("Dungeons")
    DungeonTabButton:SetID("1")
    DungeonTabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(false, 5, false, 1)
        end)

    local DungeonHTabButton = CreateFrame("Button", "GroupieTab2", GroupieFrame, "CharacterFrameTabButtonTemplate")
    DungeonHTabButton:SetPoint("LEFT", "GroupieTab1", "RIGHT", -16, 0)
    DungeonHTabButton:SetText("Dungeons (H)")
    DungeonHTabButton:SetID("2")
    DungeonHTabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(true, 5, false, 2)
        end)

    local Raid10TabButton = CreateFrame("Button", "GroupieTab3", GroupieFrame, "CharacterFrameTabButtonTemplate")
    Raid10TabButton:SetPoint("LEFT", "GroupieTab2", "RIGHT", -16, 0)
    Raid10TabButton:SetText("Raids (10)")
    Raid10TabButton:SetID("3")
    Raid10TabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(false, 10, false, 3)
        end)

    local Raid25TabButton = CreateFrame("Button", "GroupieTab4", GroupieFrame, "CharacterFrameTabButtonTemplate")
    Raid25TabButton:SetPoint("LEFT", "GroupieTab3", "RIGHT", -16, 0)
    Raid25TabButton:SetText("Raids (25)")
    Raid25TabButton:SetID("4")
    Raid25TabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(false, 25, false, 4)
        end)

    local RaidH10TabButton = CreateFrame("Button", "GroupieTab5", GroupieFrame, "CharacterFrameTabButtonTemplate")
    RaidH10TabButton:SetPoint("LEFT", "GroupieTab4", "RIGHT", -16, 0)
    RaidH10TabButton:SetText("Raids (10H)")
    RaidH10TabButton:SetID("5")
    RaidH10TabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(true, 10, false, 5)
        end)

    local RaidH25TabButton = CreateFrame("Button", "GroupieTab6", GroupieFrame, "CharacterFrameTabButtonTemplate")
    RaidH25TabButton:SetPoint("LEFT", "GroupieTab5", "RIGHT", -16, 0)
    RaidH25TabButton:SetText("Raids (25H)")
    RaidH25TabButton:SetID("6")
    RaidH25TabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(true, 25, false, 6)
        end)

    local OtherTabButton = CreateFrame("Button", "GroupieTab7", GroupieFrame, "CharacterFrameTabButtonTemplate")
    OtherTabButton:SetPoint("LEFT", "GroupieTab6", "RIGHT", -16, 0)
    OtherTabButton:SetText("Other")
    OtherTabButton:SetID("7")
    OtherTabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(nil, nil, true, 7)
        end)

    --------------------
    -- Main Tab Frame --
    --------------------
    MainTabFrame = CreateFrame("Frame", "GroupieFrame1", GroupieFrame, "InsetFrameTemplate")
    MainTabFrame:SetWidth(WINDOW_WIDTH - 19)
    MainTabFrame:SetHeight(WINDOW_HEIGHT - WINDOW_OFFSET)
    MainTabFrame:SetPoint("TOPLEFT", GroupieFrame, "TOPLEFT", 8, -84)
    MainTabFrame:SetScript("OnShow",
        function(self)
            return
        end)
    --This frame is the main container for all listing categories, so do the update here
    MainTabFrame:HookScript("OnUpdate", function()
        addon.TimerListingUpdate()
    end)

    MainTabFrame.infotext = MainTabFrame:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
    MainTabFrame.infotext:SetWidth(WINDOW_WIDTH - 44)
    MainTabFrame.infotext:SetJustifyH("CENTER")
    MainTabFrame.infotext:SetPoint("TOP", 0, 46)

    MainTabFrame.isHeroic = false
    MainTabFrame.size = 5
    MainTabFrame.isOther = false

    createColumn("Time", COL_TIME, MainTabFrame)
    createColumn("Leader", COL_LEADER, MainTabFrame)
    createColumn("Instance", COL_INSTANCE, MainTabFrame)
    createColumn("Loot Type", COL_LOOT, MainTabFrame)
    createColumn("Message", COL_MSG, MainTabFrame)

    GroupieSettingsButton = CreateFrame("Button", "GroupieTopFrame", MainTabFrame, "UIPanelButtonTemplate")
    GroupieSettingsButton:SetSize(100, 22)
    GroupieSettingsButton:SetText("Settings")
    GroupieSettingsButton:SetPoint("TOPRIGHT", -0, 50)
    GroupieSettingsButton:SetScript("OnClick", function()
        GroupieFrame:Hide()
        addon:OpenConfig()
    end)

    ------------------
    --Scroller Frame--
    ------------------
    LFGScrollFrame = CreateFrame("ScrollFrame", "LFGScrollFrame", MainTabFrame, "FauxScrollFrameTemplate")

    LFGScrollFrame:SetWidth(WINDOW_WIDTH - 46)
    LFGScrollFrame:SetHeight(BUTTON_TOTAL * BUTTON_HEIGHT)
    LFGScrollFrame:SetPoint("TOPLEFT", 0, -4)
    LFGScrollFrame:SetScript("OnVerticalScroll",
        function(self, offset)
            addon.selectedListing = nil
            FauxScrollFrame_OnVerticalScroll(self, offset, BUTTON_HEIGHT, DrawListings)
        end)
    LFGScrollFrame:HookScript("OnShow", function()
        --Expire out of date listings
        addon.ExpireListings()
    end)
    LFGScrollFrame:HookScript("OnHide", function()
        --Expire out of date listings
        addon.ExpireListings()
    end)

    CreateListingButtons()

    --------------------
    --Send Info Button--
    --------------------
    local SendInfoButton = CreateFrame("Button", "SendInfoBtn", MainTabFrame, "UIPanelButtonTemplate")
    SendInfoButton:SetSize(155, 22)
    SendInfoButton:SetText("Send Current Spec Info")
    SendInfoButton:SetPoint("BOTTOMRIGHT", -1, -24)
    SendInfoButton:SetScript("OnClick", function(self)
        if addon.selectedListing then
            addon.SendPlayerInfo(addon.groupieBoardButtons[addon.selectedListing].listing.author)
        end
    end)

    PanelTemplates_SetNumTabs(GroupieFrame, 7)
    PanelTemplates_SetTab(GroupieFrame, 1)

    GroupieFrame:Show()
end

--Minimap Icon Creation
addon.groupieLDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
    type = "data source",
    text = addonName,
    icon = "Interface\\AddOns\\" .. addonName .. "\\Images\\icon64.tga",
    OnClick = BuildGroupieWindow,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine(addonName)
        tooltip:AddLine("A better LFG tool for Classic WoW.", 255, 255, 255, false)
        tooltip:AddLine("Click to open " .. addonName, 255, 255, 255, false)
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
            recommendedLevelRange = 0,
            autoRespondFriends = true,
            autoRespondGuild = true,
            afterParty = true,
            useChannels = {
                ["Guild"] = true,
                ["General"] = true,
                ["Trade"] = true,
                ["LocalDefense"] = true,
                ["LookingForGroup"] = true,
                ["5"] = true,
            },
            showWrathH25 = true,
            showWrathH10 = true,
            showWrath25 = true,
            showWrath10 = true,
            showWrathH5 = true,
            showWrath5 = true,
            showTBCRaid = true,
            showTBCH5 = true,
            showTBC5 = true,
            showClassicRaid = true,
            showClassic5 = true,
            hideInstances = {}
        },
        global = {
            preserveData = true,
            minsToPreserve = 2,
            font = "Arial Narrow",
            fontSize = 8,
            debugData = {},
            listingTable = {},
            showMinimap = true,
            ignoreWrongLvl = true,
            ignoreSavedInstances = true,
            ignoreLFM = false,
            ignoreLFG = false,
            ignoreWrongRole = false,
            ignoreAmbiguousLanguage = false,
            ignoreTicket = false,
            ignoreGDKP = false,
            ignoreSoftRes = false,
            ignoreMSOS = false,
            keywordBlacklist = {}
        }
    }
    --Generate defaults for each individual dungeon filter
    for key, val in pairs(addon.groupieInstanceData) do
        defaults.char.hideInstances[key] = false
    end
    addon.db = LibStub("AceDB-3.0"):New("GroupieDB", defaults)
    addon.icon = LibStub("LibDBIcon-1.0")
    addon.icon:Register("GroupieLDB", addon.groupieLDB, addon.db.global)
    addon.icon:Hide("GroupieLDB")

    BuildGroupieWindow()

    addon.debugMenus = false
    --Setup Slash Commands
    SLASH_GROUPIE1 = "/groupie"
    SlashCmdList["GROUPIE"] = BuildGroupieWindow
    SLASH_GROUPIECFG1 = "/groupiecfg"
    SlashCmdList["GROUPIECFG"] = addon.OpenConfig
    SLASH_GROUPIEDEBUG1 = "/groupiedebug"
    SlashCmdList["GROUPIEDEBUG"] = function()
        addon.debugMenus = not addon.debugMenus
        print("GROUPIE DEBUG MODE: " .. tostring(addon.debugMenus))
    end
    addon.isInitialized = true
end

---------------------
-- AceConfig Setup --
---------------------
function addon.SetupConfig()
    addon.options = {
        name = addonName,
        desc = "Optional description? for the group of options",
        descStyle = "inline",
        handler = addon,
        type = 'group',
        args = {
            about = {
                name = "About",
                desc = "About Groupie",
                type = "group",
                width = "double",
                inline = false,
                order = 5,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cffffd900" .. addonName .. " | About",
                        order = 0,
                        fontSize = "large"
                    },
                    spacerdesc1 = { type = "description", name = " ", width = "full", order = 1 },
                    header2 = {
                        type = "description",
                        name = "|cffffd900Groupie on CurseForge",
                        order = 2,
                        fontSize = "medium"
                    },
                    editbox1 = {
                        type = "input",
                        name = "",
                        order = 3,
                        width = 2,
                        get = function(info) return "https://www.curseforge.com/wow/addons/groupie-lfg" end,
                        set = function(info, val) return end,
                    },
                    spacerdesc2 = { type = "description", name = " ", width = "full", order = 4 },
                    header3 = {
                        type = "description",
                        name = "|cffffd900Groupie on Discord",
                        order = 5,
                        fontSize = "medium"
                    },
                    editbox2 = {
                        type = "input",
                        name = "",
                        order = 6,
                        width = 2,
                        get = function(info) return "https://discord.gg/6xccnxcRbt" end,
                        set = function(info, val) return end,
                    },
                    spacerdesc3 = { type = "description", name = " ", width = "full", order = 7 },
                    header4 = {
                        type = "description",
                        name = "|cffffd900Groupie on GitHub",
                        order = 8,
                        fontSize = "medium"
                    },
                    editbox3 = {
                        type = "input",
                        name = "",
                        order = 9,
                        width = 2,
                        get = function(info) return "https://github.com/Gogo1951/Groupie-LFG" end,
                        set = function(info, val) return end,
                    },
                }
            },
            instancefilters = {
                name = "Instance Filters",
                desc = "Filter Groups by Instance",
                type = "group",
                width = "double",
                inline = false,
                order = 4,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cffffd900" .. addonName .. " | Instance Filters",
                        order = 0,
                        fontSize = "large"
                    },

                }
            },
            groupfilters = {
                name = "Group Filters",
                desc = "Filter Groups by Other Properties",
                type = "group",
                width = "double",
                inline = false,
                order = 3,
                args = {
                    header0 = {
                        type = "description",
                        name = "|cffffd900" .. addonName .. " | Group Filters",
                        order = 0,
                        fontSize = "large"
                    },
                    spacerdesc1 = { type = "description", name = " ", width = "full", order = 1 },
                    header1 = {
                        type = "description",
                        name = "|cffffd900General Filters",
                        order = 2,
                        fontSize = "medium"
                    },
                    levelRangeToggle = {
                        type = "toggle",
                        name = "Ignore Instances Outside of your Recommended Level Range",
                        order = 3,
                        width = "full",
                        get = function(info) return addon.db.global.ignoreWrongLvl end,
                        set = function(info, val) addon.db.global.ignoreWrongLvl = val end,
                    },
                    savedToggle = {
                        type = "toggle",
                        name = "Ignore Instances You Are Already Saved To on Current Character",
                        order = 4,
                        width = "full",
                        get = function(info) return addon.db.global.ignoreSavedInstances end,
                        set = function(info, val) addon.db.global.ignoreSavedInstances = val end,
                    },
                    ignoreLFG = {
                        type = "toggle",
                        name = "Ignore \"LFG\" Messages from People Looking for a Group",
                        order = 5,
                        width = "full",
                        get = function(info) return addon.db.global.ignoreLFG end,
                        set = function(info, val) addon.db.global.ignoreLFG = val end,
                    },
                    ignoreLFM = {
                        type = "toggle",
                        name = "Ignore \"LFM\" Messages from People Making a Group",
                        order = 6,
                        width = "full",
                        get = function(info) return addon.db.global.ignoreLFM end,
                        set = function(info, val) addon.db.global.ignoreLFM = val end,
                    },
                    roleToggle = {
                        type = "toggle",
                        name = "Ignore Groups that are Not Looking for a Role You Can Play",
                        order = 7,
                        width = "full",
                        get = function(info) return addon.db.global.ignoreWrongRole end,
                        set = function(info, val) addon.db.global.ignoreWrongRole = val end,
                    },
                    languageToggle = {
                        type = "toggle",
                        name = "Ignore Groups Not Explicitly Labeled as your Default Language",
                        order = 8,
                        width = "full",
                        get = function(info) return addon.db.global.ignoreAmbiguousLanguage end,
                        set = function(info, val) addon.db.global.ignoreAmbiguousLanguage = val end,
                    },
                    spacerdesc2 = { type = "description", name = " ", width = "full", order = 9 },
                    header2 = {
                        type = "description",
                        name = "|cffffd900Filter By Reward Distribution Style",
                        order = 10,
                        fontSize = "medium"
                    },
                    ticketToggle = {
                        type = "toggle",
                        name = "Ignore Ticket Run Reward Distribution Style Groups",
                        order = 11,
                        width = "full",
                        get = function(info) return addon.db.global.ignoreTicket end,
                        set = function(info, val) addon.db.global.ignoreTicket = val end,
                    },
                    gdkpToggle = {
                        type = "toggle",
                        name = "Ignore GDKP Reward Distribution Style Groups",
                        order = 12,
                        width = "full",
                        get = function(info) return addon.db.global.ignoreGDKP end,
                        set = function(info, val) addon.db.global.ignoreGDKP = val end,
                    },
                    softresToggle = {
                        type = "toggle",
                        name = "Ignore Soft Reserve Reward Distribution Style Groups",
                        order = 13,
                        width = "full",
                        get = function(info) return addon.db.global.ignoreSoftRes end,
                        set = function(info, val) addon.db.global.ignoreSoftRes = val end,
                    },
                    msosToggle = {
                        type = "toggle",
                        name = "Ignore MS > OS Reward Distribution Style Groups",
                        order = 14,
                        width = "full",
                        get = function(info) return addon.db.global.ignoreMSOS end,
                        set = function(info, val) addon.db.global.ignoreMSOS = val end,
                    },
                    spacerdesc3 = { type = "description", name = " ", width = "full", order = 15 },
                    header3 = {
                        type = "description",
                        name = "|cffffd900Filter By Keyword",
                        order = 16,
                        fontSize = "medium"
                    },
                    keywordBlacklist = {
                        type = "input",
                        name = "",
                        order = 17,
                        width = 2,
                        get = function(info)
                            --print(addon.BlackListToStr(addon.db.global.keywordBlacklist))
                            return addon.BlackListToStr(addon.db.global.keywordBlacklist)
                        end,
                        set = function(info, val)
                            addon.db.global.keywordBlacklist = addon.BlacklistToTable(val, ",")
                        end,
                    },
                    header4 = {
                        type = "description",
                        name = "|cff999999Separate words or phrases using a comma; any post matching any keyword will be ignored.\nExample: \"swp trash, Selling, Boost\"",
                        order = 18,
                        fontSize = "medium"
                    },
                }
            },
            charoptions = {
                name = "Character Options",
                desc = "Change Character-Specific Settings",
                type = "group",
                width = "double",
                inline = false,
                order = 1,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cffffd900" .. addonName .. " | " .. UnitName("player") .. " Options",
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
                        name = "|cffffd900Spec 2 Role - " .. addon.GetSpecByGroupNum(2),
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
                            [0] = "Default Suggested Levels",
                            [1] = "+1 - I've Done This Before",
                            [2] = "+2 - I've Got Enchanted Heirlooms",
                            [3] = "+3 - I'm Playing a Healer"
                        },
                        set = function(info, val) addon.db.char.recommendedLevelRange = val end,
                        get = function(info) return addon.db.char.recommendedLevelRange end,
                    },
                    spacerdesc4 = { type = "description", name = " ", width = "full", order = 10 },
                    header5 = {
                        type = "description",
                        name = "|cffffd900" .. addonName .. " Auto-Response",
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
                        name = "|cffffd900" .. addonName .. " After-Party Tool",
                        order = 15,
                        fontSize = "medium"
                    },
                    afterPartyToggle = {
                        type = "toggle",
                        name = "Enable " .. addonName .. " After-Party Tool",
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
                order = 2,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cffffd900" .. addonName .. " | Global Options",
                        order = 0,
                        fontSize = "large"
                    },
                    spacerdesc1 = { type = "description", name = " ", width = "full", order = 1 },
                    minimapToggle = {
                        type = "toggle",
                        name = "Enable Mini-Map Button",
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
    ---------------------------------------
    -- Generate Instance Filter Controls --
    ---------------------------------------
    addon.GenerateInstanceToggles(1, "Wrath of the Lich King Heroic Raids - 25", false, "showWrathH25")
    addon.GenerateInstanceToggles(101, "Wrath of the Lich King Heroic Raids - 10", false, "showWrathH10")
    addon.GenerateInstanceToggles(201, "Wrath of the Lich King Raids - 25", false, "showWrath25")
    addon.GenerateInstanceToggles(301, "Wrath of the Lich King Raids - 10", false, "showWrath10")
    addon.GenerateInstanceToggles(401, "Wrath of the Lich King Heroic Dungeons", false, "showWrathH5")
    addon.GenerateInstanceToggles(501, "Wrath of the Lich King Dungeons", true, "showWrath5")
    addon.GenerateInstanceToggles(601, "The Burning Crusade Raids", false, "showTBCRaid")
    addon.GenerateInstanceToggles(701, "The Burning Crusade Heroic Dungeons", true, "showTBCH5")
    addon.GenerateInstanceToggles(801, "The Burning Crusade Dungeons", true, "showTBC5")
    addon.GenerateInstanceToggles(901, "Classic Raids", false, "showClassicRaid")
    addon.GenerateInstanceToggles(1001, "Classic Dungeons", true, "showClassic5")
    ----------------------------------
    -- End Instance Filter Controls --
    ----------------------------------
    if not addon.addedToBlizz then
        LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, addon.options)
        addon.AceConfigDialog = LibStub("AceConfigDialog-3.0")
        addon.optionsFrame = addon.AceConfigDialog:AddToBlizOptions(addonName, addonName)
    end
    addon.addedToBlizz = true
    if addon.db.global.showMinimap == false then
        addon.icon:Hide("GroupieLDB")
    end
    addon.UpdateSpecOptions()
end

function addon:OpenConfig()
    addon.UpdateSpecOptions()
    InterfaceOptionsFrame_OpenToCategory(addonName)
    -- need to call it a second time as there is a bug where the first time it won't switch !BlizzBugsSuck has a fix
    InterfaceOptionsFrame_OpenToCategory(addonName)
end

--This must be done after player entering world event so that we can pull spec
addon:RegisterEvent("PLAYER_ENTERING_WORLD", addon.SetupConfig)

--Update our options menu dropdowns when the player's specialization changes
function addon.UpdateSpecOptions()
    local spec1, maxtalents1 = addon.GetSpecByGroupNum(1)
    local spec2, maxtalents2 = addon.GetSpecByGroupNum(2)
    --Set labels
    addon.options.args.charoptions.args.header2.name = "|cffffd900Role for Spec 1 - " .. spec1
    addon.options.args.charoptions.args.header3.name = "|cffffd900Role for Spec 2 - " .. spec2
    --Set dropdowns
    addon.options.args.charoptions.args.spec1Dropdown.values = addon.groupieClassRoleTable[UnitClass("player")][spec1]
    addon.options.args.charoptions.args.spec2Dropdown.values = addon.groupieClassRoleTable[UnitClass("player")][spec2]
    --Reset to default value for dropdowns if the currently selected role is now invalid after the change
    if not addon.groupieClassRoleTable[UnitClass("player")][spec1][addon.db.char.groupieSpec1Role] then
        addon.db.char.groupieSpec1Role = nil
    end
    if not addon.groupieClassRoleTable[UnitClass("player")][spec2][addon.db.char.groupieSpec2Role] then
        addon.db.char.groupieSpec2Role = nil
    end
    for i = 4, 1, -1 do
        if addon.groupieClassRoleTable[UnitClass("player")][spec1][i] and addon.db.char.groupieSpec1Role == nil then
            addon.db.char.groupieSpec1Role = i
        end
        if addon.groupieClassRoleTable[UnitClass("player")][spec2][i] and addon.db.char.groupieSpec2Role == nil then
            addon.db.char.groupieSpec2Role = i
        end
    end
    --Hide dropdown for spec 2 if no talents are spent in any tabs
    if maxtalents2 > 0 then
        addon.options.args.charoptions.args.spacerdesc2.hidden = false
        addon.options.args.charoptions.args.header3.hidden = false
        addon.options.args.charoptions.args.spec2Dropdown.hidden = false
    else
        addon.options.args.charoptions.args.spacerdesc2.hidden = true
        addon.options.args.charoptions.args.header3.hidden = true
        addon.options.args.charoptions.args.spec2Dropdown.hidden = true
    end
end

--Leave this commented for now, may trigger when swapping dual specs, which we dont want to reset settings
--Only actual talent changes
--addon:RegisterEvent("PLAYER_TALENT_UPDATE", addon.UpdateSpecOptions)
addon:RegisterEvent("CHARACTER_POINTS_CHANGED", addon.UpdateSpecOptions)
