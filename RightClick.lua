--TODO: get num talents spent to determine spec
--TODO: allow players to set role for each spec in options
--TODO: send relevant achievment if available
--TODO: sum 2 handed ilvl twice 
local function SendPlayerInfo(boolCurrentSpec, targetName)
	boolCurrentSpec = boolCurrentSpec or true

	--Convert Locales into languages
	local localeTable = {
		["frFR"] = "French",
		["deDE"] = "German",
		["enGB"] = "English",
		["enUS"] = "English",
		["itIT"] = "Italian",
		["koKR"] = "Korean",
		["zhCN"] = "Chinese",
		["zhTW"] = "Chinese",
		["ruRU"] = "Russian",
		["esES"] = "Spanish",
		["esMX"] = "Spanish",
		["ptBR"] = "Portuguese",
	}

	--Calculate average itemlevel
	local iLevelSum = 0
	for slotNum=1,19 do
		--Exclude shirt and tabard slots from itemlevel calculation
		if slotNum ~= 4 and slotNum ~= 19 then
			local tempItemLink = GetInventoryItemLink("player", slotNum)
			
			if tempItemLink then
				local name, _, _, iLevel = GetItemInfo(tempItemLink)
				iLevelSum = iLevelSum + iLevel
			end
		end
	end
	local averageiLevel = floor(iLevelSum / 17)

	local myclass = UnitClass("player")
	local mylevel = UnitLevel("player")
	local mylocale = GetLocale()

	--Sending Current Spec Info
	if boolCurrentSpec then
		SendChatMessage("{rt3} Groupie: __ROLE__ LFG! Level "..
			mylevel..
			" __SPEC__"..
			myclass..
			" wearing "..
			tostring(averageiLevel)..
			" average item-level gear. "..
			localeTable[mylocale]..
			" speaking player.", 
		"WHISPER", "COMMON", targetName)
	--Sending Alternate Spec Info
	else
		SendChatMessage("{rt3} Groupie: __ROLE__ LFG! Level "..
			mylevel..
			" __SPEC__"..
			myclass..
			" wearing "..
			tostring(averageiLevel)..
			" average item-level gear. "..
			localeTable[mylocale]..
			" speaking player.", 
		"WHISPER", "COMMON", targetName)
	end
	return true
end

---------------
-- Menu Hook --
---------------
local function GroupieUnitMenu (dropdownMenu, which, unit, name, userData, ...)

	if (UIDROPDOWNMENU_MENU_LEVEL > 1) then
		return
	end

	--Some context menus dont natively give us a name parameter
	if name == nil then
		name = UnitName(unit)
	end 

	--Check that we have a non nil name, and that the target is a player
	if name ~= nil and UnitIsPlayer(unit) then
		UIDropDownMenu_AddSeparator(UIDROPDOWNMENU_MENU_LEVEL)

		local info = UIDropDownMenu_CreateInfo()
		info.notClickable = true
		info.notCheckable = true
		info.isTitle = true
		info.text = "Groupie"	
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		local info = UIDropDownMenu_CreateInfo()
		info.notClickable = true
		info.notCheckable = true
		info.text = "Send My Info"	
		info.leftPadding = 10
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		local info = UIDropDownMenu_CreateInfo()
		info.dist = 0
		info.notCheckable = true	
		info.func = function() SendPlayerInfo(true, name) end
		info.text = "Current Spec"	
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		local info = UIDropDownMenu_CreateInfo()
		info.dist = 0
		info.notCheckable = true	
		info.func = function() SendPlayerInfo(false, name) end
		info.text = "Other Spec"	
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
	end	
	
end

hooksecurefunc("UnitPopup_ShowMenu", GroupieUnitMenu)