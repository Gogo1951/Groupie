local addonName, Groupie           = ...
local locale                       = GetLocale()
local addon                        = LibStub("AceAddon-3.0"):NewAddon(Groupie, addonName, "AceEvent-3.0",
    "AceConsole-3.0",
    "AceTimer-3.0")
local L                            = LibStub('AceLocale-3.0'):GetLocale('Groupie')
local localizedClass, englishClass = UnitClass("player")

-------------------------
--Unsupported Locale UI--
-------------------------
if not addon.tableContains(addon.validLocales, locale) then
    local GroupieFrame = nil
    local function BuildGroupieWindow()
        local LOCALE_WINDOW_WIDTH = 400
        local LOCALE_WINDOW_HEIGHT = 200
        GroupieFrame = CreateFrame("Frame", "Groupie", UIParent, "PortraitFrameTemplate")
        GroupieFrame:Hide()
        GroupieFrame:SetFrameStrata("DIALOG")
        GroupieFrame:SetWidth(LOCALE_WINDOW_WIDTH)
        GroupieFrame:SetHeight(LOCALE_WINDOW_HEIGHT)
        GroupieFrame:SetPoint("CENTER", UIParent)
        GroupieFrame:SetMovable(true)
        GroupieFrame:EnableMouse(true)
        GroupieFrame:RegisterForDrag("LeftButton", "RightButton")
        GroupieFrame:SetClampedToScreen(true)
        GroupieFrame.text = _G["GroupieTitleText"]
        GroupieFrame.text:SetText(addonName)
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
        --Icon
        local icon = GroupieFrame:CreateTexture("$parentIcon", "OVERLAY", nil, -8)
        icon:SetSize(60, 60)
        icon:SetPoint("TOPLEFT", -5, 7)
        icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Images\\icon128.tga")
        --Info Text
        local msg = GroupieFrame:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
        msg:SetPoint("TOPLEFT", GroupieFrame, "TOPLEFT", 16, -64)
        msg:SetWidth(LOCALE_WINDOW_WIDTH - 32)
        msg:SetText("Localization is Coming Soon!\n\nUnfortunately, until then Groupie is Disabled for your locale.\nIf you'd like to help with Development or Translation, you can join our Discord.")
        --Edit Box for Discord Link
        local editBox = CreateFrame("EditBox", "GroupieEditBox", GroupieFrame, "InputBoxTemplate")
        editBox:SetPoint("TOPLEFT", GroupieFrame, "TOPLEFT", 64, -128)
        editBox:SetSize(LOCALE_WINDOW_WIDTH - 128, 50)
        editBox:SetAutoFocus(false)
        editBox:SetText("https://discord.gg/p68QgZ8uqF")
        editBox:SetScript("OnTextChanged", function()
            editBox:SetText("https://discord.gg/p68QgZ8uqF")
        end)
        GroupieFrame:Show()
    end

    BuildGroupieWindow()

    addon.groupieLDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
        type = "data source",
        text = addonName,
        icon = "Interface\\AddOns\\" .. addonName .. "\\Images\\icon64.tga",
        OnClick = function(self, button, down)
            if button == "LeftButton" then
                if GroupieFrame:IsShown() then
                    GroupieFrame:Hide()
                else
                    BuildGroupieWindow()
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(addonName)
            tooltip:AddLine("A better LFG tool for Classic WoW.", 255, 255, 255, false)
            tooltip:AddLine(" ")
            tooltip:AddLine("Localization Coming Soon!")
        end
    })

    local defaults = {
        global = {
        }
    }
    addon.db = LibStub("AceDB-3.0"):New("GroupieDB", defaults)
    addon.icon = LibStub("LibDBIcon-1.0")
    addon.icon:Register("GroupieLDB", addon.groupieLDB, addon.db.global or defaults.global)
    addon.icon:Hide("GroupieLDB")
    return
end

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
local COL_LEADER            = 105
local COL_INSTANCE          = 135
local COL_LOOT              = 76
local DROPDOWN_WIDTH        = 100
local DROPDOWN_LEFTOFFSET   = 115
local DROPDOWN_PAD          = 32
local APPLY_BTN_WIDTH       = 64

local COL_MSG = WINDOW_WIDTH - COL_CREATED - COL_TIME - COL_LEADER - COL_INSTANCE - COL_LOOT - ICON_WIDTH -
    APPLY_BTN_WIDTH - 58

local SharedMedia = LibStub("LibSharedMedia-3.0")
local gsub        = gsub
local time        = time

