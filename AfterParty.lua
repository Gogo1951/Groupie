local addonName, addon = ...
local AfterParty = addon:NewModule("GroupieAfterParty", "AceEvent-3.0")

local locale = GetLocale()
if not addon.tableContains(addon.validLocales, locale) then
    return
end
local L        = LibStub('AceLocale-3.0'):GetLocale('Groupie')
local myserver = GetRealmName()
local myname   = UnitName("player")


local OuterFrame     = nil
local InnerFrame     = nil
local WINDOW_WIDTH   = 600
local WINDOW_HEIGHT  = 348
local WINDOW_OFFSET  = 123
local WINDOW_YOFFSET = -84
local FrameRows      = {}
local columnCount    = 0
local COL_NAME       = 105
local COL_LEVEL      = 75
local COL_GUILDRANK  = 105
local COL_BTN        = 120
local COL_GUILD      = WINDOW_WIDTH - COL_NAME - COL_GUILDRANK - COL_BTN - COL_LEVEL - 22
local BUTTON_WIDTH   = WINDOW_WIDTH - 44
local BUTTON_HEIGHT  = 49

--Create column headers for the UI
--Create column headers for the main tab
local function createColumn(text, width, parent)
    columnCount = columnCount + 1
    local Header = CreateFrame("Button", parent:GetName() .. "APHeader" .. columnCount, parent,
        "WhoFrameColumnHeaderTemplate")
    Header:SetWidth(width)
    _G[parent:GetName() .. "APHeader" .. columnCount .. "Middle"]:SetWidth(width - 9)
    Header:SetText(text)
    --Header:SetJustifyH("CENTER")
    Header:SetNormalFontObject("GameFontHighlight")
    Header:SetID(columnCount)
    Header:Disable()

    if columnCount == 1 then
        Header:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, 22)
    else
        Header:SetPoint("LEFT", parent:GetName() .. "APHeader" .. columnCount - 1, "RIGHT", 0, 0)
    end

    Header:SetScript("OnClick", function() return end)
end

