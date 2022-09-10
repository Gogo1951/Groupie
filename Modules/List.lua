local MAJOR, MINOR = "List-1.0", 1
local List = LibStub:NewLibrary(MAJOR, MINOR)

if not List then return end -- No upgrade needed

function List:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function List:forEach(handler) for i = 1, #self do handler(self[i], i, self) end end

function List:map(handler)
    local result = List:new()
    for i = 1, #self do result[i] = handler(self[i], i, self) end
    return result
end

function List:reduce(handler, seed)
    local result = seed
    for i = 1, #self do result = handler(result, self[i], i) end
    return result
end

function List:slice(start, stop)
    local result = List:new()
    for i = start, stop do result[#result + 1] = self[i] end
    return result
end

function List:filter(handler)
    local result = List:new()
    for i = 1, #self do
        if handler(self[i], i, self) then result[#result + 1] = self[i] end
    end
    return result
end

function List:concat(list)
    local result = List:new()
    for i = 1, #self do result[#result + 1] = self[i] end
    for i = 1, #list do result[#result + 1] = list[i] end
    return result
end

function List:join(separator)
    local result = ""
    for i = 1, #self do
        result = result .. self[i]
        if i < #self then result = result .. separator end
    end
    return result
end

function List:indexOf(value)
    for i = 1, #self do if self[i] == value then return i end end
    return nil
end

function List:includes(value) return self:indexOf(value) ~= nil end

function List:push(value) self[#self + 1] = value end

function List:pop()
    local value = self[#self]
    self[#self] = nil
    return value
end

function List:splice(start, count)
    local result = List:new()
    if not start then return result end
    for i = start, start + count - 1 do
        result[#result + 1] = self[i]
        self[i] = nil
    end
    return result
end

function List:every(handler)
    for i = 1, #self do
        if not handler(self[i], i, self) then return false end
    end
    return true
end

function List:some(handler)
    for i = 1, #self do if handler(self[i], i, self) then return true end end
    return false
end
