local addonName, Groupie    = ...
--Main UI variables
local GroupieFrame          = nil
local MainTabFrame          = nil
local GroupieSettingsButton = nil
local GroupieRoleDropdown   = nil
local GroupieLootDropdown   = nil
local GroupieLangDropdown   = nil
local GroupieLevelDropdown  = nil
local ShowingFontStr        = nil
local columnCount           = 0
local LFGScrollFrame        = nil
local WINDOW_WIDTH          = 960
local WINDOW_HEIGHT         = 640
local WINDOW_YOFFSET        = -84
local ICON_WIDTH            = 32
local WINDOW_OFFSET         = 133
local BUTTON_HEIGHT         = 40
local BUTTON_TOTAL          = math.floor((WINDOW_HEIGHT - WINDOW_OFFSET) / BUTTON_HEIGHT) + 1
local BUTTON_WIDTH          = WINDOW_WIDTH - 44
local COL_CREATED           = 75
local COL_TIME              = 75
local COL_LEADER            = 100
local COL_INSTANCE          = 175
local COL_LOOT              = 76
local DROPDOWN_WIDTH        = 100
local DROPDOWN_LEFTOFFSET   = 115
local DROPDOWN_PAD          = 32

local COL_MSG = WINDOW_WIDTH - COL_CREATED - COL_TIME - COL_LEADER - COL_INSTANCE - COL_LOOT - ICON_WIDTH - 44

local addon = LibStub("AceAddon-3.0"):NewAddon(Groupie, addonName, "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0")

local SharedMedia = LibStub("LibSharedMedia-3.0")
local gsub        = gsub
local time        = time

addon.groupieBoardButtons = {}
addon.filteredListings    = {}
addon.selectedListing     = nil

IgnoreListButtonMixin = {}
function IgnoreListButtonMixin:OnClick()
    return
end

------------------
--User Interface--
------------------
--Create a sorted index of listings
--Sort Types : -1 (default) - Time Posted
-- 0 - Time Updated
-- 1 - Leader Name
-- 2 - Instance
-- 3 - Loot Type
local function GetSortedListingIndex(sortType, sortDir)
    local idx = 1
    local numindex = {}
    sortType = sortType or -1
    sortDir = sortDir or false

    --Build a numerical index to sort on
    for author, listing in pairs(addon.db.global.listingTable) do
        numindex[idx] = listing
        idx = idx + 1
    end

    --Then sort the index
    if sortType == -1 then
        if sortDir then
            table.sort(numindex, function(a, b) return (a.createdat or 0) > (b.createdat or 0) end)
        else
            table.sort(numindex, function(a, b) return (a.createdat or 0) < (b.createdat or 0) end)
        end
    elseif sortType == 0 then
        if sortDir then
            table.sort(numindex, function(a, b) return a.timestamp > b.timestamp end)
        else
            table.sort(numindex, function(a, b) return a.timestamp < b.timestamp end)
        end
    elseif sortType == 1 then
        if sortDir then
            table.sort(numindex, function(a, b) return a.author < b.author end)
        else
            table.sort(numindex, function(a, b) return a.author > b.author end)
        end
    elseif sortType == 2 then
        if sortDir then
            table.sort(numindex, function(a, b) return a.instanceName < b.instanceName end)
        else
            table.sort(numindex, function(a, b) return a.instanceName > b.instanceName end)
        end
    elseif sortType == 3 then
        if sortDir then
            table.sort(numindex, function(a, b) return a.lootType < b.lootType end)
        else
            table.sort(numindex, function(a, b) return a.lootType > b.lootType end)
        end
    end

    return numindex
end

