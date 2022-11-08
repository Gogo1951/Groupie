local addonName, addon = ...
local GroupieListener = addon:NewModule("GroupieListener", "AceEvent-3.0")

local locale = GetLocale()
if not addon.tableContains(addon.validLocales, locale) then
    return
end
local L = LibStub('AceLocale-3.0'):GetLocale('Groupie')
local myname = UnitName("player")
local myserver = GetRealmName()
local mylevel = UnitLevel("player")

local askForPlayerInfo = addon.askForPlayerInfo
local askForInstance = addon.askForInstance
local PROTECTED_TOKENS = addon.PROTECTED_TOKENS
local WARNING_MESSAGE = addon.WARNING_MESSAGE


--Local Function References for performance reasons
local gsub = gsub
local pairs = pairs
local strmatch = strmatch
local strsub = strsub
local time = time
local tinsert = tinsert
local next = next
local format = format


--Decide whether we can auto respond OR play a sound
function addon.CanRespondOrSound(author, order, minlevel, maxlevel)
    -------------------------
    --Dont auto respond if:--
    -------------------------

    --Its our own group
    if myname == author then return false end

    --AFK or DND
    if UnitIsAFK("player") then return false end
    if UnitIsDND("player") then return false end

    --Instance is saved or hidden
    if addon.db.global.savedInstanceInfo[order] then
        if addon.db.global.savedInstanceInfo[order][myname] then return false end
    end
    if addon.db.char.hideInstances[order] then return false end

    --Instance is out of level range
    --if not minlevel or not maxlevel then return false end --required nil check for non raid/dungeon activities
    --if (minlevel > (mylevel + addon.db.char.recommendedLevelRange)) or
    --    maxlevel < mylevel then
    --    return false
    --end

    --In a group
    if UnitInAnyGroup("player") or IsActiveBattlefieldArena() then return false end

    --In a battleground/arena queue
    for i = 1, GetMaxBattlefieldID() do
        local status = GetBattlefieldStatus(i)
        if status and status ~= "none" then return false end
    end
    return true
end

--Decide whether to auto respond
function addon.ShouldAutoRespond(author, groupType)

    local resting = IsResting()
    local responseType = addon.db.char.autoResponseOptions[groupType].responseType
    --Responses are disabled for this group type
    if responseType == 7 then return false end

    --in town options are now disabled
    if responseType == 1 or responseType == 2 or responseType == 3 then return false end

    if responseType == 4 then --Global friends
        if addon.friendList[author] then return true end
    elseif responseType == 5 then --Local friends and guild
        if addon.db.global.friends[myserver][myname][author] then return true end
        if addon.db.global.guild[myserver][myname][author] then return true end
    elseif responseType == 6 then --Local friends
        if addon.db.global.friends[myserver][myname][author] then return true end
    end
    return false
end

--Decide whether to play an alert sound
function addon.ShouldPlaySound(author, groupType)
    local resting = IsResting()
    local soundType = addon.db.char.autoResponseOptions[groupType].soundType

    --Responses are disabled for this group type
    if soundType == 9 then return false end

    --in town options are now disabled
    if soundType == 1 or soundType == 2 or soundType == 3 or soundType == 4 then return false end


    if soundType == 5 then --Global friends
        if addon.friendList[author] then return true end
    elseif soundType == 6 then --Local friends and guild
        if addon.db.global.friends[myserver][myname][author] then return true end
        if addon.db.global.guild[myserver][myname][author] then return true end
    elseif soundType == 7 then --Local friends
        if addon.db.global.friends[myserver][myname][author] then return true end
    elseif soundType == 8 then --Anyone
        return true
    end
    return false
end

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

--Check if a version of an instance is valid
local function isValidVersion(instance, size, isHeroic)
    local possibleVersions = addon.instanceVersions[instance]
    local validVersionFlag = false

    if isHeroic or size then
        for version = 1, #possibleVersions do
            if isHeroic == possibleVersions[version][2] then
                if size == possibleVersions[version][1] then
                    validVersionFlag = true
                elseif size == nil then
                    size = possibleVersions[version][1]
                    validVersionFlag = true
                end
            end
        end
    end


    return validVersionFlag, size
end

