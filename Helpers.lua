local addonName, addon = ...
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
    return maxTalentSpec
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

--Generate a table for use in config spec dropdown
function addon.GenerateRoleDropdown(class, spec)

end
