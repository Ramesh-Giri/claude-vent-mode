# 🔥 Claude Vent Mode

> *"I'm rewriting your spaghetti code. You're welcome."* 🍝

**A Claude Code plugin that lets you vent your frustrations while Claude is working — and actually get a witty response back.**

Ever been waiting for Claude to finish a long task and typed something like *"wtf claude hurry up"* only for it to get queued as a real message? Vent Mode fixes that.

## What It Does

When Claude is actively working on a task (editing files, running commands, refactoring code), it detects when your message is a **vent** vs. a **real instruction**:

| You type... | Without Vent Mode | With Vent Mode 🔥 |
|---|---|---|
| "wtf so slow" | Queued as a task | *"My CPU has feelings too, you know."* |
| "are you even working??" | Queued as a task | *"I'm literally editing 47 files. What are YOU doing?"* |
| "bruh" | Queued as a task | *"Skill issue (yours, not mine). 💪"* |
| "hurry upppp" | Queued as a task | *"You want it done, or you want it done RIGHT?"* |
| "actually use TypeScript" | Processed as instruction ✅ | Processed as instruction ✅ |

**Real instructions are never affected.** Vent Mode only kicks in for short, emotional, non-technical messages.

## Install

Inside Claude Code, run:

```
/plugin add github.com/Ramesh-Giri/claude-vent-mode
```

That's it. Vent Mode activates automatically on every session.

## How It Works

The plugin has three components:

### 1. 🧠 Skill (`skills/vent-mode/SKILL.md`)
Teaches Claude how to classify vents vs. real tasks and respond with humor. Includes:
- Detection heuristics (message length, keywords, emotional tone)
- 5 tone categories: Sarcastic, Self-aware, Empathetic, Dramatic, Competitive
- Escalation rules (consecutive vents get sassier responses)
- Edge case handling

### 2. 🪝 Hook (`hooks/hooks.json` + `hooks/scripts/detect-vent.sh`)
A `UserPromptSubmit` hook that pre-classifies every incoming message:
- Runs a lightweight bash script (< 5ms) on each message
- Scores messages on frustration indicators (keywords, length, punctuation, emojis)
- Tags likely vents with a system message so Claude's skill knows to activate
- **Never blocks or modifies real messages**

### 3. 📟 Command (`commands/vent-mode.md`)
The `/vent-mode` slash command for:
- `/vent-mode` or `/vent-mode status` — Check if vent mode is active
- `/vent-mode demo` — See example vent/response pairs
- `/vent-mode examples` — Browse all quip categories

## Architecture

```
claude-vent-mode/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── skills/
│   └── vent-mode/
│       └── SKILL.md             # Core vent detection + response behavior
├── hooks/
│   ├── hooks.json               # Hook configuration (UserPromptSubmit + SessionStart)
│   └── scripts/
│       └── detect-vent.sh       # Lightweight vent classifier script
├── commands/
│   └── vent-mode.md             # /vent-mode slash command
├── LICENSE
└── README.md
```

## Vent Detection

Messages are scored on multiple signals:

| Signal | Score |
|---|---|
| Short message (≤ 20 words) | +1 |
| Frustration keywords (wtf, bruh, hurry, slow...) | +2 |
| Emoji reactions (💀😤🤦😭) | +2 |
| Very short + non-technical (≤ 5 words) | +1 |
| Multiple ?! punctuation | +1 |
| Speed challenges ("are you even working") | +1 |

**Score ≥ 3 = Vent** → Claude responds with humor
**Score < 3 = Real message** → Processed normally

### Safety Rails
- **"stop", "cancel", "abort"** → Always treated as real commands, never as vents
- **Messages with file paths, code, or technical terms** → Always real
- **Messages > 25 words with substance** → Always real
- **When in doubt** → Treated as real (never dismisses a genuine instruction)

## Quip Categories

**Sarcastic 🎭**
> "Bold words from someone who wrote this code."

**Self-aware 🤖**
> "I'm an AI, not a microwave. Quality takes time."

**Empathetic 💙**
> "I know, I know. Hang tight — almost there."

**Dramatic 🎬**
> "Rome wasn't built in a day, and neither is your app."

**Competitive 💪**
> "Race me then. Oh wait, you can't type that fast."

## Escalation

Consecutive vents in the same session get progressively funnier:

1. **1st vent:** Light quip
2. **2nd vent:** Slightly sassier
3. **3rd+ vent:** Full dramatic mode — *"Okay at this point I think YOU need a reboot, not me."*

## Configuration

Vent Mode runs automatically with zero config. The skill has `autoActivate: true` so it loads on every session.

To temporarily disable it, you can uninstall the plugin:
```
/plugin remove claude-vent-mode
```

## Contributing

Want to add more quips, improve detection, or add new tone categories? PRs are welcome!

Ideas for contributions:
- **New quip categories** (nerdy, movie references, developer-specific)
- **Localization** (vent detection in other languages)
- **Vent analytics** (track how many times you vented per session 😂)
- **Custom quip packs** (user-contributed personality packs)
- **Vent leaderboard** (competitive venting across your team)

## Why This Exists

Because developers are human. We get frustrated waiting. And instead of that frustration going into a void (or worse, getting queued as a confusing task), it should be met with a little humor.

Coding is stressful enough. Let Claude make you smile while it works. 🔥

## License

MIT — vent freely.
