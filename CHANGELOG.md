# EzReflex

## Unreleased

- **Answer in kind.** When a player does a text emote at you (`/bow`, `/wave`, `/hug`, `/rude`...), your character answers with an emote of its own after a short, human-looking pause: a bow for a bow, a blush for a kiss, `/welcome` for a thanks, a rude gesture right back. About 55 emotes are recognised, each with a few answers picked at random.
- **Your character, your manners.** `/reflex set <emote> <answers>` gives this character its own answers (one can be polite, another rude); `/reflex list` shows them all, `/reflex reset` goes back to the defaults. Each emote can be switched off on the options page or with `/reflex toggle <emote>`.
- **Knows your friends.** With EzAcquaintances loaded, people tagged rival, enemy, suspicious or liar in your Book get a cold answer (`/glare`, `/snub`, `/rude`...), and friends, allies and family a warmer one.
- **Doesn't get carried away.** A cooldown between answers and per person, nothing in combat, while dead or moving, a chance setting, and a ping-pong guard so two EzReflex users don't bow at each other forever. It only ever sends emotes, never chat text.
- `/reflex test <emote>` shows what you'd do and sends nothing; a quiet "(Reflex) You /bow back at Bob." chat echo tells you when it answered (`/reflex quiet` hides it). Options under Esc > Options > AddOns > EzReflex (`/reflex config`).
- English game clients only for now: the game doesn't give addons its emote lines, so EzReflex recognises them by their English wording.
