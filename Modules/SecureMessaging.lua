local addonName, Groupie = ...

local List = LibStub("List-1.0")

local COLOR = { RED = "FFF44336", GREEN = "FF4CAF50" }

local prototype = {
    print = print,
    verified = List:new(),
    COLOR = COLOR,
    ADDON_PREFIX = "Groupie.SM",
    PROTECTED_TOKENS = List:new {
        [1] = "{rt3}%s*groupie%s*:",
        [2] = "groupie%s*{rt3}%s*:"
    },
    WARNING_MESSAGE = WrapTextInColorCode(
        "Groupie {rt3} : the following message was not sent by Groupie",
        COLOR.RED)
}

local SecureMessaging = Groupie:NewModule("SecureMessaging", prototype,
    "AceEvent-3.0")

Groupie.SM = SecureMessaging

function WithEventFilter(filter)
    return function(handler)
        return function(self, ...)
            if filter(...) then handler(self, ...) end
        end
    end
end

function SecureMessaging:ShouldVerify(message)
    return self.PROTECTED_TOKENS:some(function(token)
        return message:lower():match(token)
    end)
end

function SecureMessaging:SendSecureMessage(message, chatType, target)
    C_ChatInfo.SendAddonMessage(SecureMessaging.ADDON_PREFIX, message, chatType,
        target)
end

-- Use this for sending secure messages. It will send the message as per regular SendChatMessage, but will also send a prior addon message to verify the message.
function SecureMessaging:SendChatMessage(message, chatType, target)
    self:SendSecureMessage(message, chatType, target)
    SendChatMessage(message, chatType, nil, target)
end

function SecureMessaging:Verify(message)
    return #self.verified:splice(self.verified:indexOf(message), 1) > 0
end

function SecureMessaging.PLAYER_ENTERING_WORLD(...)
    C_ChatInfo.RegisterAddonMessagePrefix(SecureMessaging.ADDON_PREFIX)
end

function SecureMessaging.CHAT_MSG_ADDON(...)
    SecureMessaging.verified:push(select(3, ...))
end

function SecureMessaging.CHAT_MSG_WHISPER(...)
    local _, msg, author = ...
    C_Timer.After(0.5, function()
        if not SecureMessaging:Verify(msg) then
            --SecureMessaging.print(SecureMessaging.WARNING_MESSAGE)
            SecureMessaging:SendChatMessage("{rt3} Groupie : Fake News! That is not a real Groupie Message. Quit being shady."
                , "WHISPER", author)
        end
    end)
end

local ForPrefix = WithEventFilter(function(prefix)
    return prefix == SecureMessaging.ADDON_PREFIX
end)
local ForVerified = WithEventFilter(function(message)
    return SecureMessaging:ShouldVerify(message)
end)
local ForLoginReload = WithEventFilter(function(_, isLogin, isReload)
    return isLogin or isReload
end)

SecureMessaging:RegisterEvent("CHAT_MSG_WHISPER", function(...)
    ForVerified(SecureMessaging.CHAT_MSG_WHISPER)(...)
end)
SecureMessaging:RegisterEvent("PLAYER_ENTERING_WORLD", function(...)
    ForLoginReload(SecureMessaging.PLAYER_ENTERING_WORLD)(...)
end)
SecureMessaging:RegisterEvent("CHAT_MSG_ADDON", function(...)
    ForPrefix(SecureMessaging.CHAT_MSG_ADDON)(...)
end)
