local addonName, addon = ...
local GetTalentTabInfo = GetTalentTabInfo
local time             = time
local gmatch           = gmatch
local L                = LibStub('AceLocale-3.0'):GetLocale('Groupie')

--Return the primary talent spec for either main or dual specialization
function addon.GetSpecByGroupNum(groupnum)
    local maxTalentsSpent = -1
    local maxTalentSpec = nil
    for specTab = 1, 3 do
        local specName, id, pointsSpent = GetTalentTabInfo(specTab, false, false, groupnum)
        if pointsSpent > maxTalentsSpent then
            maxTalentsSpent = pointsSpent
            maxTalentSpec = specName
        end
    end
    return maxTalentSpec, maxTalentsSpent
end

--Find the currently active spec group by comparing its talents to tab 1 and 2
function addon.GetActiveSpecGroup()
    local equaltab1 = true
    local equaltab2 = true
    for specTab = 1, 3 do
        local _, _, activePointsSpent = GetTalentTabInfo(specTab, false, false)
        local _, _, tab1PointsSpent = GetTalentTabInfo(specTab, false, false, 1)
        local _, _, tab2PointsSpent = GetTalentTabInfo(specTab, false, false, 2)
        if activePointsSpent ~= tab1PointsSpent then
            equaltab1 = false
        end
        if activePointsSpent ~= tab2PointsSpent then
            equaltab2 = false
        end
    end
    if equaltab1 then
        return 1
    elseif equaltab2 then
        return 2
    end
end

--Return boolean whether the table contains a value
function addon.tableContains(table, val)
    for i = 1, #table do
        if table[i] == val then
            return true
        end
    end
    return false
end

--Return a table by splitting a string at specified delimiter
function addon.GroupieSplit(inputstr, delimiter)
    if delimiter == nil then
        delimiter = "%s"
    end
    local t = {}
    for str in gmatch(inputstr, "([^" .. delimiter .. "]+)") do
        if tContains(t, str) == false then
            table.insert(t, str)
        end
    end
    return t
end

--Replace all characters specified in delimiters with a space
function addon.ReplaceDelimiters(msg, delimiters)
    for key, val in pairs(delimiters) do
        msg = string.gsub(msg, val, " ")
    end
    return msg
end

--Replace all non alphanumeric characters with a space, trim excess spaces, and convert to all lower case
function addon.Preprocess(msg)
    local gsub = gsub
    --Remove color escape sequences
    --lua doesnt have regex quantifiers :)
    msg = gsub(msg, "%|c[a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9]", "")
    msg = gsub(msg, "%|r", "")
    --Replace achievments with their text for data processing purposes
    local achievelink = strmatch(msg, "%|Hachievement:.+%|h")
    if achievelink then
        local achieveID = gsub(gsub(achievelink, "%|Hachievement:", ""), ":.+", "")
        local achieveID, name = GetAchievementInfo(tonumber(achieveID))
        msg = gsub(msg, "%|Hachievement:.+%|h", name)
    end
    --General preprocessing
    msg = strlower(gsub(gsub(msg, "%W", " "), "%s+", " "))
    --Multiword patterns need to be simplified
    msg = gsub(gsub(msg, "for the horde", "fth"), "for the alliance", "fta")
    msg = gsub(msg, "black temple", "blacktemple")
    msg = gsub(msg, "ms os", "msos")

    return msg
end

--Reverse a table by creating a new one
--Values from original table are split on spaces, and added to new as
--new["value"] = "key"
function addon.TableFlip(table)
    local result = {}
    for key, val in pairs(table) do
        local patterns = addon.GroupieSplit(val)
        for i = 1, #patterns do
            result[patterns[i]] = key
            --print("[" .. patterns[i] .. "] = " .. key)
        end
    end
    return result
end

