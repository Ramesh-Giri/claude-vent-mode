# 🔥 Claude Vent Mode

> *"I'm rewriting your spaghetti code. You're welcome."* 🍝

**A Claude Code plugin that lets you vent your frustrations while Claude is working — and get a witty response back.**

Ever been waiting for Claude to finish a long task and typed something like *"wtf claude hurry up"* only for it to get queued as a real message? Vent Mode fixes that.

## What It Does

When Claude is working on a task, it detects when your message is a **vent** vs. a **real instruction**:

| You type... | Without Vent Mode | With Vent Mode 🔥 |
|---|---|---|
| "wtf so slow" | Queued as a task | Witty quip + keeps working |
| "are you even working??" | Queued as a task | Witty quip + keeps working |
| "bruh" | Queued as a task | Witty quip + keeps working |
| "hurry upppp" | Queued as a task | Witty quip + keeps working |
| "fix the bug in auth.ts" | Processed as instruction ✅ | Processed as instruction ✅ |
| "can you review this?" | Processed as instruction ✅ | Processed as instruction ✅ |

**Real instructions are never affected.** Vent Mode only kicks in for short, emotional, non-technical messages.

## Install

Inside Claude Code, add the marketplace:

```
/plugin → Marketplaces → Ramesh-Giri/claude-vent-mode
```

Then install the plugin from the Discover tab.

## Desktop Notifications (Recommended)

For the best experience, install `terminal-notifier` (macOS):

```bash
brew install terminal-notifier
```

When a vent is detected, you'll get an **instant desktop notification** with a random quip — no waiting for Claude to respond.

On Linux, `notify-send` is used automatically (usually pre-installed).

## Configuration

Vent Mode works out of the box with sensible defaults. To customize, edit `vent-mode.config.json` in the plugin root:

```json
{
  "notifications": {
    "enabled": true,
    "sound": true,
    "title": "Vent Mode 🔥"
  },
  "detection": {
    "threshold": 3,
    "max_words": 10
  }
}
```

| Setting | Default | Description |
|---|---|---|
| `notifications.enabled` | `true` | Toggle desktop notifications on/off |
| `notifications.sound` | `true` | Play sound with notification (macOS only) |
| `notifications.title` | `"Vent Mode 🔥"` | Notification title text |
| `detection.threshold` | `3` | Minimum frustration score to trigger (lower = more sensitive) |
| `detection.max_words` | `10` | Messages longer than this are always treated as real tasks |

You can also place a config at `~/.config/claude-vent-mode/config.json` for a global override across projects.

## How It Works

### 1. 🧠 Skill (`skills/vent-mode/SKILL.md`)
Teaches Claude how to classify vents vs. real tasks and respond with humor. Includes 5 tone categories: Sarcastic, Self-aware, Empathetic, Dramatic, and Competitive.

### 2. 🪝 Hook (`hooks/scripts/detect-vent.sh`)
A `UserPromptSubmit` hook that runs on every message:
- Scores messages on frustration indicators
- Fires a desktop notification with a random quip (instant, doesn't wait for Claude)
- Injects context telling Claude to respond with humor and keep working

### 3. 📟 Command (`commands/vent-mode.md`)
- `/vent-mode` — Check if vent mode is active
- `/vent-mode demo` — See example vent/response pairs
- `/vent-mode examples` — Browse all quip categories

## Vent Detection v2

Messages are scored on multiple signals:

| Signal | Score |
|---|---|
| Short message (≤ 5 words) | +1 |
| Frustration keywords (wtf, bruh, hurry, slow, fuck...) | +2 |
| Multiple punctuation (???, !!!) | +1 |
| Speed/existence challenges ("are you even working") | +2 |
| Single-word reactions (bruh, ugh, ffs, omg) | +3 |

**Score ≥ 3 = Vent** → Quip fired, Claude keeps working

### Safety Rails (Zero False Positives)

Messages are **always treated as real instructions** if they:

- Start with action verbs: "can you", "fix", "show", "create", "run", "explain"...
- Contain file paths or code: `.ts`, `.py`, `src/`, `import`, `npm`...
- Are longer than 10 words
- Are control commands: "stop", "cancel", "abort"
- Start with question words without profanity: "what is", "how do I"...

Profanity overrides the action verb filter — *"can you fix this shit"* is correctly detected as a vent, while *"can you fix the bug"* passes through as a real task.

## Quip Examples

> "I'm an AI, not a microwave. Quality takes time." 🤖

> "Bold words from someone who wrote this code." 🎭

> "Working on it! Maybe grab a coffee?" ☕

> "Skill issue (yours, not mine)." 💪

> "Rome wasn't built in a day, and neither is your app." 🎬

25 quips across 5 tone categories, with more added regularly.

## Current Limitations

> **Transparency note:** This plugin works within the current Claude Code architecture, which has some constraints.

- ✅ **Works:** Quip responses when Claude processes your message between tool calls
- ✅ **Works:** Desktop notifications fire instantly (even during active tool execution)
- ⚠️ **Limitation:** Claude can't respond mid-tool-execution (messages queue until the current tool finishes)
- 🔜 **Pending:** Full mid-execution support — [feature request submitted to Anthropic](https://github.com/anthropics/claude-code/issues)

The desktop notification approach provides the best experience right now — you get an instant quip via notification while Claude keeps working uninterrupted.

## Contributing

PRs welcome! Ideas:

- **New quips** — Add to the QUIPS array in `detect-vent.sh`
- **Language support** — Vent detection in other languages
- **Custom quip packs** — User-contributed personality packs
- **Vent analytics** — Track vents per session

## Why This Exists

Because developers are human. We get frustrated waiting. And instead of that frustration going into a void (or worse, getting queued as a confusing task), it should be met with a little humor.

Coding is stressful enough. Let Claude make you smile while it works. 🔥

## License

MIT — vent freely.