addon.groupieBoardButtons = {}
addon.filteredListings    = {}
addon.selectedListing     = nil
addon.ADDON_PREFIX        = "Groupie.Core"

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
            if listing.lootType ~= L["Filters"].Loot_Styles.PVP then
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
            if listing.lootType ~= L["Filters"].Loot_Styles.Other then
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
            elseif listing.lootType == L["Filters"].Loot_Styles.Other or listing.lootType == L["Filters"].Loot_Styles.PVP then
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
    local myName = UnitName("player") .. "-" .. gsub(GetRealmName(), " ", "")
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
            button.leader:SetText("|cFF" .. listing.classColor .. gsub(listing.author, "-.+", ""))
            button.instance:SetText(listing.instanceName)
            button.loot:SetText("|cFF" .. lootColor .. listing.lootType)
            button.msg:SetText(formattedMsg)
            local texture = listing.icon
            if type(listing.icon) == "string" then
                if listing.icon:find("Interface\\") then -- it's a full path
                    texture = listing.icon
                else
                    texture = "Interface\\AddOns\\" .. addonName .. "\\Images\\InstanceIcons\\" .. listing.icon
                end
            end
            button.icon:SetTexture(texture)
            button.btn:SetScript("OnClick", function()
                addon.SendPlayerInfo(listing.author, nil, nil, listing.fullName, listing.resultID)
            end)
            if myName == button.listing.author and not addon.debugMenus then
                button.btn:Hide()
            else
                button.btn:Show()
            end
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
    local resultID = addon.groupieBoardButtons[addon.selectedListing].listing.resultID
    DrawListings(LFGScrollFrame)

    --Select a listing, if shift is held, do a Who Request
    if button == "LeftButton" then
        if addon.debugMenus then
            --print(addon.groupieBoardButtons[addon.selectedListing].listing.isLFM)
            --print(addon.groupieBoardButtons[addon.selectedListing].listing.isLFG)
            --print(addon.groupieBoardButtons[addon.selectedListing].listing.timestamp)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.instanceName)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.fullName)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.isHeroic)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.groupSize)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.lootType)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.rolesNeeded)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.msg)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.author)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.words)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.minLevel)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.maxLevel)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.order)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.instanceID)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.resultID)
            print(addon.groupieBoardButtons[addon.selectedListing].listing.createdat)
            for k, v in pairs(addon.groupieBoardButtons[addon.selectedListing].listing.rolesNeeded) do
                print(v)
            end
        end
        if IsShiftKeyDown() then
            DEFAULT_CHAT_FRAME.editBox:SetText("/who " .. fullName)
            ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox)
        end
        --Open Right click Menu
    elseif button == "RightButton" then
        local activeSpecGroup = addon.GetActiveSpecGroup()
        local maxTalentSpec, maxTalentsSpent = addon.GetSpecByGroupNum(activeSpecGroup)
        local isIgnored = C_FriendList.IsIgnored(displayName)
        local ignoreText = L["RightClickMenu"].Ignore
        local activeRole = ""

        if activeSpecGroup == 1 then
            activeRole = addon.groupieRoleTable[addon.db.char.groupieSpec1Role]
        else
            activeRole = addon.groupieRoleTable[addon.db.char.groupieSpec2Role]
        end

        if isIgnored then
            ignoreText = L["RightClickMenu"].StopIgnore
        end

        local ListingRightClick = {
            { text = displayName, isTitle = true, notCheckable = true },
            { text = L["RightClickMenu"].Invite, notCheckable = true, func = function() InviteUnit(displayName) end },
            { text = L["RightClickMenu"].Whisper, notCheckable = true, func = function()
                ChatFrame_OpenChat("/w " .. fullName .. " ")
            end },
            { text = ignoreText, notCheckable = true, func = function()
                C_FriendList.AddOrDelIgnore(displayName)
            end },
            { text = "", disabled = true, notCheckable = true },
            { text = addonName, isTitle = true, notCheckable = true },
            { text = L["RightClickMenu"].SendInfo, notClickable = true, notCheckable = true },
            { text = format(L["RightClickMenu"].Current .. " : %s (%s)", maxTalentSpec, activeRole), notCheckable = true,
                leftPadding = 8,
                func = function()
                    if instance ~= "Miscellaneous" and instance ~= L["Filters"].Loot_Styles.PVP then
                        addon.SendPlayerInfo(fullName, nil, nil, fullInstance, resultID)
                    else
                        addon.SendPlayerInfo(fullName)
                    end
                end },
        }
        if GetLocale() == "enUS" then
            tinsert(ListingRightClick, { text = L["RightClickMenu"].WCL, notCheckable = true, leftPadding = 8,
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
        currentListing.time = currentListing:CreateFontString("FontString", "OVERLAY", "GameFontNormal")
        currentListing.time:SetPoint("LEFT", currentListing.created, "RIGHT", 0, 0)
        currentListing.time:SetWidth(COL_TIME)
        currentListing.time:SetJustifyH("LEFT")
        currentListing.time:SetJustifyV("MIDDLE")

        --Leader name column
        currentListing.leader = currentListing:CreateFontString("FontString", "OVERLAY", "GameFontNormal")
        currentListing.leader:SetPoint("LEFT", currentListing.time, "RIGHT", -4, 0)
        currentListing.leader:SetWidth(COL_LEADER)
        currentListing.leader:SetJustifyH("LEFT")
        currentListing.leader:SetJustifyV("MIDDLE")

        --Instance expansion column
        currentListing.icon = currentListing:CreateTexture("$parentIcon", "OVERLAY", nil, -8)
        currentListing.icon:SetSize(ICON_WIDTH, ICON_WIDTH / 2)
        currentListing.icon:SetPoint("LEFT", currentListing.leader, "RIGHT", -4, 0)
        currentListing.icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Images\\InstanceIcons\\Other.tga")

        --Instance name column
        currentListing.instance = currentListing:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
        currentListing.instance:SetPoint("LEFT", currentListing.icon, "RIGHT", 8, 0)
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

        --Apply button
        currentListing.btn = CreateFrame("Button", "$parentApplyBtn", currentListing, "UIPanelButtonTemplate")
        currentListing.btn:SetPoint("LEFT", currentListing.msg, "RIGHT", 4, 0)
        currentListing.btn:SetWidth(APPLY_BTN_WIDTH)
        currentListing.btn:SetText("LFG")
        currentListing.btn:SetScript("OnClick", function()
            return
        end)


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

    if text == L["UI_columns"].Message then
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
local function TimerListingUpdate()
    if not addon.lastUpdate then
        addon.lastUpdate = time()
    end

    if time() - addon.lastUpdate > 1 then
        DrawListings(LFGScrollFrame)
    end
end

--Set environment variables when switching group tabs
local function TabSwap(isHeroic, size, tabType, tabNum)
    addon.ExpireListings()
    MainTabFrame:Show()

    --Reset environment values
    MainTabFrame.isHeroic = isHeroic
    MainTabFrame.size = size
    MainTabFrame.tabType = tabNum
    MainTabFrame.sortType = -1
    MainTabFrame.sortDir = false
    --Reset dropdowns
    UIDropDownMenu_SetText(GroupieRoleDropdown, L["Filters"].Roles.LookingFor .. " " .. L["Filters"].Roles.Any)
    MainTabFrame.roleType = nil
    UIDropDownMenu_SetText(GroupieLootDropdown, L["Filters"].Loot_Styles.AnyLoot)
    MainTabFrame.lootType = nil
    UIDropDownMenu_SetText(GroupieLangDropdown, L["Filters"].AnyLanguage)
    MainTabFrame.lang = nil
    UIDropDownMenu_SetText(GroupieLevelDropdown, L["Filters"].Dungeons.RecommendedDungeon)
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
        local GroupieGroupBrowser = Groupie:GetModule("GroupieGroupBrowser")
        if GroupieGroupBrowser then
            GroupieGroupBrowser:AttachLFGToolPreset(GroupieTab1, 2)
            GroupieGroupBrowser:AttachLFGToolPreset(GroupieTab2, 2)
            GroupieGroupBrowser:AttachLFGToolPreset(GroupieTab3, 114)
            GroupieGroupBrowser:AttachLFGToolPreset(GroupieTab5, 114)
            GroupieGroupBrowser:AttachLFGToolPreset(GroupieTab4, 114)
            GroupieGroupBrowser:AttachLFGToolPreset(GroupieTab6, 114)
            GroupieGroupBrowser:AttachLFGToolPreset(GroupieTab7, 118)
        end
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
    GroupieFrame.title:SetText(addonName .. " - v" .. tostring(addon.version))
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
    DungeonTabButton:SetText(L["UI_tabs"].Dungeon)
    DungeonTabButton:SetID("1")
    DungeonTabButton:SetScript("OnClick",
        function(self)
            TabSwap(false, 5, 0, 1)
        end)

    local DungeonHTabButton = CreateFrame("Button", "GroupieTab2", GroupieFrame, "CharacterFrameTabButtonTemplate")
    DungeonHTabButton:SetPoint("LEFT", "GroupieTab1", "RIGHT", -16, 0)
    DungeonHTabButton:SetText(L["UI_tabs"].Dungeon .. ' (' .. L["UI_tabs"].ShortHeroic .. ')')
    DungeonHTabButton:SetID("2")
    DungeonHTabButton:SetScript("OnClick",
        function(self)
            TabSwap(true, 5, 0, 2)
        end)

    local Raid10TabButton = CreateFrame("Button", "GroupieTab3", GroupieFrame, "CharacterFrameTabButtonTemplate")
    Raid10TabButton:SetPoint("LEFT", "GroupieTab2", "RIGHT", -16, 0)
    Raid10TabButton:SetText(L["UI_tabs"].Raid .. " (10)")
    Raid10TabButton:SetID("3")
    Raid10TabButton:SetScript("OnClick",
        function(self)
            TabSwap(false, 10, 0, 3)
        end)

    local Raid25TabButton = CreateFrame("Button", "GroupieTab4", GroupieFrame, "CharacterFrameTabButtonTemplate")
    Raid25TabButton:SetPoint("LEFT", "GroupieTab3", "RIGHT", -16, 0)
    Raid25TabButton:SetText(L["UI_tabs"].Raid .. " (25)")
    Raid25TabButton:SetID("4")
    Raid25TabButton:SetScript("OnClick",
        function(self)
            TabSwap(false, 25, 0, 4)
        end)

    local RaidH10TabButton = CreateFrame("Button", "GroupieTab5", GroupieFrame, "CharacterFrameTabButtonTemplate")
    RaidH10TabButton:SetPoint("LEFT", "GroupieTab4", "RIGHT", -16, 0)
    RaidH10TabButton:SetText(L["UI_tabs"].Raid .. ' (10' .. L["UI_tabs"].ShortHeroic .. ')')
    RaidH10TabButton:SetID("5")
    RaidH10TabButton:SetScript("OnClick",
        function(self)
            TabSwap(true, 10, 0, 5)
        end)

    local RaidH25TabButton = CreateFrame("Button", "GroupieTab6", GroupieFrame, "CharacterFrameTabButtonTemplate")
    RaidH25TabButton:SetPoint("LEFT", "GroupieTab5", "RIGHT", -16, 0)
    RaidH25TabButton:SetText(L["UI_tabs"].Raid .. ' (25' .. L["UI_tabs"].ShortHeroic .. ')')
    RaidH25TabButton:SetID("6")
    RaidH25TabButton:SetScript("OnClick",
        function(self)
            TabSwap(true, 25, 0, 6)
        end)

    local PVPTabButton = CreateFrame("Button", "GroupieTab7", GroupieFrame, "CharacterFrameTabButtonTemplate")
    PVPTabButton:SetPoint("LEFT", "GroupieTab6", "RIGHT", -16, 0)
    PVPTabButton:SetText(L["UI_tabs"].PVP)
    PVPTabButton:SetID("7")
    PVPTabButton:SetScript("OnClick",
        function(self)
            TabSwap(nil, nil, 3, 7)
        end)

    local OtherTabButton = CreateFrame("Button", "GroupieTab8", GroupieFrame, "CharacterFrameTabButtonTemplate")
    OtherTabButton:SetPoint("LEFT", "GroupieTab7", "RIGHT", -16, 0)
    OtherTabButton:SetText(L["UI_tabs"].Other)
    OtherTabButton:SetID("8")
    OtherTabButton:SetScript("OnClick",
        function(self)
            TabSwap(nil, nil, 1, 8)
        end)

    local AllTabButton = CreateFrame("Button", "GroupieTab9", GroupieFrame, "CharacterFrameTabButtonTemplate")
    AllTabButton:SetPoint("LEFT", "GroupieTab8", "RIGHT", -16, 0)
    AllTabButton:SetText(L["UI_tabs"].All)
    AllTabButton:SetID("9")
    AllTabButton:SetScript("OnClick",
        function(self)
            TabSwap(nil, nil, 2, 9)
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
        TimerListingUpdate()
    end)
    MainTabFrame.infotext:Hide()

    MainTabFrame.isHeroic = false
    MainTabFrame.size = 5
    MainTabFrame.tabType = 0

    createColumn(L["UI_columns"].Created, COL_CREATED, MainTabFrame, -1)
    createColumn(L["UI_columns"].Updated, COL_TIME, MainTabFrame, 0)
    createColumn(L["UI_columns"].Leader, COL_LEADER, MainTabFrame, 1)
    createColumn(L["UI_columns"].InstanceName, COL_INSTANCE + ICON_WIDTH, MainTabFrame, 2)
    createColumn(L["UI_columns"].LootType, COL_LOOT, MainTabFrame, 3)
    createColumn(L["UI_columns"].Message, COL_MSG, MainTabFrame)


    ---------------------------------
    --Group Listing Board Dropdowns--
    ---------------------------------
    ShowingFontStr = MainTabFrame:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
    ShowingFontStr:SetPoint("TOPLEFT", 65, 48)
    ShowingFontStr:SetWidth(70)
    ShowingFontStr:SetText(L["ShowingLabel"] .. " : ")
    ShowingFontStr:SetJustifyH("LEFT")
    ShowingFontStr:SetJustifyV("MIDDLE")
    --Role Dropdown
    GroupieRoleDropdown = CreateFrame("Frame", "GroupieRoleDropdown", MainTabFrame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(GroupieRoleDropdown, DROPDOWN_WIDTH, DROPDOWN_PAD)
    GroupieRoleDropdown:SetPoint("TOPLEFT", DROPDOWN_LEFTOFFSET, 55)
    local function RoleDropdownOnClick(self, arg1)
        if arg1 == 0 then
            UIDropDownMenu_SetText(GroupieRoleDropdown, L["Filters"].Roles.LookingFor .. " " .. L["Filters"].Roles.Any)
            MainTabFrame.roleType = nil
        elseif arg1 == 1 then
            UIDropDownMenu_SetText(GroupieRoleDropdown, L["Filters"].Roles.LookingFor .. " " .. L["Filters"].Roles.Tank)
            MainTabFrame.roleType = 1
        elseif arg1 == 2 then
            UIDropDownMenu_SetText(GroupieRoleDropdown, L["Filters"].Roles.LookingFor .. " " .. L["Filters"].Roles.Healer)
            MainTabFrame.roleType = 2
        elseif arg1 == 3 then
            UIDropDownMenu_SetText(GroupieRoleDropdown, L["Filters"].Roles.LookingFor .. " " .. L["Filters"].Roles.DPS)
            MainTabFrame.roleType = 3
        end
    end

    local function RoleDropdownInit()
        --Create menu list
        local info = UIDropDownMenu_CreateInfo()
        info.func = RoleDropdownOnClick
        info.text, info.arg1, info.notCheckable = L["Filters"].Roles.LookingFor .. " " .. L["Filters"].Roles.Any, 0, true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = L["Filters"].Roles.LookingFor .. " " .. L["Filters"].Roles.Tank, 1,
            true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = L["Filters"].Roles.LookingFor .. " " .. L["Filters"].Roles.Healer, 2,
            true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = L["Filters"].Roles.LookingFor .. " " .. L["Filters"].Roles.DPS, 3, true
        UIDropDownMenu_AddButton(info)
    end

    --Initialize Shown Value
    UIDropDownMenu_Initialize(GroupieRoleDropdown, RoleDropdownInit)
    UIDropDownMenu_SetText(GroupieRoleDropdown, L["Filters"].Roles.LookingFor .. " " .. L["Filters"].Roles.Any)
    MainTabFrame.roleType = nil

    --Loot Type Dropdown
    GroupieLootDropdown = CreateFrame("Frame", "GroupieLootDropdown", MainTabFrame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(GroupieLootDropdown, DROPDOWN_WIDTH, DROPDOWN_PAD)
    GroupieLootDropdown:SetPoint("TOPLEFT", DROPDOWN_LEFTOFFSET + DROPDOWN_WIDTH + DROPDOWN_PAD, 55)
    local function LootDropdownOnClick(self, arg1)
        if arg1 == 0 then
            UIDropDownMenu_SetText(GroupieLootDropdown, L["Filters"].Loot_Styles.AnyLoot)
            MainTabFrame.lootType = nil
        elseif arg1 == 1 then
            UIDropDownMenu_SetText(GroupieLootDropdown, L["Filters"].Loot_Styles.MSOS)
            MainTabFrame.lootType = L["Filters"].Loot_Styles.MSOS
        elseif arg1 == 2 then
            UIDropDownMenu_SetText(GroupieLootDropdown, L["Filters"].Loot_Styles.SoftRes)
            MainTabFrame.lootType = L["Filters"].Loot_Styles.SoftRes
        elseif arg1 == 3 then
            UIDropDownMenu_SetText(GroupieLootDropdown, L["Filters"].Loot_Styles.GDKP)
            MainTabFrame.lootType = L["Filters"].Loot_Styles.GDKP
        elseif arg1 == 4 then
            UIDropDownMenu_SetText(GroupieLootDropdown, L["Filters"].Loot_Styles.Ticket)
            MainTabFrame.lootType = L["Filters"].Loot_Styles.Ticket
        end
    end

    local function LootDropdownInit()
        --Create menu list
        local info = UIDropDownMenu_CreateInfo()
        info.func = LootDropdownOnClick
        info.text, info.arg1, info.notCheckable = L["Filters"].Loot_Styles.AnyLoot, 0, true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = L["Filters"].Loot_Styles.MSOS, 1, true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = L["Filters"].Loot_Styles.SoftRes, 2, true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = L["Filters"].Loot_Styles.GDKP, 3, true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = L["Filters"].Loot_Styles.Ticket, 4, true
        UIDropDownMenu_AddButton(info)
    end

    --Initialize Shown Value
    UIDropDownMenu_Initialize(GroupieLootDropdown, LootDropdownInit)
    UIDropDownMenu_SetText(GroupieLootDropdown, L["Filters"].Loot_Styles.AnyLoot)
    MainTabFrame.lootType = nil

    --Language Dropdown
    GroupieLangDropdown = CreateFrame("Frame", "GroupieLangDropdown", MainTabFrame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(GroupieLangDropdown, DROPDOWN_WIDTH, DROPDOWN_PAD)
    GroupieLangDropdown:SetPoint("TOPLEFT", DROPDOWN_LEFTOFFSET + (DROPDOWN_WIDTH + DROPDOWN_PAD) * 2, 55)
    local function LangDropdownOnClick(self, arg1)
        if arg1 == 0 then
            UIDropDownMenu_SetText(GroupieLangDropdown, L["Filters"].AnyLanguage)
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
        info.text, info.arg1, info.notCheckable = L["Filters"].AnyLanguage, 0, true
        UIDropDownMenu_AddButton(info)

        for i = 1, #addon.groupieLangList do
            info.text, info.arg1, info.notCheckable = addon.groupieLangList[i], i, true
            UIDropDownMenu_AddButton(info)
        end
    end

    --Initialize Shown Value
    UIDropDownMenu_Initialize(GroupieLangDropdown, LangDropdownInit)
    UIDropDownMenu_SetText(GroupieLangDropdown, L["Filters"].AnyLanguage)
    MainTabFrame.lang = nil

    --Dungeon Level Dropdown
    GroupieLevelDropdown = CreateFrame("Frame", "GroupieLevelDropdown", MainTabFrame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(GroupieLevelDropdown, DROPDOWN_WIDTH * 2, DROPDOWN_PAD)
    GroupieLevelDropdown:SetPoint("TOPLEFT", DROPDOWN_LEFTOFFSET + (DROPDOWN_WIDTH + DROPDOWN_PAD) * 3, 55)
    local function LevelDropdownOnClick(self, arg1)
        if arg1 == 0 then
            UIDropDownMenu_SetText(GroupieLevelDropdown, L["Filters"].Dungeons.RecommendedDungeon)
            MainTabFrame.levelFilter = true
        else
            UIDropDownMenu_SetText(GroupieLevelDropdown, L["Filters"].Dungeons.AnyDungeon)
            MainTabFrame.levelFilter = false
        end
    end

    local function LevelDropdownInit()
        --Create menu list
        local info = UIDropDownMenu_CreateInfo()
        info.func = LevelDropdownOnClick
        info.text, info.arg1, info.notCheckable = L["Filters"].Dungeons.RecommendedDungeon, 0, true
        UIDropDownMenu_AddButton(info)
        info.text, info.arg1, info.notCheckable = L["Filters"].Dungeons.AnyDungeon, 1, true
        UIDropDownMenu_AddButton(info)
    end

    --Initialize Shown Value
    UIDropDownMenu_Initialize(GroupieLevelDropdown, LevelDropdownInit)
    UIDropDownMenu_SetText(GroupieLevelDropdown, L["Filters"].Dungeons.RecommendedDungeon)
    MainTabFrame.levelFilter = true

    --Settings Button
    GroupieSettingsButton = CreateFrame("Button", "GroupieTopFrame", MainTabFrame, "UIPanelButtonTemplate")
    GroupieSettingsButton:SetSize(150, 22)
    GroupieSettingsButton:SetText(L["SettingsButton"])
    GroupieSettingsButton:SetPoint("TOPRIGHT", 0, 55)
    GroupieSettingsButton:SetScript("OnClick", function()
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


    PanelTemplates_SetNumTabs(GroupieFrame, 9)
    PanelTemplates_SetTab(GroupieFrame, 1)

    -------------
    --Statusbar--
    -------------
    --[[ May be useful in building the group builder tool later 
    local status = CreateFrame("Frame", nil, GroupieFrame)
    status:SetPoint("TOPLEFT", GroupieFrame.Bg, "BOTTOMLEFT", 5, 30)
    status:SetPoint("BOTTOMRIGHT", -10, 5)
    status.LookingForGroup = CreateFrame("Frame", nil, status)
    status.LookingForGroup:SetPoint("BOTTOMRIGHT", status, "BOTTOMRIGHT", -5, 0)
    status.LookingForGroup:SetPoint("TOPLEFT", status, "BOTTOMRIGHT", -150 - 5, 25)
    status.LookingForGroup.label = status.LookingForGroup:CreateFontString("FontString", "OVERLAY", "GameFontNormal")
    status.LookingForGroup.label:SetShadowColor(0, 0, 0, 1)
    status.LookingForGroup.label:SetShadowOffset(2, -2)
    status.LookingForGroup.label:SetAllPoints(status.LookingForGroup)
    status.LookingForGroup.label:SetText("LookingForGroup")
    status.LookingForGroup.highlight = status.LookingForGroup:CreateTexture(nil, "HIGHLIGHT")
    status.LookingForGroup.highlight:SetTexture(nil)
    status.LookingForGroup.highlight:SetAllPoints()
    status.LookingForGroup.highlight:SetBlendMode("ADD")
    status.LookingForGroup.key = "LookingForGroup"
    status.LookingForGroup.hint = "Left Click: Join LookingForGroup channel\nRight Click: Join Group Finder"
    status.LookingForGroup:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(self.key)
        GameTooltip:AddLine(self.hint or " ")
        GameTooltip:Show()
    end)
    status.LookingForGroup:SetScript("OnLeave", function(self)
        if GameTooltip:IsOwned(self) then
            GameTooltip:Hide()
        end
    end)
    status.LookingForGroup:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            local joined = GetChannelName((GetChannelName("LookingForGroup")))
            if joined == 0 then
                JoinPermanentChannel("LookingForGroup", nil, DEFAULT_CHAT_FRAME:GetID())
            end
        elseif button == "RightButton" then
            if not C_LFGList.HasActiveEntryInfo() then
                local lfg_loaded = UIParentLoadAddOn("Blizzard_LookingForGroupUI")
                if lfg_loaded then
                    local success = C_LFGList.CreateListing({ 1064 }, true) -- Custom
                    if success then
                        local joined = GetChannelName((GetChannelName("LookingForGroup")))
                        if joined == 0 then
                            JoinPermanentChannel("LookingForGroup", nil, DEFAULT_CHAT_FRAME:GetID())
                        end
                    end
                end
            end
        end
    end)
    --]]

    GroupieFrame:SetScale(addon.db.global.UIScale)
    GroupieFrame:Show()
end

--Minimap Icon Creation
addon.groupieLDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
    type = "data source",
    text = addonName,
    icon = "Interface\\AddOns\\" .. addonName .. "\\Images\\icon64.tga",
    OnClick = function(self, button, down)
        if button == "LeftButton" then
            if GroupieFrame:IsShown() then
                GroupieFrame:Hide()
            else
                BuildGroupieWindow()
            end
        else
            addon:OpenConfig()
        end
    end,
    OnTooltipShow = function(tooltip)
        addon.ExpireSavedInstances()
        local now = time()
        tooltip:AddLine(addonName .. " - v" .. tostring(addon.version))
        tooltip:AddLine(L["slogan"], 255, 255, 255, false)
        tooltip:AddLine(" ")
        tooltip:AddLine(L["Click"] ..
            " |cffffffff" ..
            L["MiniMap"].lowerOr .. "|r /groupie |cffffffff: " .. addonName .. " " .. L["BulletinBoard"] .. "|r ")
        tooltip:AddLine(L["RightClick"] .. " |cffffffff: " .. addonName .. " " .. L["Settings"] .. "|r ")
        --Version Check
        if addon.version < addon.db.global.highestSeenVersion then
            tooltip:AddLine(" ");
            tooltip:AddLine("|cff8000FF" .. L["MiniMap"].Update1 .. "|r")
            tooltip:AddLine("|cff8000FF" .. L["MiniMap"].Update2 .. "|r")
        end
        --Asking for saved instance data
        if not addon.tableContains(addon.completedLocales, locale) then
            tooltip:AddLine(" ");
            tooltip:AddLine("|cff8000FF" .. L["MiniMap"].HelpUs .. "|r")
        end
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
                                tooltip:AddDoubleLine(lockout.instance,
                                    "        " .. addon.GetTimeSinceString(lockout.resetTime, 4),
                                    255, 255, 255, 158, 158, 158)
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
            autoRespondInvites = true,
            autoRespondRequests = true,
            afterParty = true,
            useChannels = {
                [L["text_channels"].Guild] = true,
                [L["text_channels"].General] = true,
                [L["text_channels"].Trade] = true,
                [L["text_channels"].LocalDefense] = true,
                [L["text_channels"].LFG] = true,
                [L["text_channels"].World] = true,
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
            hideInstances = {},
            sendOtherRole = false,
            configVer = nil,
        },
        global = {
            lastServer = nil,
            minsToPreserve = 5,
            debugData = {},
            listingTable = {},
            showMinimap = true,
            ignoreSavedInstances = true,
            ignoreLFM = false,
            ignoreLFG = true,
            keywordBlacklist = {},
            savedInstanceInfo = {},
            needsUpdateFlag = false,
            highestSeenVersion = 0,
            UIScale = 1.0,
            savedInstanceLogs = {},
            friendsAndGuild = {},
            ignores = {},
            groupieFriends = {},
            groupieIgnores = {},
        }
    }


    --Generate defaults for each individual dungeon filter
    for key, val in pairs(addon.groupieInstanceData) do
        defaults.char.hideInstances[key] = false
    end
    addon.db = LibStub("AceDB-3.0"):New("GroupieDB", defaults)
    addon.icon = LibStub("LibDBIcon-1.0")

    --Reset instance filters due to data changes
    if addon.db.char.configVer == nil then
        addon.db.char.hideInstances = {}
        addon.db.char.configVer = addon.version
    end
    addon.icon:Register("GroupieLDB", addon.groupieLDB, addon.db.global or defaults.global)
    addon.icon:Hide("GroupieLDB")

    --Build the main UI
    BuildGroupieWindow()

    --Debug variable defaults to false
    addon.debugMenus = false

    --Setup team member tooltips
    GameTooltip:HookScript("OnTooltipSetUnit", function(...)
        local unitname, unittype = GameTooltip:GetUnit()
        if unittype then
            local curMouseOver = UnitGUID(unittype)
            if curMouseOver then
                if addon.GroupieDevs[curMouseOver] then
                    GameTooltip:AddLine(format("|TInterface\\AddOns\\" ..
                        addonName .. "\\Images\\icon64:16:16:0:0|t %s : %s"
                        ,
                        addonName, addon.GroupieDevs[curMouseOver]))
                end
                if unittype == "player" then
                    --GameTooltip:AddLine(addon.TalentSummary("mouseover"))
                end
            end
        end
    end)

    --Setup Slash Commands
    local function ToggleDebugMode()
        addon.debugMenus = not addon.debugMenus
        print("GROUPIE DEBUG MODE: " .. tostring(addon.debugMenus))
    end

    --[[local function TestRunner(...)
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
    end--]]

    addon:RegisterChatCommand("groupie", BuildGroupieWindow)
    addon:RegisterChatCommand("groupiecfg", addon.OpenConfig)
    addon:RegisterChatCommand("groupiedebug", ToggleDebugMode)
    --addon:RegisterChatCommand("groupietest", TestRunner)

    addon.isInitialized = true
end

---------------------
-- AceConfig Setup --
---------------------
function addon.SetupConfig()
    addon.options = {
        name = "|TInterface\\AddOns\\" ..
            addonName .. "\\Images\\icon64:16:16:0:4|t  " .. addonName .. " - v" .. tostring(addon.version),
        desc = "Optional description? for the group of options",
        descStyle = "inline",
        handler = addon,
        type = 'group',
        args = {
            spacerdesc0 = { type = "description", name = " ", width = "full", order = 0 },
            instanceLog = {
                name = L["InstanceLog"].Name,
                desc = L["InstanceLog"].Desc,
                type = "group",
                width = "double",
                inline = false,
                order = 10,
                args = {
                    header0 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["InstanceLog"].Name,
                        order = 0,
                        fontSize = "large"
                    },
                    spacerdesc0 = { type = "description", name = " ", width = "full", order = 1 },
                    header1 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. "Discord",
                        order = 2,
                        fontSize = "medium"
                    },
                    editbox1 = {
                        type = "input",
                        name = "",
                        order = 3,
                        width = 2,
                        get = function(info) return "https://discord.gg/p68QgZ8uqF" end,
                        set = function(info, val) return end,
                    },
                    spacerdesc1 = { type = "description", name = " ", width = "full", order = 4 },
                    header2 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["InstanceLog"].Name,
                        order = 5,
                        fontSize = "medium"
                    },
                    editbox2 = {
                        type = "input",
                        name = "",
                        order = 6,
                        width = 2,
                        multiline = true,
                        get = function(info)
                            local out = ""
                            for key, val in pairs(addon.db.global.savedInstanceLogs) do
                                out = out .. "[" .. key .. "]\n"
                                for key2, val2 in pairs(val) do
                                    out = out .. "    " .. key2 .. "\n"
                                end
                            end
                            return out
                        end,
                        set = function(info, val) return end,
                    },
                }
            },
            about = {
                name = addonName,
                desc = L["About"].Desc,
                type = "group",
                width = "double",
                inline = false,
                order = 11,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. addonName,
                        order = 0,
                        fontSize = "large"
                    },
                    spacerdesc1 = { type = "description", name = " ", width = "full", order = 1 },
                    paragraph1 = {
                        type = "description",
                        name = L["About"].Paragraph,
                        width = "full",
                        order = 2,
                        fontSize = "medium", --can be small, medium, large
                    },
                    spacerdesc2 = { type = "description", name = " ", width = "full", order = 3 },
                    header2 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. addonName .. " " ..
                            L["About"].lowerOn .. " CurseForge",
                        order = 4,
                        fontSize = "medium"
                    },
                    editbox1 = {
                        type = "input",
                        name = "",
                        order = 5,
                        width = 2,
                        get = function(info) return "https://www.curseforge.com/wow/addons/groupie" end,
                        set = function(info, val) return end,
                    },
                    spacerdesc3 = { type = "description", name = " ", width = "full", order = 6 },
                    header3 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. addonName .. " " ..
                            L["About"].lowerOn .. " Discord",
                        order = 7,
                        fontSize = "medium"
                    },
                    editbox2 = {
                        type = "input",
                        name = "",
                        order = 8,
                        width = 2,
                        get = function(info) return "https://discord.gg/p68QgZ8uqF" end,
                        set = function(info, val) return end,
                    },
                    spacerdesc4 = { type = "description", name = " ", width = "full", order = 9 },
                    header4 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. addonName .. " " ..
                            L["About"].lowerOn .. " GitHub",
                        order = 10,
                        fontSize = "medium"
                    },
                    editbox3 = {
                        type = "input",
                        name = "",
                        order = 11,
                        width = 2,
                        get = function(info) return "https://github.com/Gogo1951/Groupie" end,
                        set = function(info, val) return end,
                    },
                }
            },
            instancefiltersWrath = {
                name = L["InstanceFilters"].Wrath.Name,
                desc = L["InstanceFilters"].Wrath.Desc,
                type = "group",
                width = "double",
                inline = false,
                order = 4,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["InstanceFilters"].Wrath.Name,
                        order = 0,
                        fontSize = "large"
                    },

                }
            },
            instancefiltersTBC = {
                name = L["InstanceFilters"].TBC.Name,
                desc = L["InstanceFilters"].TBC.Desc,
                type = "group",
                width = "double",
                inline = false,
                order = 5,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["InstanceFilters"].TBC.Name,
                        order = 0,
                        fontSize = "large"
                    },

                }
            },
            instancefiltersClassic = {
                name = L["InstanceFilters"].Classic.Name,
                desc = L["InstanceFilters"].Classic.Desc,
                type = "group",
                width = "double",
                inline = false,
                order = 6,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["InstanceFilters"].Classic.Name,
                        order = 0,
                        fontSize = "large"
                    },

                }
            },
            groupfilters = {
                name = L["GroupFilters"].Name,
                desc = L["GroupFilters"].Desc,
                type = "group",
                width = "double",
                inline = false,
                order = 3,
                args = {
                    header0 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["GroupFilters"].Name,
                        order = 0,
                        fontSize = "large"
                    },
                    spacerdesc1 = { type = "description", name = " ", width = "full", order = 1 },
                    header1 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["GroupFilters"].General,
                        order = 2,
                        fontSize = "medium"
                    },
                    savedToggle = {
                        type = "toggle",
                        name = L["GroupFilters"].savedToggle,
                        order = 4,
                        width = "full",
                        get = function(info) return addon.db.global.ignoreSavedInstances end,
                        set = function(info, val) addon.db.global.ignoreSavedInstances = val end,
                    },
                    ignoreLFG = {
                        type = "toggle",
                        name = L["GroupFilters"].ignoreLFG,
                        order = 5,
                        width = "full",
                        get = function(info) return addon.db.global.ignoreLFG end,
                        set = function(info, val) addon.db.global.ignoreLFG = val end,
                    },
                    ignoreLFM = {
                        type = "toggle",
                        name = L["GroupFilters"].ignoreLFM,
                        order = 6,
                        width = "full",
                        get = function(info) return addon.db.global.ignoreLFM end,
                        set = function(info, val) addon.db.global.ignoreLFM = val end,
                    },
                    spacerdesc3 = { type = "description", name = " ", width = "full", order = 15 },
                    header3 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["GroupFilters"].keyword,
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
                        name = "|cff999999" .. L["GroupFilters"].keyword_desc,
                        order = 18,
                        fontSize = "medium"
                    },
                }
            },
            charoptions = {
                name = L["CharOptions"].Name,
                desc = L["CharOptions"].Desc,
                type = "group",
                width = "double",
                inline = false,
                order = 1,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. UnitName("player") .. " " .. L["Options"],
                        order = 0,
                        fontSize = "large"
                    },
                    spacerdesc1 = { type = "description", name = " ", width = "full", order = 1 },
                    header2 = {
                        type = "description",
                        name = "|cff" ..
                            addon.groupieSystemColor .. L["CharOptions"].Spec1 .. " - " .. addon.GetSpecByGroupNum(1),
                        order = 2,
                        fontSize = "medium"
                    },
                    spec1Dropdown = {
                        type = "select",
                        style = "dropdown",
                        name = "",
                        order = 3,
                        width = 1.4,
                        values = addon.groupieClassRoleTable[englishClass][addon.GetSpecByGroupNum(1)],
                        set = function(info, val) addon.db.char.groupieSpec1Role = val end,
                        get = function(info) return addon.db.char.groupieSpec1Role end,
                    },
                    spacerdesc2 = { type = "description", name = " ", width = "full", order = 4 },
                    header3 = {
                        type = "description",
                        name = "|cff" ..
                            addon.groupieSystemColor .. L["CharOptions"].Spec2 .. " - " .. addon.GetSpecByGroupNum(2),
                        order = 5,
                        fontSize = "medium"
                    },
                    spec2Dropdown = {
                        type = "select",
                        style = "dropdown",
                        name = "",
                        order = 6,
                        width = 1.4,
                        values = addon.groupieClassRoleTable[englishClass][addon.GetSpecByGroupNum(2)],
                        set = function(info, val) addon.db.char.groupieSpec2Role = val end,
                        get = function(info) return addon.db.char.groupieSpec2Role end,
                    },
                    spacerdesc3 = { type = "description", name = " ", width = "full", order = 7 },
                    otherRoleToggle = {
                        type = "toggle",
                        name = L["CharOptions"].OtherRole,
                        order = 8,
                        width = "full",
                        get = function(info) return addon.db.char.sendOtherRole end,
                        set = function(info, val) addon.db.char.sendOtherRole = val end,
                    },
                    spacerdesc4 = { type = "description", name = " ", width = "full", order = 9 },
                    header4 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["CharOptions"].DungeonLevelRange,
                        order = 10,
                        fontSize = "medium"
                    },
                    recLevelDropdown = {
                        type = "select",
                        style = "dropdown",
                        name = "",
                        order = 11,
                        width = 1.4,
                        values = {
                            [0] = L["CharOptions"].recLevelDropdown["0"],
                            [1] = L["CharOptions"].recLevelDropdown["1"],
                            [2] = L["CharOptions"].recLevelDropdown["2"],
                            [3] = L["CharOptions"].recLevelDropdown["3"],
                        },
                        set = function(info, val) addon.db.char.recommendedLevelRange = val end,
                        get = function(info) return addon.db.char.recommendedLevelRange end,
                    },
                    spacerdesc5 = { type = "description", name = " ", width = "full", order = 12 },
                    header5 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. addonName .. " " .. L["CharOptions"].AutoResponse,
                        order = 13,
                        fontSize = "medium",
                        hidden = true,
                        disabled = true,
                    },
                    autoFriendsToggle = {
                        type = "toggle",
                        name = L["CharOptions"].AutoFriends,
                        order = 14,
                        width = "full",
                        get = function(info) return addon.db.char.autoRespondFriends end,
                        set = function(info, val) addon.db.char.autoRespondFriends = val end,
                        hidden = true,
                        disabled = true,
                    },
                    autoGuildToggle = {
                        type = "toggle",
                        name = L["CharOptions"].AutoGuild,
                        order = 15,
                        width = "full",
                        get = function(info) return addon.db.char.autoRespondGuild end,
                        set = function(info, val) addon.db.char.autoRespondGuild = val end,
                        hidden = true,
                        disabled = true,
                    },
                    autoInviteResponseToggle = {
                        type = "toggle",
                        name = L["AutoInviteResponse"],
                        order = 16,
                        width = "full",
                        get = function(info) return addon.db.char.autoRespondInvites end,
                        set = function(info, val) addon.db.char.autoRespondInvites = val end,
                    },
                    autoRequestResponseToggle = {
                        type = "toggle",
                        name = L["AutoRequestResponse"],
                        order = 17,
                        width = "full",
                        get = function(info) return addon.db.char.autoRespondRequests end,
                        set = function(info, val) addon.db.char.autoRespondRequests = val end,
                    },
                    spacerdesc6 = { type = "description", name = " ", width = "full", order = 18 },
                    header6 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. addonName .. " " .. L["CharOptions"].AfterParty,
                        order = 19,
                        fontSize = "medium",
                        hidden = true,
                        disabled = true,
                    },
                    afterPartyToggle = {
                        type = "toggle",
                        name = "Enable " .. addonName .. " " .. L["CharOptions"].AfterParty,
                        order = 20,
                        width = "full",
                        get = function(info) return addon.db.char.afterParty end,
                        set = function(info, val) addon.db.char.afterParty = val end,
                        hidden = true,
                        disabled = true,
                    },
                    spacerdesc7 = { type = "description", name = " ", width = "full", order = 21,
                        hidden = true,
                        disabled = true, },
                    header7 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["CharOptions"].PullGroups,
                        order = 22,
                        fontSize = "medium"
                    },
                    channelGuildToggle = {
                        type = "toggle",
                        name = L["text_channels"].Guild,
                        order = 23,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels[L["text_channels"].Guild] end,
                        set = function(info, val) addon.db.char.useChannels[L["text_channels"].Guild] = val end,
                    },
                    channelGeneralToggle = {
                        type = "toggle",
                        name = L["text_channels"].General,
                        order = 24,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels[L["text_channels"].General] end,
                        set = function(info, val) addon.db.char.useChannels[L["text_channels"].General] = val end,
                    },
                    channelTradeToggle = {
                        type = "toggle",
                        name = L["text_channels"].Trade,
                        order = 25,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels[L["text_channels"].Trade] end,
                        set = function(info, val) addon.db.char.useChannels[L["text_channels"].Trade] = val end,
                    },
                    channelLocalDefenseToggle = {
                        type = "toggle",
                        name = L["text_channels"].LocalDefense,
                        order = 26,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels[L["text_channels"].LocalDefense] end,
                        set = function(info, val) addon.db.char.useChannels[L["text_channels"].LocalDefense] = val end,
                    },
                    channelLookingForGroupToggle = {
                        type = "toggle",
                        name = L["text_channels"].LFG,
                        order = 27,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels[L["text_channels"].LFG] end,
                        set = function(info, val) addon.db.char.useChannels[L["text_channels"].LFG] = val end,
                    },
                    channel5Toggle = {
                        type = "toggle",
                        name = L["text_channels"].World,
                        order = 28,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels[L["text_channels"].World] end,
                        set = function(info, val) addon.db.char.useChannels[L["text_channels"].World] = val end,
                    }
                },
            },
            globaloptions = {
                name = L["GlobalOptions"].Name,
                desc = L["GlobalOptions"].Desc,
                type = "group",
                width = "double",
                inline = false,
                order = 2,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["GlobalOptions"].Name,
                        order = 0,
                        fontSize = "large"
                    },
                    spacerdesc1 = { type = "description", name = " ", width = "full", order = 1 },
                    minimapToggle = {
                        type = "toggle",
                        name = L["GlobalOptions"].MiniMapButton,
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
                        name = "|cff" .. addon.groupieSystemColor .. L["GlobalOptions"].LFGData,
                        order = 6,
                        fontSize = "medium"
                    },
                    preserveDurationDropdown = {
                        type = "select",
                        style = "dropdown",
                        name = "",
                        order = 7,
                        width = 1.4,
                        values = { [1] = L["GlobalOptions"].DurationDropdown["1"],
                            [2] = L["GlobalOptions"].DurationDropdown["2"],
                            [5] = L["GlobalOptions"].DurationDropdown["5"],
                            [10] = L["GlobalOptions"].DurationDropdown["10"],
                            [20] = L["GlobalOptions"].DurationDropdown["20"] },
                        set = function(info, val) addon.db.global.minsToPreserve = val end,
                        get = function(info) return addon.db.global.minsToPreserve end,
                    },
                    spacerdesc4 = { type = "description", name = " ", width = "full", order = 8 },
                    header3 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["GlobalOptions"].UIScale,
                        order = 9,
                        fontSize = "medium"
                    },
                    scaleSlider = {
                        type = "range",
                        name = "",
                        min = 0.5,
                        max = 2.0,
                        step = 0.1,
                        set = function(info, val)
                            addon.db.global.UIScale = val
                            GroupieFrame:SetScale(val)
                        end,
                        get = function(info) return addon.db.global.UIScale end,
                    }
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

    --Don't preserve Data if switching servers
    local currentServer = GetRealmName()
    if currentServer ~= addon.db.global.lastServer then
        addon.db.global.listingTable = {}
    end
    addon.db.global.lastServer = currentServer


