local addonName, addon = ...
local GetTalentTabInfo = GetTalentTabInfo
local time             = time
local gmatch           = gmatch
local L                = LibStub('AceLocale-3.0'):GetLocale('Groupie')
local LGS              = LibStub("LibGearScore.1000", true)
local CI               = LibStub("LibClassicInspector")
local myname           = UnitName("player")

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

--return a string talent summary of the unit's talent tabs
function addon.TalentSummary(unit)
    local result = ""
    local maxTalentsSpent = -1
    local maxTalentSpec = ""
    local talentsum = 0
    NotifyInspect(unit)
    for i = 1, 3 do
        local name, _, pointsSpent = GetTalentTabInfo(i, true)
        talentsum = talentsum + pointsSpent

        if pointsSpent > maxTalentsSpent then
            maxTalentSpec = name
            maxTalentsSpent = pointsSpent
        end
        result = result .. tostring(pointsSpent) .. "/"
    end
    result = maxTalentSpec .. " : " .. result
    if talentsum < UnitLevel(unit) - 9 then
        result = result .. "\nUNSPENT TALENT POINTS"
    end
    return result
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
    --Prevent this quest from registering as Magister's Terrace run.
    --Probably best to do it this way for now, since we don't want to just count all
    --messages which link a quest as non dungeon runs
    msg = gsub(msg, "magister keldonus", "keldonus")

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

--Generate toggles for including friends/ignores from a certain character
function addon.GenerateFriendToggles(order, myserver, configGroup)
    local initorder = order
    --create tables for the current server if needed
    if addon.db.global.friends[myserver] == nil then
        addon.db.global.friends[myserver] = {}
    end
    if addon.db.global.ignores[myserver] == nil then
        addon.db.global.ignores[myserver] = {}
    end
    if addon.db.global.guilds[myserver] == nil then
        addon.db.global.guilds[myserver] = {}
    end
    if addon.db.global.groupieFriends[myserver] == nil then
        addon.db.global.groupieFriends[myserver] = {}
    end
    if addon.db.global.groupieIgnores[myserver] == nil then
        addon.db.global.groupieIgnores[myserver] = {}
    end
    if addon.db.global.friendnotes[myserver] == nil then
        addon.db.global.friendnotes[myserver] = {}
    end
    if addon.db.global.ignorenotes[myserver] == nil then
        addon.db.global.ignorenotes[myserver] = {}
    end
    if addon.db.global.hiddenFriendLists[myserver] == nil then
        addon.db.global.hiddenFriendLists[myserver] = {}
    end
    if addon.db.global.hiddenGuilds[myserver] == nil then
        addon.db.global.hiddenGuilds[myserver] = {}
    end

    for character, list in pairs(addon.db.global.friends[myserver]) do
        local nameStr = ""
        addon.options.args[configGroup].args[character .. "toggle"] = {
            type = "toggle",
            name = character .. "-" .. myserver,
            order = initorder,
            width = "full",
            get = function(info) return not addon.db.global.hiddenFriendLists[myserver][character] end,
            set = function(info, val)
                addon.db.global.hiddenFriendLists[myserver][character] = not val
                addon.UpdateFriends()
            end,
        }
        initorder = initorder + 1
    end
end

--Generate toggles for including friends/ignores from a certain character
function addon.GenerateGuildToggles(order, myserver, configGroup)
    local initorder = order
    --create tables for the current server if needed
    if addon.db.global.friends[myserver] == nil then
        addon.db.global.friends[myserver] = {}
    end
    if addon.db.global.ignores[myserver] == nil then
        addon.db.global.ignores[myserver] = {}
    end
    if addon.db.global.guilds[myserver] == nil then
        addon.db.global.guilds[myserver] = {}
    end
    if addon.db.global.groupieFriends[myserver] == nil then
        addon.db.global.groupieFriends[myserver] = {}
    end
    if addon.db.global.groupieIgnores[myserver] == nil then
        addon.db.global.groupieIgnores[myserver] = {}
    end
    if addon.db.global.friendnotes[myserver] == nil then
        addon.db.global.friendnotes[myserver] = {}
    end
    if addon.db.global.ignorenotes[myserver] == nil then
        addon.db.global.ignorenotes[myserver] = {}
    end
    if addon.db.global.hiddenFriendLists[myserver] == nil then
        addon.db.global.hiddenFriendLists[myserver] = {}
    end
    if addon.db.global.hiddenGuilds[myserver] == nil then
        addon.db.global.hiddenGuilds[myserver] = {}
    end

    for guild, list in pairs(addon.db.global.guilds[myserver]) do
        local nameStr = list["__NAME__"]
        if nameStr ~= nil then
            addon.options.args[configGroup].args[nameStr .. "toggle"] = {
                type = "toggle",
                name = "<" .. nameStr .. "> of " .. myserver,
                order = initorder,
                width = "full",
                get = function(info) return not addon.db.global.hiddenGuilds[myserver][nameStr] end,
                set = function(info, val)
                    addon.db.global.hiddenGuilds[myserver][nameStr] = not val
                    addon.UpdateFriends()
                end,
            }
            initorder = initorder + 1
        end
    end
