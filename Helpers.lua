--Return the primary talent spec for either main or dual specialization
function GetSpecByGroupNum(groupnum)
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
function tableContains(table, val)
    for i=1,#table do
       if table[i] == val then 
          return true
       end
    end
    return false
 end
 