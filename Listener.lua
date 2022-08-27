local addonName, addon = ...
local AceEvent = LibStub("AceEvent-3.0")
AceEvent:Embed(addon)
--Extract a specified language from an LFG message, if it exists
local function GetLanguage(messageWords)
    local language = nil
    for i = 1, #messageWords do
        local word = messageWords[i]

        --Look for loot type patterns
        local lookupAttempt = addon.groupieLanguagePatterns[word]
        if lookupAttempt ~= nil then
            language = lookupAttempt
        end
    end

    return language
end

--Extract specified dungeon and version by matching each word in an LFG message to patterns in addon.groupieInstancePatterns
local function GetDungeons(messageWords)
    local instance = nil
    local isHeroic = false
    local forceSize = nil
    for i = 1, #messageWords do
        local word = messageWords[i]

        --Look for dungeon patterns
        local lookupAttempt = addon.groupieInstancePatterns[word]
        if lookupAttempt ~= nil then
            --Handle the fact that people use MT to mean both mana-tombs and main-tank
            --Assume that if we find MT and the instance is already set, it means tank
            if lookupAttempt ~= "Mana-Tombs" or instance == nil then
                instance = lookupAttempt
            end

            --Handle instances with multiple wings by checking the word to the right
            if strmatch(instance, "Full Clear") and i < #messageWords then
                lookupAttempt = addon.groupieInstancePatterns[messageWords[i + 1]]
                if lookupAttempt ~= nil then
                    instance = lookupAttempt
                end
            end
        else
            --If we couldn't recognize an instance, try removing heroic/size patterns from the start and end of the word
            for key, val in pairs(addon.groupieVersionPatterns) do
                if addon.EndsWith(word, key) then
                    lookupAttempt = addon.groupieInstancePatterns[strsub(word, 1, #word - #key)]
                    if lookupAttempt ~= nil then
                        instance = lookupAttempt
                        if val == 0 then
                            isHeroic = true
                        elseif val == 1 then
                            forceSize = 10
                        elseif val == 2 then
                            forceSize = 25
                        elseif val == 3 then
                            isHeroic = true
                            forceSize = 10
                        elseif val == 4 then
                            isHeroic = true
                            forceSize = 25
                        end
                    end
                end
                if addon.StartsWith(word, key) then
                    lookupAttempt = addon.groupieInstancePatterns[strsub(word, 1 + #key, #word)]
                    if lookupAttempt ~= nil then
                        instance = lookupAttempt
                        if val == 0 then
                            isHeroic = true
                        elseif val == 1 then
                            forceSize = 10
                        elseif val == 2 then
                            forceSize = 25
                        elseif val == 3 then
                            isHeroic = true
                            forceSize = 10
                        elseif val == 4 then
                            isHeroic = true
                            forceSize = 25
                        end
                    end
                end
            end
        end

        --Look for heroic/size patterns
        lookupAttempt = addon.groupieVersionPatterns[word]
        if lookupAttempt ~= nil then
            if lookupAttempt == 0 then
                isHeroic = true
            elseif lookupAttempt == 1 then
                forceSize = 10
            elseif lookupAttempt == 2 then
                forceSize = 25
            elseif lookupAttempt == 3 then
                isHeroic = true
                forceSize = 10
            elseif lookupAttempt == 4 then
                isHeroic = true
                forceSize = 25
            end
        end
    end

    if instance == nil then
        return nil, nil, nil
    end
    local possibleVersions = addon.instanceVersions[instance]
    local validVersionFlag = false
    --Check that the found instance version is a valid version
    if isHeroic or forceSize then
        for version = 1, #possibleVersions do
            if isHeroic == possibleVersions[version][2] then
                if forceSize == possibleVersions[version][1] then
                    validVersionFlag = true
                elseif forceSize == nil then
                    forceSize = possibleVersions[version][1]
                    validVersionFlag = true
                end
            end
        end
    end

    --If the instance version is invalid, default to lowest size and normal mode
    if not validVersionFlag then
        forceSize = possibleVersions[1][1]
        isHeroic = possibleVersions[1][2]
    end

    return instance, isHeroic, forceSize
end

--Extract the loot system being used by the party
local function GetGroupType(messageWords)
    local lootType = "MS>OS"
    for i = 1, #messageWords do
        local word = messageWords[i]

        --Look for loot type patterns
        local lookupAttempt = addon.groupieLootPatterns[word]
        if lookupAttempt ~= nil then
            lootType = lookupAttempt
        end
    end

    return lootType
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

    --print(isLFM or isLFG)
    if isLFM or isLFG then
        groupLanguage = GetLanguage(messageWords) --This can safely be nil
        groupDungeon, isHeroic, groupSize = GetDungeons(messageWords)
        if groupDungeon == nil then
            return false --No dungeon Found
        end
        lootType = GetGroupType(messageWords) --Defaults to MS>OS if not mentioned
    else
        return false --This is not an LFM or LFG post
    end

    --Return false if any required information could not be found
    if isHeroic == nil or groupSize == nil or lootType == nil then
        return false
    end

    --The full versioned instance name for use in data table
    local fullName = groupDungeon
    if isHeroic then
        fullName = "Heroic " .. fullName
    end
    if #addon.instanceVersions[groupDungeon] > 1 then
        if groupSize == 10 then
            fullName = fullName .. " - 10"
        elseif groupSize == 25 then
            fullName = fullName .. " - 25"
        end
    end

    --Create the listing entry
    addon.groupieListingTable[author] = {}
    addon.groupieListingTable[author].isLFM = isLFM
    addon.groupieListingTable[author].isLFG = isLFG
    addon.groupieListingTable[author].instanceID = addon.groupieInstanceData[fullName].instanceID
    addon.groupieListingTable[author].MinLevel = addon.groupieInstanceData[fullName].MinLevel
    addon.groupieListingTable[author].MaxLevel = addon.groupieInstanceData[fullName].MaxLevel
    addon.groupieListingTable[author].timestamp = groupTimestamp
    addon.groupieListingTable[author].language = groupLanguage
    addon.groupieListingTable[author].instanceName = groupDungeon
    addon.groupieListingTable[author].fullName = fullName
    addon.groupieListingTable[author].isHeroic = isHeroic
    addon.groupieListingTable[author].groupSize = groupSize
    addon.groupieListingTable[author].lootType = lootType
    addon.groupieListingTable[author].rolesNeeded = rolesNeeded
    --Collect data to debug with
    print(groupDungeon)
    print(isHeroic)
    print(groupSize)

    if addon.debugMenus then
        tinsert(groupielfg_global.debugData, { msg, preprocessedStr, addon.groupieListingTable[author] })
    end
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
    return true
end

addon:RegisterEvent("CHAT_MSG_CHANNEL", GroupieEventHandlers)
addon:RegisterEvent("CHAT_MSG_GUILD", GroupieEventHandlers)
