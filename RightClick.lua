local addonName, addon = ...
local locale = GetLocale()
if not addon.tableContains(addon.validLocales, locale) then
	return
end
local L       = LibStub('AceLocale-3.0'):GetLocale('Groupie')
local LGS     = LibStub:GetLibrary("LibGearScore.1000", true)
local myname  = UnitName("player")
local myclass = UnitClass("player")
local mylevel = UnitLevel("player")

-------------------------------
-- Right Click Functionality --
-------------------------------
function addon.SendPlayerInfo(targetName, dropdownMenu, which, fullName, resultID, isAutoResponse)
	addon.UpdateSpecOptions()
	--Calculate average itemlevel
	local iLevelSum = 0
	for slotNum = 1, 19 do
		--Exclude shirt and tabard slots from itemlevel calculation
		if slotNum ~= 4 and slotNum ~= 19 then
			local tempItemLink = GetInventoryItemLink("player", slotNum)

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
	local averageiLevel = floor(iLevelSum / 17)



	--Find out which spec group is active
	local specGroup = addon.GetActiveSpecGroup()
	--1+2=3 :)
	local inactiveSpecGroup = 3 - specGroup
	--Find out which talent spec has the most points spent in it
	local activeTalentSpec = addon.GetSpecByGroupNum(specGroup)
	local inactiveTalentSpec, inactiveTalentsSpent = addon.GetSpecByGroupNum(inactiveSpecGroup)
	local activeRole = nil
	local inactiveRole = nil
	if specGroup == 1 then
		activeRole = addon.groupieRoleTable[addon.db.char.groupieSpec1Role]
		inactiveRole = addon.groupieRoleTable[addon.db.char.groupieSpec2Role]
	else
		activeRole = addon.groupieRoleTable[addon.db.char.groupieSpec2Role]
		inactiveRole = addon.groupieRoleTable[addon.db.char.groupieSpec1Role]
	end

	local otherRoleMsg = ""
	local otherSpecMsg = ""
	--Send other spec role if dual spec is purchased and used
	--and it is enabled in options
	if (inactiveTalentsSpent > 0 or addon.debugMenus) and addon.db.char.sendOtherRole then
		if inactiveRole ~= activeRole then
			otherRoleMsg = format(" / %s", inactiveRole)
		end
		if inactiveTalentSpec ~= activeTalentSpec then
			otherSpecMsg = format(" / %s", inactiveTalentSpec)
		end
	end

	local lfgStr = "LFG"
	--Include instance name if whispering from a listing
	if fullName and fullName ~= "Miscellaneous" then
		lfgStr = "for " .. fullName
	end

	local achieveLinkStr = ""
	--include relevant achievement link if available
	if fullName then
		local priorities = addon.groupieAchievementPriorities[fullName]
		if priorities ~= nil then
			for i = 1, #priorities do
				if achieveLinkStr == "" then
					local _, _, _, completed = GetAchievementInfo(priorities[i])
					if completed then
						local achieveLink = GetAchievementLink(priorities[i])
						if achieveLink then
							achieveLinkStr = " " .. achieveLink
						end
					end
				end
			end
		end
	end

	local lvlStr = ""
	--Show ilvl or gearscore or level
	if mylevel < 80 or addon.db.char.LFGMsgGearType == 1 then
		lvlStr = "Level " .. tostring(mylevel)
	elseif addon.db.char.LFGMsgGearType == 2 then
		lvlStr = "Item-Level " .. tostring(averageiLevel)
	elseif addon.db.char.LFGMsgGearType == 3 then
		local guid, gearScore = LGS:GetScore("player")
		lvlStr = "GearScore " .. tostring(gearScore.GearScore)
	end

	local isAutoResponseString = ""
	if isAutoResponse then
		isAutoResponseString = "Hey Friend, you can count on me! "
	end

	local groupieMsg = format("{rt3} %s : %s%s%s %s! %s %s%s %s.%s",
		addonName,
		isAutoResponseString,
		activeRole,
		otherRoleMsg,
		lfgStr,
		lvlStr,
		activeTalentSpec,
		otherSpecMsg,
		myclass,
		achieveLinkStr
	)

	--Hash the message and attach the suffix of the hash
	------------
	--Old Hash--
	------------
	local msgHash = addon.StringHash(myname .. groupieMsg)
	groupieMsg = format("%s [#%s]", groupieMsg, msgHash)
	------------
	--New Hash--
	------------
	--local msgHash = addon.RTHash(myname .. groupieMsg)
	--groupieMsg = format("%s %s", groupieMsg, msgHash)

	--Sending Current Spec Info
	if which == "BN_FRIEND" then
		BNSendWhisper(dropdownMenu.accountInfo.bnetAccountID, groupieMsg)
	else
		SendChatMessage(groupieMsg, "WHISPER", "COMMON", targetName)
	end
	return true