end

function addon:OpenConfig()
    GroupieFrame:Hide()
    addon.UpdateSpecOptions()
    InterfaceOptionsFrame_OpenToCategory(addonName)
    -- need to call it a second time as there is a bug where the first time it won't switch !BlizzBugsSuck has a fix
    InterfaceOptionsFrame_OpenToCategory(addonName)
end

--Update our options menu dropdowns when the player's specialization changes
function addon.UpdateSpecOptions()
    local spec1, maxtalents1 = addon.GetSpecByGroupNum(1)
    local spec2, maxtalents2 = addon.GetSpecByGroupNum(2)
    --Set labels
    addon.options.args.charoptions.args.header2.name = "|cff" ..
        addon.groupieSystemColor .. L["UpdateSpec"].Spec1 .. " - " .. spec1
    addon.options.args.charoptions.args.header3.name = "|cff" ..
        addon.groupieSystemColor .. L["UpdateSpec"].Spec2 .. " - " .. spec2
    --Set dropdowns
    addon.options.args.charoptions.args.spec1Dropdown.values = addon.groupieClassRoleTable[englishClass][spec1]
    addon.options.args.charoptions.args.spec2Dropdown.values = addon.groupieClassRoleTable[englishClass][spec2]
    --Reset to default value for dropdowns if the currently selected role is now invalid after the change
    if not addon.groupieClassRoleTable[englishClass][spec1][addon.db.char.groupieSpec1Role] then
        addon.db.char.groupieSpec1Role = nil
    end
    if not addon.groupieClassRoleTable[englishClass][spec2][addon.db.char.groupieSpec2Role] then
        addon.db.char.groupieSpec2Role = nil
    end
    for i = 4, 1, -1 do
        if addon.groupieClassRoleTable[englishClass][spec1][i] and addon.db.char.groupieSpec1Role == nil then
            addon.db.char.groupieSpec1Role = i
        end
        if addon.groupieClassRoleTable[englishClass][spec2][i] and addon.db.char.groupieSpec2Role == nil then
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

