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
        if strmatch(msg, failedreset) or strmatch(msg, successreset) then
            if (UnitIsGroupLeader("player")) then
                if (IsInRaid()) then
                    SendChatMessage(addon.instanceResetString, "RAID")
                elseif (IsInGroup()) then
                    SendChatMessage(addon.instanceResetString, "RAID")
                end
            end
        end
    end
end

function GroupieAnnounceReset:OnEnable()
    self:RegisterEvent("CHAT_MSG_SYSTEM", function(...)
        AnnounceInstanceReset(...)
    end)
end
