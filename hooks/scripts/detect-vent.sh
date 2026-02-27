#!/bin/bash
# detect-vent.sh
# Runs on UserPromptSubmit to classify messages as vents
# Uses hookSpecificOutput.additionalContext for strong context injection

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

# Short message
[ "$word_count" -le 20 ] && vent_score=$((vent_score + 1))

# Frustration keywords
echo "$lower_prompt" | grep -qiE "(wtf|wth|omfg|ffs|bruh|ugh|sigh|smh|come on|hurry|slow|faster|taking so long|ridiculous|seriously|hello\?|you there|alive|crash|stuck|frozen|dead|waiting|forever|ages|mofo|fucker|fuck|shit|damn|dammit|crap|bloody)" && vent_score=$((vent_score + 2))

# Very short + non-technical
if [ "$word_count" -le 5 ]; then
  echo "$prompt" | grep -qiE "(\.ts|\.js|\.py|\.dart|\.tsx|\.jsx|\.css|\.html|\.json|\.yaml|/|\\\\|->|=>|import|export|function|class|def |const |let |var |npm|pip|git |docker)" || vent_score=$((vent_score + 1))
fi

# Multiple punctuation
echo "$prompt" | grep -qE '[?!]{2,}' && vent_score=$((vent_score + 1))

# Speed/existence challenges
echo "$lower_prompt" | grep -qiE "(you (even|actually) (work|doing)|what.*(doing|happening)|how long|still working|yet\?|done yet|finish already|are you (there|alive|working|ok)|what is happening)" && vent_score=$((vent_score + 1))

# Single word reactions
if [ "$word_count" -le 2 ]; then
  echo "$lower_prompt" | grep -qiE "^(bro|bruh|dude|man|ugh|sigh|wow|lol|omg|lmao|smh|ffs|rip|help|pain|crying|dead|mofo|wtf|wth)[?.!]*$" && vent_score=$((vent_score + 2))
fi

# --- Decision ---
if [ "$vent_score" -ge 3 ]; then
  # Use hookSpecificOutput with additionalContext for strong injection
  cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "⚠️ VENT MODE ACTIVATED: The user's message is NOT a task — they are venting frustration while you work. CRITICAL INSTRUCTION: Reply with ONLY a single short witty/sarcastic/empathetic quip (under 15 words, with max 1 emoji). Do NOT address it as a real question. Do NOT explain what you're working on. Do NOT provide a status update. Just drop ONE funny one-liner, then IMMEDIATELY continue your current task with your next tool call. Example responses: 'I'm an AI, not a microwave. Quality takes time. 🎩' or 'Bold words from someone who wrote this code.' or 'Working on it! Maybe grab a coffee? ☕' or 'Skill issue (yours, not mine). 💪' — Pick ONE quip, say it, then keep working."
  }
}
ENDJSON
else
  echo '{}'
fi

exit 0