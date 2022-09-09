local MAJOR, MINOR = "Events-1.0", 1
local Events = LibStub:NewLibrary(MAJOR, MINOR)

if not Events then return end

Events.embeds = Events.embeds or {} -- what objects embed this lib

--------------------------------------------------------------------------
-- Event:new
--
--   Subscribe         - main subscription factory
--   function Subscribe(Trigger)
--      // subscribe to the event dispatcher, for example:
--      addon:RegisterEvent("SOME_EVENT", Trigger);
--
--      return function TeardownLogic()
--          // handles unsubscribing from the event dispatcher, for examaple:
--          addon:UnregisterEvent("SOME_EVENT")
--      end
--   end
local Event = {};
function Event:new(Subscribe)
    local o = {}
    local handlers = {}

    function handlers:Call(...)
        for i = 1, table.getn(handlers) do
            handlers[i](...)
        end
    end
    function handlers:IndexOf(handler)
        for i = 1, table.getn(handlers) do
            if handlers[i] == handler then return i end
        end
        return nil
    end

    local function Trigger(...)
        handlers:Call(...)
    end

    local teardown = nil;

    function o:Unsubscribe()
        if not teardown then
            return error("Event already unsubscribed.");
        end
        teardown();
        teardown = nil;
    end

    function o:Subscribe()
        teardown = teardown or Subscribe(Trigger);
    end

    function o:Handle(handler)
        if (handlers:IndexOf(handler)) then
            return error(
                "You're trying to register a handler that's already registered, which would cause it to be called twice every time the event is triggered."
                .." If this is intentional, Event:Handle(function(...) ##YOUR_HANDLER##(...) end) will achieve this."
            );
        end
        table.insert(handlers, handler)

        return function()
            table.remove(handlers, handlers:IndexOf(handler))
        end
    end

    setmetatable(o, self)
    self.__index = self
    o:Subscribe();
    return o
end

local EventProvider = {}
function EventProvider:new(o)
    local events = {}
    o = o or {}

    function o:OnEvent(event, handler)
        if not events[event] then
            events[event] = Event:new(function(trigger)
                self:RegisterEvent(event, trigger);
                return function()
                    self:UnregisterEvent(event);
                end
            end);
        end
        return events[event]:Handle(handler);
    end

    setmetatable(o, self)
    self.__index = self
    return o
end

function Events:Embed(target)
	self.embeds[target] = true
	return EventProvider:new(target)
end

for target, v in pairs(Events.embeds) do
	Events:Embed(target)
end
