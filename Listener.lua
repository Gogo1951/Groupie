local addonName, addon = ...
local AceEvent = LibStub("AceEvent-3.0")
AceEvent:Embed(addon)

--Local Function References for performance reasons
local gsub = gsub
local pairs = pairs
local strmatch = strmatch
local strsub = strsub
local time = time
local tinsert = tinsert
local next = next
local format = format

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
            --Handle edge cases of instance acronyms that overlap with other words people use
            --Currently MT, OS, UP
            --Only use these as valid instance patterns if the instance is nil so far
            if instance == nil or not addon.tableContains(addon.edgeCaseInstances, lookupAttempt) then
                instance = lookupAttempt
            end

            --Set to heroic for special case "TOGC"
            if word == "togc" then
                isHeroic = true
                if forceSize == nil then
                    forceSize = 10
                end
            end

            --Handle instances with multiple wings by checking the word to the right
            if strmatch(instance, "Full Clear") and i < #messageWords then
                lookupAttempt = addon.groupieInstancePatterns[messageWords[i + 1]]
                if lookupAttempt ~= nil then
                    instance = lookupAttempt
                end
            end
        elseif instance == nil then -- We shouldn't try matching for instance+heroic+size patterns if we've already found one
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

    --Return early if PVP
    if instance == "PVP" then
        return instance, false, 5
    end

    --Handle "TOC" disambiguation
    if instance == "TOC-SPECIALCASE" then
        --If size specified, it is the raid
        if forceSize == 25 or forceSize == 10 then
            instance = "Trial of the Crusader"
            --Otherwise, assume it is the 5 man
        else
            instance = "Trial of the Champion"
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
    if addon.debugMenus then
        print(instance, isHeroic, forceSize)
    end
    return instance, isHeroic, forceSize
end

--Extract the loot system being used by the party
local function GetGroupType(messageWords)
    local lootType = "MS > OS"
    for i = 1, #messageWords do
        local word = messageWords[i]

        --Look for loot type patterns
        local lookupAttempt = addon.groupieLootPatterns[word]
        if lookupAttempt ~= nil then
            --Because GDKP messages sometimes include the word carry, avoid overwriting in this case
            if lookupAttempt ~= "Ticket" or lootType ~= "GDKP" then
                lootType = lookupAttempt
            end
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
    local minLevel = nil
    local maxLevel = nil
    local instanceOrder = nil
    local instanceID = -1
    local icon = "Other.tga"

    for i = 1, #messageWords do
        --handle cases of 'LF3M', etc by removing numbers for this part
        local word = gsub(messageWords[i], "%d", "")
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
                tinsert(rolesNeeded, 4)
            elseif patternType == 4 then --LFG
                isLFM = false
                isLFG = true
            elseif patternType == 5 then --Other Groups
                isLFM = true
                lootType = "Other"
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
        if groupDungeon == nil or strmatch(msg, "|Henchant") or strmatch(msg, "|Htrade") then
            groupDungeon = "Miscellaneous" --No dungeon Found
            lootType = "Other"
            isHeroic = false
            groupSize = 5
        end
        if groupDungeon == "PVP" then -- Support for PVP tab
            lootType = "PVP"
            isHeroic = false
            groupSize = 5
            icon = "PVP.tga"
        end
        if lootType == nil then
            lootType = GetGroupType(messageWords) --Defaults to MS>OS if not mentioned
        end
    else
        return false --This is not an LFM or LFG post
    end

    --Return false if any required information could not be found
    if isHeroic == nil or groupSize == nil then
        return false
    end

    --Trial of the crusader heroic is called Trial of the grand crusader
    if groupDungeon == "Trial of the Crusader" and isHeroic then
        groupDungeon = "Trial of the Grand Crusader"
    end

    --The full versioned instance name for use in data table
    local fullName = groupDungeon
    if groupDungeon ~= "Miscellaneous" and groupDungeon ~= "PVP" then
        if isHeroic then
            fullName = format("Heroic %s", fullName)
        end
        if #addon.instanceVersions[groupDungeon] > 1 then
            if groupSize == 10 then
                fullName = format("%s - 10", fullName)
            elseif groupSize == 25 then
                fullName = format("%s - 25", fullName)
            end
        end
        minLevel = addon.groupieInstanceData[fullName].MinLevel
        maxLevel = addon.groupieInstanceData[fullName].MaxLevel
        instanceOrder = addon.groupieInstanceData[fullName].Order
        icon = addon.groupieInstanceData[fullName].Icon
        instanceID = addon.groupieInstanceData[fullName].InstanceID
    end

    --For some reason sometimes realm name is not included
    if not strfind(author, "-") then
        author = author .. "-" .. gsub(GetRealmName(), " ", "")
    end

    --If no roles are mentioned, assume they are looking for all roles
    if next(rolesNeeded) == nil then
        rolesNeeded = { 1, 2, 3, 4 }
    end
    --If it is an LFG message, prevent filtering based on role
    if isLFG then
        rolesNeeded = { 1, 2, 3, 4 }
    end

    --Create a new entry for the author if one doesnt exist
    --Used in listing board to prevent jumpy data by default
    if addon.db.global.listingTable[author] == nil then
        addon.db.global.listingTable[author] = {}
    end
    if addon.db.global.listingTable[author].createdat == nil then
        --Set the created time if it isnt already set
        addon.db.global.listingTable[author].createdat = time()
    elseif addon.db.global.listingTable[author].instanceName ~= groupDungeon then
        --Also, update the created time if the instance has changed since last posting, as this is functionally a new group
        addon.db.global.listingTable[author].createdat = time()
    end

    --Create the listing entry
    addon.db.global.listingTable[author].isLFM = isLFM
    addon.db.global.listingTable[author].isLFG = isLFG
    addon.db.global.listingTable[author].timestamp = groupTimestamp
    addon.db.global.listingTable[author].language = groupLanguage
    addon.db.global.listingTable[author].instanceName = groupDungeon
    addon.db.global.listingTable[author].fullName = fullName
    addon.db.global.listingTable[author].isHeroic = isHeroic
    addon.db.global.listingTable[author].groupSize = groupSize
    addon.db.global.listingTable[author].lootType = lootType
    addon.db.global.listingTable[author].rolesNeeded = rolesNeeded
    addon.db.global.listingTable[author].author = author
    addon.db.global.listingTable[author].msg = msg
    addon.db.global.listingTable[author].words = messageWords
    addon.db.global.listingTable[author].minLevel = minLevel or 0
    addon.db.global.listingTable[author].maxLevel = maxLevel or 1000
    addon.db.global.listingTable[author].order = instanceOrder or -1
    addon.db.global.listingTable[author].instanceID = instanceID
    addon.db.global.listingTable[author].icon = icon
    --Collect data to debug with
    --if addon.debugMenus then
    --tinsert(addon.db.global.debugData, { msg, preprocessedStr, addon.db.global.listingTable[author] })
    --end
    return true
