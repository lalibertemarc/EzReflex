-- EzReflex static data: how to recognise an emote aimed at you, what to answer, guard timings.
local _, ns = ...

ns.ERA = select(4, GetBuildInfo()) < 16000

ns.DEFAULTS = {
    enabled = true,
    chance = 100,          -- % of emotes you answer
    cooldown = 8,          -- seconds between any two answers
    personCooldown = 30,   -- seconds before you answer the same person again
    pingPong = 20,         -- ignore someone's emote this soon after you emoted at them (stops two EzReflex users looping)
    combat = true,         -- stay quiet in combat
    moving = true,         -- stay quiet while moving (most emotes don't animate on the run)
    echo = true,           -- "(Reflex) You /bow back at Bob." in your chat
    acquaintances = true,  -- warm/cold answers from EzAcquaintances tags, when it's loaded
}

ns.DELAY_MIN, ns.DELAY_MAX = 0.6, 1.5 -- seconds before answering, picked at random so it looks human
ns.HEARD_TIME = 120                    -- seconds someone stays "recent" after emoting at you (for the ping-pong guard)

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
}

-- EzAcquaintances (optional, read only): people in your Book with these tags or relationships get the cold set
-- for anything they do; warm people get WARM's answers where there are some, the normal ones otherwise.
-- Cold wins when someone is both.
ns.COLD_TAGS = { rival = true, enemy = true, suspicious = true, liar = true }
ns.COLD_RELS = { rival = true, enemy = true }
ns.WARM_TAGS = { friend = true, ally = true, family = true, flirt = true }
ns.WARM_RELS = { friend = true, ["close friend"] = true, ally = true, family = true, sweetheart = true }

ns.COLD = { "GLARE", "GLARE", "SNUB", "ROLLEYES", "SCOFF", "RUDE" }

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
}
