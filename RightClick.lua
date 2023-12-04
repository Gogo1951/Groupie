local addonName, addon = ...
local locale = GetLocale()
if not addon.tableContains(addon.validLocales, locale) then
	return
end
local L       = LibStub('AceLocale-3.0'):GetLocale('Groupie')
local LGS     = LibStub:GetLibrary("LibGearScore.1000", true)
local LDD     = LibStub("LibDropDown")
local myname  = UnitName("player")
local myclass = UnitClass("player")


-------------------------------
-- Right Click Functionality --
-------------------------------
local msgCache = {}
function addon.GetPlayerInfoMsg(fullName, isAutoResponse, isTooltip)
	local msgKey = format("%s:%s",tostring(fullName),tostring(isAutoResponse))
	if msgCache[msgKey] and isTooltip then
		return msgCache[msgKey]
	end
	local mylevel = UnitLevel("player")
	addon.UpdateSpecOptions()

	if addon.playerILVL == nil or addon.playerGearScore == nil or addon.playerILVL < 1 or addon.playerGearScore < 1 then
		addon.UpdateCharacterSheet()
	end

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
		if addon.playerILVL == nil or addon.playerILVL < 1 then
			addon.UpdateCharacterSheet()
		end
		if addon.playerILVL ~= nil and addon.playerILVL > 0 then
			lvlStr = "Item-level " .. tostring(addon.playerILVL)
		else
			lvlStr = "Level " .. tostring(mylevel)
		end
	elseif addon.db.char.LFGMsgGearType == 3 then
		if addon.playerGearScore == nil or addon.playerGearScore < 1 then
			addon.UpdateCharacterSheet()
		end
		if addon.playerGearScore ~= nil and addon.playerGearScore > 0 then
			lvlStr = "GearScore " .. tostring(addon.playerGearScore)
		else
			lvlStr = "Level " .. tostring(mylevel)
		end
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
	msgCache[msgKey] = groupieMsg:gsub("%b{}%s*","")
	if isTooltip then return msgCache[msgKey] end
	return groupieMsg
end

function addon.SendPlayerInfo(targetName, dropdownMenu, which, fullName, resultID, isAutoResponse)

	local groupieMsg = addon.GetPlayerInfoMsg(fullName, isAutoResponse)

	--Hash the message and attach the suffix of the hash
	------------
	--Old Hash--
	------------
	--local msgHash = addon.StringHash(myname .. groupieMsg)
	--groupieMsg = format("%s [#%s]", groupieMsg, msgHash)
	------------
	--New Hash--
	------------
	local msgHash = addon.RTHash(myname .. groupieMsg)
	groupieMsg = format("%s %s", groupieMsg, msgHash)

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
	--local msgHash = addon.StringHash(myname .. groupieMsg)
	--groupieMsg = format("%s [#%s]", groupieMsg, msgHash)
	------------
	--New Hash--
	------------
	local msgHash = addon.RTHash(myname .. groupieMsg)
	groupieMsg = format("%s %s", groupieMsg, msgHash)


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

	--Attempt to prevent taint by not hooking dropdown while in combat
	if InCombatLockdown() then
		return
	end

	if (UIDROPDOWNMENU_MENU_LEVEL > 1) or (which ~= "PLAYER") then
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
	if UnitIsUnit(unit,"player") and not addon.debugMenus then
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