end

function addon.SendWCLInfo(targetName, dropdownMenu, which)

	local myserver = (GetRealmName()):gsub("[ '`]", "-"):lower() or nil
	local region = (GetCVar("portal")):lower() or nil
	local link
	if (myserver and region) then -- all good
		link = format("https://classic.warcraftlogs.com/character/%s/%s/%s", region, myserver, myname)
	else -- just send them a search with our name, will at least help if we're named Ărtĥäś
		link = format("https://classic.warcraftlogs.com/search/?term=%s", myname)
	end
	local groupieMsg = "{rt3} " .. addonName .. " : Check My Parses on Warcraft Logs " .. link

	--Hash the message and attach the suffix of the hash
	------------
	--Old Hash--
	------------
	local msgHash = addon.StringHash(myname .. groupieMsg)
	groupieMsg = format("%s [#%s]", groupieMsg, msgHash)
	------------
	--New Hash--
	------------
	--local msgHash = addon.RTHash(myname .. groupieMsg)
	--groupieMsg = format("%s %s", groupieMsg, msgHash)


	if which == "BN_FRIEND" then
		BNSendWhisper(dropdownMenu.accountInfo.bnetAccountID, groupieMsg)
	else
		SendChatMessage(groupieMsg, "WHISPER", "COMMON", targetName)
	end
end

---------------
-- Menu Hook --
---------------
local function GroupieUnitMenu(dropdownMenu, which, unit, name, userData, ...)

	if (UIDROPDOWNMENU_MENU_LEVEL > 1) then
		return
	end

	--Attempt to prevent taint by not hooking dropdown while in combat
	if InCombatLockdown() then
		return
	end

	--Some context menus dont natively give us a name parameter
	if name == nil then
		name = UnitName(unit)
	end

	--Return if the unit is not a player
	if unit ~= nil and not UnitIsPlayer(unit) then
		return
	end

	--Dont show the menu on the player's own frame if not in debug mode
	if unit == "player" and not addon.debugMenus then
		return
	end
	if myname == name and not addon.debugMenus then
		return
	end

	--Check that we have a non nil name, and that the target is a player
	if name ~= nil then
		UIDropDownMenu_AddSeparator(UIDROPDOWNMENU_MENU_LEVEL)
		local info = UIDropDownMenu_CreateInfo()
		info.notClickable = true
		info.notCheckable = true
		info.isTitle = true
		info.text = addonName
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		info = UIDropDownMenu_CreateInfo()
		info.notClickable = true
		info.notCheckable = true
		info.text = L["RightClickMenu"].SendInfo
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		info = UIDropDownMenu_CreateInfo()
		info.dist = 0
		info.notCheckable = true
		info.func = function()
			addon.SendPlayerInfo(name, dropdownMenu, which)
		end

		local activeSpecGroup = addon.GetActiveSpecGroup()
		local maxTalentSpec, maxTalentsSpent = addon.GetSpecByGroupNum(activeSpecGroup)
		local activeRole = ""
		if activeSpecGroup == 1 then
			activeRole = addon.groupieRoleTable[addon.db.char.groupieSpec1Role]
		else
			activeRole = addon.groupieRoleTable[addon.db.char.groupieSpec2Role]
		end
		info.text = format(L["RightClickMenu"].Current .. " : %s (%s)", maxTalentSpec, activeRole)
		info.leftPadding = 8
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		--Only US region supported for now
		if GetLocale() == "enUS" then
			info = UIDropDownMenu_CreateInfo()
			info.dist = 0
			info.notCheckable = true
			info.func = function()
				addon.SendWCLInfo(name, dropdownMenu, which)
			end
			info.text = L["RightClickMenu"].WCL
			info.leftPadding = 8
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end

hooksecurefunc("UnitPopup_ShowMenu", GroupieUnitMenu)
