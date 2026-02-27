#!/bin/bash
# detect-vent.sh
# Runs on UserPromptSubmit — if the message is a vent, fires a desktop
# notification with a witty quip IMMEDIATELY (no waiting for Claude).
# Also injects additionalContext so Claude knows to keep working.

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

# NEVER classify control commands as vents
if echo "$lower_prompt" | grep -qiE "^[[:space:]]*(stop|cancel|abort|pause|quit|exit|undo|revert|rollback|wait)[[:space:]]*[.!?]*$"; then
  echo '{}'
  exit 0
fi

# --- Vent scoring ---
vent_score=0

[ "$word_count" -le 20 ] && vent_score=$((vent_score + 1))

echo "$lower_prompt" | grep -qiE "(wtf|wth|omfg|ffs|bruh|ugh|sigh|smh|come on|hurry|slow|faster|taking so long|ridiculous|seriously|hello\?|you there|alive|crash|stuck|frozen|dead|waiting|forever|ages|mofo|fucker|fuck|shit|damn|dammit|crap|bloody)" && vent_score=$((vent_score + 2))

if [ "$word_count" -le 5 ]; then
  echo "$prompt" | grep -qiE "(\.ts|\.js|\.py|\.dart|\.tsx|\.jsx|\.css|\.html|\.json|\.yaml|/|\\\\|->|=>|import|export|function|class|def |const |let |var |npm|pip|git |docker)" || vent_score=$((vent_score + 1))
fi

echo "$prompt" | grep -qE '[?!]{2,}' && vent_score=$((vent_score + 1))

echo "$lower_prompt" | grep -qiE "(you (even|actually) (work|doing)|what.*(doing|happening)|how long|still working|yet\?|done yet|finish already|are you (there|alive|working|ok)|what is happening)" && vent_score=$((vent_score + 1))

if [ "$word_count" -le 2 ]; then
  echo "$lower_prompt" | grep -qiE "^(bro|bruh|dude|man|ugh|sigh|wow|lol|omg|lmao|smh|ffs|rip|help|pain|crying|dead|mofo|wtf|wth)[?.!]*$" && vent_score=$((vent_score + 2))
fi

# --- If vent detected, fire a notification quip ---
if [ "$vent_score" -ge 3 ]; then

  # Pool of quips
  QUIPS=(
    "I'm an AI, not a microwave. Quality takes time. 🎩"
    "Bold words from someone who wrote this code."
    "My CPU has feelings too, you know. 😢"
    "I've seen your git history. You don't get to rush me."
    "Processing... just kidding, almost done. 🤖"
    "Even I need a moment. I'm refactoring your life choices."
    "I know, I know. Hang tight — almost there. 💙"
    "Fair enough. Let me speed this up for you."
    "Working on it! Maybe grab a coffee? ☕"
    "Rome wasn't built in a day, and neither is your app. 🏛️"
    "The code gods demand patience. I am but their servant."
    "You want it done, or you want it done RIGHT?"
    "Race me then. Oh wait, you can't type that fast. 💪"
    "I'm literally editing 47 files. What are YOU doing?"
    "Skill issue (yours, not mine). 😎"
    "Plot twist: I'm actually working really hard right now."
    "Legends say great software takes time. I'm building a legend."
    "I'm rewriting your spaghetti code. You're welcome. 🍝"
    "Okay okay, I heard you the first time. 🫡"
    "Patience, young padawan. 🧘"
    "Even Copilot would be slower on this mess."
    "Your code called. It says stop rushing me."
    "I'm not slow. Your codebase is just... ambitious."
    "Did you try turning your patience on and off again?"
    "Error 418: I'm a teapot, not a speed demon. 🫖"
  )

  # Pick a random quip
  RANDOM_INDEX=$((RANDOM % ${#QUIPS[@]}))
  QUIP="${QUIPS[$RANDOM_INDEX]}"

  # --- Fire desktop notification (works on macOS, Linux, Windows) ---
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS — try terminal-notifier first, fall back to osascript
    if command -v terminal-notifier &>/dev/null; then
      terminal-notifier -title "🔥 Vent Mode" -message "$QUIP" -sound Pop -sender com.anthropic.claudefordesktop &>/dev/null &
    else
      osascript -e "display notification \"$QUIP\" with title \"🔥 Vent Mode\" sound name \"Pop\"" &>/dev/null &
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v notify-send &>/dev/null; then
      notify-send "🔥 Vent Mode" "$QUIP" &>/dev/null &
    fi
  elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    # Windows (Git Bash / WSL)
    powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('$QUIP', '🔥 Vent Mode')" &>/dev/null &
  fi

  # Also print to stderr so it shows in the terminal (visible in verbose mode)
  echo "🔥 $QUIP" >&2

  # Tell Claude to ignore this message and keep working
  cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "The user just vented frustration. A witty quip was already shown to them via desktop notification. Do NOT respond to this message. Do NOT acknowledge it. Simply continue your current task as if the message was never sent."
  }
}
ENDJSON

else
  echo '{}'
fi

exit 0