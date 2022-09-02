local addonName, addon = ...
local GetTalentTabInfo = GetTalentTabInfo
local time = time

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
    for str in string.gmatch(inputstr, "([^" .. delimiter .. "]+)") do
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
function addon.GenerateInstanceToggles(order, instanceType, showMaxLevel, groupToggle)
    local initorder = order
    addon.options.args.instancefilters.args[tostring(initorder) .. "headerspacer"] = {
        type = "description",
        name = " ",
        width = "full",
        order = initorder
    }
    initorder = initorder + 1
    addon.options.args.instancefilters.args[tostring(initorder) .. "header"] = {
        type = "description",
        name = "|cffffd900" .. instanceType,
        width = "full",
        fontSize = "medium",
        order = initorder
    }
    initorder = initorder + 1
    --[[addon.options.args.instancefilters.args[groupToggle] = {
        type = "toggle",
        name = "|cffffd900" .. instanceType,
        order = initorder,
        width = "full",
        get = function(info)
            return addon.db.char[groupToggle]
        end,
        set = function(info, val)
            addon.db.char[groupToggle] = val
            for key, val in pairs(addon.options.args.instancefilters.args) do
                if val.order >= initorder and val.order < initorder + 98 then
                    if val.type == "toggle" then
                        val.set(info, val, true)
                    end
                end
            end
        end,
    }
    initorder = initorder + 1--]]
    for _, key in ipairs(addon.instanceOrders) do
        if addon.instanceConfigData[key].InstanceType == instanceType then
            --This slows down the page way too much, need to find a better solution to indent
            --addon.options.args.instancefilters.args[tostring(order) .. "leftspacer"] = {
            --    type = "description",
            --    name = " ",
            --    width = 0.1,
            --    order = order
            --}
            --order = order + 1
            local nameStr = ""
            if showMaxLevel then
                nameStr = format("%s | %d-%d", addon.instanceConfigData[key].Name,
                    addon.instanceConfigData[key].MinLevel, addon.instanceConfigData[key].MaxLevel,
                    addon.instanceConfigData[key].GroupSize)
            else
                nameStr = format("%s | %d", addon.instanceConfigData[key].Name,
                    addon.instanceConfigData[key].MinLevel, addon.instanceConfigData[key].GroupSize)
            end
            addon.options.args.instancefilters.args[addon.instanceConfigData[key].Name] = {
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
    local expirytimediff = addon.db.global.minsToPreserve * 60
    for key, val in pairs(addon.groupieListingTable) do
        if time() - val.timestamp > expirytimediff then
            addon.groupieListingTable[key] = nil
        end
    end
end