--Create a numerically indexed table of listings for use in the scroller
--Tab numbers:
-- 1 - Dungeons | 2 - Heroic Dungeons | 3 - 10 Raids
-- 4 - 25 Raids | 5 - Heroic 10 Raids | 6 - Heroic 25 Raids
-- 7 - PVP | 8 - Other | 9 - All
local function filterListings()
    addon.filteredListings = {}
    local idx = 1
    local total = 0
    local sortType = MainTabFrame.sortType or -1
    local now = time()
    local playerName = UnitName("player")
    local sortDir = MainTabFrame.sortDir or false
    local sorted = GetSortedListingIndex(sortType, sortDir)


    if MainTabFrame.tabType == 7 then --PVP
        for key, listing in pairs(sorted) do
            if listing.lootType ~= "PVP" then
                --Wrong tab
                --Other tab shows groups with 'pvp' loot type
                --most filters do not apply to this tab
            elseif now - listing.timestamp > addon.db.global.minsToPreserve * 60 then
                --Expired based on user settings
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
    elseif MainTabFrame.tabType == 8 then --Other
        for key, listing in pairs(sorted) do
            if listing.lootType ~= "Other" then
                --Wrong tab
                --Other tab shows groups with 'other' loot type, and 40 man raids
                --Loot type filters therefore dont apply to this tab
            elseif now - listing.timestamp > addon.db.global.minsToPreserve * 60 then
                --Expired based on user settings
            elseif addon.db.global.ignoreLFM and listing.isLFM then
                --Ignoring LFM groups
            elseif addon.db.global.ignoreLFG and listing.isLFG then
                --Ignoring LFG groups
            elseif MainTabFrame.roleType ~= nil and
                not addon.tableContains(listing.rolesNeeded, MainTabFrame.roleType) then
                --Doesnt match role in the dropdown
            elseif MainTabFrame.lang ~= nil and MainTabFrame.lang ~= listing.language then
                --Doesnt match language in the dropdown
            elseif addon.db.char.hideInstances[listing.order] == true then
                --Ignoring specifically hidden instances
            elseif addon.db.global.ignoreSavedInstances and addon.db.global.savedInstanceInfo[listing.order] and
                addon.db.global.savedInstanceInfo[listing.order][playerName] and
                (addon.db.global.savedInstanceInfo[listing.order][playerName].resetTime > now) then
                --Ignore instances the player is saved to
                if addon.debugMenus then
                    print("FILTERED DUE TO LOCKOUT: ", listing.fullName)
                end
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
    elseif MainTabFrame.tabType == 9 then --All
        for key, listing in pairs(sorted) do
            if now - listing.timestamp > addon.db.global.minsToPreserve * 60 then
                --Expired based on user settings
            elseif MainTabFrame.roleType ~= nil and
                not addon.tableContains(listing.rolesNeeded, MainTabFrame.roleType) then
                --Doesnt match role in the dropdown
            elseif MainTabFrame.lootType ~= nil and MainTabFrame.lootType ~= listing.lootType then
                --Doesnt match loot type in the dropdown
            elseif MainTabFrame.lang ~= nil and MainTabFrame.lang ~= listing.language then
                --Doesnt match language in the dropdown
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
    else --Dungeon/Raid tabs
        for key, listing in pairs(sorted) do
            if listing.isHeroic ~= MainTabFrame.isHeroic then
                --Wrong tab
            elseif listing.groupSize ~= MainTabFrame.size then
                --Wrong tab
            elseif listing.lootType == "Other" or listing.lootType == "PVP" then
                --Only show these groups in 'Other' and 'PVP' tabs
            elseif now - listing.timestamp > addon.db.global.minsToPreserve * 60 then
                --Expired based on user settings
            elseif addon.db.global.ignoreLFM and listing.isLFM then
                --Ignoring LFM groups
            elseif addon.db.global.ignoreLFG and listing.isLFG then
                --Ignoring LFG groups
            elseif MainTabFrame.roleType ~= nil and
                not addon.tableContains(listing.rolesNeeded, MainTabFrame.roleType) then
                --Doesnt match role in the dropdown
            elseif MainTabFrame.lootType ~= nil and MainTabFrame.lootType ~= listing.lootType then
                --Doesnt match loot type in the dropdown
            elseif MainTabFrame.lang ~= nil and MainTabFrame.lang ~= listing.language then
                --Doesnt match language in the dropdown
            elseif MainTabFrame.levelFilter and listing.minLevel and
                MainTabFrame.size == 5 and MainTabFrame.isHeroic == false
                and listing.minLevel > (UnitLevel("player") + addon.db.char.recommendedLevelRange) then
                --Instance is outside of level range (ONLY for normal dungeons)
            elseif MainTabFrame.levelFilter and listing.maxLevel and
                MainTabFrame.size == 5 and MainTabFrame.isHeroic == false
                and listing.maxLevel < UnitLevel("player") then
                --Instance is outside of level range (ONLY for normal dungeons)
            elseif addon.db.char.hideInstances[listing.order] == true then
                --Ignoring specifically hidden instances
            elseif addon.db.global.ignoreSavedInstances and addon.db.global.savedInstanceInfo[listing.order] and
                addon.db.global.savedInstanceInfo[listing.order][playerName] and
                (addon.db.global.savedInstanceInfo[listing.order][playerName].resetTime > now) then
                --Ignore instances the player is saved to
                if addon.debugMenus then
                    print("FILTERED DUE TO LOCKOUT: ", listing.fullName)
                end
            else
                --Check for blacklisted words
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
    end
    MainTabFrame.infotext:SetText(format(
        "Showing %d of %d possible groups. To see more groups adjust your [Group Filters] or [Instance Filters] under Groupie > Settings."
        , idx - 1, total))
    if addon.debugMenus then
        MainTabFrame.infotext:Show()
    else
        MainTabFrame.infotext:Hide()
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
            local formattedMsg = gsub(gsub(listing.msg, "%{%w+%}", ""), "%s+", " ")
            local lootColor = addon.lootTypeColors[listing.lootType]
            button.listing = listing
            button.created:SetText(addon.GetTimeSinceString(listing.createdat, 2))
            button.time:SetText(addon.GetTimeSinceString(listing.timestamp, 2))
            button.leader:SetText(gsub(listing.author, "-.+", ""))
            button.instance:SetText(" " .. listing.instanceName)
            button.loot:SetText("|cFF" .. lootColor .. listing.lootType)
            button.msg:SetText(formattedMsg)
            button.icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Images\\InstanceIcons\\" .. listing.icon)
            button:SetScript("OnEnter", function()
                GameTooltip:SetOwner(button, "ANCHOR_CURSOR")
                GameTooltip:SetText(formattedMsg, 1, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            button:SetID(idx)
            button:Show()
            btnNum = btnNum + 1
        else
            button:Hide()
        end
    end
end

--Onclick for group listings, highlights the selected listing
local function ListingOnClick(self, button, down)
    if addon.selectedListing then
        addon.groupieBoardButtons[addon.selectedListing]:UnlockHighlight()
    end
    addon.selectedListing = self.id
    addon.groupieBoardButtons[addon.selectedListing]:LockHighlight()
    local fullName = addon.groupieBoardButtons[addon.selectedListing].listing.author
    local instance = addon.groupieBoardButtons[addon.selectedListing].listing.instanceName
    local fullInstance = addon.groupieBoardButtons[addon.selectedListing].listing.fullName
    local displayName = gsub(fullName, "-.+", "")
    DrawListings(LFGScrollFrame)

    --Select a listing, if shift is held, do a Who Request
    if button == "LeftButton" then
        if addon.debugMenus then
            print(addon.selectedListing)
            print(fullName)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.msg)
        end
        if IsShiftKeyDown() then
            DEFAULT_CHAT_FRAME.editBox:SetText("/who " .. fullName)
            ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox)
        end
        --Open Right click Menu
    elseif button == "RightButton" then
        local maxTalentSpec, maxTalentsSpent = addon.GetSpecByGroupNum(addon.GetActiveSpecGroup())
        local isIgnored = C_FriendList.IsIgnored(displayName)
        local ignoreText = "Ignore"

        if isIgnored then
            ignoreText = "Stop Ignoring"
        end

        local ListingRightClick = {
            { text = displayName, isTitle = true, notCheckable = true },
            { text = "Invite", notCheckable = true, func = function() InviteUnit(displayName) end },
            { text = "Whisper", notCheckable = true, func = function()
                ChatFrame_OpenChat("/w " .. fullName .. " ")
            end },
            { text = ignoreText, notCheckable = true, func = function()
                C_FriendList.AddOrDelIgnore(displayName)
            end },
            { text = "", disabled = true, notCheckable = true },
            { text = addonName, isTitle = true, notCheckable = true },
            { text = "Send My Info...", notClickable = true, notCheckable = true },
            { text = "Current Spec : " .. maxTalentSpec, notCheckable = true, leftPadding = 8,
                func = function()
                    if instance ~= "Miscellaneous" and instance ~= "PVP" then
                        addon.SendPlayerInfo(fullName, nil, nil, instance, fullInstance)
                    else
                        addon.SendPlayerInfo(fullName)
                    end
                end },
        }
        if GetLocale() == "enUS" then
            tinsert(ListingRightClick, { text = "Warcraft Logs Link", notCheckable = true, leftPadding = 8,
                func = function()
                    addon.SendWCLInfo(fullName)
                end })
        end

        local f = CreateFrame("Frame", "GroupieListingRightClick", UIParent, "UIDropDownMenuTemplate")
        EasyMenu(ListingRightClick, f, "cursor", 0, 0, "MENU")
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
        currentListing:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        --Created at column
        currentListing.created:SetWidth(COL_CREATED)

        --Time column
        currentListing.time = currentListing:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
        currentListing.time:SetPoint("LEFT", currentListing.created, "RIGHT", 0, 0)
        currentListing.time:SetWidth(COL_TIME)
        currentListing.time:SetJustifyH("LEFT")
        currentListing.time:SetJustifyV("MIDDLE")

        --Leader name column
        currentListing.leader = currentListing:CreateFontString("FontString", "OVERLAY", "GameFontNormal")
        currentListing.leader:SetPoint("LEFT", currentListing.time, "RIGHT", 0, 0)
        currentListing.leader:SetWidth(COL_LEADER)
        currentListing.leader:SetJustifyH("LEFT")
        currentListing.leader:SetJustifyV("MIDDLE")

        --Instance expansion column
        currentListing.icon = currentListing:CreateTexture("$parentIcon", "OVERLAY", nil, -8)
        currentListing.icon:SetSize(ICON_WIDTH, ICON_WIDTH / 2)
        currentListing.icon:SetPoint("LEFT", currentListing.leader, "RIGHT", 2, 0)
        currentListing.icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Images\\InstanceIcons\\Other.tga")

        --Instance name column
        currentListing.instance = currentListing:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
        currentListing.instance:SetPoint("LEFT", currentListing.icon, "RIGHT", 0, 0)
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
        currentListing.msg:SetWordWrap(false)

        currentListing.id = listcount
        listcount = listcount + 1
    end
    DrawListings(LFGScrollFrame)
