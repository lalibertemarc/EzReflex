-- EzReflex static data: how to recognise an emote aimed at you, what to answer, guard timings.
local _, ns = ...

ns.ERA = select(4, GetBuildInfo()) < 16000

ns.DEFAULTS = {
    enabled = true,
    chance = 100,          -- % of emotes you answer
    cooldown = 8,          -- seconds between any two answers
    personCooldown = 30,   -- seconds before you answer the same person again
    pingPong = 20,         -- ignore someone's emote this soon after you emoted at them (stops two EzReflex users looping)
    combat = true,         -- stay quiet in combat (emotes only; group events answer anyway)
    moving = true,         -- stay quiet while moving (most emotes don't animate on the run)
    echo = true,           -- "(Reflex) You /bow back at Bob." in your chat
    acquaintances = true,  -- warm/cold answers from EzAcquaintances tags, when it's loaded
}

ns.DELAY_MIN, ns.DELAY_MAX = 0.6, 1.5 -- seconds before answering, picked at random so it looks human
ns.HEARD_TIME = 120                    -- seconds someone stays "recent" after emoting at you (for the ping-pong guard)
ns.EVENT_WAIT = 20                     -- seconds an answer to a group event waits for you to stop moving

-- Group events: things that happen near you rather than emotes at you, answered like emotes under made-up
-- tokens. Each has its own on/off switch in EzReflexDB.emotes and answers set with /reflex set <any of
-- names> ...; they're answered in combat too, wait out moving, and the chance setting doesn't apply.
-- echo: what they did, for the chat echo (%s = the quest).
ns.LEVELUP = "LEVELUP"
ns.EVENTS = {
    { token = "LEVELUP", label = "level-ups", names = { "levelup", "level", "ding" },
      what = "A level-up in your group or target", title = "Cheer level-ups",
      tip = "When someone in your group, or your target, levels up near you, your character congratulates them (/congratulate, /cheer...). Change the answers with /reflex set levelup <answers>." },
    { token = "OBJECTIVE", label = "objectives done", names = { "objective" }, echo = "finished an objective of %s",
      what = "A group member finishing a quest objective (Questie)", title = "Quest objectives (Questie)",
      tip = "When someone in your group running Questie finishes a quest objective near you, your character claps or nods. Questie sends these to your party unless they switched it off. Change the answers with /reflex set objective <answers>." },
    { token = "QUESTITEM", label = "quest items found", names = { "questitem", "item" }, echo = "found an item that starts %s",
      what = "A group member looting an item that starts a quest (Questie)", title = "Quest-starting items (Questie)",
      tip = "When someone in your group running Questie loots an item that starts a quest near you, your character gasps or nods. Questie sends these to your party unless they switched it off. Change the answers with /reflex set item <answers>." },
    { token = "QUESTDONE", label = "quests done", names = { "questdone", "quest", "complete" }, echo = "turned in %s",
      what = "A group member turning in a quest (Questie)", title = "Cheer finished quests (Questie)",
      tip = "When someone in your group running Questie turns in a quest near you, your character cheers them. They have to switch on Questie's \"Quest completed\" announce. Change the answers with /reflex set quest <answers>." },
    { token = "QUESTDROP", label = "quests dropped", names = { "questdrop", "abandon" }, echo = "abandoned %s",
      what = "A group member abandoning a quest (Questie)", title = "Quests abandoned (Questie)",
      tip = "When someone in your group running Questie abandons a quest near you, your character shrugs or sighs. They have to switch on Questie's \"Quest abandoned\" announce. Change the answers with /reflex set abandon <answers>." },
    { token = "QUESTTAKE", label = "quests taken", names = { "questtake", "accept" }, echo = "took %s",
      what = "A group member taking a quest (Questie)", title = "Quests taken (Questie)",
      tip = "When someone in your group running Questie accepts a quest near you, your character nods. They have to switch on Questie's \"Quest accepted\" announce. Change the answers with /reflex set accept <answers>." },
}

-- Questie's group announces are plain party/raid chat: "{rt1} Questie: Quest Completed: [link]". Questie
-- sends objectives and quest-starting items by default; completed/accepted/abandoned only when the sender
-- switches them on. The marker is {rt1} ({звезда} from ruRU, "Questie :" from frFR); the rest is in the
-- sender's language, and only English is known here. First match wins.
ns.QUESTIE_PREFIX = "^{[^}]+}%s*Questie%s?:%s*"
ns.QUESTIE = {
    { "QUESTDONE", "^Quest Completed:" },
    { "QUESTTAKE", "^Quest Accepted:" },
    { "QUESTDROP", "^Quest Abandoned:" },
    { "QUESTITEM", "^Picked up " }, -- "Picked up [item] which starts [link]!"
    { "OBJECTIVE", " for .+!$" }, -- "Kobold Vermin slain: 10/10 for [link]!"
}
-- Instance chat may not exist on every client; those are registered under pcall.
ns.QUESTIE_CHANNELS = {
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
}

-- The client has no Lua strings for "%s bows before you." (they come from the server's emote text data, not
-- GlobalStrings), so incoming emotes are recognised by these English phrases, first match wins. Each phrase
-- must appear as whole words in the line, with the sender's name taken out and "you"/"your" somewhere in it.
-- Order matters where one phrase hides inside another ("waves goodbye" before "waves").
ns.LOCALES = { enUS = true, enGB = true }
ns.INCOMING = {
    { "GOLFCLAP", "unimpressed" },
    { "BYE", "waves goodbye", "farewell" },
    { "WAVE", "waves" },
    { "HELLO", "hearty hello" },
    { "GREET", "greets" },
    { "HAIL", "hails" },
    { "INTRODUCE", "introduces" },
    { "BOW", "bows" },
    { "CURTSEY", "curtsies", "curtseys" },
    { "KNEEL", "kneels" },
    { "SALUTE", "salutes" },
    { "HUG", "hugs" },
    { "CUDDLE", "cuddles" },
    { "KISS", "kiss", "kisses" },
    { "LOVE", "loves" },
    { "FLIRT", "flirts" },
    { "WINK", "winks" },
    { "HOLDHAND", "holds your hand" },
    { "CHEER", "cheers" },
    { "APPLAUD", "applauds", "bravo" },
    { "CLAP", "claps" },
    { "CONGRATULATE", "congratulates" },
    { "PRAISE", "praise", "praises" },
    { "COMMEND", "commends" },
    { "THANK", "thanks" },
    { "WELCOME", "welcomes" },
    { "DANCE", "dances" },
    { "HIGHFIVE", "high five", "high-five" },
    { "ROFL", "rolls on the floor" },
    { "LAUGH", "laughs" },
    { "GIGGLE", "giggles" },
    { "SMILE", "smiles" },
    { "NOD", "nods" },
    { "POKE", "pokes" },
    { "TICKLE", "tickles" },
    { "PAT", "pats" },
    { "RUDE", "rude gesture" },
    { "SPIT", "spits" },
    { "SLAP", "slaps" },
    { "INSULT", "motherless ogre", "insults" },
    { "THREATEN", "threatens" },
    { "GLARE", "glares" },
    { "GROWL", "growls" },
    { "ROAR", "roars" },
    { "MOCK", "mocks" },
    { "TAUNT", "taunts", "taunting" },
    { "CHICKEN", "clucks" },
    { "FLEX", "flexes" },
    { "SHOO", "shoos" },
    { "BONK", "bonks" },
    { "BEG", "begs" },
    { "CRY", "cries" },
    { "SOOTHE", "soothes" },
    { "COMFORT", "comforts" },
    { "APOLOGIZE", "apologizes" },
    { "SNUB", "snubs" },
}

-- Incoming emote -> answers. A random entry is picked, so repeat one to make it likelier.
-- Answers are emote tokens; ones this client doesn't have are left out at login.
-- /reflex set <emote> <answers> overrides them per character (EzReflexCharDB.reactions).
ns.REACTIONS = {
    BOW = { "BOW", "BOW", "BOW", "NOD" },
    CURTSEY = { "BOW" },
    KNEEL = { "BOW", "BLUSH" },
    SALUTE = { "SALUTE" },
    WAVE = { "WAVE", "WAVE", "HELLO" },
    HELLO = { "HELLO", "WAVE" },
    GREET = { "GREET", "WAVE" },
    HAIL = { "HAIL", "SALUTE" },
    BYE = { "BYE", "WAVE" },
    INTRODUCE = { "GREET", "BOW" },
    HUG = { "HUG", "HUG", "BLUSH" },
    CUDDLE = { "HUG", "BLUSH" },
    KISS = { "BLUSH", "BLUSH", "KISS" },
    LOVE = { "BLUSH", "SMILE" },
    FLIRT = { "BLUSH", "GIGGLE", "WINK" },
    WINK = { "WINK", "SMILE", "BLUSH" },
    HOLDHAND = { "BLUSH", "SMILE" },
    SMILE = { "SMILE" },
    CHEER = { "BOW", "BOW", "CHEER" },
    APPLAUD = { "BOW", "THANK" },
    CLAP = { "BOW" },
    GOLFCLAP = { "SHRUG", "GLARE" },
    CONGRATULATE = { "THANK", "BOW" },
    PRAISE = { "BLUSH", "BOW", "THANK" },
    COMMEND = { "THANK", "BOW" },
    THANK = { "WELCOME" },
    WELCOME = { "THANK", "BOW" },
    DANCE = { "DANCE" },
    HIGHFIVE = { "HIGHFIVE" },
    LAUGH = { "SHRUG", "GLARE", "LAUGH" },
    ROFL = { "GLARE", "SIGH" },
    GIGGLE = { "SMILE", "WINK" },
    NOD = { "NOD" },
    POKE = { "GLARE", "SIGH", "POKE" },
    TICKLE = { "GIGGLE", "LAUGH" },
    PAT = { "SMILE", "BLUSH" },
    RUDE = { "RUDE", "SPIT" },
    SPIT = { "SPIT", "RUDE", "GLARE" },
    SLAP = { "GASP", "GLARE", "SLAP" },
    INSULT = { "RUDE", "INSULT", "GLARE" },
    THREATEN = { "GLARE", "LAUGH", "THREATEN" },
    GLARE = { "GLARE", "SHRUG" },
    GROWL = { "GROWL", "COWER" },
    ROAR = { "ROAR", "COWER" },
    MOCK = { "GLARE", "RUDE" },
    TAUNT = { "FLEX", "LAUGH" },
    CHICKEN = { "FLEX", "GLARE" },
    FLEX = { "APPLAUD", "LAUGH" },
    SHOO = { "GLARE", "RUDE" },
    BONK = { "GLARE", "CRY" },
    BEG = { "SIGH", "PITY" },
    CRY = { "COMFORT", "HUG" },
    SOOTHE = { "THANK", "SMILE" },
    COMFORT = { "THANK", "HUG" },
    APOLOGIZE = { "NOD", "SHRUG" },
    SNUB = { "SHRUG", "SNUB" },
    LEVELUP = { "CONGRATULATE", "CONGRATULATE", "CHEER", "APPLAUD" },
    QUESTDONE = { "CHEER", "CHEER", "CONGRATULATE", "APPLAUD" },
    QUESTDROP = { "SHRUG", "SHRUG", "SIGH", "PITY" },
    QUESTTAKE = { "NOD", "NOD", "READY" },
    OBJECTIVE = { "CLAP", "NOD", "CHEER" },
    QUESTITEM = { "GASP", "NOD", "CHEER" },
}

-- EzAcquaintances (optional, read only): people in your Book with these tags or relationships get the cold set
-- for anything they do; warm people get WARM's answers where there are some, the normal ones otherwise.
-- Cold wins when someone is both.
ns.COLD_TAGS = { rival = true, enemy = true, suspicious = true, liar = true }
ns.COLD_RELS = { rival = true, enemy = true }
ns.WARM_TAGS = { friend = true, ally = true, family = true, flirt = true }
ns.WARM_RELS = { friend = true, ["close friend"] = true, ally = true, family = true, sweetheart = true }

ns.COLD = { "GLARE", "GLARE", "SNUB", "ROLLEYES", "SCOFF", "RUDE" }
-- A rival's group events, unless you set your own cold set.
ns.COLD_EVENTS = {
    LEVELUP = { "GOLFCLAP", "GOLFCLAP", "SHRUG" },
    QUESTDONE = { "GOLFCLAP", "GOLFCLAP", "SHRUG" },
    QUESTDROP = { "LAUGH", "GOLFCLAP" },
    QUESTTAKE = { "SHRUG" },
    OBJECTIVE = { "GOLFCLAP", "SHRUG" },
    QUESTITEM = { "SHRUG" },
}

ns.WARM = {
    BOW = { "BOW", "SMILE" },
    WAVE = { "WAVE", "HELLO", "HUG" },
    HELLO = { "HELLO", "HUG" },
    HUG = { "HUG", "HUG", "CUDDLE" },
    POKE = { "GIGGLE", "POKE", "TICKLE" },
    LAUGH = { "LAUGH", "GIGGLE" },
    RUDE = { "LAUGH", "RUDE" },
    INSULT = { "LAUGH", "RUDE" },
    SLAP = { "GASP", "CRY" },
    BYE = { "BYE", "HUG" },
    LEVELUP = { "CHEER", "CONGRATULATE", "HUG" },
    QUESTDONE = { "CHEER", "HIGHFIVE", "HUG" },
    QUESTDROP = { "COMFORT", "SHRUG" },
}
