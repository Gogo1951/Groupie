local addonName, addon = ...
local AfterParty = addon:NewModule("GroupieAfterParty", "AceEvent-3.0")

local locale = GetLocale()
if not addon.tableContains(addon.validLocales, locale) then
    return
end
local L        = LibStub('AceLocale-3.0'):GetLocale('Groupie')
local myserver = GetRealmName()


local OuterFrame     = nil
local InnerFrame     = nil
local WINDOW_WIDTH   = 600
local WINDOW_HEIGHT  = 300
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
    local Header = CreateFrame("Button", parent:GetName() .. "Header" .. columnCount, parent,
        "WhoFrameColumnHeaderTemplate")
    Header:SetWidth(width)
    _G[parent:GetName() .. "Header" .. columnCount .. "Middle"]:SetWidth(width - 9)
    Header:SetText(text)
    --Header:SetJustifyH("CENTER")
    Header:SetNormalFontObject("GameFontHighlight")
    Header:SetID(columnCount)
    Header:Disable()

    if columnCount == 1 then
        Header:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, 22)
    else
        Header:SetPoint("LEFT", parent:GetName() .. "Header" .. columnCount - 1, "RIGHT", 0, 0)
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
    OuterFrame:SetScript("OnShow", function() return end)

    --------
    --Icon--
    --------
    local icon = OuterFrame:CreateTexture("$parentIcon", "OVERLAY", nil, -8)
    icon:SetSize(60, 60)
    icon:SetPoint("TOPLEFT", -5, 7)
    icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Images\\icon128.tga")



    InnerFrame = CreateFrame("Frame", "GroupieAfterPartyInner", OuterFrame, "InsetFrameTemplate")
    InnerFrame:SetWidth(WINDOW_WIDTH - 20)
    InnerFrame:SetHeight(WINDOW_HEIGHT - WINDOW_OFFSET + 20)
    InnerFrame:SetPoint("TOPLEFT", OuterFrame, "TOPLEFT", 8, WINDOW_YOFFSET)
    InnerFrame:SetScript("OnShow",
        function(self)
            return
        end)

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
        FrameRows[i]:Disable()

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
        FrameRows[i].btn:SetPoint("LEFT", FrameRows[i].guildrank, "RIGHT", 0, 0)
        FrameRows[i].btn:SetWidth(COL_BTN - 12)
        FrameRows[i].btn:SetScript("OnClick", function()
            return
        end)

    end


    OuterFrame:Hide()
end

--Clear saved party info on initial login or after displaying window
local function ClearParty()
    addon.db.global.savedPartyPlayers = nil
end

--Store information about party players on boss kill
local function StoreParty()
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

    --Test data injection
    --addon.db.global.savedPartyPlayers = {
    --    [1] = {
    --        name = "Funnyguy",
    --        level = UnitLevel("player"),
    --        class = "SHAMAN",
    --        guildName = "Test Guild 1",
    --        guildRank = "Testrank1",
    --    },
    --    [2] = {
    --        name = "Dog",
    --        level = 70,
    --        class = "DRUID",
    --        guildName = "Long Guild Name Here",
    --        guildRank = "testrank2",
    --    },
    --    [3] = {
    --        name = "Cat",
    --        level = 25,
    --        class = "HUNTER",
    --        guildName = nil,
    --        guildRank = nil,
    --    },
    --    --[4] = {
    --    --    name = "Sillyguy",
    --    --    level = 80,
    --    --    class = "WARRIOR",
    --    --    guildName = "Test Guild 1",
    --    --    guildRank = "Rank",
    --    --}
    --}
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
                    elseif addon.ignoreList[name] then
                        FrameRows[i].btn:SetText("Ignored")
                        FrameRows[i].btn:Disable()
                    else
                        FrameRows[i].btn:SetText("Add To Friends")
                        FrameRows[i].btn:SetScript("OnClick", function()
                            addon.db.global.groupieFriends[myserver][name] = true
                            addon.UpdateFriends()
                            FrameRows[i].btn:SetText("Already Friends")
                            FrameRows[i].btn:Disable()
                        end)
                        FrameRows[i].btn:Enable()
                    end
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
    self:RegisterEvent("GROUP_LEFT", ShowPartyWindow)
end

--TODO: REMOVE TESTING COMMANDS
--function AfterParty:OnInitialize()
--    addon:RegisterChatCommand("gshow", ShowPartyWindow)
--    addon:RegisterChatCommand("gstore", StoreParty)
--    addon:RegisterChatCommand("gclear", ClearParty)
--end
