local addonName, addon = ...
local List = addon.List
local SlashCmdList = SlashCmdList

local function assert(condition, success, failure)
    return condition and WrapTextInColorCode(success, addon.SM.COLOR.GREEN) or
               WrapTextInColorCode(failure, addon.SM.COLOR.RED)
end

local SPEC = {}

local printed = List:new()
hooksecurefunc(addon.SM, "print",
               function(...) printed:push(List:new{...}:join("")) end)

local CHAT_MSG_WHISPER_STUB = function(...) end
hooksecurefunc(addon.SM, "CHAT_MSG_WHISPER",
               function(...) CHAT_MSG_WHISPER_STUB(...) end)

SPEC["SecureMessaging.should warn user"] = function(next)
    CHAT_MSG_WHISPER_STUB = function(...)
        next(assert(printed:includes(addon.SM.WARNING_MESSAGE),
                    "Called print with warning message.",
                    "Expected warning message."))
    end
    SendChatMessage("{rt3} groupie : failing test", "WHISPER", nil, "Raegen")
end

SPEC["SecureMessaging.should allow verified whisper"] = function(next)
    CHAT_MSG_WHISPER_STUB = function(event, message)
        next(assert(message == "{rt3} groupie : passing test",
                    "Received uninterrupted whisper.",
                    "Expected uninterrupted whisper."))
    end
    addon.SM:SendChatMessage("{rt3} groupie : passing test", "WHISPER", "Raegen")
end

function SPEC.run()
    local allTests = List:new()
    for name, test in pairs(SPEC) do
        if name ~= "run" then allTests:push({name = name, test = test}) end
    end
    local run = function(tests, run)
        local test = tests:pop()
        if test then
            print("Running test: " .. test.name)
            return test.test(function(result)
                print(result)
                run(tests, run)
            end)
        end

        print("All tests passed.")
    end
    run(allTests, run)
end

addon.SM.SPEC = SPEC