end

--Generate dropdowns for all auto response/sound alert options
function addon.GenerateAutoResponseOptions(order, groupTypeTitle, groupTypeKey, configGroup)
    local initorder = order
    --spacer
    addon.options.args[configGroup].args[tostring(initorder) .. "headerspacer"] = {
        type = "description",
        name = " ",
        width = "full",
        order = initorder
    }
    initorder = initorder + 1
    --Group Type Title
    addon.options.args[configGroup].args[tostring(initorder) .. "header"] = {
        type = "description",
        name = "|cff" ..
            addon.groupieSystemColor .. "When a " .. groupTypeTitle ..
            " Group that Matches Your Filters is Discovered...",
        width = "full",
        fontSize = "medium",
        order = initorder
    }
    initorder = initorder + 1
    --spacer
    addon.options.args[configGroup].args[tostring(initorder) .. "headerspacer"] = {
        type = "description",
        name = " ",
        width = "full",
        order = initorder
    }
    initorder = initorder + 1

    --indent spacer
    addon.options.args[configGroup].args[tostring(initorder) .. "indentspacer"] = {
        type = "description",
        name = " ",
        width = 0.2,
        order = initorder
    }
    initorder = initorder + 1
    --Auto response dropdown
    addon.options.args[configGroup].args[groupTypeTitle .. "responsedropdown"] = {
        type = "select",
        style = "dropdown",
        name = "",
        width = 1.8,
        order = initorder,
        values = {
            --[1] = "Respond to Global Friends, When in in Town",
            --[2] = "Respond to Local Friends & Guildies, When in in Town",
            --[3] = "Respond to Local Friends, When in in Town",
            [4] = "Respond to Global Friends",
            [5] = "Respond to Local Friends & Guildies",
            [6] = "Respond to Local Friends",
            [7] = "Disable Auto Responses for " .. groupTypeTitle .. " Groups",
        },
        get = function(info) return addon.db.char.autoResponseOptions[groupTypeKey].responseType end,
        set = function(info, val) addon.db.char.autoResponseOptions[groupTypeKey].responseType = val end,
    }
    initorder = initorder + 1
    --spacer
    addon.options.args[configGroup].args[tostring(initorder) .. "headerspacer"] = {
        type = "description",
        name = " ",
        width = "full",
        order = initorder
    }
    initorder = initorder + 1
    --indent spacer
    addon.options.args[configGroup].args[tostring(initorder) .. "indentspacer"] = {
        type = "description",
        name = " ",
        width = 0.2,
        order = initorder
    }
    initorder = initorder + 1
    --Alert sound title
    addon.options.args[configGroup].args[tostring(initorder) .. "header"] = {
        type = "description",
        name = "|cff" ..
            addon.groupieSystemColor .. "... Play an Alert Sound When a",
        width = 1.9,
        fontSize = "medium",
        order = initorder
    }
    initorder = initorder + 1
    --indent spacer
    addon.options.args[configGroup].args[tostring(initorder) .. "indentspacer"] = {
        type = "description",
        name = " ",
        width = 0.2,
        order = initorder
    }
    initorder = initorder + 1
    --Alert sound dropdown
    addon.options.args[configGroup].args[groupTypeTitle .. "sounddropdown"] = {
        type = "select",
        style = "dropdown",
        name = "",
        width = 1.8,
        order = initorder,
        values = {
            --[1] = "Global Friend Creates a Group, When in in Town",
            --[2] = "Local Friend or Guildie Creates a Group, When in in Town",
            --[3] = "Local Friend Creates a Group, When in in Town",
            --[4] = "Anyone Creates a Group, When in in Town",
            [5] = "Global Friend Creates a Group",
            [6] = "Local Friend or Guildie Creates a Group",
            [7] = "Local Friend Creates a Group",
            [8] = "Anyone Creates a Group",
            [9] = "Disable Alert Sounds for " .. groupTypeTitle .. " Groups",
        },
        get = function(info) return addon.db.char.autoResponseOptions[groupTypeKey].soundType end,
        set = function(info, val) addon.db.char.autoResponseOptions[groupTypeKey].soundType = val end,
    }
    initorder = initorder + 1
    --spacer
    addon.options.args[configGroup].args[tostring(initorder) .. "headerspacer"] = {
        type = "description",
        name = " ",
        width = "full",
        order = initorder
    }
    initorder = initorder + 1
    --indent spacer
    addon.options.args[configGroup].args[tostring(initorder) .. "indentspacer"] = {
        type = "description",
        name = " ",
        width = 0.2,
        order = initorder
    }
    initorder = initorder + 1
    --Alert sound selection title
    addon.options.args[configGroup].args[tostring(initorder) .. "header"] = {
        type = "description",
        name = "|cff" ..
            addon.groupieSystemColor .. "... Play Sound",
        width = 1.9,
        fontSize = "medium",
        order = initorder
    }
    initorder = initorder + 1

    --indent spacer
    addon.options.args[configGroup].args[tostring(initorder) .. "indentspacer"] = {
        type = "description",
        name = " ",
        width = 0.2,
        order = initorder
    }
    initorder = initorder + 1
    --Alert sound selection dropdown
    addon.options.args[configGroup].args[groupTypeTitle .. "soundiddropdown"] = {
        type = "select",
        style = "dropdown",
        name = "",
        width = 1.8,
        order = initorder,
        values = addon.sounds,
        get = function(info) return addon.db.char.autoResponseOptions[groupTypeKey].alertSoundID end,
        set = function(info, val) addon.db.char.autoResponseOptions[groupTypeKey].alertSoundID = val end,
    }
    initorder = initorder + 1
