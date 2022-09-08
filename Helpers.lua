local addonName, addon = ...
local GetTalentTabInfo = GetTalentTabInfo
local time = time
local gmatch = gmatch

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
    return gsub(strlower(gsub(gsub(msg, "%W", " "), "%s+", " ")), "ms os", "msos")
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
function addon.GenerateInstanceToggles(order, instanceType, instanceSize, showMaxLevel, configGroup)
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
        name = "|cffffd900" .. instanceType,
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
function addon.GetTimeSinceString(timestamp)
    local timediff = time() - timestamp
    local mins = floor(timediff / 60)
    local secs = timediff - (60 * mins)
    return format("%02dm %02ds", mins, secs)
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

--Return a table of instance IDs the player is saved to
function addon.GetSavedInstances()
    local t = {}
    for i = 1, GetNumSavedInstances() do
        local name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers,
        difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i)
        if locked then
            tinsert(t, { id, difficulty, maxPlayers })
        end
    end
    return t
end
