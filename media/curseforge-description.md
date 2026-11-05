# EzReflex

*Good manners, on autopilot.*

Someone bows to you outside the bank. By the time you've found `/bow` in your head, typed it and hit Enter, they've mounted up and left, and your character bows politely at an empty street.

**EzReflex** gives your character reflexes. When another player does a text emote at you, your character answers with an emote of its own, after a short pause that looks human. A bow gets a bow, a wave gets a wave, a kiss gets a blush, and a rude gesture gets one right back.

> **Bob bows before you.**
> *a second later*
> **You bow before Bob.**

Nobody else needs the addon. Everyone just sees two very polite adventurers.

## What it answers

About 55 emotes, each with a few answers picked at random so you don't sound like a machine:

- **Greetings:** wave, hello, hail, greet, introduce, bye
- **Courtesy:** bow, curtsey, kneel, salute, thank, welcome, applaud, cheer, congratulate
- **Affection:** hug, cuddle, kiss, flirt, wink, love, holding hands
- **Fun:** dance (you dance back), high five, tickle, giggle, poke, pat
- **Trouble:** rude, spit, slap, insult, threaten, mock, taunt, chicken, glare, growl, roar

Don't like an answer? `/reflex set kiss blush, wink` gives this character its own, so your paladin can be a gentleman and your rogue can be... less so. `/reflex toggle <emote>` switches one off completely.

## Your group

EzReflex also keeps an eye on the people around you:

- **Level-ups.** When someone in your group, or your target, levels up near you, your character congratulates, cheers or applauds them.
- **Deaths.** When someone in your group dies near you, your character gasps, cries or salutes them. Hunters playing dead don't count.
- **Duels.** Win, and you bow or salute the loser. Lose, and you salute the winner. Your foe runs away? You cluck like a chicken at them. Watching someone else's duel? You applaud the winner.
- **Questie.** When a group member runs Questie, your character cheers their finished objectives and gasps at a quest item they found. If they share more, you cheer turned-in quests and shrug at abandoned ones. You don't need Questie yourself.

These go out in combat too, and wait a few seconds while you're moving instead of being missed. Each one has its own switch on the options page.

## Friends and rivals

With **EzAcquaintances** loaded, EzReflex knows who people are to you. Someone tagged rival, enemy, suspicious or liar in your Book gets a cold answer: a glare, a snub, an eye roll. Friends, allies and family get a warmer one, like a hug. Watch a friend lose a duel to a stranger and your character comforts the friend instead of cheering the stranger. A rival who wins gets a slow golf clap.

## It knows when to stop

- A short cooldown between answers, and a longer one per person.
- No answers to emotes in combat, while you're dead, or while you're running.
- A chance setting if you'd like your character to answer only some of the time.
- A ping-pong guard, so two EzReflex users don't bow at each other forever.
- It only ever does emotes. It never types a word in chat for you.

A small "(Reflex) You /bow back at Bob." line in your chat tells you when it answered (`/reflex quiet` hides it). `/reflex test bow` shows what you'd do without doing it.

## Good to know

- **English game clients only for now.** The game doesn't give addons its emote lines, so EzReflex recognises them by their English wording. Duels work on any language.
- The game doesn't tell addons when strangers outside your group level up or die, so those answers are for your group (and your target, for level-ups).
- **WoW Forever and Classic Era**, from one download.

## Commands

`/reflex` or `/ezreflex`

| Command | Does |
|---|---|
| `/reflex on` / `off` | Answer emotes or not |
| `/reflex chance <0-100>` | How often you answer |
| `/reflex cd <sec>` | Seconds between any two answers (`cd person`, `cd pingpong` for the others) |
| `/reflex list` | What you answer to what |
| `/reflex set <emote> <answers>` | This character's own answers (`set cold ...` for rivals, `default` to go back) |
| `/reflex toggle <emote>` | Switch one emote off or on (`levelup`, `death`, `won`, `lost`, `fled`, `watch`, `objective`, `item`, `quest`, `abandon`, `accept` for group events) |
| `/reflex reset` | Drop this character's own answers |
| `/reflex test <emote>` | What you'd do, without doing it |
| `/reflex quiet` | Hide or show the chat line |
| `/reflex config` | The options (Esc > Options > AddOns > EzReflex) |

## Tell us what you think!

Is there an emote your character should answer and doesn't? An answer that feels wrong? Playing in another language and want to help EzReflex understand it? **Leave a comment or open an issue on [GitHub](https://github.com/lalibertemarc/EzReflex/issues)** and it might be in the next update.
