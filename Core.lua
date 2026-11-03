-- EzReflex: when a player emotes at you (/bow, /wave, /hug...), your character answers with an emote of its own.
local _, ns = ...

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff7fd4ffEzReflex|r: " .. msg)
end

local function Echo(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff9d9d9d(Reflex) " .. msg .. "|r")
end

local function Trim(s)
    return (s or ""):match("^%s*(.-)%s*$")
end

local function issecret(v)
    return issecretvalue and issecretvalue(v)
end

local function Plain(s)
    return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

---------------------------------------------------------------------------
-- Names. Forever puts a surname where Era puts the realm ("First Surname", "First-Realm"); first names are
-- unique, so people are keyed by their lowercase first name.
---------------------------------------------------------------------------
local function FirstName(name)
    return name:match("^[^%s%-]+") or name
end

function ns.Key(name)
    return strlower(FirstName(name))
end

local function MyKey()
    local name = UnitName("player")
    if name and not issecret(name) then return ns.Key(name) end
end

---------------------------------------------------------------------------
-- API compat (C_ChatInfo first, old global as fallback). Emotes from timers are fine on Forever; chat text
-- isn't, so EzReflex never sends any.
---------------------------------------------------------------------------
local function PerformEmote(token, target)
    if C_ChatInfo and C_ChatInfo.PerformEmote then
        return C_ChatInfo.PerformEmote(token, target, true) -- true: no "can't do that while moving" error
    end
    DoEmote(token, target)
    return true
end

-- Encounters and similar lock addon chat and emotes (C_ChatInfo.InChatMessagingLockdown).
local function ChatLocked()
    return C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()
end

---------------------------------------------------------------------------
-- Emote catalog from the client's EMOTEn_TOKEN / EMOTEn_CMDn globals
---------------------------------------------------------------------------
ns.emotes = {}   -- token -> slash command without "/" ("BOW" -> "bow")
local byCmd = {} -- command or alias, lowercase without "/" -> token

local function Command(s)
    return (s:gsub("^/", ""):lower())
end

local function BuildCatalog()
    for i = 1, MAXEMOTEINDEX or 700 do
        local token, cmd = _G["EMOTE" .. i .. "_TOKEN"], _G["EMOTE" .. i .. "_CMD1"]
        if token and cmd then
            ns.emotes[token] = ns.emotes[token] or Command(cmd)
            local j = 1
            while _G["EMOTE" .. i .. "_CMD" .. j] do
                local alias = Command(_G["EMOTE" .. i .. "_CMD" .. j])
                byCmd[alias] = byCmd[alias] or token
                j = j + 1
            end
        end
    end
end

-- Token for "bow", "/bow" or "BOW"; nil if this client has no such emote.
function ns.FindToken(name)
    local token = byCmd[Command(name)]
    if token then return token end
    local upper = name:gsub("^/", ""):upper()
    if ns.emotes[upper] or not next(ns.emotes) then return upper end
end

-- Group events by token, and by the names you can type for them ("levelup", "quest"...).
ns.events, ns.eventNames = {}, {}
for _, event in ipairs(ns.EVENTS) do
    ns.events[event.token] = event
    for _, name in ipairs(event.names) do ns.eventNames[name] = event.token end
end

-- What you can be answering: an emote, or a group event.
local function FindIncoming(name)
    return ns.eventNames[Command(name)] or ns.FindToken(name)
end

local function Label(token)
    if ns.events[token] then return ns.events[token].label end
    return "/" .. (ns.emotes[token] or token:lower())
end

local function Labels(list)
    local out = {}
    for i, token in ipairs(list) do out[i] = Label(token) end
    return table.concat(out, ", ")
end

-- Leaves out answers this client doesn't have (Forever and Era emote lists differ a little).
local function Known(list)
    if not next(ns.emotes) then return list end
    local out = {}
    for _, token in ipairs(list) do
        if ns.emotes[token] then out[#out + 1] = token end
    end
    return out
end

---------------------------------------------------------------------------
-- Recognising an incoming text emote
---------------------------------------------------------------------------
local compiled = {} -- { token, patterns }

local function Compile()
    for _, entry in ipairs(ns.INCOMING) do
        local pats = {}
        for i = 2, #entry do pats[#pats + 1] = "%f[%w]" .. Plain(entry[i]) .. "%f[%W]" end
        compiled[#compiled + 1] = { token = entry[1], patterns = pats }
    end
end

-- A letter, digit or byte of a UTF-8 letter, for cutting a name out as a whole word.
local NAME_EDGE = "[^%w\128-\255]"

-- The emote token of a text emote line aimed at you ("Bob bows before you."), or nil. The sender's name is
-- taken out first, so a "Bows" in a name can't count.
function ns.Identify(text, sender)
    local msg = " " .. strlower(text) .. " "
    for word in strlower(sender or ""):gmatch("[^%s%-]+") do
        msg = msg:gsub("(" .. NAME_EDGE .. ")" .. Plain(word) .. "(" .. NAME_EDGE .. ")", "%1%2")
    end
    if not msg:find("%f[%a]your?%f[%A]") then return end
    for _, entry in ipairs(compiled) do
        for _, pat in ipairs(entry.patterns) do
            if msg:find(pat) then return entry.token end
        end
    end
end

---------------------------------------------------------------------------
-- What to answer
---------------------------------------------------------------------------
-- "cold" or "warm" from EzAcquaintances' Book for this character (read only), plus why; nil when neither.
function ns.Mood(key)
    if not EzReflexDB.acquaintances then return end
    local book = type(EzAcquaintancesCharDB) == "table" and EzAcquaintancesCharDB.people
    local p = type(book) == "table" and book[key]
    if type(p) ~= "table" then return end
    local tags = type(p.tags) == "table" and p.tags or {}
    for tag in pairs(ns.COLD_TAGS) do
        if tags[tag] then return "cold", tag end
    end
    if ns.COLD_RELS[p.rel] then return "cold", p.rel end
    for tag in pairs(ns.WARM_TAGS) do
        if tags[tag] then return "warm", tag end
    end
    if ns.WARM_RELS[p.rel] then return "warm", p.rel end
end

-- Answers to an incoming emote, and where they come from.
function ns.Answers(token, mood)
    if mood == "cold" then
        if ns.events[token] and not EzReflexCharDB.cold then return Known(ns.COLD_EVENTS[token]), "cold set" end
        return Known(EzReflexCharDB.cold or ns.COLD), EzReflexCharDB.cold and "your cold set" or "cold set"
    end
    local own = EzReflexCharDB.reactions[token]
    if own then return Known(own), "yours" end
    if mood == "warm" and ns.WARM[token] then return Known(ns.WARM[token]), "warm set" end
    return Known(ns.REACTIONS[token] or {}), "default"
end

-- Every incoming emote EzReflex recognises, in INCOMING order, and the same as a set.
ns.incoming, ns.isIncoming = {}, {}
for _, entry in ipairs(ns.INCOMING) do
    ns.incoming[#ns.incoming + 1] = entry[1]
    ns.isIncoming[entry[1]] = true
end
for token in pairs(ns.events) do ns.isIncoming[token] = true end

local function Pick(list)
    return list[math.random(#list)]
end

---------------------------------------------------------------------------
-- Guards
---------------------------------------------------------------------------
local lastAnswer = -math.huge -- GetTime() of your last answer to anyone
local answered = {}           -- key -> GetTime() of your last answer to them
local sent = {}               -- key -> GetTime() you last emoted at them, by hand or by EzReflex
local heard = {}              -- key -> GetTime() they last emoted at you
local pending                 -- an answer is waiting on its timer

local function Moving()
    return GetUnitSpeed("player") > 0 or (IsFalling and IsFalling())
end

-- Why you can't answer anyone right now, or nil; true as well when it's something that passes (combat, moving).
-- event: answering a group event, which goes out in combat too (objectives finish on a kill).
local function StateBlocked(event)
    local db = EzReflexDB
    if not db.enabled then return "EzReflex is off" end
    if UnitIsDeadOrGhost("player") then return "you're dead" end
    if ChatLocked() then return "emotes are locked here" end
    if db.combat and not event and (InCombatLockdown() or UnitAffectingCombat("player")) then return "you're in combat", true end
    if db.moving and Moving() then return "you're moving", true end
end

-- Why you wouldn't answer this emote from this person right now, or nil. An answer to a group event waits out
-- moving instead (see Answer).
local function Blocked(token, key, now)
    local db = EzReflexDB
    if db.emotes[token] == false then return "answers to " .. Label(token) .. " are switched off" end
    local event = ns.events[token] ~= nil
    local reason, passes = StateBlocked(event)
    if reason and not (passes and event) then return reason end
    if pending then return "already answering someone" end
    if now - lastAnswer < db.cooldown then
        return format("cooldown (%ds left)", math.ceil(db.cooldown - (now - lastAnswer)))
    end
    if key and answered[key] and now - answered[key] < db.personCooldown then
        return format("you answered them %ds ago", now - answered[key])
    end
    if key and sent[key] and now - sent[key] < db.pingPong then
        return format("you emoted at them %ds ago (ping-pong guard)", now - sent[key])
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
-- Your own text emote ("You bow before Bob."): remember whom it was aimed at, so their answer to it isn't
-- answered back. Checks the words against your target and people who emoted at you lately.
local function OwnEmote(text)
    local now = GetTime()
    local target = UnitExists("target") and UnitName("target")
    local targetKey = target and not issecret(target) and ns.Key(target)
    for word in strlower(text):gmatch("[^%s%p]+") do
        if word == targetKey or (heard[word] and now - heard[word] < ns.HEARD_TIME) then sent[word] = now end
    end
end

-- Emotes answer at name after a short pause and remembers it for the guards. event: a group event's answer,
-- which goes out in combat and keeps trying for ns.EVENT_WAIT while you're moving instead of dropping it.
local function Answer(key, name, answer, echo, event)
    pending = true
    local giveUp = GetTime() + (event and ns.EVENT_WAIT or 0)
    local function Try()
        if StateBlocked(event) then
            if GetTime() < giveUp then return C_Timer.After(1, Try) end
            pending = nil
            return
        end
        pending = nil
        if PerformEmote(answer, name) == false then return end
        local now = GetTime()
        lastAnswer, answered[key], sent[key] = now, now, now
        if EzReflexDB.echo then Echo(echo) end
    end
    C_Timer.After(ns.DELAY_MIN + math.random() * (ns.DELAY_MAX - ns.DELAY_MIN), Try)
end

local function OnTextEmote(text, sender, guid)
    if issecret(text) or issecret(sender) or type(text) ~= "string" or type(sender) ~= "string" then return end
    if sender == "" then return end
    local key = ns.Key(sender)
    if key == MyKey() then return OwnEmote(text) end
    -- Players only (pets and NPCs don't send text emotes today, but be sure).
    if type(guid) == "string" and not issecret(guid) and guid ~= "" and not guid:find("^Player") then return end
    local token = ns.Identify(text, sender)
    if not token then return end
    local now = GetTime()
    heard[key] = now
    if Blocked(token, key, now) then return end
    if math.random(100) > EzReflexDB.chance then return end
    local answers = ns.Answers(token, ns.Mood(key))
    if #answers == 0 then return end
    local answer, name = Pick(answers), FirstName(sender)
    Answer(key, name, answer, format("You %s back at %s (they %s).", Label(answer), name, Label(token)))
end

---------------------------------------------------------------------------
-- Level-ups. The game only tells addons the level of units they have a token for, so EzReflex looks at your
-- group and target, keeps the last level it saw per person (this session) and counts a rise from that as a
-- level-up. Its first look at someone never is one.
---------------------------------------------------------------------------
local levels = {} -- key -> last level seen

local function PlayerUnit(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end
    local name, level = UnitName(unit), UnitLevel(unit)
    if issecret(name) or issecret(level) or type(name) ~= "string" or type(level) ~= "number" then return end
    if name == "" or name == UNKNOWNOBJECT or level <= 0 then return end -- not loaded yet, or "??" level
    return ns.Key(name), name, level
end

local function Remember(unit)
    local key, _, level = PlayerUnit(unit)
    if key then levels[key] = level end
end

local function ForGroup(fn)
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, GetNumGroupMembers() do fn(prefix .. i) end
end

-- Only units EzReflex keeps up to date; a stale state from a mouseover could look like a change.
local function GroupToken(unit)
    return unit:find("^party%d") or unit:find("^raid%d")
end

-- Close enough to see your emote: in sight, and within ~28 yd where addons may check (out of combat).
local function Near(unit)
    if not UnitIsVisible(unit) then return false end
    return InCombatLockdown() or CheckInteractDistance(unit, 4) ~= false
end

local function OnUnitLevel(unit)
    if unit ~= "target" and not GroupToken(unit) then return end
    local key, name, level = PlayerUnit(unit)
    if not key then return end
    local old = levels[key]
    levels[key] = level -- the same person under two tokens (target and party1) only counts once
    if not old or level <= old or not Near(unit) then return end
    if Blocked(ns.LEVELUP, key, GetTime()) then return end
    local answers = ns.Answers(ns.LEVELUP, ns.Mood(key))
    if #answers == 0 then return end
    local answer, first = Pick(answers), FirstName(name)
    Answer(key, first, answer, format("You %s %s (level %d).", Label(answer), first, level), true)
end

---------------------------------------------------------------------------
-- Deaths in your group. The combat log is off limits on Forever, so EzReflex watches group members' health
-- and flags, keeps whether each was dead when it last looked and counts going from alive to dead as a death.
-- Its first look at someone never is one, nor is a feigned death or turning into a ghost.
---------------------------------------------------------------------------
local dead = {} -- key -> whether they were dead when last seen

-- Whether this unit is dead now, or nil when the game won't say.
local function IsDead(unit)
    local isDead = UnitIsDeadOrGhost(unit)
    if issecret(isDead) then return end
    if isDead and UnitIsFeignDeath then
        local feign = UnitIsFeignDeath(unit)
        if issecret(feign) then return end
        if feign then return false end
    end
    return isDead and true or false
end

local function RememberDeath(unit)
    local key = PlayerUnit(unit)
    local isDead = key and IsDead(unit)
    if isDead ~= nil then dead[key] = isDead end
end

local function OnUnitHealth(unit)
    if not GroupToken(unit) then return end
    local key, name = PlayerUnit(unit)
    if not key then return end
    local isDead = IsDead(unit)
    if isDead == nil then return end
    local was = dead[key]
    dead[key] = isDead -- the same person under two tokens (raid1 and party1) only counts once
    if not isDead or was ~= false or not Near(unit) then return end
    if Blocked(ns.DEATH, key, GetTime()) then return end
    local answers = ns.Answers(ns.DEATH, ns.Mood(key))
    if #answers == 0 then return end
    local answer, first = Pick(answers), FirstName(name)
    Answer(key, first, answer, format("You %s %s (they died).", Label(answer), first), true)
end

---------------------------------------------------------------------------
-- Questie's group announces. Questie sends real party/raid chat lines for objectives finished, quest-starting
-- items, quests taken, turned in and abandoned; EzReflex answers the ones from group members near you.
---------------------------------------------------------------------------
-- The group event token of a Questie announce line and the quest's name, or nil.
function ns.QuestieKind(text)
    local _, last = text:find(ns.QUESTIE_PREFIX)
    if not last then return end
    local rest = text:sub(last + 1)
    for _, rule in ipairs(ns.QUESTIE) do
        if rest:find(rule[2]) then
            return rule[1], rest:match(".*%[(.-)%]") or "a quest"
        end
    end
end

-- This person's unit in your group, or nil.
local function GroupUnit(key)
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, GetNumGroupMembers() do
        if PlayerUnit(prefix .. i) == key then return prefix .. i end
    end
end

local function OnQuestie(text, sender)
    if issecret(text) or issecret(sender) or type(text) ~= "string" or type(sender) ~= "string" then return end
    if sender == "" then return end
    local token, quest = ns.QuestieKind(text)
    if not token then return end
    local key = ns.Key(sender)
    if key == MyKey() then return end
    local unit = GroupUnit(key)
    if not unit or not Near(unit) then return end
    if Blocked(token, key, GetTime()) then return end
    local answers = ns.Answers(token, ns.Mood(key))
    if #answers == 0 then return end
    local answer, first = Pick(answers), FirstName(sender)
    Answer(key, first, answer, format("You %s %s (%s).", Label(answer), first,
        format(ns.events[token].echo, quest)), true)
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
local function Help()
    Print(format("%s, answering %d%% of emotes. Commands:", EzReflexDB.enabled and "On" or "Off", EzReflexDB.chance))
    Print("/reflex on|off - answer emotes or not")
    Print("/reflex chance <0-100> - how often you answer")
    Print("/reflex cd <sec> - between any two answers;  cd person <sec>;  cd pingpong <sec>")
    Print("/reflex list - what you answer to what")
    Print("/reflex set <emote> <answer1,answer2...>|default|none - this character's answers (set cold ... for rivals)")
    Print("/reflex toggle <emote> - switch answering one emote on or off (also levelup, death; Questie's objective, item, quest, abandon, accept)")
    Print("/reflex reset - drop this character's own answers")
    Print("/reflex test <emote or emote line> [name] - what you'd do, sends nothing")
    Print("/reflex quiet - hide or show the (Reflex) chat echo;  /reflex config - options")
end

local function List()
    Print("Incoming -> answers (repeats weigh more):")
    local function Line(token)
        local answers, from = ns.Answers(token)
        local line = format("%s -> %s", Label(token), #answers > 0 and Labels(answers) or "nothing")
        if from == "yours" then line = line .. " |cff7fd4ff(yours)|r" end
        if EzReflexDB.emotes[token] == false then line = "|cff808080" .. line .. " (off)|r" end
        if ns.WARM[token] and from ~= "yours" then line = line .. " |cff9d9d9dfriends: " .. Labels(Known(ns.WARM[token])) .. "|r" end
        Print(line)
    end
    for _, token in ipairs(ns.incoming) do Line(token) end
    for _, event in ipairs(ns.EVENTS) do Line(event.token) end
    Print("Rivals and enemies (EzAcquaintances): " .. Labels(Known(EzReflexCharDB.cold or ns.COLD)))
end
ns.List = List

local function ParseList(arg)
    local list, bad = {}, {}
    for word in arg:gmatch("[^,%s]+") do
        local token = ns.FindToken(word)
        if token then list[#list + 1] = token else bad[#bad + 1] = word end
    end
    return list, bad
end

local function Set(rest)
    local what, arg = rest:match("^(%S+)%s*(.*)$")
    if not what then return Print("Usage: /reflex set <emote> <answer1,answer2...>|default|none") end
    arg = Trim(arg):lower()
    local cold = what:lower() == "cold"
    local token = not cold and FindIncoming(what)
    if not cold and not token then return Print("No emote called " .. what .. ".") end
    if token and not ns.isIncoming[token] then
        return Print("EzReflex can't tell when someone does " .. Label(token) .. " at you, so it has nothing to answer.")
    end
    local function Store(v)
        if cold then EzReflexCharDB.cold = v else EzReflexCharDB.reactions[token] = v end
    end
    local name = cold and "rivals" or Label(token)
    if arg == "" then
        local answers, from = ns.Answers(token, cold and "cold" or nil)
        return Print(format("%s -> %s (%s).", name, Labels(answers), from))
    elseif arg == "default" then
        Store(nil)
        return Print(name .. " is back to the default answers.")
    elseif arg == "none" then
        Store({})
        return Print("This character won't answer " .. name .. ".")
    end
    local list, bad = ParseList(arg)
    if #bad > 0 then return Print("Unknown emote(s): " .. table.concat(bad, ", ") .. ". Nothing changed.") end
    Store(list)
    Print(format("%s -> %s (this character).", name, Labels(list)))
end

local function Test(rest)
    rest = Trim(rest)
    if rest == "" then return Print("Usage: /reflex test <emote or a line like \"Bob bows before you.\"> [name]") end
    local first, name = rest:match("^(%S+)%s*(%S*)$")
    local token = first and FindIncoming(first)
    local sender
    if token then
        sender = name ~= "" and name or nil
    else
        token = ns.QuestieKind(rest) -- a Questie line ("{rt1} Questie: Quest Completed: [Name]") names nobody
        if not token then
            sender = rest:match("^(%S+)")
            token = ns.Identify(rest, sender)
        end
        if not token then return Print("Not an emote aimed at you or a Questie line that EzReflex knows: \"" .. rest .. "\"") end
    end
    local key = sender and ns.Key(sender)
    local mood, why = nil, nil
    if key then mood, why = ns.Mood(key) end
    local answers, from = ns.Answers(token, mood)
    local event = ns.events[token]
    Print(format("%s -> %s (%s)%s.", event and event.what or Label(token) .. " at you",
        #answers > 0 and Labels(answers) or "nothing", from, mood and format(", %s is %s: %s", sender, mood, why) or ""))
    local reason = Blocked(token, key, GetTime())
    if #answers == 0 then
        Print("You wouldn't answer it.")
    elseif reason then
        Print("Right now you wouldn't answer: " .. reason .. ".")
    else
        local busy = event and StateBlocked(true) -- group events wait out moving, and always get an answer
        Print(format("Right now you'd answer %s %s%s. Nothing sent.", Label(Pick(answers)),
            busy and format("once you're free (%s; waits up to %ds)", busy, ns.EVENT_WAIT) or "after a short pause",
            event and "" or format(" (%d%% chance)", EzReflexDB.chance)))
    end
end

local function Cooldown(rest)
    local which, n = rest:lower():match("^(%a*)%s*(%d*%.?%d+)$")
    local field = ({ [""] = "cooldown", person = "personCooldown", pingpong = "pingPong" })[which or "x"]
    if not field then
        return Print(format("Cooldowns: %ds between answers, %ds per person, %ds ping-pong guard. " ..
            "Change with /reflex cd <sec>, cd person <sec>, cd pingpong <sec>.",
            EzReflexDB.cooldown, EzReflexDB.personCooldown, EzReflexDB.pingPong))
    end
    EzReflexDB[field] = math.min(600, tonumber(n))
    Print(format("%s set to %ds.", ({ cooldown = "Cooldown", personCooldown = "Per-person cooldown",
        pingPong = "Ping-pong guard" })[field], EzReflexDB[field]))
end

local COMMANDS = {
    on = function()
        EzReflexDB.enabled = true
        Print("On: you answer emotes aimed at you.")
    end,
    off = function()
        EzReflexDB.enabled = false
        Print("Off.")
    end,
    chance = function(rest)
        local n = tonumber(rest)
        if not n then return Print(format("You answer %d%% of emotes. Change with /reflex chance <0-100>.", EzReflexDB.chance)) end
        EzReflexDB.chance = math.max(0, math.min(100, math.floor(n + 0.5)))
        Print(format("You answer %d%% of emotes.", EzReflexDB.chance))
    end,
    cd = Cooldown,
    list = List,
    set = Set,
    toggle = function(rest)
        local token = FindIncoming(Trim(rest))
        if not token then return Print("Usage: /reflex toggle <emote>") end
        EzReflexDB.emotes[token] = EzReflexDB.emotes[token] == false
        Print(format("Answers to %s: %s.", Label(token), EzReflexDB.emotes[token] and "on" or "off"))
    end,
    reset = function()
        wipe(EzReflexCharDB.reactions)
        EzReflexCharDB.cold = nil
        Print("This character's own answers are gone; back to the defaults.")
    end,
    test = Test,
    quiet = function()
        EzReflexDB.echo = not EzReflexDB.echo
        Print("Chat echo " .. (EzReflexDB.echo and "on." or "off."))
    end,
    config = function()
        if ns.settingsCategory then Settings.OpenToCategory(ns.settingsCategory:GetID()) end
    end,
}

SLASH_EZREFLEX1 = "/reflex"
SLASH_EZREFLEX2 = "/ezreflex"
SlashCmdList.EZREFLEX = function(msg)
    msg = Trim(msg)
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    local fn = cmd and COMMANDS[cmd:lower()]
    if fn then return fn(rest) end
    Help()
end

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------
local questieChat = {}
for _, event in ipairs(ns.QUESTIE_CHANNELS) do questieChat[event] = true end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_TEXT_EMOTE" then
        local text, sender, _, _, _, _, _, _, _, _, _, guid = ...
        return OnTextEmote(text, sender, guid)
    elseif questieChat[event] then
        return OnQuestie(...)
    elseif event == "UNIT_LEVEL" then
        return OnUnitLevel(...)
    elseif event == "UNIT_HEALTH" or event == "UNIT_FLAGS" then
        return OnUnitHealth(...)
    elseif event == "PLAYER_TARGET_CHANGED" then
        return Remember("target")
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        ForGroup(Remember)
        return ForGroup(RememberDeath)
    end
    EzReflexDB = EzReflexDB or {}
    EzReflexCharDB = EzReflexCharDB or {}
    for k, v in pairs(ns.DEFAULTS) do
        if EzReflexDB[k] == nil then EzReflexDB[k] = v end
    end
    EzReflexDB.emotes = EzReflexDB.emotes or {}
    EzReflexCharDB.reactions = EzReflexCharDB.reactions or {}
    BuildCatalog()
    Compile()
    for token in pairs(ns.isIncoming) do
        if EzReflexDB.emotes[token] == nil then EzReflexDB.emotes[token] = true end
    end
    ns.BuildSettings()
    -- Level-ups and deaths don't depend on the client's language, and Questie's lines on the sender's, not yours.
    self:RegisterEvent("UNIT_LEVEL")
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("UNIT_FLAGS")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    for chat in pairs(questieChat) do pcall(self.RegisterEvent, self, chat) end
    if ns.LOCALES[GetLocale()] then
        self:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
    else
        Print("only knows English emote lines for now, so it only answers level-ups, deaths and Questie lines on this client.")
    end
end)
