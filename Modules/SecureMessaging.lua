local addonName, addon = ...

local COLOR = {
    RED = "FFF44336",
}

local SecureMessaging = {
    verified = {},
    ADDON_PREFIX = "Groupie.SM",
    WHISPER_MATCHES = {
        [1] = "{rt3} groupie :",
    },
    WARNING_MESSAGE = "the following message was not sent by Groupie"
};

function SecureMessaging:SendSecureMessage(message, chatType, target)
    C_ChatInfo.SendAddonMessage(SecureMessaging.ADDON_PREFIX, message, chatType, target);
end

-- Use this for sending secure messages. It will send the message as per regular SendChatMessage, but will also send a prior addon message to verify the message.
function SecureMessaging:SendChatMessage(message, chatType, target)
    self:SendSecureMessage(message, chatType, target);
    SendChatMessage(message, chatType, nil, target);
end

function SecureMessaging:IsGroupiePrefix(prefix)
    return prefix == SecureMessaging.ADDON_PREFIX;
end

function SecureMessaging:IsGroupieWhisper(message)
    message = message:lower();
    for _, match in ipairs(self.WHISPER_MATCHES) do
        if message:find(match) then
            return true;
        end
    end
    return false;
end

function SecureMessaging.PLAYER_ENTERING_WORLD(self, event, isLogin, isReload)
    if isLogin or isReload then
        C_ChatInfo.RegisterAddonMessagePrefix(SecureMessaging.ADDON_PREFIX);
    end
end

function SecureMessaging.CHAT_MSG_ADDON(self, prefix, message, ...)
    if SecureMessaging:IsGroupiePrefix(prefix) then
        SecureMessaging.verified[message] = true;
    end
end

function SecureMessaging.verify(self, message)
    local verified = SecureMessaging.verified[message];
    SecureMessaging.verified[message] = nil
    return verified;
end

function SecureMessaging.CHAT_MSG_WHISPER(self, message)
    if SecureMessaging:IsGroupieWhisper(message) then
        if not SecureMessaging:verify(message) then
            print(WrapTextInColorCode("{rt3} Groupie :", COLOR.RED),
                WrapTextInColorCode(SecureMessaging.WARNING_MESSAGE, COLOR.RED));
            SecureMessaging:SendChatMessage("{rt3} Groupie :" .. SecureMessaging.WARNING_MESSAGE, chatType, target)
        end
    end
end

--addon:RegisterEvent("CHAT_MSG_WHISPER", SecureMessaging.CHAT_MSG_WHISPER);
--addon:RegisterEvent("PLAYER_ENTERING_WORLD", SecureMessaging.PLAYER_ENTERING_WORLD);
--addon:RegisterEvent("CHAT_MSG_ADDON", SecureMessaging.CHAT_MSG_ADDON);

addon.SM = SecureMessaging;
