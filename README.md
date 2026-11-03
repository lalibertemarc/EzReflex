# EzReflex

When another player does a text emote at you (`/bow`, `/wave`, `/hug`, `/rude`...), your character answers with an emote of its own, automatically. For WoW Forever and Classic Era.

## How it works

- Listens to text emotes aimed at you ("Bob bows before you."). The game doesn't give addons its emote lines, so they are recognised by their English wording (`ns.INCOMING` in `Data.lua`): English clients only for now.
- Picks an answer at random from the reaction table (`ns.REACTIONS`; repeat an entry to make it likelier) and plays it with `C_ChatInfo.PerformEmote` after 0.6–1.5 s. Never sends chat text.
- Level-ups: on `UNIT_LEVEL` for your group or target, a level higher than the last one seen for that person this session (seeded on roster/target changes, so a first look never counts) gets `REACTIONS.LEVELUP` (`WARM.LEVELUP`, `COLD_EVENTS.LEVELUP` for rivals), if they're in sight and ~28 yd. It goes out in combat too; moving doesn't drop it: it waits up to 20 s. The chance setting doesn't apply. Works on any client language.
- Questie announces: a group member running Questie sends party/raid lines like `{rt1} Questie: Quest Completed: [link]`. Those from someone in sight and ~28 yd get answered like level-ups under made-up tokens (`ns.EVENTS`): `OBJECTIVE` (objective finished) and `QUESTITEM` (looted an item that starts a quest), which Questie sends by default, and `QUESTDONE` (turned in), `QUESTDROP` (abandoned), `QUESTTAKE` (accepted), which the sender has to switch on in Questie. Lines are matched by `ns.QUESTIE` in `Data.lua`: English Questie text only (the sender's language, not yours). Your own lines are skipped. You don't need Questie yourself.
- With EzAcquaintances loaded, people in its Book tagged rival/enemy/suspicious/liar (or with that relationship) get the cold set (`ns.COLD`), friends/allies/family the warm answers (`ns.WARM`) where there are some.
- Guards: global and per-person cooldowns, no answers to emotes in combat, none while dead or moving, a chance setting, and a ping-pong guard: an emote from someone you emoted at (by hand or by EzReflex) in the last 20 s is not answered, so two EzReflex users don't loop.

## Commands

| Command | |
|---|---|
| `/reflex on\|off` | answer emotes or not |
| `/reflex chance <0-100>` | how often you answer |
| `/reflex cd <sec>`, `cd person <sec>`, `cd pingpong <sec>` | cooldowns |
| `/reflex list` | what you answer to what |
| `/reflex set <emote> <a,b,c>` / `default` / `none` | this character's own answers (`set cold ...` for rivals) |
| `/reflex toggle <emote>` | switch answering one emote on or off (`levelup` for level-ups; `objective`, `item`, `quest`, `abandon`, `accept` for Questie lines) |
| `/reflex reset` | drop this character's own answers |
| `/reflex test <emote> [name]`, `/reflex test Bob bows before you.` or a Questie line | what you'd do, sends nothing |
| `/reflex quiet` | hide/show the "(Reflex) ..." chat echo |
| `/reflex config` | options page |

Options (account): `EzReflexDB`. Answers you set (per character): `EzReflexCharDB`.
