function addon.GroupieEventRegister(...)
    addon.SetupConfig()

end

addon:RegisterEvent("PLAYER_ENTERING_WORLD", addon.GroupieEventRegister)
