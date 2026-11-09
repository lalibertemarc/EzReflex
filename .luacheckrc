std = "lua51"
max_line_length = false
self = false

globals = {
    "EzReflexDB",
    "EzReflexCharDB",
    "SLASH_EZREFLEX1",
    "SLASH_EZREFLEX2",
    "SlashCmdList",
}

read_globals = {
    -- Lua / WoW string and table helpers
    "format", "strlower", "wipe",
    -- Frames & UI
    "CreateFrame", "DEFAULT_CHAT_FRAME",
    -- Settings panel
    "Settings", "CreateSettingsListSectionHeaderInitializer", "CreateSettingsButtonInitializer",
    "MinimalSliderWithSteppersMixin",
    -- Namespaced APIs
    "C_ChatInfo", "C_Timer", "issecretvalue",
    -- Global APIs
    "GetBuildInfo", "GetLocale", "GetTime", "GetUnitSpeed", "IsFalling", "InCombatLockdown",
    "UnitAffectingCombat", "UnitIsDeadOrGhost", "UnitExists", "UnitName", "DoEmote", "MAXEMOTEINDEX",
    "UnitIsPlayer", "UnitIsUnit", "UnitLevel", "UnitIsVisible", "CheckInteractDistance", "IsInRaid",
    "GetNumGroupMembers", "UNKNOWNOBJECT", "UnitIsFeignDeath", "DUEL_WINNER_KNOCKOUT", "DUEL_WINNER_RETREAT",
    -- Other addons (read only)
    "EzAcquaintancesAPI",
}
