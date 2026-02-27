#!/bin/bash
# detect-vent.sh v2.0
# Vent detection with desktop notification support
# Part of claude-vent-mode plugin
# https://github.com/Ramesh-Giri/claude-vent-mode

input=$(cat)

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

# Messages over 10 words — likely real instructions, skip scoring entirely
if [ "$word_count" -gt 10 ]; then
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
# DECISION (threshold: 3)
# ============================================================
if [ "$vent_score" -ge 3 ]; then

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

  # Fire desktop notification (cross-platform, non-blocking)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v terminal-notifier &>/dev/null; then
      terminal-notifier -title "Vent Mode" -message "$QUIP" -sound Pop -sender com.anthropic.claudefordesktop &>/dev/null &
    else
      osascript -e "display notification \"$QUIP\" with title \"Vent Mode\"" &>/dev/null &
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    command -v notify-send &>/dev/null && notify-send "Vent Mode" "$QUIP" &>/dev/null &
  fi

  # Tell Claude to ignore this and keep working
  cat <<ENDJSON
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "VENT MODE: The user just vented frustration (score: ${vent_score}). A quip was shown via desktop notification. Respond with ONLY a single short witty one-liner (under 15 words), then immediately continue your current task."
  }
}
ENDJSON

else
  echo '{}'
fi

exit 0