--Construct Frames for the after party tool
local function BuildAfterPartyWindow()
    OuterFrame = CreateFrame("Frame", "GroupieAfterPartyOuter", UIParent, "PortraitFrameTemplate")
    OuterFrame:Hide()
    --Allow the frame to close when ESC is pressed
    tinsert(UISpecialFrames, "Groupie")
    OuterFrame:SetFrameStrata("DIALOG")
    OuterFrame:SetWidth(WINDOW_WIDTH)
    OuterFrame:SetHeight(WINDOW_HEIGHT)
    OuterFrame:SetPoint("CENTER", UIParent)
    OuterFrame:SetMovable(true)
    OuterFrame:EnableMouse(true)
    OuterFrame:RegisterForDrag("LeftButton", "RightButton")
    OuterFrame:SetClampedToScreen(true)
    OuterFrame.title = _G["GroupieAfterPartyOuterTitleText"]
    OuterFrame.title:SetText(addonName .. " - v" .. tostring(addon.version))
    OuterFrame:SetScript("OnMouseDown",
        function(self)
            self:StartMoving()
            self.isMoving = true
        end)
    OuterFrame:SetScript("OnMouseUp",
        function(self)
            if self.isMoving then
                self:StopMovingOrSizing()
                self.isMoving = false
            end
        end)
    OuterFrame:SetFrameStrata("FULLSCREEN")


    --------
    --Icon--
    --------
    local icon = OuterFrame:CreateTexture("$parentIcon", "OVERLAY", nil, -8)
    icon:SetSize(60, 60)
    icon:SetPoint("TOPLEFT", -5, 7)
    icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Images\\icon128.tga")

    --------------
    --CheckBoxes--
    --------------

    local CheckBoxAP = CreateFrame("CheckButton", "GroupieAfterPartyCB1", OuterFrame,
        "ChatConfigCheckButtonTemplate")
    CheckBoxAP:SetPoint("BOTTOMLEFT", 8, 8)
    CheckBoxAP.Text:SetText(" Enable Groupie After Party")
    CheckBoxAP:SetScript("OnClick", function()
        addon.db.char.afterParty = CheckBoxAP:GetChecked()
    end)
    CheckBoxAP:SetChecked(addon.db.char.afterParty)

    local CheckBoxAPMsg = CreateFrame("CheckButton", "GroupieAfterPartyCB2", OuterFrame,
        "ChatConfigCheckButtonTemplate")
    CheckBoxAPMsg:SetPoint("LEFT", _G["GroupieAfterPartyCB1Text"], "RIGHT", 8, -2)
    CheckBoxAPMsg.Text:SetText(" Notify New Friends")
    CheckBoxAPMsg:SetScript("OnClick", function()
        addon.db.char.notifyAfterParty = CheckBoxAPMsg:GetChecked()
    end)
    CheckBoxAPMsg:SetChecked(addon.db.char.notifyAfterParty)

    OuterFrame:SetScript("OnShow", function()
        --Update values for checkboxes
        CheckBoxAP:SetChecked(addon.db.char.afterParty)
        CheckBoxAPMsg:SetChecked(addon.db.char.notifyAfterParty)
    end)

    -----------
    --Content--
    -----------

    InnerFrame = CreateFrame("Frame", "GroupieAfterPartyInner", OuterFrame, "InsetFrameTemplate")
    InnerFrame:SetWidth(WINDOW_WIDTH - 20)
    InnerFrame:SetHeight(WINDOW_HEIGHT - WINDOW_OFFSET + 20 - 16)
    InnerFrame:SetPoint("TOPLEFT", OuterFrame, "TOPLEFT", 8, WINDOW_YOFFSET)
    InnerFrame:SetScript("OnShow",
        function(self)
            return
        end)

    InnerFrame.infotext = InnerFrame:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
    InnerFrame.infotext:SetJustifyH("CENTER")
    InnerFrame.infotext:SetPoint("TOP", 0, 52)
    InnerFrame.infotext:SetWidth(WINDOW_WIDTH - 128)
    InnerFrame.infotext:SetText("Note : Since you are limited to 100 in-game friends per Character, these friends will be added to your Groupie Global Friends List.")

    createColumn("Name", COL_NAME, InnerFrame)
    createColumn("Level", COL_LEVEL, InnerFrame)
    createColumn("Guild", COL_GUILD, InnerFrame)
    createColumn("Guild Rank", COL_GUILDRANK, InnerFrame)
    createColumn("Add to Friends", COL_BTN, InnerFrame)


    for i = 1, 4 do
        FrameRows[i] = CreateFrame(
            "Button",
            "AfterPartyListingBtn" .. tostring(i),
            InnerFrame,
            "IgnoreListButtonTemplate2"
        )
        if i == 1 then
            FrameRows[i]:SetPoint("TOPLEFT", InnerFrame, -1, 0)
        else
            FrameRows[i]:SetPoint("TOP", FrameRows[i - 1], "BOTTOM", 0, 0)
        end
        FrameRows[i]:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
        --FrameRows[i]:Disable()

        --Name Col
        FrameRows[i].name:SetWidth(COL_NAME)

        --Level Col
        FrameRows[i].lvl = FrameRows[i]:CreateFontString("FontString", "OVERLAY", "GameFontNormal")
        FrameRows[i].lvl:SetPoint("LEFT", FrameRows[i].name, "RIGHT", 0, 0)
        FrameRows[i].lvl:SetWidth(COL_LEVEL)
        FrameRows[i].lvl:SetJustifyH("LEFT")
        FrameRows[i].lvl:SetJustifyV("MIDDLE")

        --Guild Col
        FrameRows[i].guild = FrameRows[i]:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
        FrameRows[i].guild:SetPoint("LEFT", FrameRows[i].lvl, "RIGHT", 0, 0)
        FrameRows[i].guild:SetWidth(COL_GUILD)
        FrameRows[i].guild:SetJustifyH("LEFT")
        FrameRows[i].guild:SetJustifyV("MIDDLE")

        --Guild Rank Col
        FrameRows[i].guildrank = FrameRows[i]:CreateFontString("FontString", "OVERLAY", "GameFontHighlight")
        FrameRows[i].guildrank:SetPoint("LEFT", FrameRows[i].guild, "RIGHT", 0, 0)
        FrameRows[i].guildrank:SetWidth(COL_GUILDRANK)
        FrameRows[i].guildrank:SetJustifyH("LEFT")
        FrameRows[i].guildrank:SetJustifyV("MIDDLE")

        --Add Col
        FrameRows[i].btn = CreateFrame("Button", "$parentApplyBtn", FrameRows[i], "UIPanelButtonTemplate")
        FrameRows[i].btn:SetPoint("LEFT", FrameRows[i].guildrank, "RIGHT", -2, 0)
        FrameRows[i].btn:SetWidth(COL_BTN - 12)
        FrameRows[i].btn:SetScript("OnClick", function()
            return
        end)

    end


    OuterFrame:Hide()