end

--Handle chat events
local function GroupieEventHandlers(...)
    local event, msg, author, _, channel = ...
    local validChannel = false
    if addon.db.char.useChannels["Guild"] and strmatch(channel, "Guild") then
        validChannel = true
    elseif addon.db.char.useChannels["General"] and strmatch(channel, "General") then
        validChannel = true
    elseif addon.db.char.useChannels["Trade"] and strmatch(channel, "Trade") then
        validChannel = true
    elseif addon.db.char.useChannels["LocalDefense"] and strmatch(channel, "LocalDefense") then
        validChannel = true
    elseif addon.db.char.useChannels["LookingForGroup"] and strmatch(channel, "LookingForGroup") then
        validChannel = true
    elseif addon.db.char.useChannels["5"] and strmatch(channel, "5. ") then
        validChannel = true
    end
    if validChannel then
        ParseMessage(event, msg, author, _, channel)
    end
    return true
end

addon:OnEvent("CHAT_MSG_CHANNEL", GroupieEventHandlers)
addon:OnEvent("CHAT_MSG_GUILD", GroupieEventHandlers)

-------------------------------
--DEBUG FUNCTIONS FOR TESTING--
-------------------------------

local function testfunc(_, msg, ...)
    if not addon.debugMenus then
        return
    end
    if msg == "clear" then
        addon.db.global.listingTable = {}
    elseif msg == "all" then
        addon.db.global.listingTable = {}
        local idx = 0
        for key, val in pairs(addon.groupieUnflippedDungeonPatterns) do
            local temppattern = gsub(val, " .+", "")
            ParseMessage(nil, "lfm " .. temppattern, tostring(idx), nil, nil)
            idx = idx + 1
        end
        ParseMessage(nil, "lfm togc", tostring(idx + 1), nil, nil)
        ParseMessage(nil, "lfm icc 25h", tostring(idx + 2), nil, nil)
    end
end

addon:OnEvent("CHAT_MSG_WHISPER", testfunc)
