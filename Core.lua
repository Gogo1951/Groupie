local addonName, Groupie           = ...
local locale                       = GetLocale()
local addon                        = LibStub("AceAddon-3.0"):NewAddon(Groupie, addonName, "AceEvent-3.0",
    "AceConsole-3.0",
    "AceTimer-3.0")
local CI                           = LibStub("LibClassicInspector")
local LGS                          = LibStub:GetLibrary("LibGearScore.1000", true)
L_UIDROPDOWNMENU_SHOW_TIME         = 2 -- Timeout once the cursor leaves menu
local L                            = LibStub('AceLocale-3.0'):GetLocale('Groupie')
local localizedClass, englishClass = UnitClass("player")
local myserver                     = GetRealmName()
local myname                       = UnitName("player")
local mylevel                      = UnitLevel("player")

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
                BuildGroupieWindow()
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
    addon.icon = LibStub("LibDBIconGroupie-1.0")
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
local CharSheetSummaryFrame = nil
local MiniMapDropdown       = nil
local columnCount           = 0
local LFGScrollFrame        = nil
local AddButton             = nil
local SetNoteButton         = nil
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
local COL_FRIENDNAME        = 105
local REMOVE_BTN_WIDTH      = 75
local COL_GROUPIENOTE       = 150
local COL_NOTE              = WINDOW_WIDTH - COL_FRIENDNAME - REMOVE_BTN_WIDTH - COL_GROUPIENOTE - 58
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
addon.filteredFriends     = {}
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
    local sortType = sortType or -1
    local sortDir = sortDir or false

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

--Create a sorted index of friends/ignores alphabetically by name
--Sort Types : -1 (default) - name
-- 0 - Groupie Note
-- 1 - User Note
local function GetSortedFriendIndex(sortType, sortDir)
    local idx = 1
    local numindex = {}
    sortDir = sortDir or false


    --Build a numerical index to sort on
    if MainTabFrame.tabType == 10 then --Friends
        --Include Friends
        for source, list in pairs(addon.db.global.friends[myserver]) do
            if addon.db.global.hiddenFriendLists[myserver][source] then
                --Hide this character's friends
            else
                for name, _ in pairs(list) do
                    numindex[idx] = {
                        name = name,
                        groupieNote = "Friend : " .. source,
                        userNote = addon.db.global.friendnotes[myserver][name] or "",
                        isGroupieFriend = false
                    }
                    idx = idx + 1
                end
            end
        end

        --Include Groupie Friends
        for name, _ in pairs(addon.db.global.groupieFriends[myserver]) do
            numindex[idx] = {
                name = name,
                groupieNote = "Groupie Global Friend",
                userNote = addon.db.global.friendnotes[myserver][name] or "",
                isGroupieFriend = true
            }
            idx = idx + 1
        end

        --Include Guilds
        for source, guild in pairs(addon.db.global.guilds[myserver]) do
            local currentGuildName = guild["__NAME__"]
            if addon.db.global.hiddenGuilds[myserver][currentGuildName] then
                --Hide this guild
            else
                for name, _ in pairs(guild) do
                    if name ~= "__NAME__" then
                        numindex[idx] = {
                            name = name,
                            groupieNote = "Guild : " .. currentGuildName,
                            userNote = addon.db.global.friendnotes[myserver][name] or "",
                            isGroupieFriend = false
                        }
                        idx = idx + 1
                    end
                end
            end
        end
    elseif MainTabFrame.tabType == 11 then --Ignores
        --Include Ignores
        for source, list in pairs(addon.db.global.ignores[myserver]) do
            if addon.db.global.hiddenFriendLists[myserver][source] then
                --Hide this character's ignores
            else
                for name, _ in pairs(list) do
                    numindex[idx] = {
                        name = name,
                        groupieNote = "Ignore : " .. source,
                        userNote = addon.db.global.ignorenotes[myserver][name] or "",
                        isGroupieFriend = false
                    }
                    idx = idx + 1
                end
            end
        end

        --Include Groupie Ignores
        for name, _ in pairs(addon.db.global.groupieIgnores[myserver]) do
            numindex[idx] = {
                name = name,
                groupieNote = "Groupie Global Ignore",
                userNote = addon.db.global.ignorenotes[myserver][name] or "",
                isGroupieFriend = true
            }
            idx = idx + 1
        end

    end


    --Then sort the index
    if sortType == -1 then --Name
        if sortDir then
            table.sort(numindex, function(a, b) return (a.name or 0) > (b.name or 0) end)
        else
            table.sort(numindex, function(a, b) return (a.name or 0) < (b.name or 0) end)
        end
    elseif sortType == 0 then --Groupie Note
        if sortDir then
            table.sort(numindex, function(a, b) return (a.groupieNote or 0) > (b.groupieNote or 0) end)
        else
            table.sort(numindex, function(a, b) return (a.groupieNote or 0) < (b.groupieNote or 0) end)
        end
    else --User Note
        if sortDir then
            table.sort(numindex, function(a, b) return (a.userNote or 0) > (b.userNote or 0) end)
        else
            table.sort(numindex, function(a, b) return (a.userNote or 0) < (b.userNote or 0) end)
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
            elseif addon.db.char.ignoreLFM and listing.isLFM then
                --Ignoring LFM groups
            elseif addon.db.char.ignoreLFG and listing.isLFG then
                --Ignoring LFG groups
            elseif MainTabFrame.roleType ~= nil and
                not addon.tableContains(listing.rolesNeeded, MainTabFrame.roleType) then
                --Doesnt match role in the dropdown
            elseif MainTabFrame.lang ~= nil and MainTabFrame.lang ~= listing.language then
                --Doesnt match language in the dropdown
            elseif addon.db.char.hideInstances[listing.order] == true then
                --Ignoring specifically hidden instances
            elseif addon.db.char.ignoreSavedInstances and addon.db.global.savedInstanceInfo[listing.order] and
                addon.db.global.savedInstanceInfo[listing.order][myname] and
                (addon.db.global.savedInstanceInfo[listing.order][myname].resetTime > now) then
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
            elseif addon.db.char.ignoreLFM and listing.isLFM then
                --Ignoring LFM groups
            elseif addon.db.char.ignoreLFG and listing.isLFG then
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
            elseif addon.db.char.ignoreSavedInstances and addon.db.global.savedInstanceInfo[listing.order] and
                addon.db.global.savedInstanceInfo[listing.order][myname] and
                (addon.db.global.savedInstanceInfo[listing.order][myname].resetTime > now) then
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

--Create a numerically indexed table of listings for use in the scroller
--Tab numbers:
-- 10 - Friends | 11 - Ignores
local function filterFriends()
    addon.filteredFriends = {}
    local seen = {}
    local idx = 1
    local sortDir = MainTabFrame.sortDir or false
    local sortType = MainTabFrame.sortType or -1
    local sorted = GetSortedFriendIndex(sortType, sortDir)
    for key, listing in pairs(sorted) do
        --Ensure no duplicates
        if not addon.tableContains(seen, listing.name) then
            addon.filteredFriends[idx] = listing
            idx = idx + 1
            tinsert(seen, listing.name)
        end
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
    local myName = myname .. "-" .. gsub(GetRealmName(), " ", "")
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
                listing.messageSent = true
                listing.senderName = myname
            end)
            --clear messages sent on switching characters
            if listing.messageSent and myname ~= listing.senderName then
                listing.messageSent = nil
                listing.senderName = nil
            end
            --Change
            if listing.messageSent then
                button.btn:SetText("|TInterface\\AddOns\\" ..
                    addonName .. "\\Images\\load" .. tostring(MainTabFrame.animFrame + 1) .. ":10:32:0:-1|t")
            else
                button.btn:SetText("LFG")
            end
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

