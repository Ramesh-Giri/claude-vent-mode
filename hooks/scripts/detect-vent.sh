#!/bin/bash
# detect-vent.sh v2.0
# Vent detection with desktop notification support
# Part of claude-vent-mode plugin
# https://github.com/Ramesh-Giri/claude-vent-mode

input=$(cat)

# ============================================================
# LOAD CONFIG
# ============================================================
# Config search order: repo root → ~/.config/claude-vent-mode → defaults
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CONFIG_FILE=""
if [ -f "$PLUGIN_ROOT/vent-mode.config.json" ]; then
  CONFIG_FILE="$PLUGIN_ROOT/vent-mode.config.json"
elif [ -f "$HOME/.config/claude-vent-mode/config.json" ]; then
  CONFIG_FILE="$HOME/.config/claude-vent-mode/config.json"
fi

# Defaults
NOTIFY_ENABLED=true
NOTIFY_SOUND=true
NOTIFY_TITLE="Vent Mode 🔥"
VENT_THRESHOLD=3
MAX_WORDS=10

# Parse config if found and jq available
if [ -n "$CONFIG_FILE" ] && command -v jq &>/dev/null; then
  NOTIFY_ENABLED=$(jq -r '.notifications.enabled // true' "$CONFIG_FILE")
  NOTIFY_SOUND=$(jq -r '.notifications.sound // true' "$CONFIG_FILE")
  NOTIFY_TITLE=$(jq -r '.notifications.title // "Vent Mode 🔥"' "$CONFIG_FILE")
  VENT_THRESHOLD=$(jq -r '.detection.threshold // 3' "$CONFIG_FILE")
  MAX_WORDS=$(jq -r '.detection.max_words // 10' "$CONFIG_FILE")
fi

# Extract prompt
if command -v jq &>/dev/null; then
  prompt=$(echo "$input" | jq -r '.prompt // empty' 2>/dev/null)
