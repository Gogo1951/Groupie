local addonName, addon = ...
local GroupieAnnounceReset = addon:NewModule("GroupieAnnounceReset", "AceEvent-3.0")

local locale = GetLocale()
if not addon.tableContains(addon.validLocales, locale) then
    return
end
local L = LibStub('AceLocale-3.0'):GetLocale('Groupie')


local failedreset = "There are players still inside the instance." --This is actually a success, the message is a lie
local successreset = "has been reset."
local function AnnounceInstanceReset(_, msg, ...)
    if addon.db.global.announceInstanceReset then
        if strmatch(msg, successreset) then
            if (UnitIsGroupLeader("player")) then
                if (IsInRaid()) then
                    SendChatMessage(addon.instanceResetString, "RAID")
                elseif (IsInGroup()) then
                    SendChatMessage(addon.instanceResetString, "PARTY")
                end
            end
        elseif strmatch(msg, failedreset) then
            local playersStillInside = " Any players still inside will need to exit and then re-enter."
            if (UnitIsGroupLeader("player")) then
                if (IsInRaid()) then
                    SendChatMessage(addon.instanceResetString .. playersStillInside, "RAID")
                elseif (IsInGroup()) then
                    SendChatMessage(addon.instanceResetString .. playersStillInside, "PARTY")
                end
            end
        end
    end
end

--filter the incorrect 'failed reset' message
function addon.resetChatFilter(self, event, msg, author, ...)
    if strmatch(msg, failedreset) then
        return true
    end
end

function GroupieAnnounceReset:OnEnable()
    self:RegisterEvent("CHAT_MSG_SYSTEM", function(...)
        AnnounceInstanceReset(...)
    end)
    if addon.db.global.announceInstanceReset then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", addon.resetChatFilter)
    end
end