end

--Remove expired listings from the listing table
function addon.ExpireListings()
    --Save 20 mins of data for everyone
    --Filter this based on their settings in filterListings in core.lua
    local expirytimediff = 1200
    local maxLFGposttime = 1800
    for key, val in pairs(addon.db.global.listingTable) do
        if val.timestamp and (GetServerTime() - val.timestamp) > expirytimediff then
            addon.db.global.listingTable[key] = nil
        end
        --Also expire LFG listings created >30 min ago
        if GetServerTime() - val.createdat > maxLFGposttime and val.resultID ~= nil then
            addon.db.global.listingTable[key] = nil
        end
    end
end

--Convert a timestamp into a XXMin:XXSec string
function addon.GetTimeSinceString(timestamp, displayLen)
    local timediff = abs(GetServerTime() - timestamp)
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
    local now = GetServerTime()
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
    local playerName = myname
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
                                resetTime = reset + GetServerTime()
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
        resetTime = 41595 + GetServerTime()
    }
    addon.db.global.savedInstanceInfo[2160] = {}
    addon.db.global.savedInstanceInfo[2160][UnitName("player")] = {
        characterName = "Cooltestguy",
        classColor = addon.classColors[engClass],
        instance = "Coilfang: The Underbog",
        isHeroic = true,
        groupSize = 5,
        resetTime = 41595 + GetServerTime()
    }
    addon.db.global.savedInstanceInfo[2370] = {}
    addon.db.global.savedInstanceInfo[2370][UnitName("player")] = {
        characterName = "Cooltestguy",
        classColor = addon.classColors[engClass],
        instance = "Tempest Keep",
        isHeroic = false,
        groupSize = 25,
        resetTime = 386957 + GetServerTime()
    }
    addon.db.global.savedInstanceInfo[2330]["OtherGuy"] = {
        characterName = "OtherGuy",
        classColor = addon.classColors["DRUID"],
        instance = "Zul'Aman",
        isHeroic = false,
        groupSize = 10,
        resetTime = 41595 + GetServerTime()
    }
    addon.db.global.savedInstanceInfo[2330]["FunnyGuy"] = {
        characterName = "FunnyGuy",
        classColor = addon.classColors["HUNTER"],
        instance = "Zul'Aman",
        isHeroic = false,
        groupSize = 10,
        resetTime = 41595 + GetServerTime()
    }
    addon.db.global.savedInstanceInfo[2390] = {}
    addon.db.global.savedInstanceInfo[2390]["OtherGuy"] = {
        characterName = "OtherGuy",
        classColor = addon.classColors["DEATHKNIGHT"],
        instance = "Black Temple",
        isHeroic = false,
        groupSize = 25,
        resetTime = 386957 + GetServerTime()
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

--Return a string of 3 raid target icons from the hash of a given string input
--From https://wowwiki-archive.fandom.com/wiki/USERAPI_StringHash
function addon.RTHash(text)
    local counter = 1
    local len = string.len(text)
    for i = 1, len, 3 do
        counter = math.fmod(counter * 8161, 4294967279) + -- 2^32 - 17: Prime!
            (string.byte(text, i) * 16776193) +
            ((string.byte(text, i + 1) or (len - i + 256)) * 8372226) +
            ((string.byte(text, i + 2) or (len - i + 256)) * 3932164)
    end
    local numhash = math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
    local strhash = format("%x", numhash)
    local char1 = tonumber(strsub(strhash, -3, -3), 16) % 8 + 1
    local char2 = tonumber(strsub(strhash, -2, -2), 16) % 8 + 1
    local char3 = tonumber(strsub(strhash, -1, -1), 16) % 8 + 1
    return format("{rt%d}{rt%d}{rt%d}", char1, char2, char3)
end

--Calculate the player's own ilvl average
function addon.MyILVL()
    if LGS then
        local _, gsData = LGS:GetScore("player")
        if gsData and gsData.GearScore and gsData.GearScore > 0 then
            return gsData.AvgItemLevel
        end
    end

    local iLevelSum = 0
    for slotNum = 1, 19 do
        --Exclude shirt and tabard slots from itemlevel calculation
        if slotNum ~= 4 and slotNum ~= 19 then
            local tempItemLink = GetInventoryItemLink("player", slotNum)

            if tempItemLink then
                local name, _, _, iLevel, _, _, _, _, itemType = GetItemInfo(tempItemLink)
                if iLevel then
                    if slotNum == 16 and itemType == "INVTYPE_2HWEAPON" then
                        --If the weapon is 2 handed, and the offhand slot is empty, we sum the weapon's itemlevel twice
                        if GetInventoryItemLink("player", 17) == nil then
                            iLevelSum = iLevelSum + iLevel
                        end
                    end

                    iLevelSum = iLevelSum + iLevel
                else
                    return 0
                end
            end
        end
    end
    return floor(iLevelSum / 17)
end

--Calculate the average ilvl for a given GUID
function addon.GetILVLByGUID(guid)
    if LGS then
        local _, gsData = LGS:GetScore(guid)
        if gsData and gsData.GearScore and gsData.GearScore > 0 then
            return gsData.AvgItemLevel
        end
    end

    if addon.ILVLCache[guid] then
        return addon.ILVLCache[guid]
    end

    local iLevelSum = 0
    for slotNum = 1, 19 do

        --Exclude shirt and tabard slots from itemlevel calculation
        if slotNum ~= 4 and slotNum ~= 19 then
            local item = CI:GetInventoryItemMixin(guid, slotNum)
            if item then
                if not item:IsItemDataCached() then

                    local itemID = item:GetItemID()
                    if itemID then
                        C_Item.RequestLoadItemDataByID(itemID)
                    end
                end
                local tempItemLink = item:GetItemLink()
                if tempItemLink then
                    local name, _, _, iLevel, _, _, _, _, itemType = GetItemInfo(tempItemLink)
                    if slotNum == 16 and itemType == "INVTYPE_2HWEAPON" then
                        --If the weapon is 2 handed, and the offhand slot is empty, we sum the weapon's itemlevel twice
                        if GetInventoryItemLink("player", 17) == nil then
                            iLevelSum = iLevelSum + iLevel
                        end
                    end

                    iLevelSum = iLevelSum + iLevel
                end
            end
        end
    end

    local averageilvl = floor(iLevelSum / 17)
    if averageilvl > 0 then
        addon.ILVLCache[guid] = averageilvl
    end

    return averageilvl
end
