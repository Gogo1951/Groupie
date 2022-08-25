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
    for i=1,#table do
       if table[i] == val then 
          return true
       end
    end
    return false
 end


 --Return a table by splitting a string at specified delimiter
 function addon.groupieSplit(inputstr, delimiter)
	if delimiter == nil then
		delimiter = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..delimiter.."]+)") do
		if tContains(t, str)==false then
			table.insert(t, str)
		end
	end
	return t
end
 