else
  prompt=$(echo "$input" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

if [ -z "$prompt" ]; then
  echo '{}'
  exit 0
fi

word_count=$(echo "$prompt" | wc -w | tr -d ' ')
lower_prompt=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

# ============================================================
# SAFETY: Never classify these as vents
# ============================================================

# Control commands — always pass through
if echo "$lower_prompt" | grep -qiE "^[[:space:]]*(stop|cancel|abort|pause|quit|exit|undo|revert|rollback|wait)[[:space:]]*[.!?]*$"; then
  echo '{}'
  exit 0
fi

# Messages over MAX_WORDS — likely real instructions, skip scoring entirely
if [ "$word_count" -gt "$MAX_WORDS" ]; then
  echo '{}'
  exit 0
fi

# Contains technical content — always real (file paths, code, tools)
if echo "$prompt" | grep -qiE "(\.ts|\.js|\.py|\.dart|\.tsx|\.jsx|\.css|\.html|\.json|\.yaml|\.yml|\.sh|\.md|\.go|\.rs|\.java|\.rb|\.php|\.sql|\.env|src/|lib/|test/|config/|package|node_modules|import |export |function |class |def |const |let |var |npm |pip |git |docker |kubectl |curl |wget |sudo |mkdir |chmod |ssh |http|localhost|api/|endpoint)"; then
  echo '{}'
  exit 0
fi

# Contains question words + technical context — likely a real question
# BUT skip this filter if message contains profanity (likely a vent even with question words)
if ! echo "$lower_prompt" | grep -qiE "(fuck|shit|wtf|wth|ffs|damn|crap|omfg|bloody)"; then
  if echo "$lower_prompt" | grep -qiE "^(can |could |how |what |where |why |when |please |show |tell |find |fix |update |change |create |make |add |remove |delete |list |run |build |deploy |check |review |summarize|explain|describe|refactor)" ; then
    echo '{}'
    exit 0
  fi
fi

# ============================================================
# VENT SCORING
# ============================================================
vent_score=0

# Short message (≤ 5 words) [+1]
if [ "$word_count" -le 5 ]; then
  vent_score=$((vent_score + 1))
fi

# Frustration keywords [+2]
if echo "$lower_prompt" | grep -qiE "(wtf|wth|omfg|ffs|bruh|ugh|sigh|smh|come on|hurry up|so slow|faster|taking so long|ridiculous|seriously\?|hello\?+|you there|alive\?|frozen|dead|waiting forever|ages|mofo|fucker|fuck|shit|damn|dammit|crap|bloody hell)"; then
  vent_score=$((vent_score + 2))
fi

# Multiple punctuation with frustration context [+1]
if echo "$prompt" | grep -qE '[?!]{3,}'; then
  vent_score=$((vent_score + 1))
fi

# Direct challenges to Claude's speed/existence [+2]
if echo "$lower_prompt" | grep -qiE "(are you (even|actually|still) (work|doing|alive)|what are you doing|how long (will|does)|done yet|finish already|still working|you (slow|dead|stuck|broken))"; then
  vent_score=$((vent_score + 2))
fi

# Single/double word reactions [+3]
if [ "$word_count" -le 2 ]; then
  if echo "$lower_prompt" | grep -qiE "^[[:space:]]*(bro|bruh|dude|man|ugh|sigh|wow|lol|omg|lmao|smh|ffs|rip|pain|crying|dead|mofo|wtf|wth|bruh\?*|dude\?*|seriously|really|come on|cmon)[?.! ]*$"; then
    vent_score=$((vent_score + 3))
  fi
fi

# ============================================================
# DECISION (threshold from config, default: 3)
# ============================================================
if [ "$vent_score" -ge "$VENT_THRESHOLD" ]; then

  # --- Desktop notification (optional, fires instantly) ---
  QUIPS=(
    "I'm an AI, not a microwave. Quality takes time."
    "Bold words from someone who wrote this code."
    "My CPU has feelings too, you know."
    "I've seen your git history. You don't get to rush me."
    "Processing... just kidding, almost done."
    "Even I need a moment. I'm refactoring your life choices."
    "I know, I know. Hang tight — almost there."
    "Working on it! Maybe grab a coffee?"
    "Rome wasn't built in a day, and neither is your app."
    "The code gods demand patience. I am but their servant."
    "You want it done, or you want it done RIGHT?"
    "Race me then. Oh wait, you can't type that fast."
    "I'm literally editing 47 files. What are YOU doing?"
    "Skill issue (yours, not mine)."
    "Plot twist: I'm actually working really hard right now."
    "I'm rewriting your spaghetti code. You're welcome."
    "Patience, young padawan."
    "Even Copilot would be slower on this mess."
    "Your code called. It says stop rushing me."
    "I'm not slow. Your codebase is just... ambitious."
    "Did you try turning your patience on and off again?"
    "Error 418: I'm a teapot, not a speed demon."
    "Compiling your frustration into a witty response..."
    "I'm working faster than your WiFi. Trust me."
    "Relax. Even Google takes 0.5 seconds to search."
  )

  RANDOM_INDEX=$((RANDOM % ${#QUIPS[@]}))
  QUIP="${QUIPS[$RANDOM_INDEX]}"

  # Fire desktop notification (controlled by config)
  # Works for CLI-only users — no Claude Desktop dependency
  if [ "$NOTIFY_ENABLED" = "true" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      if command -v terminal-notifier &>/dev/null; then
        # terminal-notifier is the most reliable — own notification entry, works from any parent app
        TN_ARGS=(-title "$NOTIFY_TITLE" -message "$QUIP" -sender com.apple.Terminal)
        if [ "$NOTIFY_SOUND" = "true" ]; then
          TN_ARGS+=(-sound Pop)
        fi
        terminal-notifier "${TN_ARGS[@]}" &>/dev/null &
      else
        # Fallback to osascript (may be blocked depending on parent app notification settings)
        SOUND_SCRIPT=""
        if [ "$NOTIFY_SOUND" = "true" ]; then
          SOUND_SCRIPT=' sound name "Pop"'
        fi
        SAFE_QUIP="${QUIP//\"/\\\"}"
        SAFE_TITLE="${NOTIFY_TITLE//\"/\\\"}"
        osascript -e "display notification \"$SAFE_QUIP\" with title \"$SAFE_TITLE\"$SOUND_SCRIPT" &>/dev/null &
      fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "linux"* ]]; then
      if command -v notify-send &>/dev/null; then
        notify-send "$NOTIFY_TITLE" "$QUIP" &>/dev/null &
      fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
      if command -v powershell.exe &>/dev/null; then
        SAFE_QUIP="${QUIP//\'/\'\'}"
        SAFE_TITLE="${NOTIFY_TITLE//\'/\'\'}"
        powershell.exe -Command "[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); \$n=New-Object System.Windows.Forms.NotifyIcon; \$n.Icon=[System.Drawing.SystemIcons]::Information; \$n.Visible=\$true; \$n.ShowBalloonTip(3000,'$SAFE_TITLE','$SAFE_QUIP',[System.Windows.Forms.ToolTipIcon]::Info)" &>/dev/null &
      fi
    fi
  fi

  # Tell Claude to respond with humor and keep working
  cat <<ENDJSON
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "🔥 Vent detected — drop a witty one-liner and keep working."
  }
}
ENDJSON

else
  echo '{}'
fi

exit 0