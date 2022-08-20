local AceGUI = LibStub("AceGUI-3.0")

local function BuildGroupieWindow()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Groupie")
    frame:SetStatusText("Groupie LFG - Party Listing")

    _G["GroupieFrame"] = frame.frame
    tinsert(UISpecialFrames, "GroupieFrame")
end

SLASH_GROUPIE1, SLASH_GROUPIE2= "/groupie", "/groupielfg"
SlashCmdList["GROUPIE"] = BuildGroupieWindow