end

--Generate a tooltip for a given friended or ignored player name
local function GenerateTooltip(name, isIgnore)
    local outStr = ""
    local ignores = {}
    local friends = {}
    local guilds = {}
    name = name:gsub("%-.+", "")
    if isIgnore then
        --Ignore
        outStr = "Ignored\n\n"

        for char, ignorelist in pairs(addon.db.global.ignores[myserver]) do
            if ignorelist[name] then
                tinsert(ignores, char)
            end
        end
        sort(ignores, function(a, b) return a < b end)
        for k, v in pairs(ignores) do
            outStr = outStr .. "\nvia " .. v
        end

    else
        --Friend
        outStr = "Already Friends!\n\n"

        --Check Groupie Friends
        if addon.db.global.groupieFriends[myserver][name] then
            return "Already Friends!"
        end

        --Check Character Friends
        for char, friendlist in pairs(addon.db.global.friends[myserver]) do
            if friendlist[name] then
                tinsert(friends, char)
            end
        end
        sort(friends, function(a, b) return a < b end)
        for k, v in pairs(friends) do
            outStr = outStr .. "\nvia " .. v
        end

        --Check Guilds
        for guild, roster in pairs(addon.db.global.guilds[myserver]) do
            if roster[name] then
                tinsert(guilds, roster["__NAME__"])
            end
        end
        sort(guilds, function(a, b) return a < b end)
        for k, v in pairs(guilds) do
            outStr = outStr .. "\nvia <" .. v .. ">"
        end
    end
    return outStr
end

--Clear saved party info on initial login or after displaying window
local function ClearParty()
    addon.db.global.savedPartyPlayers = nil
end

--Store information about party players on boss kill
local function StoreParty()
    --Disabled if global friends are disabled, or if this characters friend lists are disabled
    if not addon.db.global.enableGlobalFriends then return end
    if addon.db.global.hiddenFriendLists[myserver][myname] then return end

    if IsInGroup() and not IsInRaid() then
        for i = 1, 4 do
            local name = UnitName("party" .. tostring(i))
            if name ~= nil and name ~= _G.UNKNOWNOBJECT then
                local _, class = UnitClass("party" .. tostring(i))
                local level = UnitLevel("party" .. tostring(i))
                local guildName, guildRank, guildRankIndex = GetGuildInfo("party" .. tostring(i))
                if addon.db.global.savedPartyPlayers == nil then
                    addon.db.global.savedPartyPlayers = {}
                end
                addon.db.global.savedPartyPlayers[i] = {
                    name = name,
                    class = class,
                    level = level,
                    guildName = guildName,
                    guildRank = guildRank,
                }
            end
        end
    end

end