--Load the current character's friend, ignore, and guild lists, and merge them with all others
function addon.UpdateFriends()
    local myname = UnitName("player")
    --Always clear and reload the current character
    addon.db.global.friendsAndGuild[myname] = {}
    addon.db.global.ignores[myname] = {}

    --Update for the current character
    for i = 1, C_FriendList.GetNumFriends() do
        local name = C_FriendList.GetFriendInfoByIndex(i).name
        if name then
            name = name:gsub("%-.+", "")
            addon.db.global.friendsAndGuild[myname][name] = true
        end
    end
    for i = 1, C_FriendList.GetNumIgnores() do
        local name = C_FriendList.GetIgnoreName(i)
        if name then
            name = name:gsub("%-.+", "")
            addon.db.global.ignores[myname][name] = true
        end
    end

    --Then clear the global lists and merge all lists
    --FRIENDLIST_UPDATE and IGNORELIST_UPDATE don't have context
    --so we need to just re-merge every time
    addon.friendList = {}
    addon.ignoreList = {}

    for char, friendlist in pairs(addon.db.global.friendsAndGuild) do
        for name, _ in pairs(friendlist) do
            addon.friendList[name] = true
        end
    end

    for char, ignorelist in pairs(addon.db.global.ignores) do
        for name, _ in pairs(ignorelist) do
            addon.ignoreList[name] = true
            --Remove listings from the table as well
            if not strfind(name, "-") then
                name = name .. "-" .. gsub(GetRealmName(), " ", "")
            end
            addon.db.global.listingTable[name] = nil
        end
    end
