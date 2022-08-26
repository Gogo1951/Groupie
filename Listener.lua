local addonName, addon = ...
local AceEvent = LibStub("AceEvent-3.0")
AceEvent:Embed(addon)
--Extract a specified language from an LFG message, if it exists
local function GetLanguage(messageWords)

end

--Extract specified dungeon and version by matching each word in an LFG message to patterns in addon.groupieInstancePatterns
local function GetDungeons(messageWords)
    for word = 1, #messageWords do

    end
end

--Extract the loot system being used by the party
local function GetGroupType(messageWords)

end

--Given a message passed by event handler, extract information about the party
local function ParseMessage(event, msg, author, _, channel)
    local preprocessedStr = addon.Preprocess(msg)
    local messageWords = addon.GroupieSplit(preprocessedStr)
    local isLFG = false
    local isLFM = false
    local rolesNeeded = {}
    local groupLanguage = nil
    local groupTimestamp = time()
    local groupDungeon = nil
    local isHeroic = nil
    local groupSize = nil
    local lootType = nil

    for i = 1, #messageWords do
        --handle cases of 'LF3M', etc by removing numbers for this part
        local word = string.gsub(messageWords[i], "%d", "")
        local patternType = addon.groupieLFPatterns[word]
        if patternType ~= nil then
            if patternType == 0 then --Generic LFM
                isLFM = true
                isLFG = false
            elseif patternType == 1 then --Mentions tank
                tinsert(rolesNeeded, 1)
            elseif patternType == 2 then --Mentions healer
                tinsert(rolesNeeded, 2)
            elseif patternType == 3 then --Mentions DPS
                tinsert(rolesNeeded, 3)
            elseif patternType == 4 then --LFG
                isLFM = false
                isLFG = true
            elseif patternType == 5 then --Boost run
                isLFM = true
                lootType = "boost"
            end
            --If a role was mentioned but not LFG OR LFM, assume it is LFM
            if not isLFM and not isLFG and next(rolesNeeded) ~= nil then
                isLFM = true
                isLFG = false
            end
        end
    end

    if isLFM or isLFG then
        groupLanguage = GetLanguage(messageWords) --This can safely be nil
        groupDungeon, isHeroic, groupSize = GetDungeons(messageWords)
        --TODO: Get instance level range and ID from table
        if groupDungeon == nil then
            return false --No dungeon Found
        end
        if lootType == nil then
            lootType = GetGroupType(messageWords) --Defaults to MS>OS if not mentioned
        end
    else
        return false --This is not an LFM or LFG post
    end

    --Return false if any required information could not be found
    if isHeroic == nil or groupSize == nil or lootType == nil then
        return false
    end

    --TODO: return an object containing all the information about the group listing
    return true
end

--Handle chat events
local function GroupieEventHandlers(...)
    local event, msg, author, _, channel = ...
    local validChannel = false
    if groupielfg_db.useChannels["Guild"] and strmatch(channel, "Guild") then
        validChannel = true
    elseif groupielfg_db.useChannels["General"] and strmatch(channel, "General") then
        validChannel = true
    elseif groupielfg_db.useChannels["Trade"] and strmatch(channel, "Trade") then
        validChannel = true
    elseif groupielfg_db.useChannels["LocalDefense"] and strmatch(channel, "LocalDefense") then
        validChannel = true
    elseif groupielfg_db.useChannels["LookingForGroup"] and strmatch(channel, "LookingForGroup") then
        validChannel = true
    elseif groupielfg_db.useChannels["5"] and strmatch(channel, "5. ") then
        validChannel = true
    end
    if validChannel then
        ParseMessage(event, msg, author, _, channel)
    end
end

addon:RegisterEvent("CHAT_MSG_CHANNEL", GroupieEventHandlers)
addon:RegisterEvent("CHAT_MSG_GUILD", GroupieEventHandlers)