--Draw Friends/Ignore listings in the LFG board
local function DrawFriends(self)
    --Create a numerical index for use populating the table
    filterFriends()

    FauxScrollFrame_Update(self, #addon.filteredFriends, BUTTON_TOTAL, BUTTON_HEIGHT)

    if addon.selectedListing then
        if addon.selectedListing > #addon.filteredFriends then
            addon.selectedListing = nil
            if SetNoteButton then
                SetNoteButton:Hide()
            end
        else
            if SetNoteButton then
                SetNoteButton:Show()
            end
        end
    else
        if SetNoteButton then
            SetNoteButton:Hide()
        end
    end

    local offset = FauxScrollFrame_GetOffset(self)
    local idx = 0
    local myName = myname .. "-" .. gsub(GetRealmName(), " ", "")
    for btnNum = 1, BUTTON_TOTAL do
        idx = btnNum + offset
        local button = addon.friendBoardButtons[btnNum]
        local listing = addon.filteredFriends[idx]
        if idx <= #addon.filteredFriends then
            if btnNum == addon.selectedListing then
                button:LockHighlight()
            else
                button:UnlockHighlight()
            end
            button.listing = listing
            button.name:SetText(listing.name)
            button.groupieNote:SetText(listing.groupieNote)
            button.userNote:SetText(listing.userNote)
            button.btn:SetScript("OnClick", function()
                if MainTabFrame.tabType == 10 then
                    addon.db.global.groupieFriends[myserver][listing.name] = nil
                else
                    addon.db.global.groupieIgnores[myserver][listing.name] = nil
                end
            end)
            if listing.isGroupieFriend then
                button.btn:Show()
            else
                button.btn:Hide()
            end
            button:SetScript("OnEnter", function()
                GameTooltip:SetOwner(button, "ANCHOR_CURSOR")
                GameTooltip:SetText(listing.userNote, 1, 1, 1, 1, true)
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
            for k, v in pairs(addon.ignoreList) do
                print(k, v)
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

--Onclick for group listings, highlights the selected listing
local function FriendListingOnClick(self, button, down)
    if addon.selectedListing then
        addon.friendBoardButtons[addon.selectedListing]:UnlockHighlight()
    end
    addon.selectedListing = self.id
    addon.friendBoardButtons[addon.selectedListing]:LockHighlight()
    local name = addon.friendBoardButtons[addon.selectedListing].listing.name
    DrawFriends(FriendScrollFrame)

    if addon.debugMenus then
        local a = {}
        tinsert(a, "s")
        print(addon.tableContains(a, "s"))
    end

    --Select a listing, if shift is held, do a Who Request
    if button == "LeftButton" then
        if IsShiftKeyDown() then
            DEFAULT_CHAT_FRAME.editBox:SetText("/who " .. name)
            ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox)
        end
        --Open Right click Menu
    elseif button == "RightButton" then
    end
end

--Create entries in the LFG board for each group listing
local function CreateFriendListingButtons()
    addon.friendBoardButtons = {}
    local currentListing
    for listcount = 1, BUTTON_TOTAL do
        addon.friendBoardButtons[listcount] = CreateFrame(
            "Button",
            "ListingBtn" .. tostring(listcount),
            FriendScrollFrame:GetParent(),
            "IgnoreListButtonTemplate2"
        )
        currentListing = addon.friendBoardButtons[listcount]
        if listcount == 1 then
            currentListing:SetPoint("TOPLEFT", FriendScrollFrame, -1, 0)
        else
            currentListing:SetPoint("TOP", addon.friendBoardButtons[listcount - 1], "BOTTOM", 0, 0)
        end
        currentListing:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
        currentListing:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        currentListing:SetScript("OnClick", FriendListingOnClick)
        currentListing:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        --Name Column
        currentListing.name:SetWidth(COL_FRIENDNAME)

        --Groupie Note Column
        currentListing.groupieNote = currentListing:CreateFontString("FontString", "OVERLAY", "GameFontNormal")
        currentListing.groupieNote:SetPoint("LEFT", currentListing.name, "RIGHT", 0, 0)
        currentListing.groupieNote:SetWidth(COL_GROUPIENOTE)
        currentListing.groupieNote:SetJustifyH("LEFT")
        currentListing.groupieNote:SetJustifyV("MIDDLE")

        --User Note Column
        currentListing.userNote = currentListing:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
        currentListing.userNote:SetPoint("LEFT", currentListing.groupieNote, "RIGHT", -4, 0)
        currentListing.userNote:SetWidth(COL_NOTE)
        currentListing.userNote:SetJustifyH("LEFT")
        currentListing.userNote:SetJustifyV("MIDDLE")

        --Apply button
        currentListing.btn = CreateFrame("Button", "$parentApplyBtn", currentListing, "UIPanelButtonTemplate")
        currentListing.btn:SetPoint("LEFT", currentListing.userNote, "RIGHT", 4, 0)
        currentListing.btn:SetWidth(REMOVE_BTN_WIDTH)
        currentListing.btn:SetText("Remove")
        currentListing.btn:SetScript("OnClick", function()
            return
        end)


        currentListing.id = listcount
        listcount = listcount + 1
        --Initially hide for friend columns
        currentListing:Hide()
    end
    DrawFriends(FriendScrollFrame)
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
local function createColumn(text, width, parent, sortType, isFriendTab)
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

    if columnCount == 1 or columnCount == 7 then
        Header:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, 22)
    else
        Header:SetPoint("LEFT", parent:GetName() .. "Header" .. columnCount - 1, "RIGHT", 0, 0)
    end
    if sortType ~= nil then
        Header:SetScript("OnClick", function()
            MainTabFrame.sortType = sortType
            MainTabFrame.sortDir = not MainTabFrame.sortDir
            if isFriendTab then
                DrawFriends(FriendScrollFrame)
            else
                DrawListings(LFGScrollFrame)
            end
        end)
    else
        Header:SetScript("OnClick", function() return end)
    end
end