end

-------------------
--Event Registers--
-------------------
--Leave this commented for now, may trigger when swapping dual specs, which we dont want to reset settings
--Only actual talent changes
--addon:RegisterEvent("PLAYER_TALENT_UPDATE", addon.UpdateSpecOptions)
addon:RegisterEvent("CHARACTER_POINTS_CHANGED", addon.UpdateSpecOptions)
--Update player's saved instances on boss kill and login
--The api is very slow to populate saved instance data, so we need a delay on these events
addon:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    addon.SetupConfig()
    C_Timer.After(5, function()
        addon.UpdateFriends()
        addon.UpdateSavedInstances()
        C_ChatInfo.RegisterAddonMessagePrefix(addon.ADDON_PREFIX)
        C_ChatInfo.SendAddonMessage(addon.ADDON_PREFIX, "v" .. tostring(addon.version), "YELL")
    end)
    C_Timer.After(15, function()
        local GroupieGroupBrowser = Groupie:GetModule("GroupieGroupBrowser")
        if GroupieGroupBrowser then
            --Queue updates from the LFG tool for dungeons and raids on login
            local dungeons, dungeonactivities = GroupieGroupBrowser:GetActivitiesFor(2)
            GroupieGroupBrowser:Queue(dungeons, dungeonactivities)
            local raids, raidactivities = GroupieGroupBrowser:GetActivitiesFor(114)
            GroupieGroupBrowser:Queue(raids, raidactivities)
        end
    end)
