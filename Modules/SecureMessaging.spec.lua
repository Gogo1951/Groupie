local addonName, addon = ...

local List = LibStub("List-1.0")
local Spec = LibStub("Spec-1.0")
local SecureMessaging = addon.SM

SecureMessaging.SPEC = Spec:new("SecureMessaging", function(It)
    local printed = List:new()
    local character = UnitName("player")

    hooksecurefunc(addon.SM, "print",
                   function(...) printed:push(List:new{...}:join("")) end)

    local CHAT_MSG_WHISPER_STUB = function(...) end
    hooksecurefunc(addon.SM, "CHAT_MSG_WHISPER",
                   function(...) CHAT_MSG_WHISPER_STUB(...) end)

    It("should warn user", function(assert, next)
        CHAT_MSG_WHISPER_STUB = function(...)
            assert(printed:includes(addon.SM.WARNING_MESSAGE),
                        "Called print with warning message.",
                        "Expected warning message.")
            next()
        end
        SendChatMessage("{rt3} groupie : failing test", "WHISPER", nil, character)
    end)

    It("should allow verified whisper", function(assert, next)
        CHAT_MSG_WHISPER_STUB = function(event, message)
            assert(message == "{rt3} groupie : passing test",
                   "Received uninterrupted whisper.",
                   "Expected uninterrupted whisper.")
            next()
        end
        addon.SM:SendChatMessage("{rt3} groupie : passing test",
                                        "WHISPER", character)
    end)
end)
