-- Options page: Esc > Options > AddOns > EzReflex. Built at login, once the saved variables exist.
local _, ns = ...

function ns.BuildSettings()
    local category, layout = Settings.RegisterVerticalLayoutCategory("EzReflex")
    ns.settingsCategory = category
    local db = EzReflexDB

    local function Header(text)
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
    end

    local function Register(key, varType, name)
        return Settings.RegisterAddOnSetting(category, "EZREFLEX_" .. key:upper(), key, db, varType, name,
            ns.DEFAULTS[key])
    end

    local function Check(key, name, tooltip)
        return Settings.CreateCheckbox(category, Register(key, Settings.VarType.Boolean, name), tooltip)
    end

    local function Slider(key, name, tooltip, min, max, step, formatter)
        local options = Settings.CreateSliderOptions(min, max, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatter)
        return Settings.CreateSlider(category, Register(key, Settings.VarType.Number, name), options, tooltip)
    end

    local function Percent(value) return format("%d%%", value) end
    local function Seconds(value) return format("%ds", value) end

    Header("Answering")
    Check("enabled", "Answer emotes", "When a player does a text emote at you (/bow, /wave, /hug...), your character answers with one of its own.")
    Slider("chance", "Chance", "How often you answer an emote aimed at you.", 0, 100, 5, Percent)
    Check("echo", "Chat echo", "Prints \"(Reflex) You /bow back at Bob.\" in your chat (only you see it), so you know it was EzReflex.")
    Check("acquaintances", "Friends and rivals (EzAcquaintances)",
        "With EzAcquaintances loaded, people in its Book tagged rival, enemy, suspicious or liar get a cold answer (/glare, /snub, /rude...), and friends, allies and family a warmer one.")

    Header("Your group")
    for _, event in ipairs(ns.EVENTS) do
        local setting = Settings.RegisterAddOnSetting(category, "EZREFLEX_IN_" .. event.token, event.token, db.emotes,
            Settings.VarType.Boolean, event.title, true)
        Settings.CreateCheckbox(category, setting, event.tip .. " Answers in combat too; waits while you're moving. The chance setting doesn't apply.")
    end

    Header("Holding back")
    Check("combat", "Not in combat", "Don't answer emotes while you're in combat. Level-ups and Questie lines are answered in combat anyway.")
    Check("moving", "Not while moving", "Stay quiet while you move: most emotes don't play their animation on the run.")
    Slider("cooldown", "Cooldown", "Shortest time between any two answers.", 0, 60, 1, Seconds)
    Slider("personCooldown", "Per-person cooldown", "Shortest time before you answer the same person again.", 0, 300, 5, Seconds)
    Slider("pingPong", "Ping-pong guard",
        "Ignore someone's emote this soon after you emoted at them (by hand or by EzReflex), so two EzReflex users don't keep answering each other.",
        0, 60, 1, Seconds)

    Header("Emotes you answer")
    layout:AddInitializer(CreateSettingsButtonInitializer("Answers", "List in chat", function() ns.List() end,
        "Prints what this character answers to each emote. Change them with /reflex set <emote> <answer1,answer2...>.", false))
    for _, token in ipairs(ns.incoming) do
        local label = "/" .. (ns.emotes[token] or token:lower())
        local setting = Settings.RegisterAddOnSetting(category, "EZREFLEX_IN_" .. token, token, db.emotes,
            Settings.VarType.Boolean, label, true)
        Settings.CreateCheckbox(category, setting, "Answer when someone does " .. label .. " at you.")
    end

    Settings.RegisterAddOnCategory(category)
end