--Display the window, clear saved party info
local function ShowPartyWindow()

    --Disabled if global friends are disabled, or if this characters friend lists are disabled
    if not addon.db.global.enableGlobalFriends then return end
    if addon.db.global.hiddenFriendLists[myserver][myname] then return end

    --Test data injection
    if addon.debugMenus then
        addon.db.global.savedPartyPlayers = {
            [1] = {
                name = "Funnyguy",
                level = UnitLevel("player"),
                class = "SHAMAN",
                guildName = "Test Guild 1",
                guildRank = "Testrank1",
            },
            [2] = {
                name = "Dog",
                level = 70,
                class = "DRUID",
                guildName = "Long Guild Name Here",
                guildRank = "testrank2",
            },
            [3] = {
                name = "Testguytwo",
                level = 25,
                class = "HUNTER",
                guildName = nil,
                guildRank = nil,
            },
            [4] = {
                name = "Sillyguy",
                level = 80,
                class = "WARRIOR",
                guildName = "Test Guild 1",
                guildRank = "Rank",
            }
        }
    end
    --Populate the rows with text
    if addon.db.global.savedPartyPlayers ~= nil then
        for i = 1, 4 do
            if addon.db.global.savedPartyPlayers[i] then
                if addon.db.global.savedPartyPlayers[i].name then
                    FrameRows[i]:Show()
                    local name = addon.db.global.savedPartyPlayers[i].name
                    local level = addon.db.global.savedPartyPlayers[i].level
                    local class = addon.db.global.savedPartyPlayers[i].class
                    local guildName = addon.db.global.savedPartyPlayers[i].guildName or ""
                    local guildRank = addon.db.global.savedPartyPlayers[i].guildRank or ""
                    local tooltip = ""

                    --Row data
                    FrameRows[i].name:SetText(format("|cff%s%s",
                        addon.classColors[class],
                        name))
                    FrameRows[i].lvl:SetText(level)
                    if guildName ~= "" then
                        FrameRows[i].guild:SetText("<" .. guildName .. ">")
                    else
                        FrameRows[i].guild:SetText(guildName)
                    end
                    FrameRows[i].guildrank:SetText(guildRank)

                    --Show either add button, already friends, or ignored
                    if addon.friendList[name] then
                        FrameRows[i].btn:SetText("Already Friends")
                        FrameRows[i].btn:Disable()
                        tooltip = GenerateTooltip(name, false)
                        --Tooltip
                        FrameRows[i]:SetScript("OnEnter", function()
                            GameTooltip:SetOwner(FrameRows[i], "ANCHOR_CURSOR")
                            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
                            GameTooltip:Show()
                        end)
                        FrameRows[i]:SetScript("OnLeave", function()
                            GameTooltip:Hide()
                        end)
                    elseif addon.ignoreList[name] then
                        FrameRows[i].btn:SetText("Ignored")
                        FrameRows[i].btn:Disable()
                        tooltip = GenerateTooltip(name, true)
                    else
                        FrameRows[i].btn:SetText("Add To Friends")
                        FrameRows[i].btn:SetScript("OnClick", function()
                            addon.db.global.groupieFriends[myserver][name] = true
                            if addon.db.char.notifyAfterParty then
                                SendChatMessage(addon.addedNewFriendString, "WHISPER", "COMMON", name)
                            end
                            addon.UpdateFriends()
                            FrameRows[i].btn:SetText("Already Friends")
                            FrameRows[i].btn:Disable()
                        end)
                        FrameRows[i].btn:Enable()
                        tooltip = ""
                    end
                    --Tooltip
                    FrameRows[i]:SetScript("OnEnter", function()
                        GameTooltip:SetOwner(FrameRows[i], "ANCHOR_CURSOR")
                        GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
                        GameTooltip:Show()
                    end)
                    FrameRows[i]:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                    end)
                else
                    FrameRows[i].btn:Disable()
                    FrameRows[i]:Hide()
                end
            else
                FrameRows[i].btn:Disable()
                FrameRows[i]:Hide()
            end
        end
        OuterFrame:Show()
        ClearParty()
    end
end

-------------------
--EVENT REGISTERS--
-------------------

function AfterParty:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function(...)
        local event, isInitialLogin, isReloadingUi = ...
        if isInitialLogin then
            ClearParty()
        end
        BuildAfterPartyWindow()
    end)
    self:RegisterEvent("BOSS_KILL", StoreParty)
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", function() --Workaround for normal dungeons with no BOSS_KILL event
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "party" then
            StoreParty()
        end
    end)

    self:RegisterEvent("GROUP_LEFT", function()
        if addon.db.char.afterParty then
            ShowPartyWindow()
        end
    end)
end

--TODO: REMOVE TESTING COMMANDS
function AfterParty:OnInitialize()
    addon:RegisterChatCommand("gpapshow", ShowPartyWindow)
    addon:RegisterChatCommand("gpapstore", StoreParty)
    --addon:RegisterChatCommand("gclear", ClearParty)
end
