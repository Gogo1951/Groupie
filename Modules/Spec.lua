local MAJOR, MINOR = "Spec-1.0", 1
local Spec = LibStub:NewLibrary(MAJOR, MINOR)

if not Spec then return end -- No upgrade needed

local function createAssertHandler()
    function Assert(result, success, failure)
        return result and WrapTextInColorCode(success, "FF4CAF50") or
                   WrapTextInColorCode(failure, "FFF44336")
    end

    local assertions = {}

    return assertions, function(...)
        table.insert(assertions, Assert(...))
        return assertions[#assertions]
    end
end

function Spec:new(name, create)
    print("Testing " .. name)
    local tests = {}
    local function next(tests)
        local test = table.remove(tests)
        print("Running test: " .. test.describe)

        local assertions, assert = createAssertHandler()
        local function done()
            for i = 1, #assertions do print(assertions[i]) end

            if #tests > 0 then next(tests) end
        end
        test.test(assert, done)
    end
    local function It(describe, fn)
        table.insert(tests, {describe = describe, test = fn})
    end
    local o = {}
    function o.run() next(tests) end
    create(It)
    setmetatable(o, self)
    self.__index = self
    return o
end
