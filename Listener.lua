local addonName, addon = ...

--Extract a specified language from an LFG message, if it exists
local function GetLanguage(msg)

end

--Extract specified dungeon by matching each word in an LFG message to patterns in addon.groupieInstancePatterns
local function GetDungeons(msg)

end

--Extract whether a party is for heroic or normal, and what raid size it is
local function GetInstanceVersion(msg, skipHeroic)

end

--Extract the loot system being used by the party
local function GetGroupType(msg)

end

--Determine whether a message is an LFG or LFM post
local function IsLFGPost(msg)

end

--Given a message passed by event handler, extract information about the party
local function ParseMessage(msg)
    local preprocessedStr = strlower(msg)
    preprocessedStr = addon.ReplaceDelimiters(msg, " -:.?!,")
    local messageWords = addon.GroupieSplit(preprocessedStr)
    local isLFG = false
    local isLFM = false
    local rolesNeeded = {}
    local groupLanguage = nil
    local groupTimestamp = time()
    local groupDungeon = nil
    local skipHeroic = false
    local isHeroic = nil
    local groupSize = nil
    local lootType = nil

    for key, val in pairs(messageWords) do
        if addon.groupieLFPatterns[key] ~= nil then
            if val == 0 then --Generic LFM
                isLFM = true
                isLFG = false
            elseif val == 1 then --Mentions tank
                tinsert(rolesNeeded, 1)
            elseif val == 2 then --Mentions healer
                tinsert(rolesNeeded, 2)
            elseif val == 3 then --Mentions DPS
                tinsert(rolesNeeded, 3)
            elseif val == 4 then --LFG
                isLFM = false
                isLFG = true
            elseif val == 5 then --Boost run
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
        groupLanguage = GetLanguage(msg) --This can safely be nil
        groupDungeon, skipHeroic = GetDungeons(msg)
        --TODO: Get instance level range and ID from table
        if skipHeroic then
            isHeroic = true
        end
        if groupDungeon == nil then
            return false --No dungeon Found
        end
        isHeroic, groupSize = GetInstanceVersion(msg, skipHeroic) --Defaults to smallest size, normal mode if not mentioned
        if lootType == nil then
            lootType = GetGroupType(msg) --Defaults to MS>OS if not mentioned
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