end

--Create column headers for the main tab
local function createColumn(text, width, parent, sortType)
    columnCount = columnCount + 1
    local Header = CreateFrame("Button", parent:GetName() .. "Header" .. columnCount, parent,
        "WhoFrameColumnHeaderTemplate")
    Header:SetWidth(width)
    _G[parent:GetName() .. "Header" .. columnCount .. "Middle"]:SetWidth(width - 9)
    Header:SetText(text)
    Header:SetNormalFontObject("GameFontHighlight")
    Header:SetID(columnCount)

    if text == "Message" then
        Header:Disable()
    end

    if columnCount == 1 then
        Header:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, 22)
    else
        Header:SetPoint("LEFT", parent:GetName() .. "Header" .. columnCount - 1, "RIGHT", 0, 0)
    end
    if sortType ~= nil then
        Header:SetScript("OnClick", function()
            MainTabFrame.sortType = sortType
            MainTabFrame.sortDir = not MainTabFrame.sortDir
            DrawListings(LFGScrollFrame)
        end)
    else
        Header:SetScript("OnClick", function() return end)
    end
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
function addon.TabSwap(isHeroic, size, tabType, tabNum)
    addon.ExpireListings()
    MainTabFrame:Show()
    --Reset environment values
    MainTabFrame.isHeroic = isHeroic
    MainTabFrame.size = size
    MainTabFrame.tabType = tabNum
    MainTabFrame.sortType = -1
    MainTabFrame.sortDir = false
    --Reset dropdowns
    UIDropDownMenu_SetText(GroupieRoleDropdown, "LF Any Role")
    MainTabFrame.roleType = nil
    UIDropDownMenu_SetText(GroupieLootDropdown, "All Loot Styles")
    MainTabFrame.lootType = nil
    UIDropDownMenu_SetText(GroupieLangDropdown, "All Languages")
    MainTabFrame.lang = nil
    UIDropDownMenu_SetText(GroupieLevelDropdown, "Recommended Level Dungeons")
    MainTabFrame.levelFilter = true

    --Clear selected listing
    if addon.selectedListing then
        addon.groupieBoardButtons[addon.selectedListing]:UnlockHighlight()
    end
    addon.selectedListing = nil

    --Only show level dropdown on normal dungeon tab
    --Show no filters on pvp tab
    if tabNum == 1 then --Normal dungeons
        GroupieLangDropdown:SetPoint("TOPLEFT", DROPDOWN_LEFTOFFSET + (DROPDOWN_WIDTH + DROPDOWN_PAD) * 2, 55)
        GroupieLevelDropdown:Show()
        GroupieRoleDropdown:Show()
        GroupieLootDropdown:Show()
        GroupieLangDropdown:Show()
        ShowingFontStr:Show()
    elseif tabNum == 8 then --Other
        GroupieLangDropdown:SetPoint("TOPLEFT", DROPDOWN_LEFTOFFSET + (DROPDOWN_WIDTH + DROPDOWN_PAD) * 1, 55)
        GroupieLevelDropdown:Hide()
        GroupieRoleDropdown:Show()
        GroupieLootDropdown:Hide()
        GroupieLangDropdown:Show()
        ShowingFontStr:Show()
    elseif tabNum == 7 then --PVP
        GroupieLangDropdown:SetPoint("TOPLEFT", DROPDOWN_LEFTOFFSET + (DROPDOWN_WIDTH + DROPDOWN_PAD) * 2, 55)
        GroupieLevelDropdown:Hide()
        GroupieRoleDropdown:Hide()
        GroupieLootDropdown:Hide()
        GroupieLangDropdown:Hide()
        ShowingFontStr:Hide()
    else --All other tabs
        GroupieLangDropdown:SetPoint("TOPLEFT", DROPDOWN_LEFTOFFSET + (DROPDOWN_WIDTH + DROPDOWN_PAD) * 2, 55)
        GroupieLevelDropdown:Hide()
        GroupieRoleDropdown:Show()
        GroupieLootDropdown:Show()
        GroupieLangDropdown:Show()
        ShowingFontStr:Show()
    end

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
    icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Images\\icon128.tga")

    ------------------------
    --Category Tab Buttons--
    ------------------------
    local DungeonTabButton = CreateFrame("Button", "GroupieTab1", GroupieFrame, "CharacterFrameTabButtonTemplate")
    DungeonTabButton:SetPoint("TOPLEFT", GroupieFrame, "BOTTOMLEFT", 20, 1)
    DungeonTabButton:SetText("Dungeons")
    DungeonTabButton:SetID("1")
    DungeonTabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(false, 5, 0, 1)
        end)

    local DungeonHTabButton = CreateFrame("Button", "GroupieTab2", GroupieFrame, "CharacterFrameTabButtonTemplate")
    DungeonHTabButton:SetPoint("LEFT", "GroupieTab1", "RIGHT", -16, 0)
    DungeonHTabButton:SetText("Dungeons (H)")
    DungeonHTabButton:SetID("2")
    DungeonHTabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(true, 5, 0, 2)
        end)

    local Raid10TabButton = CreateFrame("Button", "GroupieTab3", GroupieFrame, "CharacterFrameTabButtonTemplate")
    Raid10TabButton:SetPoint("LEFT", "GroupieTab2", "RIGHT", -16, 0)
    Raid10TabButton:SetText("Raids (10)")
    Raid10TabButton:SetID("3")
    Raid10TabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(false, 10, 0, 3)
        end)

    local Raid25TabButton = CreateFrame("Button", "GroupieTab4", GroupieFrame, "CharacterFrameTabButtonTemplate")
    Raid25TabButton:SetPoint("LEFT", "GroupieTab3", "RIGHT", -16, 0)
    Raid25TabButton:SetText("Raids (25)")
    Raid25TabButton:SetID("4")
    Raid25TabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(false, 25, 0, 4)
        end)

    local RaidH10TabButton = CreateFrame("Button", "GroupieTab5", GroupieFrame, "CharacterFrameTabButtonTemplate")
    RaidH10TabButton:SetPoint("LEFT", "GroupieTab4", "RIGHT", -16, 0)
    RaidH10TabButton:SetText("Raids (10H)")
    RaidH10TabButton:SetID("5")
    RaidH10TabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(true, 10, 0, 5)
        end)

    local RaidH25TabButton = CreateFrame("Button", "GroupieTab6", GroupieFrame, "CharacterFrameTabButtonTemplate")
    RaidH25TabButton:SetPoint("LEFT", "GroupieTab5", "RIGHT", -16, 0)
    RaidH25TabButton:SetText("Raids (25H)")
    RaidH25TabButton:SetID("6")
    RaidH25TabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(true, 25, 0, 6)
        end)

    local PVPTabButton = CreateFrame("Button", "GroupieTab7", GroupieFrame, "CharacterFrameTabButtonTemplate")
    PVPTabButton:SetPoint("LEFT", "GroupieTab6", "RIGHT", -16, 0)
    PVPTabButton:SetText("PVP")
    PVPTabButton:SetID("7")
    PVPTabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(nil, nil, 3, 7)
        end)

    local OtherTabButton = CreateFrame("Button", "GroupieTab8", GroupieFrame, "CharacterFrameTabButtonTemplate")
    OtherTabButton:SetPoint("LEFT", "GroupieTab7", "RIGHT", -16, 0)
    OtherTabButton:SetText("Other")
    OtherTabButton:SetID("8")
    OtherTabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(nil, nil, 1, 8)
        end)

    local AllTabButton = CreateFrame("Button", "GroupieTab9", GroupieFrame, "CharacterFrameTabButtonTemplate")
    AllTabButton:SetPoint("LEFT", "GroupieTab8", "RIGHT", -16, 0)
    AllTabButton:SetText("All")
    AllTabButton:SetID("9")
    AllTabButton:SetScript("OnClick",
        function(self)
            addon.TabSwap(nil, nil, 2, 9)
        end)



    --------------------
    -- Main Tab Frame --
    --------------------
    MainTabFrame = CreateFrame("Frame", "GroupieFrame1", GroupieFrame, "InsetFrameTemplate")
    MainTabFrame:SetWidth(WINDOW_WIDTH - 19)
    MainTabFrame:SetHeight(WINDOW_HEIGHT - WINDOW_OFFSET + 20)
    MainTabFrame:SetPoint("TOPLEFT", GroupieFrame, "TOPLEFT", 8, WINDOW_YOFFSET)
    MainTabFrame:SetScript("OnShow",
        function(self)
            return
        end)
    MainTabFrame.infotext = MainTabFrame:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
    MainTabFrame.infotext:SetJustifyH("CENTER")
    MainTabFrame.infotext:SetPoint("TOP", 0, 150)
    --This frame is the main container for all listing categories, so do the update here
    MainTabFrame:HookScript("OnUpdate", function()
        addon.TimerListingUpdate()
    end)
    MainTabFrame.infotext:Hide()

    MainTabFrame.isHeroic = false
    MainTabFrame.size = 5
    MainTabFrame.tabType = 0

    createColumn("Created", COL_CREATED, MainTabFrame, -1)
    createColumn("Updated", COL_TIME, MainTabFrame, 0)
    createColumn("Leader", COL_LEADER, MainTabFrame, 1)
    createColumn("Instance", COL_INSTANCE + ICON_WIDTH, MainTabFrame, 2)
    createColumn("Loot Type", COL_LOOT, MainTabFrame, 3)
    createColumn("Message", COL_MSG, MainTabFrame)


    ---------------------------------
    --Group Listing Board Dropdowns--
    ---------------------------------
    ShowingFontStr = MainTabFrame:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
    ShowingFontStr:SetPoint("TOPLEFT", 65, 48)
    ShowingFontStr:SetWidth(54)
    ShowingFontStr:SetText("Showing: ")
    ShowingFontStr:SetJustifyH("LEFT")
    ShowingFontStr:SetJustifyV("MIDDLE")
    --Role Dropdown
    GroupieRoleDropdown = CreateFrame("Frame", "GroupieRoleDropdown", MainTabFrame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(GroupieRoleDropdown, DROPDOWN_WIDTH, DROPDOWN_PAD)
    GroupieRoleDropdown:SetPoint("TOPLEFT", DROPDOWN_LEFTOFFSET, 55)
    local function RoleDropdownOnClick(self, arg1)
        if arg1 == 0 then
            UIDropDownMenu_SetText(GroupieRoleDropdown, "LF Any Role")
            MainTabFrame.roleType = nil
        elseif arg1 == 1 then
            UIDropDownMenu_SetText(GroupieRoleDropdown, "LF Tank")
            MainTabFrame.roleType = 1
        elseif arg1 == 2 then
            UIDropDownMenu_SetText(GroupieRoleDropdown, "LF Healer")
            MainTabFrame.roleType = 2
        elseif arg1 == 3 then
            UIDropDownMenu_SetText(GroupieRoleDropdown, "LF DPS")
            MainTabFrame.roleType = 3
        end
    end

    local function RoleDropdownInit()
        --Create menu list
        local info = UIDropDownMenu_CreateInfo()
        info.func = RoleDropdownOnClick
        info.text, info.arg1, info.notCheckable = "LF Any Role", 0, true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = "LF Tank", 1, true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = "LF Healer", 2, true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = "LF DPS", 3, true
        UIDropDownMenu_AddButton(info)
    end

    --Initialize Shown Value
    UIDropDownMenu_Initialize(GroupieRoleDropdown, RoleDropdownInit)
    UIDropDownMenu_SetText(GroupieRoleDropdown, "LF Any Role")
    MainTabFrame.roleType = nil

    --Loot Type Dropdown
    GroupieLootDropdown = CreateFrame("Frame", "GroupieLootDropdown", MainTabFrame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(GroupieLootDropdown, DROPDOWN_WIDTH, DROPDOWN_PAD)
    GroupieLootDropdown:SetPoint("TOPLEFT", DROPDOWN_LEFTOFFSET + DROPDOWN_WIDTH + DROPDOWN_PAD, 55)
    local function LootDropdownOnClick(self, arg1)
        if arg1 == 0 then
            UIDropDownMenu_SetText(GroupieLootDropdown, "All Loot Styles")
            MainTabFrame.lootType = nil
        elseif arg1 == 1 then
            UIDropDownMenu_SetText(GroupieLootDropdown, "MS > OS")
            MainTabFrame.lootType = "MS > OS"
        elseif arg1 == 2 then
            UIDropDownMenu_SetText(GroupieLootDropdown, "SoftRes")
            MainTabFrame.lootType = "SoftRes"
        elseif arg1 == 3 then
            UIDropDownMenu_SetText(GroupieLootDropdown, "GDKP")
            MainTabFrame.lootType = "GDKP"
        elseif arg1 == 4 then
            UIDropDownMenu_SetText(GroupieLootDropdown, "TICKET")
            MainTabFrame.lootType = "TICKET"
        end
    end

    local function LootDropdownInit()
        --Create menu list
        local info = UIDropDownMenu_CreateInfo()
        info.func = LootDropdownOnClick
        info.text, info.arg1, info.notCheckable = "All Loot Styles", 0, true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = "MS > OS", 1, true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = "SoftRes", 2, true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = "GDKP", 3, true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = "TICKET", 4, true
        UIDropDownMenu_AddButton(info)
    end

    --Initialize Shown Value
    UIDropDownMenu_Initialize(GroupieLootDropdown, LootDropdownInit)
    UIDropDownMenu_SetText(GroupieLootDropdown, "All Loot Styles")
    MainTabFrame.lootType = nil

    --Language Dropdown
    GroupieLangDropdown = CreateFrame("Frame", "GroupieLangDropdown", MainTabFrame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(GroupieLangDropdown, DROPDOWN_WIDTH, DROPDOWN_PAD)
    GroupieLangDropdown:SetPoint("TOPLEFT", DROPDOWN_LEFTOFFSET + (DROPDOWN_WIDTH + DROPDOWN_PAD) * 2, 55)
    local function LangDropdownOnClick(self, arg1)
        if arg1 == 0 then
            UIDropDownMenu_SetText(GroupieLangDropdown, "All Languages")
            MainTabFrame.lang = nil
        else
            UIDropDownMenu_SetText(GroupieLangDropdown, addon.groupieLangList[arg1])
            MainTabFrame.lang = addon.groupieLangList[arg1]
        end
    end

    local function LangDropdownInit()
        --Create menu list
        local info = UIDropDownMenu_CreateInfo()
        info.func = LangDropdownOnClick
        info.text, info.arg1, info.notCheckable = "All Languages", 0, true
        UIDropDownMenu_AddButton(info)

        for i = 1, #addon.groupieLangList do
            info.text, info.arg1, info.notCheckable = addon.groupieLangList[i], i, true
            UIDropDownMenu_AddButton(info)
        end
    end

    --Initialize Shown Value
    UIDropDownMenu_Initialize(GroupieLangDropdown, LangDropdownInit)
    UIDropDownMenu_SetText(GroupieLangDropdown, "All Languages")
    MainTabFrame.lang = nil

    --Dungeon Level Dropdown
    GroupieLevelDropdown = CreateFrame("Frame", "GroupieLevelDropdown", MainTabFrame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(GroupieLevelDropdown, DROPDOWN_WIDTH * 2, DROPDOWN_PAD)
    GroupieLevelDropdown:SetPoint("TOPLEFT", DROPDOWN_LEFTOFFSET + (DROPDOWN_WIDTH + DROPDOWN_PAD) * 3, 55)
    local function LevelDropdownOnClick(self, arg1)
        if arg1 == 0 then
            UIDropDownMenu_SetText(GroupieLevelDropdown, "Recommended Level Dungeons")
            MainTabFrame.levelFilter = true
        else
            UIDropDownMenu_SetText(GroupieLevelDropdown, "All Dungeons")
            MainTabFrame.levelFilter = false
        end
    end

    local function LevelDropdownInit()
        --Create menu list
        local info = UIDropDownMenu_CreateInfo()
        info.func = LevelDropdownOnClick
        info.text, info.arg1, info.notCheckable = "Recommended Level Dungeons", 0, true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = "All Dungeons", 1, true
        UIDropDownMenu_AddButton(info)
    end

    --Initialize Shown Value
    UIDropDownMenu_Initialize(GroupieLevelDropdown, LevelDropdownInit)
    UIDropDownMenu_SetText(GroupieLevelDropdown, "Recommended Level Dungeons")
    MainTabFrame.levelFilter = true

    --Settings Button
    GroupieSettingsButton = CreateFrame("Button", "GroupieTopFrame", MainTabFrame, "UIPanelButtonTemplate")
    GroupieSettingsButton:SetSize(100, 22)
    GroupieSettingsButton:SetText("Settings")
    GroupieSettingsButton:SetPoint("TOPRIGHT", 0, 55)
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

    PanelTemplates_SetNumTabs(GroupieFrame, 9)
    PanelTemplates_SetTab(GroupieFrame, 1)

    GroupieFrame:Show()
end

--Minimap Icon Creation
addon.groupieLDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
    type = "data source",
    text = addonName,
    icon = "Interface\\AddOns\\" .. addonName .. "\\Images\\icon64.tga",
    OnClick = function(self, button, down)
        if button == "LeftButton" then
            BuildGroupieWindow()
        else
            addon:OpenConfig()
        end
    end,
    OnTooltipShow = function(tooltip)
        local now = time()
        tooltip:AddLine(addonName)
        tooltip:AddLine("A better LFG tool for Classic WoW.", 255, 255, 255, false)
        tooltip:AddLine(" ")
        tooltip:AddLine("Click |cffffffffor|r /groupie |cffffffff: Open " .. addonName .. "|r ")
        tooltip:AddLine(" ")
        tooltip:AddLine("Right Click |cffffffff: Open " .. addonName .. " Settings|r ")
        --TODO: Version check
        for _, order in ipairs(addon.instanceOrders) do
            local val = addon.db.global.savedInstanceInfo[order]
            if val then
                local titleFlag = false
                local numindex = {}
                local idx = 1
                for player, lockout in pairs(val) do
                    numindex[idx] = player
                    idx = idx + 1
                end
                sort(numindex, function(a, b) return a < b end)

                if val ~= nil then
                    for i, player in pairs(numindex) do
                        local lockout = val[player]
                        if lockout.resetTime > now then
                            if not titleFlag then
                                titleFlag = true
                                tooltip:AddLine(" ")
                                tooltip:AddLine(lockout.instance, 255, 255, 255, false)
                                tooltip:AddLine("|cff9E9E9E  Reset : " .. addon.GetTimeSinceString(lockout.resetTime, 4))
                            end
                            tooltip:AddLine("    |cff" .. lockout.classColor .. player .. "|r")
                        end
                    end
                end
            end
        end
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
            lastServer = nil,
            minsToPreserve = 5,
            font = "Arial Narrow",
            fontSize = 8,
            debugData = {},
            listingTable = {},
            showMinimap = true,
            ignoreSavedInstances = true,
            ignoreLFM = false,
            ignoreLFG = false,
            keywordBlacklist = {},
            savedInstanceInfo = {}
        }
    }
    --Generate defaults for each individual dungeon filter
    for key, val in pairs(addon.groupieInstanceData) do
        defaults.char.hideInstances[key] = false
    end
    addon.db = LibStub("AceDB-3.0"):New("GroupieDB", defaults)
    addon.icon = LibStub("LibDBIcon-1.0")

    addon.icon:Register("GroupieLDB", addon.groupieLDB, addon.db.global or defaults.global)
    addon.icon:Hide("GroupieLDB")

    --Build the main UI
    BuildGroupieWindow()

    --Debug variable defaults to false
    addon.debugMenus = false

    --Setup team member tooltips
    GameTooltip:HookScript("OnTooltipSetUnit", function(...)
        local unitname, unittype = GameTooltip:GetUnit()
        local curMouseOver = UnitGUID(unittype)
        if addon.GroupieDevs[curMouseOver] then
            GameTooltip:AddLine(format("|TInterface\\AddOns\\" .. addonName .. "\\Images\\icon64:16:16:0:0|t %s : %s",
                addonName, addon.GroupieDevs[curMouseOver]))
        end
    end)

    --Setup Slash Commands
    local function ToggleDebugMode()
        addon.debugMenus = not addon.debugMenus
        print("GROUPIE DEBUG MODE: " .. tostring(addon.debugMenus))
    end

    local function TestRunner(...)
        local module = addon:GetArgs(..., 1)
        module = module and module:lower()

        local modules = {}
        for k, v in pairs(addon) do
            if type(v) == "table" and v.SPEC then
                modules[k:lower()] = v
            end
        end
        if modules[module] then
            modules[module].SPEC:run()
        else
            print("No testable module found for " .. module)
        end
    end

    addon:RegisterChatCommand("groupie", BuildGroupieWindow)
    addon:RegisterChatCommand("groupiecfg", addon.OpenConfig)
    addon:RegisterChatCommand("groupiedebug", ToggleDebugMode)
    addon:RegisterChatCommand("groupietest", TestRunner)

    addon.isInitialized = true
end

---------------------
-- AceConfig Setup --
---------------------
function addon.SetupConfig()
    addon.options = {
        name = "|TInterface\\AddOns\\" .. addonName .. "\\Images\\icon64:32:32:0:12|t" .. addonName,
        desc = "Optional description? for the group of options",
        descStyle = "inline",
        handler = addon,
        type = 'group',
        args = {
            spacerdesc0 = { type = "description", name = " ", width = "full", order = 0 },
            about = {
                name = "About",
                desc = "About Groupie",
                type = "group",
                width = "double",
                inline = false,
                order = 11,
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
                        get = function(info) return "https://www.curseforge.com/wow/addons/groupie" end,
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
                        get = function(info) return "https://github.com/Gogo1951/Groupie" end,
                        set = function(info, val) return end,
                    },
                    spacerdesc4 = { type = "description", name = " ", width = "full", order = 10 },
                    paragraph1 = {
                        type = "description",
                        name = "put_text_here",
                        width = "full",
                        order = 11,
                        fontSize = "small", --can be small, medium, large
                    },
                }
            },
            instancefiltersWrath = {
                name = "Instance Filters - Wrath",
                desc = "Filter Groups by Instance",
                type = "group",
                width = "double",
                inline = false,
                order = 4,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cffffd900" .. addonName .. " | Instance Filters - Wrath",
                        order = 0,
                        fontSize = "large"
                    },

                }
            },
            instancefiltersTBC = {
                name = "Instance Filters - TBC",
                desc = "Filter Groups by Instance",
                type = "group",
                width = "double",
                inline = false,
                order = 5,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cffffd900" .. addonName .. " | Instance Filters - TBC",
                        order = 0,
                        fontSize = "large"
                    },

                }
            },
            instancefiltersClassic = {
                name = "Instance Filters - Classic",
                desc = "Filter Groups by Instance",
                type = "group",
                width = "double",
                inline = false,
                order = 6,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cffffd900" .. addonName .. " | Instance Filters - Classic",
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
                        values = { [2] = "2 Minutes", [5] = "5 Minutes", [10] = "10 Minutes", [20] = "20 Minutes" },
                        set = function(info, val) addon.db.global.minsToPreserve = val end,
                        get = function(info) return addon.db.global.minsToPreserve end,
                    },
                    spacerdesc4 = { type = "description", name = " ", width = "full", order = 8 },
                    header3 = {
                        type = "description",
                        name = "|cffffd900Font",
                        order = 9,
                        fontSize = "medium",
                        hidden = true,
                        disabled = true,
                    },
                    fontDropdown = {
                        type = "select",
                        style = "dropdown",
                        name = "",
                        order = 10,
                        width = 1.4,
                        values = addon.TableFlip(SharedMedia:HashTable("font")),
                        hidden = true,
                        disabled = true,
                        set = function(info, val) addon.db.global.font = val end,
                        get = function(info) return addon.db.global.font end,
                    },
                    spacerdesc5 = { type = "description", name = " ", width = "full", order = 11 },
                    header4 = {
                        type = "description",
                        name = "|cffffd900Base Font Size",
                        order = 12,
                        fontSize = "medium",
                        hidden = true,
                        disabled = true,
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
                        hidden = true,
                        disabled = true,
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
    addon.GenerateInstanceToggles(1, "Wrath of the Lich King Heroic Raids - 25", false, "instancefiltersWrath")
    addon.GenerateInstanceToggles(101, "Wrath of the Lich King Heroic Raids - 10", false, "instancefiltersWrath")
    addon.GenerateInstanceToggles(201, "Wrath of the Lich King Raids - 25", false, "instancefiltersWrath")
    addon.GenerateInstanceToggles(301, "Wrath of the Lich King Raids - 10", false, "instancefiltersWrath")
    addon.GenerateInstanceToggles(401, "Wrath of the Lich King Heroic Dungeons", false, "instancefiltersWrath")
    addon.GenerateInstanceToggles(501, "Wrath of the Lich King Dungeons", true, "instancefiltersWrath")
    addon.GenerateInstanceToggles(601, "The Burning Crusade Raids", false, "instancefiltersTBC")
    addon.GenerateInstanceToggles(701, "The Burning Crusade Heroic Dungeons", true, "instancefiltersTBC")
    addon.GenerateInstanceToggles(801, "The Burning Crusade Dungeons", true, "instancefiltersTBC")
    addon.GenerateInstanceToggles(901, "Classic Raids", false, "instancefiltersClassic")
    addon.GenerateInstanceToggles(1001, "Classic Dungeons", true, "instancefiltersClassic")
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

    --Update some saved variables for the current character
    addon.UpdateSpecOptions()
    addon.UpdateSavedInstances()

    --Don't preserve Data if switching servers
    local currentServer = GetRealmName()
    if currentServer ~= addon.db.global.lastServer then
        addon.db.global.listingTable = {}
    end
    addon.db.global.lastServer = currentServer
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
addon:RegisterEvent("BOSS_KILL", addon.UpdateSavedInstances)


addon:RegisterEvent("PLAYER_LEAVE_COMBAT", function() print('test test test') end)
