# EzReflex

## v1.2.1

- Listed under **Roleplay** in the game's AddOns list, next to other roleplay addons.

## v1.2.0

- **Thanks whoever buffs you.** When another player buffs you (a blessing, Fortitude, Arcane Intellect...), your character thanks them with `/thank`, a bow, a nod or a salute; a friend (EzAcquaintances) may get a smile or a hug, a rival a grudging nod or a snub. Heals over time and shields don't count, it stays quiet in combat, and each person is thanked once every ten minutes. In Forever it sees buffs from your target, your group and players in sight; Classic Era sees any player in range. Switch it off with "Thank buffs" on the options page or `/reflex toggle buffed`; `/reflex set buffed <answers>` picks your own.

## v1.1.0

- **Quick off switch for RP scenes.** In the middle of a roleplay scene, an automatic `/cheer` or `/laugh` can ruin the mood. Turn EzReflex off in one press before the scene and back on after it: bind a key under Key Bindings > AddOns > EzReflex, type `/reflex toggle`, or click EzReflex in the addon drawer by the minimap (Forever; right-click opens the options). Off holds back every answer, level-ups, deaths, duels and quest cheers included, and drops one that was about to go out.

## v1.0.1

- **Works with EzAcquaintances 1.1.1.** EzAcquaintances now keeps people by their full name, so two players who share a first name no longer share a page. EzReflex now looks them up the same way, so your friends still get warm answers and your rivals cold ones, and the right Grim gets the right one.

## v1.0.0

- **Answer in kind.** When a player does a text emote at you (`/bow`, `/wave`, `/hug`, `/rude`...), your character answers with an emote of its own after a short, human-looking pause: a bow for a bow, a blush for a kiss, `/welcome` for a thanks, a rude gesture right back. About 55 emotes are recognised, each with a few answers picked at random.
- **Your character, your manners.** `/reflex set <emote> <answers>` gives this character its own answers (one can be polite, another rude); `/reflex list` shows them all, `/reflex reset` goes back to the defaults. Each emote can be switched off on the options page or with `/reflex toggle <emote>`.
- **Cheers level-ups.** When someone in your group, or your target, levels up near you, your character congratulates them (`/congratulate`, `/cheer`, `/applaud`; a friend may get a hug, a rival a `/golfclap`). It answers in combat too, and waits a few seconds while you move instead of missing it. Switch it off with "Cheer level-ups" on the options page or `/reflex toggle levelup`; `/reflex set levelup <answers>` picks your own. Strangers outside your group can't be seen levelling: the game doesn't tell addons.
- **Mourns the fallen.** When someone in your group dies near you, your character gasps, cries, sighs or salutes them; a friend gets your tears or a kneel, a rival your laughter. Like level-ups it answers in combat too and waits while you move; you stay quiet when you died as well. Switch it off with "Mourn the fallen" on the options page or `/reflex toggle death`; `/reflex set death <answers>` picks your own. Hunters feigning death don't count.
- **Cheers your group's quests.** When someone in your group runs Questie, EzReflex reads the announces it sends to party chat and answers the ones made near you. A finished objective gets a `/clap` or `/nod`, and a looted item that starts a quest gets a `/gasp`; Questie sends both by default. If the sender switches on Questie's other announces, a quest turned in gets a `/cheer`, an abandoned one a `/shrug`, and a new one a `/nod`. Switches are under "Your group" on the options page, or use `/reflex toggle objective|item|quest|abandon|accept`; `/reflex set quest <answers>` picks your own. You don't need Questie yourself. Only English Questie lines are recognised.
- **Good sport.** When you win a duel, your character bows, salutes or flexes at the loser. When you lose, it salutes or congratulates the winner, and when your foe runs off it clucks like a chicken at them. Duels you only watch get applause for the winner. With EzAcquaintances, a friend who loses is comforted instead and a rival who wins gets a `/golfclap`. EzReflex reads the game's own duel line, so this works on any client language. Switches are under "Your group and duels" on the options page, or use `/reflex toggle won|lost|fled|watch`. `/reflex set watch <answers>` picks your own answers. Turn off "Duels you watch" if you hang around busy duel spots.
- **Knows your friends.** With EzAcquaintances loaded, people tagged rival, enemy, suspicious or liar in your Book get a cold answer (`/glare`, `/snub`, `/rude`...), and friends, allies and family a warmer one.
- **Doesn't get carried away.** A cooldown between answers and per person, no answers to emotes in combat (level-ups, deaths, duels and quests still get one), none while dead or moving, a chance setting, and a ping-pong guard so two EzReflex users don't bow at each other forever. It only ever sends emotes, never chat text.
- `/reflex test <emote>` shows what you'd do and sends nothing; a quiet "(Reflex) You /bow back at Bob." chat echo tells you when it answered (`/reflex quiet` hides it). Options under Esc > Options > AddOns > EzReflex (`/reflex config`).
- English game clients only for now: the game doesn't give addons its emote lines, so EzReflex recognises them by their English wording.
