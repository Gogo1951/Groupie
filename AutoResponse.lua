local addonName, addon = ...
local locale = GetLocale()
if not addon.tableContains(addon.validLocales, locale) then
    return
end
local L = LibStub('AceLocale-3.0'):GetLocale('Groupie')
local time = time

addon.recentPlayers = {}
local askForPlayerInfo = format("{rt3} %s : What are you?", addonName)
local askForInstance = format("{rt3} %s : What are you inviting me to? Let me know what Role you need, and if there are any reserves. Thanks!"
    , addonName)

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
    if not addon.db.char.autoRespondInvites then
        return
    end

    --Not someone recently spoken to
    if addon.recentPlayers[author] == nil then
        SendChatMessage(askForInstance, "WHISPER", "COMMON", author)
        addon.recentPlayers[author] = time()
    end
end

--Respond to requests to join player's group
local function RespondToRequest(_, msg, ...)
    expireRecentPlayers()
    if not addon.db.char.autoRespondRequests then
        return
    end
    if not strmatch(msg, "has requested to join your group") then
        return
    end

    local author = msg:gsub("%|Hplayer:", ""):gsub("%|h.+", "")
    --Not someone recently spoken to
    if addon.recentPlayers[author] == nil then
        SendChatMessage(askForPlayerInfo, "WHISPER", "COMMON", author)
        addon.recentPlayers[author] = time()
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

-------------------
--EVENT REGISTERS--
-------------------

addon:RegisterEvent("PARTY_INVITE_REQUEST", RespondToInvite)
--GROUP_INVITE_CONFIRMATION is the event fired for invite requests
--but doesnt return any context, so we need to use the system message
addon:RegisterEvent("CHAT_MSG_SYSTEM", RespondToRequest)
addon:RegisterEvent("CHAT_MSG_WHISPER", function(...)
    OnWhisper(true, ...)
end)

addon:RegisterEvent("CHAT_MSG_WHISPER_INFORM", function(...)
    OnWhisper(false, ...)
end)