--Check if a string starts with a given pattern
function addon.StartsWith(str, pattern)
    return str:sub(1, #pattern) == pattern
end

--Check if a string ends with a given pattern
function addon.EndsWith(str, pattern)
    return pattern == "" or str:sub(- #pattern) == pattern
end

--Generate toggles for all instances of a specified type
function addon.GenerateInstanceToggles(order, instanceType, showMaxLevel, configGroup)
    local initorder = order
    addon.options.args[configGroup].args[tostring(initorder) .. "headerspacer"] = {
        type = "description",
        name = " ",
        width = "full",
        order = initorder
    }
    initorder = initorder + 1
    addon.options.args[configGroup].args[tostring(initorder) .. "header"] = {
        type = "description",
        name = "|cff" .. addon.groupieSystemColor .. instanceType,
        width = "full",
        fontSize = "medium",
        order = initorder
    }
    initorder = initorder + 1

    for _, key in ipairs(addon.instanceOrders) do
        if addon.instanceConfigData[key].InstanceType == instanceType then

            local nameStr = ""
            if showMaxLevel then
                nameStr = format("%s | %d-%d", addon.instanceConfigData[key].Name,
                    addon.instanceConfigData[key].MinLevel, addon.instanceConfigData[key].MaxLevel,
                    addon.instanceConfigData[key].GroupSize)
            else
                nameStr = format("%s | %d", addon.instanceConfigData[key].Name,
                    addon.instanceConfigData[key].MinLevel, addon.instanceConfigData[key].GroupSize)
            end
            addon.options.args[configGroup].args[addon.instanceConfigData[key].Name] = {
                type = "toggle",
                name = nameStr,
                order = initorder,
                width = "full",
                get = function(info) return not addon.db.char.hideInstances[key] end,
                set = function(info, val)
                    addon.db.char.hideInstances[key] = not val
                end,
            }
            initorder = initorder + 1
        end
    end
end

--Remove expired listings from the listing table
function addon.ExpireListings()
    --Save 20 mins of data for everyone
    --Filter this based on their settings in filterListings in core.lua
    local expirytimediff = 1200
    for key, val in pairs(addon.db.global.listingTable) do
        if time() - val.timestamp > expirytimediff then
            addon.db.global.listingTable[key] = nil
        end
    end
end

--Convert a timestamp into a XXMin:XXSec string
function addon.GetTimeSinceString(timestamp, displayLen)
    local timediff = abs(time() - timestamp)
    if displayLen == 4 then
        local days = floor(timediff / 86400)
        local hours = floor(mod(timediff, 86400) / 3600)
        local mins = floor(mod(timediff, 3600) / 60)
        return format("%02dd %02dh %02dm", days, hours, mins)
    elseif displayLen == 3 then
        local hours = floor(timediff / 3600)
        local mins = floor(mod(timediff, 3600) / 60)
        local secs = floor(mod(timediff, 60))
        return format("%02dh %02dm %02ds", hours, mins, secs)
    elseif displayLen == 2 then
        local mins = floor(timediff / 60)
        local secs = floor(mod(timediff, 60))
        return format("%02dm %02ds", mins, secs)
    else
        local secs = floor(timediff / 60)
        return format("%02ds", secs)
    end
end

--Convert keyword blacklist into a string
function addon.BlackListToStr(blacklistStr)
    local out = ""
    for k, word in pairs(blacklistStr) do
        out = out .. word .. ","
    end
    return strsub(out, 1, -2)
end

--Convert keyword blacklist into a table
function addon.BlacklistToTable(blacklistStr)
    if blacklistStr == nil or blacklistStr == "" then
        return {}
    end
    local delimiter = ","
    local t = {}
    blacklistStr = strlower(gsub(gsub(blacklistStr, "[,%s]+$", ""), "^[%s,]+", ""))
    for str in string.gmatch(blacklistStr, "([^" .. delimiter .. "]+)") do
        str = gsub(gsub(str, "%s+$", ""), "^%s+", "")
        if tContains(t, str) == false then
            table.insert(t, str)
        end
    end
    return t
end

--Credit Wowpedia for code snippet below
--https://wowpedia.fandom.com/wiki/RunSlashCmd
local _G = _G
function addon.RunSlashCmd(cmd)
    local slash, rest = cmd:match("^(%S+)%s*(.-)$")
    for name, func in pairs(SlashCmdList) do
        local i, slashCmd = 1
        repeat
            slashCmd, i = _G["SLASH_" .. name .. i], i + 1
            if slashCmd == slash then
                return true, func(rest)
            end
        until not slashCmd
    end
    -- Okay, so it's not a slash command. It may also be an emote.
    local i = 1
    while _G["EMOTE" .. i .. "_TOKEN"] do
        local j, cn = 2, _G["EMOTE" .. i .. "_CMD1"]
        while cn do
            if cn == slash then
                return true, DoEmote(_G["EMOTE" .. i .. "_TOKEN"], rest);
            end
            j, cn = j + 1, _G["EMOTE" .. i .. "_CMD" .. j]
        end
        i = i + 1
    end
end

--Expire out of date lockouts
function addon.ExpireSavedInstances()
    local now = time()
    for order, val in pairs(addon.db.global.savedInstanceInfo) do
        for player, lockout in pairs(val) do
            if lockout.resetTime < now then
                addon.db.global.savedInstanceInfo[order][player] = nil
            end
        end
    end
end

--Update a character's saved instances
--Stored in a double nested table with form:
--savedInstanceInfo[instanceOrder][playerName]
function addon.UpdateSavedInstances()
    local playerName = UnitName("player")
    local locClass, engClass = UnitClass("player")
    local locale = GetLocale()
    if addon.db.global.savedInstanceLogs[locale] == nil then
        addon.db.global.savedInstanceLogs[locale] = {}
    end

    for i = 1, GetNumSavedInstances() do
        local name, _, reset, _, locked, _, _, _, maxPlayers, difficultyName = GetSavedInstanceInfo(i)
        --Log all saved instances - for localization
        addon.db.global.savedInstanceLogs[locale][name] = true
        --Preprocess name returned by GetSavedInstanceInfo
        local savedname = strlower(gsub(gsub(name, "%W", ""), "%s+", " "))
        if locked and (reset > 0) then --check that the lockout is active
            for key, val in pairs(addon.groupieInstanceData) do
                local isHeroic, shouldBeHeroic = false, false
                --Preprocess our name from groupieInstanceData
                local diffIndependent = gsub(gsub(key, " %- .+", ""), "Heroic ", "")
                --Get a shortened localized name
                local shortname = L["ShortLocalizedInstances"][diffIndependent]
                --If this is an instance we have a localized name to compare the saved name to
                if shortname ~= nil then
                    local ourname = strlower(gsub(gsub(shortname, "%W", ""), "%s+", " "))
                    --Will probably end up with more funky edge cases here
                    if strfind(savedname, ourname) then --Check that the name matches
                        if strfind(difficultyName, "Heroic") then
                            isHeroic = true
                        end
                        if strfind(key, "Heroic") then
                            shouldBeHeroic = true
                        end
                        --Check that we've found the correct difficulty and size, then use this order
                        if isHeroic == shouldBeHeroic and maxPlayers == val.GroupSize then
                            if not addon.db.global.savedInstanceInfo[val.Order] then
                                addon.db.global.savedInstanceInfo[val.Order] = {}
                            end
                            addon.db.global.savedInstanceInfo[val.Order][playerName] = {
                                characterName = playerName,
                                classColor = addon.classColors[engClass],
                                instance = key,
                                isHeroic = isHeroic,
                                groupSize = maxPlayers,
                                resetTime = reset + time()
                            }
                        end
                    end
                end
            end
        end
    end

    addon.ExpireSavedInstances()
    --Inject test data for instance filtering/minimap based on saved instances
    --[[
    addon.db.global.savedInstanceInfo[2330] = {}
    addon.db.global.savedInstanceInfo[2330][UnitName("player")] = {
        characterName = "Cooltestguy",
        classColor = addon.classColors[engClass],
        instance = "Zul'Aman",
        isHeroic = false,
        groupSize = 10,
        resetTime = 41595 + time()
    }
    addon.db.global.savedInstanceInfo[2160] = {}
    addon.db.global.savedInstanceInfo[2160][UnitName("player")] = {
        characterName = "Cooltestguy",
        classColor = addon.classColors[engClass],
        instance = "Coilfang: The Underbog",
        isHeroic = true,
        groupSize = 5,
        resetTime = 41595 + time()
    }
    addon.db.global.savedInstanceInfo[2370] = {}
    addon.db.global.savedInstanceInfo[2370][UnitName("player")] = {
        characterName = "Cooltestguy",
        classColor = addon.classColors[engClass],
        instance = "Tempest Keep",
        isHeroic = false,
        groupSize = 25,
        resetTime = 386957 + time()
    }
    addon.db.global.savedInstanceInfo[2330]["OtherGuy"] = {
        characterName = "OtherGuy",
        classColor = addon.classColors["DRUID"],
        instance = "Zul'Aman",
        isHeroic = false,
        groupSize = 10,
        resetTime = 41595 + time()
    }
    addon.db.global.savedInstanceInfo[2330]["FunnyGuy"] = {
        characterName = "FunnyGuy",
        classColor = addon.classColors["HUNTER"],
        instance = "Zul'Aman",
        isHeroic = false,
        groupSize = 10,
        resetTime = 41595 + time()
    }
    addon.db.global.savedInstanceInfo[2390] = {}
    addon.db.global.savedInstanceInfo[2390]["OtherGuy"] = {
        characterName = "OtherGuy",
        classColor = addon.classColors["DEATHKNIGHT"],
        instance = "Black Temple",
        isHeroic = false,
        groupSize = 25,
        resetTime = 386957 + time()
    }
    --]]
end

--Return the 4-character suffix of a hash for a given string input
--From https://wowwiki-archive.fandom.com/wiki/USERAPI_StringHash
function addon.StringHash(text)
    local counter = 1
    local len = string.len(text)
    for i = 1, len, 3 do
        counter = math.fmod(counter * 8161, 4294967279) + -- 2^32 - 17: Prime!
            (string.byte(text, i) * 16776193) +
            ((string.byte(text, i + 1) or (len - i + 256)) * 8372226) +
            ((string.byte(text, i + 2) or (len - i + 256)) * 3932164)
    end
    local numhash = math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
    return strsub(format("%x", numhash), -4)
end