--Listing update timer
local function TimerListingUpdate()
    if not addon.lastUpdate then
        addon.lastUpdate = GetTime()
        addon.lastAnimUpdate = addon.lastUpdate
    end

    local now = GetTime()

    --Animate the spinner texture by cycling
    if (now - addon.lastAnimUpdate) > 0.4 then
        addon.lastAnimUpdate = now
        MainTabFrame.animFrame = (MainTabFrame.animFrame + 1) % 3
    end

    --Draw the listings
    if (now - addon.lastUpdate) > 0.1 then
        addon.lastUpdate = now
        if MainTabFrame.tabType ~= 10 and MainTabFrame.tabType ~= 11 then
            DrawListings(LFGScrollFrame)
        else
            DrawFriends(FriendScrollFrame)
        end
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

    if tabNum == 10 then --Friends
        for i = 1, 6 do --Hide group listing columns
            _G["GroupieFrame1Header" .. i]:Hide()
        end
        for i = 7, 9 do --Show friend related columns
            _G["GroupieFrame1Header" .. i]:Show()
        end
        GroupieLevelDropdown:Hide()
        GroupieRoleDropdown:Hide()
        GroupieLootDropdown:Hide()
        GroupieLangDropdown:Hide()
        ShowingFontStr:Hide()
        LFGScrollFrame:Hide()
        FriendScrollFrame:Show()
        for k, v in pairs(addon.groupieBoardButtons) do
            v:Hide()
        end
        AddButton:SetText("Add Groupie Friend")
        AddButton:Hide() --TODO: Show()
        SetNoteButton:Show()
        DrawFriends(FriendScrollFrame)

    elseif tabNum == 11 then --Ignores
        for i = 1, 6 do --Hide group listing columns
            _G["GroupieFrame1Header" .. i]:Hide()
        end
        for i = 7, 9 do --Show friend related columns
            _G["GroupieFrame1Header" .. i]:Show()
        end
        GroupieLevelDropdown:Hide()
        GroupieRoleDropdown:Hide()
        GroupieLootDropdown:Hide()
        GroupieLangDropdown:Hide()
        ShowingFontStr:Hide()
        LFGScrollFrame:Hide()
        FriendScrollFrame:Show()
        for k, v in pairs(addon.groupieBoardButtons) do
            v:Hide()
        end
        AddButton:SetText("Add Groupie Ignore")
        AddButton:Hide() --TODO: Show()
        SetNoteButton:Show()
        DrawFriends(FriendScrollFrame)

    else --Non friend list related tabs
        LFGScrollFrame:Show()
        FriendScrollFrame:Hide()
        AddButton:Hide()
        SetNoteButton:Hide()
        for k, v in pairs(addon.friendBoardButtons) do
            v:Hide()
        end
        for i = 1, 6 do --Show group listing columns
            _G["GroupieFrame1Header" .. i]:Show()
        end
        for i = 7, 9 do --Hide friend related columns
            _G["GroupieFrame1Header" .. i]:Hide()
        end
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
    end
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
        if GroupieFrame:IsShown() then
            GroupieFrame:Hide()
        else
            GroupieFrame:Show()
        end
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

    local FriendsTabButton = CreateFrame("Button", "GroupieTab10", GroupieFrame, "CharacterFrameTabButtonTemplate")
    FriendsTabButton:SetPoint("LEFT", "GroupieTab9", "RIGHT", -16, 0)
    FriendsTabButton:SetText("Friends")
    FriendsTabButton:SetID("10")
    FriendsTabButton:SetScript("OnClick",
        function(self)
            TabSwap(nil, nil, nil, 10)
        end)

    local IgnoresTabButton = CreateFrame("Button", "GroupieTab11", GroupieFrame, "CharacterFrameTabButtonTemplate")
    IgnoresTabButton:SetPoint("LEFT", "GroupieTab10", "RIGHT", -16, 0)
    IgnoresTabButton:SetText("Ignores")
    IgnoresTabButton:SetID("11")
    IgnoresTabButton:SetScript("OnClick",
        function(self)
            TabSwap(nil, nil, nil, 11)
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
    MainTabFrame.animFrame = 0

    --Listing Columns
    createColumn(L["UI_columns"].Created, COL_CREATED, MainTabFrame, -1, nil)
    createColumn(L["UI_columns"].Updated, COL_TIME, MainTabFrame, 0, nil)
    createColumn(L["UI_columns"].Leader, COL_LEADER, MainTabFrame, 1, nil)
    createColumn(L["UI_columns"].InstanceName, COL_INSTANCE + ICON_WIDTH, MainTabFrame, 2, nil)
    createColumn(L["UI_columns"].LootType, COL_LOOT, MainTabFrame, 3, nil)
    createColumn(L["UI_columns"].Message, COL_MSG, MainTabFrame, nil)
    --Friend Columns
    createColumn("Name", COL_FRIENDNAME, MainTabFrame, -1, true)
    createColumn(addonName .. " Auto Note", COL_GROUPIENOTE, MainTabFrame, 0, true)
    createColumn("Your Note", COL_NOTE, MainTabFrame, 1, true)
    --createColumn("Action", REMOVE_BTN_WIDTH, MainTabFrame, 2, true)
    --Initially hide Friend Columns
    for i = 7, 9 do --Hide friend related columns
        _G["GroupieFrame1Header" .. i]:Hide()
    end

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

    ----------------------
    --LFG Scroller Frame--
    ----------------------
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

    --------------------------
    --Friends Scroller Frame--
    --------------------------
    FriendScrollFrame = CreateFrame("ScrollFrame", "FriendScrollFrame", MainTabFrame, "FauxScrollFrameTemplate")
    FriendScrollFrame:SetWidth(WINDOW_WIDTH - 46)
    FriendScrollFrame:SetHeight(BUTTON_TOTAL * BUTTON_HEIGHT)
    FriendScrollFrame:SetPoint("TOPLEFT", 0, -4)
    FriendScrollFrame:SetScript("OnVerticalScroll",
        function(self, offset)
            addon.selectedListing = nil
            FauxScrollFrame_OnVerticalScroll(self, offset, BUTTON_HEIGHT, DrawFriends)
        end)
    CreateFriendListingButtons()
    --Initially hide all friend related UI
    FriendScrollFrame:Hide()


    PanelTemplates_SetNumTabs(GroupieFrame, 11)
    PanelTemplates_SetTab(GroupieFrame, 1)

    -------------------
    --Set Note Button--
    -------------------
    SetNoteButton = CreateFrame("Button", "GroupieNoteButton", MainTabFrame, "UIPanelButtonTemplate")
    SetNoteButton:SetSize(85, 22)
    SetNoteButton:SetText("Set Note")
    SetNoteButton:SetPoint("BOTTOMRIGHT", -1, -24)
    SetNoteButton:SetScript("OnClick", function(self)
        if addon.selectedListing then
            MainTabFrame.selectedFriend = addon.friendBoardButtons[addon.selectedListing].listing.name
            if MainTabFrame.selectedFriend then
                if MainTabFrame.tabType == 10 then --Friend
                    StaticPopupDialogs["GroupieAddFriendNote"] = {
                        text = "Set Note for " .. MainTabFrame.selectedFriend,
                        hasEditBox = 1,
                        maxLetters = 255,
                        OnShow = function(self)
                            local editBox = self.editBox
                            editBox:SetText("")
                            editBox:SetFocus()
                        end,
                        EditBoxOnEnterPressed = function(self)
                            local editBox = self:GetParent().editBox
                            local text = editBox:GetText()
                            addon.db.global.friendnotes[myserver][MainTabFrame.selectedFriend] = text

                            self:GetParent():Hide()
                        end,
                        EditBoxOnEscapePressed = function(self)
                            self:GetParent():Hide()
                        end,
                        timeout = 0,
                        whileDead = 1,
                        hideOnEscape = 1
                    }
                    StaticPopup_Show("GroupieAddFriendNote")
                else --Ignore
                    StaticPopupDialogs["GroupieAddIgnoreNote"] = {
                        text = "Set Note for " .. MainTabFrame.selectedFriend,
                        hasEditBox = 1,
                        maxLetters = 255,
                        OnShow = function(self)
                            local editBox = self.editBox
                            editBox:SetText("")
                            editBox:SetFocus()
                        end,
                        EditBoxOnEnterPressed = function(self)
                            local editBox = self:GetParent().editBox
                            local text = editBox:GetText()
                            addon.db.global.ignorenotes[myserver][MainTabFrame.selectedFriend] = text

                            self:GetParent():Hide()
                        end,
                        EditBoxOnEscapePressed = function(self)
                            self:GetParent():Hide()
                        end,
                        timeout = 0,
                        whileDead = 1,
                        hideOnEscape = 1
                    }
                    StaticPopup_Show("GroupieAddIgnoreNote")
                end
            end
        end
    end)
    SetNoteButton:Hide()

    ----------------------------
    --Add Friend/Ignore Button--
    ----------------------------
    AddButton = CreateFrame("Button", "GroupieAddButton", MainTabFrame, "UIPanelButtonTemplate")
    AddButton:SetSize(155, 22)
    AddButton:SetText("Add Groupie Friend")
    AddButton:SetPoint("RIGHT", SetNoteButton, "LEFT", -24, 0)
    AddButton:SetScript("OnClick", function(self)
        if MainTabFrame.tabType == 10 then --Friend
            StaticPopupDialogs["GroupieAddFriend"] = {
                text = "Add Groupie Global Friend",
                hasEditBox = 1,
                maxLetters = 12,
                OnShow = function(self)
                    local editBox = self.editBox
                    editBox:SetText("")
                    editBox:SetFocus()
                end,
                EditBoxOnEnterPressed = function(self)
                    local editBox = self:GetParent().editBox
                    --Here we remove whitespace and number characters, capitalize properly
                    --Could do more validation to ensure it is a valid character name
                    --but it wont break anything if users input invalid names anyways
                    local text = editBox:GetText():lower():gsub("^%l", string.upper):gsub("%s+", ""):gsub("%d+", "")

                    print("|cff" ..
                        addon.groupieSystemColor .. text .. " added to Groupie Global Friends")
                    addon.db.global.groupieFriends[myserver][text] = true
                    addon.db.global.groupieIgnores[myserver][text] = nil --Also remove from ignore

                    self:GetParent():Hide()
                end,
                EditBoxOnEscapePressed = function(self)
                    self:GetParent():Hide()
                end,
                timeout = 0,
                whileDead = 1,
                hideOnEscape = 1
            }
            StaticPopup_Show("GroupieAddFriend")
        else --Ignore
            StaticPopupDialogs["GroupieAddIgnore"] = {
                text = "Add Groupie Global Ignore",
                hasEditBox = 1,
                maxLetters = 12,
                OnShow = function(self)
                    local editBox = self.editBox
                    editBox:SetText("")
                    editBox:SetFocus()
                end,
                EditBoxOnEnterPressed = function(self)
                    local editBox = self:GetParent().editBox
                    --Here we remove whitespace and number characters, capitalize properly
                    --Could do more validation to ensure it is a valid character name
                    --but it wont break anything if users input invalid names anyways
                    local text = editBox:GetText():lower():gsub("^%l", string.upper):gsub("%s+", ""):gsub("%d+", "")

                    print("|cff" ..
                        addon.groupieSystemColor .. text .. " added to Groupie Global Ignores")
                    addon.db.global.groupieIgnores[myserver][text] = true
                    addon.db.global.groupieFriends[myserver][text] = nil --Also remove from friends

                    self:GetParent():Hide()
                end,
                EditBoxOnEscapePressed = function(self)
                    self:GetParent():Hide()
                end,
                timeout = 0,
                whileDead = 1,
                hideOnEscape = 1
            }
            StaticPopup_Show("GroupieAddIgnore")
        end
    end)
    AddButton:Hide()


    --------------------------------------
    --Character Sheet Gear Summary Frame--
    --------------------------------------
    CharSheetSummaryFrame = _G["CharacterModelFrame"]:CreateFontString("GroupieCharSheetAddin", "OVERLAY",
        "GameFontNormalSmall")
    CharSheetSummaryFrame:SetPoint("LEFT", CharSheetSummaryFrame:GetParent(), "LEFT", 8 +
        addon.db.global.charSheetXOffset, -60 + addon.db.global.charSheetYOffset)
    CharSheetSummaryFrame:SetJustifyH("LEFT")

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
            if IsShiftKeyDown() then
                addon.OpenConfig()
            else
                BuildGroupieWindow()
            end
        elseif button == "RightButton" then
            if IsShiftKeyDown() then
                addon.OpenConfig()
            else
                addon.LFGMode = not addon.LFGMode
                if addon.LFGMode then
                    PlaySound(8458)
                    addon.icon:ChangeTexture("Interface\\AddOns\\" .. addonName .. "\\Images\\lfg64.tga", "GroupieLDB")

                else
                    addon.icon:ChangeTexture("Interface\\AddOns\\" .. addonName .. "\\Images\\icon64.tga", "GroupieLDB")
                end
            end
        end
    end,
    OnTooltipShow = function(tooltip)
        addon.ExpireSavedInstances()
        local now = time()
        --tooltip:AddLine(addonName .. " - v" .. tostring(addon.version))
        tooltip:AddDoubleLine(addonName, tostring(addon.version),
            1, 0.85, 0.00, 1, 0.85, 0.00)

        tooltip:AddLine(" ")

        if addon.LFGMode then
            tooltip:AddLine("LFG Auto-Response : Enabled", 0, 255, 0)
        else
            tooltip:AddLine("LFG Auto-Response : Disabled", 255, 255, 255)
        end

        tooltip:AddLine(" ")

        tooltip:AddLine(L["Click"] ..
            " |cffffffff" ..
            L["MiniMap"].lowerOr .. "|r /groupie|cffffffff : " .. addonName .. " Toggle " .. L["BulletinBoard"] .. "|r ")
        tooltip:AddLine(L["RightClick"] .. "|cffffffff : Toggle LFG Auto-Response|r ")
        tooltip:AddLine("Shift + Click|cffffffff : Open " .. addonName .. " Settings|r ")
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
                                    1.00, 1.00, 1.00, 0.63, 0.62, 0.62)
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
            autoRespondInvites = false,
            autoRejectInvites = false,
            autoRespondRequests = false,
            autoRejectRequests = false,
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
            ignoreSavedInstances = true,
            ignoreLFM = false,
            ignoreLFG = true,
            LFGMsgGearType = 3,
            defaultLFGModeOn = false,
            showedv160InfoPopup = false,

            --Auto Response Types:
            -- 1 : Respond to Global Friends, but only when You are in Town
            -- 2 : Respond to Local Friends & Guildies, but only when You are in Town
            -- 3 : Respond to Local Friends, but only when You are in Town
            -- 4 : Respond to Global Friends
            -- 5 : Respond to Local Friends & Guildies
            -- 6 : Respond to Local Friends
            -- 7 : Disable Auto Responses for Raid 25 Groups
            --Alert Sound Types
            -- 1 : When a Global Friend Creates a Group, but only when You are in Town
            -- 2 : When a Local Friend or Guildie Creates a Group, but only when You are in Town
            -- 3 : When a Local Friend Creates a Group, but only when You are in Town
            -- 4 : Whenever Anyone Creates a Group, but only when You are in Town
            -- 5 : When a Global Friend Creates a Group
            -- 6 : When a Local Friend or Guildie Creates a Group
            -- 7 : When a Local Friend Creates a Group
            -- 8 : Whenever Anyone Creates a Group
            -- 9 : Disable Alert Sounds for Raid 25 Groups
            autoResponseOptions = {
                ["25"] = {
                    responseType = 7,
                    soundType = 5,
                    alertSoundID = 17318,
                },
                ["10"] = {
                    responseType = 7,
                    soundType = 5,
                    alertSoundID = 17318,
                },
                ["5H"] = {
                    responseType = 4,
                    soundType = 5,
                    alertSoundID = 17318,
                },
                ["5"] = {
                    responseType = 4,
                    soundType = 5,
                    alertSoundID = 17318,
                },
                ["PVP"] = {
                    responseType = 7,
                    soundType = 9,
                    alertSoundID = 17318,
                },
            }
        },
        global = {
            lastServer = nil,
            minsToPreserve = 5,
            debugData = {},
            listingTable = {},
            showMinimap = true,
            keywordBlacklist = {},
            savedInstanceInfo = {},
            needsUpdateFlag = false,
            highestSeenVersion = 0,
            UIScale = 1.0,
            savedInstanceLogs = {},
            friends = {},
            ignores = {},
            friendnotes = {},
            ignorenotes = {},
            guilds = {},
            groupieFriends = {},
            groupieIgnores = {},
            configVer = nil,
            enableGlobalFriends = true,
            hiddenFriendLists = {},
            hiddenGuilds = {},
            talentTooltips = true,
            gearSummaryTooltips = true,
            charSheetGear = true,
            charSheetXOffset = 0,
            charSheetYOffset = 0,
            announceInstanceReset = true,
            showedv161InfoPopup = false,
            lastShowedInfoPopup = 1.63,
        }
    }


    --Generate defaults for each individual dungeon filter
    for key, val in pairs(addon.groupieInstanceData) do
        defaults.char.hideInstances[key] = false
    end
    addon.db = LibStub("AceDB-3.0"):New("GroupieDB", defaults)
    addon.icon = LibStub("LibDBIconGroupie-1.0")

    --For changes requiring resetting certain saved variables
    if addon.db.global.configVer == nil or addon.db.global.configVer < 1.53 then
        --Due to an issue with how guilds were stored
        addon.db.global.guilds = {}
    end
    if addon.db.global.minsToPreserve > 10 then
        --Removing 20 minute option to fix an issue on high pop servers
        addon.db.global.minsToPreserve = 10
    end
    addon.db.global.configVer = addon.version

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
            local mouseoverLevel = UnitLevel("mouseover")
            if curMouseOver then
                if not InCombatLockdown() then
                    --Talents/Spec Information
                    if addon.db.global.talentTooltips then
                        local spec1, spec2, spec3 = CI:GetTalentPoints(curMouseOver)
                        local _, class = GetPlayerInfoByGUID(curMouseOver)
                        local mainSpecIndex, pointsSpent = CI:GetSpecialization(curMouseOver)
                        if mainSpecIndex then
                            local specName = CI:GetSpecializationName(class, mainSpecIndex)
                            if specName ~= nil then
                                GameTooltip:AddLine(" ")
                                GameTooltip:AddDoubleLine(specName, format("%d / %d / %d", spec1, spec2, spec3))
                                if (mouseoverLevel - 9) > (spec1 + spec2 + spec3) then
                                    GameTooltip:AddLine("Unspent Talent Points!", 148, 0, 211)
                                end
                            end
                        end
                    end

                    --Gearscore/Ilevel Information
                    local playerLevel = UnitLevel(unittype)
                    if playerLevel and playerLevel >= 80 and addon.db.global.gearSummaryTooltips then
                        if not TacoTip_GSCallback then -- Dont show information TacoTip shows if it is loaded
                            if CI:CanInspect(curMouseOver) then
                                CI:DoInspect(curMouseOver)
                            end
                            local guid, gearScore = LGS:GetScore(curMouseOver)
                            local ilvl = addon.GetILVLByGUID(curMouseOver)
                            if gearScore and gearScore.GearScore > 0 and ilvl and ilvl > 0 then
                                GameTooltip:AddDoubleLine(format("Item-level : %d", ilvl),
                                    format("GearScore : |c%s%d", gearScore.Color:GenerateHexColor(), gearScore.GearScore))
                            end
                        end
                    end
                end

                if addon.GroupieDevs[curMouseOver] then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(format("|TInterface\\AddOns\\%s\\Images\\icon64:16:16:0:0|t %s : %s"
                        , addonName, addonName, addon.GroupieDevs[curMouseOver]))
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
        desc = "",
        descStyle = "inline",
        handler = addon,
        type = 'group',
        args = {
            spacerdesc0 = { type = "description", name = " ", width = "full", order = 0 },
            instanceLog = {
                name = "    " .. L["InstanceLog"].Name,
                desc = "",
                type = "group",
                width = "double",
                inline = false,
                order = 22,
                args = {
                    header0 = {
                        type = "description",
                        name = "|cff9d9d9d|Hitem:3299::::::::20:257::::::|h[Fractured Canine]|h|r|cff" ..
                            addon.groupieSystemColor .. L["InstanceLog"].Name,
                        order = 0,
                        fontSize = "large"
                    },
                    spacerdesc0 = { type = "description", name = " ", width = "full", order = 1 },
                    infodesc = { type = "description", name = L["InstanceLogInfo"], width = "full", order = 2 },
                    spacerdesc1 = { type = "description", name = " ", width = "full", order = 3 },
                    header1 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. "Discord",
                        order = 4,
                        fontSize = "medium"
                    },
                    editbox1 = {
                        type = "input",
                        name = "",
                        order = 5,
                        width = 2,
                        get = function(info) return "https://discord.gg/p68QgZ8uqF" end,
                        set = function(info, val) return end,
                    },
                    spacerdesc2 = { type = "description", name = " ", width = "full", order = 6 },
                    header2 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["InstanceLog"].Name,
                        order = 7,
                        fontSize = "medium"
                    },
                    editbox2 = {
                        type = "input",
                        name = "",
                        order = 8,
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
                desc = "",
                type = "group",
                width = "double",
                inline = false,
                order = 21,
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
                name = "    " .. L["InstanceFilters"].Wrath.Name,
                desc = "",
                type = "group",
                width = "double",
                inline = false,
                order = 13,
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
                name = "    " .. L["InstanceFilters"].TBC.Name,
                desc = "",
                type = "group",
                width = "double",
                inline = false,
                order = 14,
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
                name = "    " .. L["InstanceFilters"].Classic.Name,
                desc = "",
                type = "group",
                width = "double",
                inline = false,
                order = 15,
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
                name = "    " .. L["GroupFilters"].Name,
                desc = "",
                type = "group",
                width = "double",
                inline = false,
                order = 12,
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
                        get = function(info) return addon.db.char.ignoreSavedInstances end,
                        set = function(info, val) addon.db.char.ignoreSavedInstances = val end,
                    },
                    ignoreLFG = {
                        type = "toggle",
                        name = L["GroupFilters"].ignoreLFG,
                        order = 5,
                        width = "full",
                        get = function(info) return not addon.db.char.ignoreLFG end,
                        set = function(info, val) addon.db.char.ignoreLFG = not val end,
                    },
                    ignoreLFM = {
                        type = "toggle",
                        name = L["GroupFilters"].ignoreLFM,
                        order = 6,
                        width = "full",
                        get = function(info) return not addon.db.char.ignoreLFM end,
                        set = function(info, val) addon.db.char.ignoreLFM = not val end,
                    },
                }
            },
            keywordfilters = {
                name = "    " .. L["KeywordFilters"],
                desc = "",
                type = "group",
                width = "double",
                inline = false,
                order = 4,
                args = {
                    header0 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["KeywordFilters"],
                        order = 0,
                        fontSize = "large"
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
            globalfriendslist = {
                name = "    " .. L["GlobalFriendsLabel"],
                desc = "",
                type = "group",
                width = "double",
                inline = false,
                order = 2,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. "Global Options: Global Friends List",
                        order = 0,
                        fontSize = "large"
                    },
                    spacerdesc1 = { type = "description", name = " ", width = "full", order = 1 },
                    enableGlobalFriendsToggle = {
                        type = "toggle",
                        name = "Enable Global Friends & Ignore Lists",
                        order = 2,
                        width = "full",
                        get = function(info) return addon.db.global.enableGlobalFriends end,
                        set = function(info, val)
                            addon.db.global.enableGlobalFriends = val
                            for k, v in pairs(addon.options.args.globalfriendslist.args) do
                                if v and v.order then
                                    if v.order > 2 then
                                        if val then
                                            v.hidden = false
                                        else
                                            v.hidden = true
                                        end
                                    end
                                end
                            end
                        end,
                    },
                    spacerdesc2 = { type = "description", name = " ", width = "full", order = 3 },
                    header2 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. "Include Friends & Ignore Data From",
                        order = 4,
                        fontSize = "medium"
                    },
                    spacerdesc3 = { type = "description", name = " ", width = "full", order = 5 },
                    spacerdesc4 = { type = "description", name = " ", width = "full", order = 1000 },
                    header3 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. "Include Guild Roster Data From",
                        order = 1001,
                        fontSize = "medium"
                    },
                    spacerdesc5 = { type = "description", name = " ", width = "full", order = 1002 },
                },
            },
            charoptions = {
                name = L["CharOptions"].Name,
                desc = "",
                type = "group",
                width = "double",
                inline = false,
                order = 11,
                args = {
                    header1 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. myname .. " " .. L["Options"],
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
                    headerLFG = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. "LFG Messages",
                        order = 8,
                        fontSize = "medium"
                    },
                    spacerdescLFG = { type = "description", name = " ", width = "full", order = 9 },
                    descLFG = {
                        type = "description",
                        name = "LFG Messages sent before Max Level will always show your Character Level.\n\nAt Max Level, show:",
                        order = 10,
                    },
                    LFGMsgDropdown = {
                        type = "select",
                        style = "dropdown",
                        name = "",
                        order = 11,
                        width = 1.4,
                        values = {
                            [1] = "Character Level",
                            [2] = "Item-level",
                            [3] = "GearScore"
                        },
                        set = function(info, val) addon.db.char.LFGMsgGearType = val end,
                        get = function(info) return addon.db.char.LFGMsgGearType end,
                    },
                    spacerdescLFG2 = { type = "description", name = " ", width = "full", order = 12 },
                    otherRoleToggle = {
                        type = "toggle",
                        name = L["CharOptions"].OtherRole,
                        order = 13,
                        width = "full",
                        get = function(info) return addon.db.char.sendOtherRole end,
                        set = function(info, val) addon.db.char.sendOtherRole = val end,
                    },
                    spacerdesc4 = { type = "description", name = " ", width = "full", order = 14 },
                    header4 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["CharOptions"].DungeonLevelRange,
                        order = 15,
                        fontSize = "medium"
                    },
                    recLevelDropdown = {
                        type = "select",
                        style = "dropdown",
                        name = "",
                        order = 16,
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
                    spacerdesc5 = { type = "description", name = " ", width = "full", order = 17 },

                    respondRequestHeader = {
                        type = "description",
                        name = "|cff" ..
                            addon.groupieSystemColor ..
                            "Auto-Respond : When someone Requests to Join your group, without messaging you first...",
                        order = 22,
                        fontSize = "medium"
                    },
                    respondRequestDesc = {
                        type = "description",
                        name = "Note : This will only engage when you are listed in the LFG Tool.",
                        width = "full",
                        order = 23,
                    },
                    autoRequestResponseToggle = {
                        type = "toggle",
                        name = "Auto Response with, \"What Role are you?...\"",
                        order = 24,
                        width = "full",
                        get = function(info) return addon.db.char.autoRespondRequests end,
                        set = function(info, val) addon.db.char.autoRespondRequests = val end,
                    },
                    autoRequestRejectToggle = {
                        type = "toggle",
                        name = "...and Reject Request",
                        order = 25,
                        width = "full",
                        get = function(info) return addon.db.char.autoRejectRequests end,
                        set = function(info, val) addon.db.char.autoRejectRequests = val end,
                    },
                    spacerdesc7 = { type = "description", name = " ", width = "full", order = 26 },
                    respondInviteHeader = {
                        type = "description",
                        name = "|cff" ..
                            addon.groupieSystemColor ..
                            "Auto-Respond : When someone Invites you to their group, without messaging you first...",
                        order = 27,
                        fontSize = "medium"
                    },
                    respondInviteDesc = {
                        type = "description",
                        name = "Note : This will only engage when you are listed in the LFG Tool.",
                        width = "full",
                        order = 28,
                    },
                    autoInviteResponseToggle = {
                        type = "toggle",
                        name = "Auto Response with, \"What's this Invite for?...\"",
                        order = 29,
                        width = "full",
                        get = function(info) return addon.db.char.autoRespondInvites end,
                        set = function(info, val) addon.db.char.autoRespondInvites = val end,
                    },
                    autoInviteRejectToggle = {
                        type = "toggle",
                        name = "...and Reject Request",
                        order = 30,
                        width = "full",
                        get = function(info) return addon.db.char.autoRejectInvites end,
                        set = function(info, val) addon.db.char.autoRejectInvites = val end,
                    },

                    spacerdesc8 = { type = "description", name = " ", width = "full", order = 31 },
                    header6 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. addonName .. " " .. L["CharOptions"].AfterParty,
                        order = 32,
                        fontSize = "medium",
                        hidden = true,
                        disabled = true,
                    },
                    afterPartyToggle = {
                        type = "toggle",
                        name = "Enable " .. addonName .. " " .. L["CharOptions"].AfterParty,
                        order = 33,
                        width = "full",
                        get = function(info) return addon.db.char.afterParty end,
                        set = function(info, val) addon.db.char.afterParty = val end,
                        hidden = true,
                        disabled = true,
                    },
                    spacerdesc9 = { type = "description", name = " ", width = "full", order = 34,
                        hidden = true,
                        disabled = true, },
                    header7 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. "Enable Auto Responses",
                        order = 35,
                        fontSize = "medium",
                    },
                    autorespDesc = {
                        type = "description",
                        name = "Note : Auto-Response will only fire when you are not already in an arena, battleground, or group of any kind, and only when LFG Auto-Response|r is toggled on using the Minimap button.\n\n    \"Hey Friend, you can count on me!...\"",
                        order = 36,
                    },

                    spacerdesc10 = { type = "description", name = " ", width = "full", order = 999 },
                    header8 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["CharOptions"].PullGroups,
                        order = 1000,
                        fontSize = "medium"
                    },
                    channelGuildToggle = {
                        type = "toggle",
                        name = L["text_channels"].Guild,
                        order = 1001,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels[L["text_channels"].Guild] end,
                        set = function(info, val) addon.db.char.useChannels[L["text_channels"].Guild] = val end,
                    },
                    channelGeneralToggle = {
                        type = "toggle",
                        name = L["text_channels"].General,
                        order = 1002,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels[L["text_channels"].General] end,
                        set = function(info, val) addon.db.char.useChannels[L["text_channels"].General] = val end,
                    },
                    channelTradeToggle = {
                        type = "toggle",
                        name = L["text_channels"].Trade,
                        order = 1003,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels[L["text_channels"].Trade] end,
                        set = function(info, val) addon.db.char.useChannels[L["text_channels"].Trade] = val end,
                    },
                    channelLocalDefenseToggle = {
                        type = "toggle",
                        name = L["text_channels"].LocalDefense,
                        order = 1004,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels[L["text_channels"].LocalDefense] end,
                        set = function(info, val) addon.db.char.useChannels[L["text_channels"].LocalDefense] = val end,
                    },
                    channelLookingForGroupToggle = {
                        type = "toggle",
                        name = L["text_channels"].LFG,
                        order = 1005,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels[L["text_channels"].LFG] end,
                        set = function(info, val) addon.db.char.useChannels[L["text_channels"].LFG] = val end,
                    },
                    channel5Toggle = {
                        type = "toggle",
                        name = L["text_channels"].World,
                        order = 1006,
                        width = "full",
                        get = function(info) return addon.db.char.useChannels[L["text_channels"].World] end,
                        set = function(info, val) addon.db.char.useChannels[L["text_channels"].World] = val end,
                    }
                },
            },
            globaloptions = {
                name = L["GlobalOptions"].Name,
                desc = "",
                type = "group",
                width = "double",
                inline = false,
                order = 1,
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
                    talentTooltipToggle = {
                        type = "toggle",
                        name = "Enable Talent Summary in Player Tooltips",
                        order = 8,
                        width = "full",
                        get = function(info) return addon.db.global.talentTooltips end,
                        set = function(info, val) addon.db.global.talentTooltips = val end,
                    },
                    gearTooltipToggle = {
                        type = "toggle",
                        name = "Enable Gear Summary in Max-Level Player Tooltips",
                        order = 9,
                        width = "full",
                        get = function(info) return addon.db.global.gearSummaryTooltips end,
                        set = function(info, val) addon.db.global.gearSummaryTooltips = val end,
                    },
                    charSheetGearToggle = {
                        type = "toggle",
                        name = "Enable Gear Summary on Your Character Sheet",
                        order = 11,
                        width = "full",
                        get = function(info) return addon.db.global.charSheetGear end,
                        set = function(info, val)
                            addon.db.global.charSheetGear = val
                            if val then
                                CharSheetSummaryFrame:Show()
                            else
                                CharSheetSummaryFrame:Hide()
                            end
                        end,
                    },
                    announceResetToggle = {
                        type = "toggle",
                        name = "Announce Instance Reset in Party/Raid Chat",
                        order = 10,
                        width = "full",
                        get = function(info) return addon.db.global.announceInstanceReset end,
                        set = function(info, val)
                            addon.db.global.announceInstanceReset = val
                            if addon.db.global.announceInstanceReset then
                                ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", addon.resetChatFilter)
                            else
                                ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", addon.resetChatFilter)
                            end
                        end,
                    },
                    spacerdesc4 = { type = "description", name = " ", width = "full", order = 12 },
                    header2 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. "Gear Summary Offsets",
                        order = 13,
                        fontSize = "medium"
                    },
                    spacerdesc5 = { type = "description", name = " ", width = "full", order = 14 },
                    header3 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. "X Offset",
                        order = 15,
                        fontSize = "medium"
                    },
                    charSheetXSlider = {
                        type = "range",
                        name = "",
                        min = 0,
                        max = 150,
                        step = 1,
                        order = 16,
                        width = 1.5,
                        set = function(info, val)
                            addon.db.global.charSheetXOffset = val
                            CharSheetSummaryFrame:SetPoint("LEFT", CharSheetSummaryFrame:GetParent(), "LEFT",
                                8 + addon.db.global.charSheetXOffset,
                                -60 + addon.db.global.charSheetYOffset)
                        end,
                        get = function(info) return addon.db.global.charSheetXOffset end,
                    },
                    header4 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. "Y Offset",
                        order = 17,
                        fontSize = "medium"
                    },
                    charSheetYSlider = {
                        type = "range",
                        name = "",
                        min = 0,
                        max = 150,
                        step = 1,
                        order = 18,
                        width = 1.5,
                        set = function(info, val)
                            addon.db.global.charSheetYOffset = val
                            CharSheetSummaryFrame:SetPoint("LEFT", CharSheetSummaryFrame:GetParent(), "LEFT",
                                8 + addon.db.global.charSheetXOffset,
                                -60 + addon.db.global.charSheetYOffset)
                        end,
                        get = function(info) return addon.db.global.charSheetYOffset end,
                    },
                    spacerdesc6 = { type = "description", name = " ", width = "full", order = 19 },
                    header5 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["GlobalOptions"].LFGData,
                        order = 20,
                        fontSize = "medium"
                    },
                    preserveDurationDropdown = {
                        type = "select",
                        style = "dropdown",
                        name = "",
                        order = 21,
                        width = 1.4,
                        values = { [1] = L["GlobalOptions"].DurationDropdown["1"],
                            [2] = L["GlobalOptions"].DurationDropdown["2"],
                            [5] = L["GlobalOptions"].DurationDropdown["5"],
                            [10] = L["GlobalOptions"].DurationDropdown["10"] },
                        set = function(info, val) addon.db.global.minsToPreserve = val end,
                        get = function(info) return addon.db.global.minsToPreserve end,
                    },
                    spacerdesc7 = { type = "description", name = " ", width = "full", order = 22 },
                    header6 = {
                        type = "description",
                        name = "|cff" .. addon.groupieSystemColor .. L["GlobalOptions"].UIScale,
                        order = 23,
                        fontSize = "medium"
                    },
                    scaleSlider = {
                        type = "range",
                        name = "",
                        min = 0.5,
                        max = 2.0,
                        step = 0.1,
                        order = 24,
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
    -----------------------------------
    -- Generate Friend List Controls --
    -----------------------------------
    addon.GenerateFriendToggles(10, myserver, "globalfriendslist")
    addon.GenerateGuildToggles(1010, myserver, "globalfriendslist")
    addon.GenerateAutoResponseOptions(100, "Raid 25", "25", "charoptions")
    addon.GenerateAutoResponseOptions(150, "Raid 10", "10", "charoptions")
    addon.GenerateAutoResponseOptions(200, "Heroic Dungeon", "5H", "charoptions")
    addon.GenerateAutoResponseOptions(250, "Dungeon", "5", "charoptions")
    addon.GenerateAutoResponseOptions(300, "PVP", "PVP", "charoptions")


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


    if addon.db.global.lastShowedInfoPopup < addon.version then
        addon.db.global.lastShowedInfoPopup = addon.version
        local PopupFrame = nil
        local POPUP_WINDOW_WIDTH = 400
        local POPUP_WINDOW_HEIGHT = 450
        PopupFrame = CreateFrame("Frame", "GroupiePopUp", UIParent, "PortraitFrameTemplate")
        PopupFrame:Hide()
        PopupFrame:SetFrameStrata("DIALOG")
        PopupFrame:SetWidth(POPUP_WINDOW_WIDTH)
        PopupFrame:SetHeight(POPUP_WINDOW_HEIGHT)
        PopupFrame:SetPoint("CENTER", UIParent)
        PopupFrame:SetMovable(true)
        PopupFrame:EnableMouse(true)
        PopupFrame:RegisterForDrag("LeftButton", "RightButton")
        PopupFrame:SetClampedToScreen(true)
        PopupFrame.text = _G["GroupieTitleText"]
        PopupFrame.text:SetText(addonName)
        PopupFrame:SetScript("OnMouseDown",
            function(self)
                self:StartMoving()
                self.isMoving = true
            end)
        PopupFrame:SetScript("OnMouseUp",
            function(self)
                if self.isMoving then
                    self:StopMovingOrSizing()
                    self.isMoving = false
                end
            end)
        PopupFrame:SetScript("OnShow", function() return end)
        --Icon
        local PopupIcon = PopupFrame:CreateTexture("$parentIconPopup", "OVERLAY", nil, -8)
        PopupIcon:SetSize(60, 60)
        PopupIcon:SetPoint("TOPLEFT", -5, 7)
        PopupIcon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Images\\icon128.tga")
        local PopupGroupieTitle = PopupFrame:CreateFontString("FontString", "OVERLAY", "GameFontNormalMed1")
        PopupGroupieTitle:SetPoint("TOP", PopupFrame, "TOP", 0, -36)
        PopupGroupieTitle:SetWidth(POPUP_WINDOW_WIDTH - 32)
        PopupGroupieTitle:SetText("Groupie 1.64")
        --Info Text
        local PopupMsg = PopupFrame:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
        PopupMsg:SetPoint("TOPLEFT", PopupFrame, "TOPLEFT", 16, -64)
        PopupMsg:SetWidth(POPUP_WINDOW_WIDTH - 32)
        PopupMsg:SetText("1.64\n\nHey Everyone,\n\nGroupie is switching to a new \"Charm Validation\" technique and getting rid of the ugly hashes -- like \"[#Ag4f]\" at the end of messages.\n\nInstead we're using 3 target markers. The idea came from user Haste on our Discord.\n\nYou may see some \"Fake News\" responses from people who haven't updated yet. Hopefully it won't take too long to get everyone updated.\n\nCheers!")
        PopupMsg:SetJustifyH("LEFT")
        --Edit Box for Discord Link
        local PopupEditBox = CreateFrame("EditBox", "GroupieEditBoxPopup", PopupFrame, "InputBoxTemplate")
        PopupEditBox:SetPoint("BOTTOMLEFT", PopupFrame, "BOTTOMLEFT", 64, 20)
        PopupEditBox:SetSize(POPUP_WINDOW_WIDTH - 128, 50)
        PopupEditBox:SetAutoFocus(false)
        PopupEditBox:SetText("https://discord.gg/p68QgZ8uqF")
        PopupEditBox:SetScript("OnTextChanged", function()
            PopupEditBox:SetText("https://discord.gg/p68QgZ8uqF")
        end)
        local PopupDiscordTitle = PopupFrame:CreateFontString("FontString", "OVERLAY", "GameFontNormal")
        PopupDiscordTitle:SetPoint("BOTTOM", PopupEditBox, "TOP", 48, -12)
        PopupDiscordTitle:SetWidth(POPUP_WINDOW_WIDTH - 32)
        PopupDiscordTitle:SetText("Groupie Community Discord : ")
        PopupDiscordTitle:SetJustifyH("LEFT")
        PopupFrame:Show()
    end
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
    local myguild = GetGuildInfo("player")

    --create tables for the current server if needed
    if addon.db.global.friends[myserver] == nil then
        addon.db.global.friends[myserver] = {}
    end
    if addon.db.global.ignores[myserver] == nil then
        addon.db.global.ignores[myserver] = {}
    end
    if addon.db.global.guilds[myserver] == nil then
        addon.db.global.guilds[myserver] = {}
    end
    if addon.db.global.groupieFriends[myserver] == nil then
        addon.db.global.groupieFriends[myserver] = {}
    end
    if addon.db.global.groupieIgnores[myserver] == nil then
        addon.db.global.groupieIgnores[myserver] = {}
    end
    if addon.db.global.friendnotes[myserver] == nil then
        addon.db.global.friendnotes[myserver] = {}
    end
    if addon.db.global.ignorenotes[myserver] == nil then
        addon.db.global.ignorenotes[myserver] = {}
    end
    if addon.db.global.hiddenFriendLists[myserver] == nil then
        addon.db.global.hiddenFriendLists[myserver] = {}
    end
    if addon.db.global.hiddenGuilds[myserver] == nil then
        addon.db.global.hiddenGuilds[myserver] = {}
    end

    --Always clear and reload the current character
    addon.db.global.friends[myserver][myname] = {}
    addon.db.global.ignores[myserver][myname] = {}
    addon.db.global.guilds[myserver][myname] = {}
    if myguild ~= nil then
        addon.db.global.guilds[myserver][myname]["__NAME__"] = myguild
        --Show title in options
    end

    local hasAnyGuilds = false
    for k, v in pairs(addon.db.global.guilds[myserver]) do

        if addon.db.global.guilds[myserver][k] ~= nil then
            if addon.db.global.guilds[myserver][k]["__NAME__"] ~= nil then
                hasAnyGuilds = true
            end
        end
    end

    if hasAnyGuilds then
        addon.options.args.globalfriendslist.args.header3.hidden = false
    else
        addon.options.args.globalfriendslist.args.header3.hidden = true
    end

    --Update for the current character
    for i = 1, C_FriendList.GetNumFriends() do
        local name = C_FriendList.GetFriendInfoByIndex(i).name
        if name and name ~= _G.UKNOWNOBJECT then
            name = name:gsub("%-.+", "")
            addon.db.global.friends[myserver][myname][name] = true
        end
    end
    for i = 1, C_FriendList.GetNumIgnores() do
        local name = C_FriendList.GetIgnoreName(i)
        if name and name ~= _G.UKNOWNOBJECT then
            name = name:gsub("%-.+", "")
            addon.db.global.ignores[myserver][myname][name] = true
        end
    end
    if myguild ~= nil then
        for i = 1, GetNumGuildMembers() do
            local name = GetGuildRosterInfo(i)
            if name and name ~= _G.UKNOWNOBJECT then
                name = name:gsub("%-.+", "")
                addon.db.global.guilds[myserver][myname][name] = true
            end
        end
    end

    --Then clear the global lists and merge all lists
    --FRIENDLIST_UPDATE and IGNORELIST_UPDATE don't have context
    --so we need to just re-merge every time
    addon.friendList = {}
    addon.ignoreList = {}

    for char, friendlist in pairs(addon.db.global.friends[myserver]) do
        if addon.db.global.hiddenFriendLists[myserver][char] then
            --Hide this character's friends
        else
            for name, _ in pairs(friendlist) do
                addon.friendList[name] = true
            end
        end
    end

    for char, ignorelist in pairs(addon.db.global.ignores[myserver]) do
        if addon.db.global.hiddenFriendLists[myserver][char] then
            --Hide this character's ignores
        else
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

    for guild, roster in pairs(addon.db.global.guilds[myserver]) do
        local currentGuildName = roster["__NAME__"]
        if addon.db.global.hiddenGuilds[myserver][currentGuildName] then
            --Hide this guild
        else
            for name, _ in pairs(roster) do
                if name ~= "__NAME__" then
                    addon.friendList[name] = true
                end
            end
        end
    end
    addon.GenerateFriendToggles(10, myserver, "globalfriendslist")
    addon.GenerateGuildToggles(1010, myserver, "globalfriendslist")
end

function addon.UpdateCharacterSheet(ignoreILVL, ignoreGS)
    --1st Line : Show Talents
    --2nd Line : Show Average Item Level
    --3rd Line : Show Gear Score

    --Calculate talents
    local spec1, spec2, spec3 = CI:GetTalentPoints("player")
    local talentStr = format("%d / %d / %d", spec1, spec2, spec3)
    --Calculate Item level
    local ilvl = addon.MyILVL()
    if ilvl then
        if ilvl > 0 then
            addon.playerILVL = ilvl
        end
    end
    --Calculate gearscore
    LGS:PLAYER_EQUIPMENT_CHANGED() --Workaround for PEW event in library being too early
    CI:DoInspect("player")
    local guid, gearScore = LGS:GetScore("player")
    if gearScore and gearScore.GearScore and gearScore.GearScore > 0 then
        addon.playerGearScore = gearScore.GearScore
    end
    local colorStr = ""
    if gearScore.Color then
        colorStr = "|c" .. gearScore.Color:GenerateHexColor()
    end
    --Display on character sheet
    if addon.db.global.charSheetGear then
        CharSheetSummaryFrame:SetText(format("%s\nItem-level : %d\nGearScore : %s%d", talentStr, ilvl,
            colorStr, gearScore.GearScore))
    end
end

-------------------
--Event Registers--
-------------------
function addon:OnEnable()
    addon:RegisterEvent("CHARACTER_POINTS_CHANGED", function()
        addon.UpdateSpecOptions()
        addon.UpdateCharacterSheet()
    end)
    --Update player's saved instances on boss kill and login
    --The api is very slow to populate saved instance data, so we need a delay on these events
    addon:RegisterEvent("PLAYER_ENTERING_WORLD", function(...)
        addon.SetupConfig()
        local event, isInitialLogin, isReloadingUi = ...
        C_Timer.After(3, function()
            addon.UpdateFriends()
            addon.UpdateSavedInstances()
            addon.UpdateCharacterSheet()
            C_ChatInfo.RegisterAddonMessagePrefix(addon.ADDON_PREFIX)
            C_ChatInfo.SendAddonMessage(addon.ADDON_PREFIX, "v" .. tostring(addon.version), "YELL")

        end)
        if isInitialLogin == true then
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
        end
    end)
    --Update friend and ignore lists
    addon:RegisterEvent("FRIENDLIST_UPDATE", function()
        C_Timer.After(3, addon.UpdateFriends)
    end)
    addon:RegisterEvent("IGNORELIST_UPDATE", function()
        C_Timer.After(3, addon.UpdateFriends)
    end)
    addon:RegisterEvent("GUILD_ROSTER_UPDATE", function()
        C_Timer.After(3, addon.UpdateFriends)
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

        --Turn LFG mode off on group join
        addon.icon:ChangeTexture("Interface\\AddOns\\" .. addonName .. "\\Images\\icon64.tga", "GroupieLDB")
        addon.LFGMode = false

        for author, listing in pairs(addon.db.global.listingTable) do
            listing.messageSent = nil
            listing.senderName = nil
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
    --Update the gearscore/ilvl/talent lines in the character sheet
    addon:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function(...)
        addon.UpdateCharacterSheet()
    end)
end