end)
--Update friend and ignore lists
addon:RegisterEvent("FRIENDLIST_UPDATE", function()
    addon.UpdateFriends()
end)
addon:RegisterEvent("IGNORELIST_UPDATE", function()
    addon.UpdateFriends()
end)
--Update saved instances
addon:RegisterEvent("BOSS_KILL", function()
    C_Timer.After(5, addon.UpdateSavedInstances)
end)
--Send version check
addon:RegisterEvent("CHAT_MSG_ADDON", function(...)
    local _, prefix, msg = ...
    if prefix == addon.ADDON_PREFIX then
        local strversion = gsub(msg, "v", "")
        local version = tonumber(strversion)
        if version > addon.db.global.highestSeenVersion then
            addon.db.global.highestSeenVersion = version
        end
    end
end)
--Send version check to group/raid
addon:RegisterEvent("GROUP_JOINED", function(...)
    local inParty = UnitInParty("player")
    local inRaid = UnitInRaid("player")
    if inRaid then
        C_ChatInfo.SendAddonMessage(addon.ADDON_PREFIX, "v" .. tostring(addon.version), "RAID")
    elseif inParty then
        C_ChatInfo.SendAddonMessage(addon.ADDON_PREFIX, "v" .. tostring(addon.version), "PARTY")
    end
end)
--Send version check to players joining group/raid
addon:RegisterEvent("CHAT_MSG_SYSTEM", function(...)
    local event, msg = ...
    if strmatch(msg, L["VersionChecking"].JoinRaid) then
        C_ChatInfo.SendAddonMessage(addon.ADDON_PREFIX, "v" .. tostring(addon.version), "RAID")
    elseif strmatch(msg, L["VersionChecking"].JoinParty) then
        C_ChatInfo.SendAddonMessage(addon.ADDON_PREFIX, "v" .. tostring(addon.version), "PARTY")
    end
end)
