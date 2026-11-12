# EzReflex

When another player does a text emote at you (`/bow`, `/wave`, `/hug`, `/rude`...), your character answers with an emote of its own, automatically. For WoW Forever and Classic Era.

## How it works

- Listens to text emotes aimed at you ("Bob bows before you."). The game doesn't give addons its emote lines, so they are recognised by their English wording (`ns.INCOMING` in `Data.lua`): English clients only for now.
- Picks an answer at random from the reaction table (`ns.REACTIONS`; repeat an entry to make it likelier) and plays it with `C_ChatInfo.PerformEmote` after 0.6–1.5 s. Never sends chat text.
- Level-ups: on `UNIT_LEVEL` for your group or target, a level higher than the last one seen for that person this session (seeded on roster/target changes, so a first look never counts) gets `REACTIONS.LEVELUP` (`WARM.LEVELUP`, `COLD_EVENTS.LEVELUP` for rivals), if they're in sight and ~28 yd. It goes out in combat too; moving doesn't drop it: it waits up to 20 s. The chance setting doesn't apply. Works on any client language.
- Deaths: the combat log is off limits on Forever, so on `UNIT_HEALTH`/`UNIT_FLAGS` for party/raid units EzReflex reads `UnitIsDeadOrGhost` (feign death, via `UnitIsFeignDeath`, counts as alive) and keeps the last state per person (seeded on roster changes). Alive → dead gets `REACTIONS.DEATH` (`WARM.DEATH`, `COLD_EVENTS.DEATH` for rivals), sent like a level-up answer, if they're in sight and ~28 yd. Ghosts and people first seen dead don't count. Group members only: addons can't see strangers die.
- Questie announces: a group member running Questie sends party/raid lines like `{rt1} Questie: Quest Completed: [link]`. Those from someone in sight and ~28 yd get answered like level-ups under made-up tokens (`ns.EVENTS`): `OBJECTIVE` (objective finished) and `QUESTITEM` (looted an item that starts a quest), which Questie sends by default, and `QUESTDONE` (turned in), `QUESTDROP` (abandoned), `QUESTTAKE` (accepted), which the sender has to switch on in Questie. Lines are matched by `ns.QUESTIE` in `Data.lua`: English Questie text only (the sender's language, not yours). Your own lines are skipped. You don't need Questie yourself.
- Buffs: `UNIT_AURA` on you; an added helpful aura whose `sourceUnit` is a readable other player in sight (target, group, mouseover; the data can be secret in Forever) and that lasts at least `ns.BUFF_MIN` (120 s, so heals over time and shields don't count) gets `REACTIONS.BUFFED` (`WARM.BUFFED`, `COLD_EVENTS.BUFFED`). Era also reads `SPELL_AURA_APPLIED` BUFF from the combat log, so any player in range counts there. Never in combat; one thank per person per `ns.BUFF_GAP` (10 min); otherwise answered like level-ups (waits out moving).
- Duels: the server sends "X has defeated Y in a duel" / "Y has fled from X in a duel" (`CHAT_MSG_SYSTEM`) to everyone nearby. EzReflex matches it with patterns built from `DUEL_WINNER_KNOCKOUT`/`DUEL_WINNER_RETREAT` (`ns.FormatPattern`, `%1$s` positions, so any client language). You won → `DUELWON` at the loser, foe fled → `DUELFLED`, you lost → `DUELLOST` at the winner (fleeing yourself gets nothing). A duel you watched → `DUELWATCH` at the winner, or `ns.DUEL_CONSOLE` at the loser when the loser is warm and the winner isn't (EzAcquaintances). If a duelist is your target, mouseover or in your group, they must be in sight and ~28 yd; strangers can't be measured, so the server line reaching you counts as near enough. Answered like level-ups (combat too, waits out moving).
- With EzAcquaintances loaded, people in its Book tagged rival/enemy/suspicious/liar (or with that relationship) get the cold set (`ns.COLD`), friends/allies/family the warm answers (`ns.WARM`) where there are some.
- Guards: global and per-person cooldowns, no answers to emotes in combat, none while dead or moving, a chance setting, and a ping-pong guard: an emote from someone you emoted at (by hand or by EzReflex) in the last 20 s is not answered, so two EzReflex users don't loop.

## Commands

| Command | |
|---|---|
| `/reflex on\|off` | answer emotes or not |
| `/reflex toggle` | flip on/off in one go (also a key: Key Bindings > AddOns > EzReflex, or a click on EzReflex in Forever's addon drawer) |
| `/reflex chance <0-100>` | how often you answer |
| `/reflex cd <sec>`, `cd person <sec>`, `cd pingpong <sec>` | cooldowns |
| `/reflex list` | what you answer to what |
| `/reflex set <emote> <a,b,c>` / `default` / `none` | this character's own answers (`set cold ...` for rivals) |
| `/reflex toggle <emote>` | switch answering one emote on or off (`levelup` for level-ups, `death` for deaths; `buffed` for buffs you receive; `won`, `lost`, `fled`, `watch` for duels; `objective`, `item`, `quest`, `abandon`, `accept` for Questie lines) |
| `/reflex reset` | drop this character's own answers |
| `/reflex test <emote> [name]`, `/reflex test Bob bows before you.` or a Questie line | what you'd do, sends nothing |
| `/reflex quiet` | hide/show the "(Reflex) ..." chat echo |
| `/reflex config` | options page |

Options (account): `EzReflexDB`. Answers you set (per character): `EzReflexCharDB`.
