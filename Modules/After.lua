local MAJOR, MINOR = "After-1.0", 1
local After = LibStub:NewLibrary(MAJOR, MINOR)

if not After then return end -- No upgrade needed

setmetatable(After, {
    __call = function(_, duration)
        local waitTable = {}
        local waitFrame = nil
        return {
            Do = function(func, ...)
                if type(duration) ~= "number" or type(func) ~= "function" then
                    return false
                end
                if waitFrame == nil then
                    waitFrame = CreateFrame("Frame", "WaitFrame", UIParent)
                    waitFrame:SetScript("onUpdate", function(_, elapse)
                        local count = #waitTable
                        local i = 1
                        while i <= count do
                            local waitRecord = tremove(waitTable, i)
                            local d = tremove(waitRecord, 1)
                            local f = tremove(waitRecord, 1)
                            local p = tremove(waitRecord, 1)
                            if d > elapse then
                                tinsert(waitTable, i, { d - elapse, f, p })
                                i = i + 1
                            else
                                count = count - 1
                                f(unpack(p))
                            end
                        end
                    end)
                end
                tinsert(waitTable, { duration, func, { ... } })
                return true
            end
        }
    end
})