--Extract specified dungeon and version by matching each word in an LFG message to patterns in addon.groupieInstancePatterns
local function GetDungeons(messageWords)
    local instance = nil
    local isHeroic = false
    local forceSize = nil
    local lastUsedToken = ""
    for i = 1, #messageWords do
        local word = messageWords[i]
        --Look for dungeon patterns
        local lookupAttempt = addon.groupieInstancePatterns[word]
        if lookupAttempt ~= nil then
            --Handle edge cases of instance acronyms that overlap with other words people use
            --Only overwrite with instance tokens occurring later in the message if they are an edge case token
            if instance == nil or addon.tableContains(addon.edgeCasePatterns, lastUsedToken) then
                instance = lookupAttempt
                lastUsedToken = word
            end

            --Set to heroic for special case "TOGC"
            if word == "togc" then
                isHeroic = true
                if forceSize == nil then
                    forceSize = 10
                end
            end

            --Handle instances with multiple wings by checking the word to the right
            --if strmatch(instance, "Full Clear") and i < #messageWords then
            --    lookupAttempt = addon.groupieInstancePatterns[messageWords[i + 1]]
            --    if lookupAttempt ~= nil then
            --        instance = lookupAttempt
            --    end
            --end
        elseif instance == nil or addon.tableContains(addon.edgeCasePatterns, lastUsedToken) then -- We shouldn't try matching for instance+heroic+size patterns if we've already found one
            --If we couldn't recognize an instance, try removing heroic/size patterns from the start and end of the word
            for key, val in pairs(addon.groupieVersionPatterns) do
                if addon.EndsWith(word, key) then
                    lookupAttempt = addon.groupieInstancePatterns[strsub(word, 1, #word - #key)]
                    if lookupAttempt ~= nil and addon.groupieVersionPatterns[word] == nil then
                        --local validVersion, _ = isValidVersion(lookupAttempt, forceSize, isHeroic)
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
                    if lookupAttempt ~= nil and addon.groupieVersionPatterns[word] == nil then
                        --local validVersion, _ = isValidVersion(lookupAttempt, forceSize, isHeroic)
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

    --Check that the found instance version is a valid version
    local possibleVersions = addon.instanceVersions[instance]
    local validVersionFlag, forceSize = isValidVersion(instance, forceSize, isHeroic)

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
    local lootType = L["Filters"].Loot_Styles.MSOS
    for i = 1, #messageWords do
        local word = messageWords[i]

        --Look for loot type patterns
        local lookupAttempt = addon.groupieLootPatterns[word]
        if lookupAttempt ~= nil then
            --Because GDKP messages sometimes include the word carry, avoid overwriting in this case
            if lookupAttempt ~= L["Filters"].Loot_Styles.Ticket or lootType ~= L["Filters"].Loot_Styles.GDKP then
                lootType = lookupAttempt
            end
        end
    end

    return lootType
end

--Given a message passed by event handler, extract information about the party
local function ParseMessage(event, msg, author, _, channel, guid)
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
    local instanceOrder = -1
    local instanceID = -1
    local icon = "Other.tga"
    local classColor = addon.groupieSystemColor

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
                lootType = L["Filters"].Loot_Styles.Other
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
            lootType = L["Filters"].Loot_Styles.Other
            isHeroic = false
            groupSize = 5
        end
        if groupDungeon == "PVP" then -- Support for PVP tab
            lootType = L["Filters"].Loot_Styles.PVP
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
        --The event bosses don't have entries in the instance data table
        if groupDungeon == "Coren Direbrew" then
            minLevel = 70
            maxLevel = 80
        elseif groupDungeon == "Ahune" then
            minLevel = 70
            maxLevel = 80
        elseif groupDungeon == "Headless Horseman" then
            minLevel = 70
            maxLevel = 80
        elseif groupDungeon == "Apothecary Hummel" then
            minLevel = 70
            maxLevel = 80
        else
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


    local isNewListing = false
    --Create a new entry for the author if one doesnt exist
    --Used in listing board to prevent jumpy data by default
    if addon.db.global.listingTable[author] == nil or addon.db.global.listingTable[author].resultID ~= nil then
        addon.db.global.listingTable[author] = {}
        isNewListing = true
    end
    if addon.db.global.listingTable[author].createdat == nil then
        --Set the created time if it isnt already set
        addon.db.global.listingTable[author].createdat = time()
    elseif addon.db.global.listingTable[author].instanceName ~= groupDungeon then
        --Also, update the created time if the instance has changed since last posting, as this is functionally a new group
        addon.db.global.listingTable[author].createdat = time()
    end

    --Moved from Event listener to minimize API calls to only successfully parsed listings
    --and only new listings, not updated listings. Should significantly reduce the api calls here
    if addon.db.global.listingTable[author].classColor == nil then
        local locClass, engClass = GetPlayerInfoByGUID(guid)
        classColor = addon.classColors[engClass]
    else
        classColor = addon.db.global.listingTable[author].classColor
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
    addon.db.global.listingTable[author].classColor = classColor
    addon.db.global.listingTable[author].resultID = nil -- Required to prevent /4 listings from being overwritten by LFG listings

    if isNewListing and addon.LFGMode then --If the listing is new, we can autoRespond
        --Find the group type string for auto response options
        local optionsGroupType = nil
        if lootType == "PVP" then
            optionsGroupType = "PVP"
        elseif groupSize == 25 and lootType ~= "Other" then
            optionsGroupType = "25"
        elseif groupSize == 10 and lootType ~= "Other" then
            optionsGroupType = "10"
        elseif groupSize == 5 and isHeroic == true and lootType ~= "Other" then
            optionsGroupType = "5H"
        elseif groupSize == 5 and lootType ~= "Other" then
            optionsGroupType = "5"
        end

        --Remove server name from author string
        local shortAuthor = author:gsub("-.+", "")
        if optionsGroupType then
            if addon.CanRespondOrSound(shortAuthor, instanceOrder, minLevel, maxLevel) then
                if addon.ShouldAutoRespond(shortAuthor, optionsGroupType) then
                    addon.SendPlayerInfo(author, nil, nil, fullName, nil, true)
                end

                if addon.ShouldPlaySound(shortAuthor, optionsGroupType) then
                    PlaySound(addon.db.char.autoResponseOptions[optionsGroupType].alertSoundID)
                end
            end
        end
    end

    return true
end

--Handle chat events
local function GroupieEventHandlers(...)
    local event, msg, author, _, channel, _, _, _, _, _, _, _, guid = ...
    local validChannel = false
    if addon.db.char.useChannels[L["text_channels"].Guild] and event == "CHAT_MSG_GUILD" then
        validChannel = true
    elseif addon.db.char.useChannels[L["text_channels"].General] and strmatch(channel, L["text_channels"].General) then
        validChannel = true
    elseif addon.db.char.useChannels[L["text_channels"].Trade] and strmatch(channel, L["text_channels"].Trade) then
        validChannel = true
    elseif addon.db.char.useChannels[L["text_channels"].LocalDefense] and
        strmatch(channel, L["text_channels"].LocalDefense) then
        validChannel = true
    elseif addon.db.char.useChannels[L["text_channels"].LFG] and strmatch(channel, L["text_channels"].LFG) then
        validChannel = true
    elseif addon.db.char.useChannels[L["text_channels"].World] and strmatch(channel, L["text_channels"].World .. ". ") then
        validChannel = true
    end
    if validChannel then
        ParseMessage(event, msg, author, _, channel, guid)
    end
    return true
end

--This function currently does two things
--1. Provides testing functions when the player whispers commands to themselves
--2. Checks that the message hash is valid and therefore a non fake groupie message
--TODO: This should be separated into two seperate functions, and probably the hash validation should live in rightclick.lua
local function WhisperListener(_, msg, longAuthor, ...)

    local author = gsub(longAuthor, "-.*", "")

    --test phrases for debugging
    if msg == "clear" and author == myname and addon.debugMenus then
        addon.db.global.listingTable = {}
    elseif msg == "all" and author == myname and addon.debugMenus then
        addon.db.global.listingTable = {}
        local idx = 0
        for key, val in pairs(addon.groupieUnflippedDungeonPatterns) do
            local temppattern = gsub(val, " .+", "")
            ParseMessage(nil, "lfm " .. temppattern, tostring(idx), nil, nil, UnitGUID("player"))
            idx = idx + 1
        end
    elseif msg == "friends" and author == myname and addon.debugMenus then
        for k, v in pairs(addon.friendList) do
            print(k, v)
        end
    else
        --Check the hash if it is a groupie branded message
        --Unless it is the warning message itself
        if msg ~= WARNING_MESSAGE and msg ~= askForInstance and msg ~= askForPlayerInfo then
            for key, val in pairs(PROTECTED_TOKENS) do
                if strmatch(strlower(msg), val) then
                    local flag1, flag2 = false, false
                    ------------
                    --Old Hash--
                    ------------
                    --Remove the hash
                    local hashRecieved = gsub(gsub(msg, ".+ %[%#", ""), "%]", "")
                    local suffixRemoved = gsub(msg, " %[%#.+", "")
                    local hashCalculated = addon.StringHash(author .. suffixRemoved)
                    --Fake found
                    if hashCalculated ~= hashRecieved then
                        flag1 = true
                    end
                    ------------
                    --New Hash--
                    ------------
                    --Remove the hash
                    hashRecieved = strmatch(gsub(msg, "{rt3} Groupie", ""), "{.+}")
                    suffixRemoved = gsub(msg, " {rt.+", "")
                    hashCalculated = addon.RTHash(author .. suffixRemoved)
                    --Fake found
                    if hashCalculated ~= hashRecieved then
                        flag2 = true
                    end
                    if flag1 and flag2 then
                        SendChatMessage(WARNING_MESSAGE, "WHISPER", "COMMON", longAuthor)
                    end
                end
            end
        end
    end
end

-------------------
--Event Registers--
-------------------
function GroupieListener:OnEnable()
    self:RegisterEvent("CHAT_MSG_CHANNEL", GroupieEventHandlers)
    self:RegisterEvent("CHAT_MSG_GUILD", GroupieEventHandlers)
    self:RegisterEvent("CHAT_MSG_WHISPER", WhisperListener)
end
