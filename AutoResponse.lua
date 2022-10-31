local addonName, addon = ...
local GroupieAutoResponse = addon:NewModule("GroupieAutoResponse", "AceEvent-3.0")

local locale = GetLocale()
if not addon.tableContains(addon.validLocales, locale) then
    return
end
local L = LibStub('AceLocale-3.0'):GetLocale('Groupie')
local time = time

addon.recentPlayers = {}
local askForPlayerInfo = addon.askForPlayerInfo
local askForInstance = addon.askForInstance
local autoReject = addon.autoReject

--Clear table entries more than 1 minute old
local function expireRecentPlayers()
    local timediff = 60
    local now = time()
    for player, timestamp in pairs(addon.recentPlayers) do
        if now - timestamp > timediff then
            addon.recentPlayers[player] = nil
        end
    end
end

--Respond to invitations the player recieves to another's group
local function RespondToInvite(_, author)
    expireRecentPlayers()
    local listedLFG = C_LFGList.HasActiveEntryInfo()

    --automatically reject party invites
    if addon.db.char.autoRejectInvites and listedLFG then
        for i = 1, STATICPOPUP_NUMDIALOGS do
            if _G["StaticPopup" .. i].which == "PARTY_INVITE" then
                local player = _G["StaticPopup" .. i].text.text_arg1:gsub(" invites you.+", "")
                --dont reject recently spoken to players or friends
                if addon.recentPlayers[player] == nil and addon.friendList[player] == nil then
                    _G["StaticPopup" .. i .. "Button2"]:Click()
                end
            end
        end
    end

    if not addon.db.char.autoRespondInvites then
        return
    end

    --Not someone recently spoken to
    if addon.recentPlayers[author] == nil and listedLFG then
        local msg = askForInstance
        if addon.db.char.autoRejectInvites then
            msg = msg .. " " .. autoReject
        end
        SendChatMessage(msg, "WHISPER", "COMMON", author)
        addon.recentPlayers[author] = time()
    end
end

--Respond to requests to join player's group
local function RespondToRequest(_, msg, ...)
    expireRecentPlayers()
    local listedLFG = C_LFGList.HasActiveEntryInfo()

    if strmatch(msg, "has requested to join your group") then


        if not addon.db.char.autoRespondRequests then
            return
        end

        local author = msg:gsub("%|Hplayer:", ""):gsub("%|h.+", "")

        --Not someone recently spoken to
        if addon.recentPlayers[author] == nil and listedLFG then
            local msg = askForPlayerInfo
            if addon.db.char.autoRejectRequests then
                msg = msg .. " " .. autoReject
            end
            SendChatMessage(msg, "WHISPER", "COMMON", author)
            addon.recentPlayers[author] = time()
        end
    elseif strmatch(msg, "could not accept because you are already in a group") then
        if not addon.db.char.autoRespondInvites then
            return
        end

        local author = msg:gsub("%|Hplayer:", ""):gsub("%|h.+", "")

        --Not someone recently spoken to
        if addon.recentPlayers[author] == nil and listedLFG then
            SendChatMessage(askForInstance, "WHISPER", "COMMON", author)
            addon.recentPlayers[author] = time()
        end
    end
end

local function OnWhisper(isReceiver, _, msg, longAuthor, ...)
    expireRecentPlayers()
    local author = gsub(longAuthor, "%-.+", "")
    --Store the player as recently spoken to with a timestamp
    addon.recentPlayers[author] = time()
    if msg == askForPlayerInfo and isReceiver then
        addon.SendPlayerInfo(author)
    end
end

local function RejectInviteRequest()
    expireRecentPlayers()
    local listedLFG = C_LFGList.HasActiveEntryInfo()

    --automatically reject party invite requests
    if addon.db.char.autoRejectRequests and listedLFG then
        for i = 1, STATICPOPUP_NUMDIALOGS do
            if _G["StaticPopup" .. i].which == "GROUP_INVITE_CONFIRMATION" then
                local player = _G["StaticPopup" .. i].text.text_arg1:gsub(" has requested.+", "")
                if addon.recentPlayers[player] == nil and addon.friendList[player] == nil then
                    _G["StaticPopup" .. i .. "Button2"]:Click()
                end
            end
        end
    end
end

-------------------
--EVENT REGISTERS--
-------------------
function GroupieAutoResponse:OnEnable()
    self:RegisterEvent("PARTY_INVITE_REQUEST", RespondToInvite)
    --GROUP_INVITE_CONFIRMATION is the event fired for invite requests
    --but doesnt return any context, so we need to use the system message
    self:RegisterEvent("CHAT_MSG_SYSTEM", RespondToRequest)
    self:RegisterEvent("CHAT_MSG_WHISPER", function(...)
        OnWhisper(true, ...)
    end)
    --This requires a seperate event register, as we use system message for
    --responding to invite requests, but this fires before the popup sometimes
    self:RegisterEvent("GROUP_INVITE_CONFIRMATION", RejectInviteRequest)

    --self:RegisterEvent("CHAT_MSG_WHISPER_INFORM", function(...)
    --    OnWhisper(false, ...)
    --end)
end
