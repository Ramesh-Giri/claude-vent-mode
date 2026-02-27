#!/bin/bash
# detect-vent.sh
# Runs on UserPromptSubmit to tag messages as potential vents
# This helps Claude's vent-mode skill by pre-classifying messages
# No external dependencies required (no jq needed)

# Read the hook input from stdin
input=$(cat)

# Extract the user's prompt text using lightweight parsing
# Try jq first, fall back to sed if jq isn't available
if command -v jq &>/dev/null; then
  prompt=$(echo "$input" | jq -r '.prompt // empty' 2>/dev/null)
else
  # Extract "prompt" value from JSON using sed
  prompt=$(echo "$input" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

# If we can't parse the prompt, let it through normally
if [ -z "$prompt" ]; then
  echo '{}'
  exit 0
fi

# Count words in the message
word_count=$(echo "$prompt" | wc -w | tr -d ' ')

# Convert to lowercase for matching
lower_prompt=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

# ---- NEVER classify these as vents (control commands) ----
if echo "$lower_prompt" | grep -qiE "^[[:space:]]*(stop|cancel|abort|pause|quit|exit|undo|revert|rollback|wait)[[:space:]]*[.!?]*$"; then
  echo '{}'
  exit 0
fi

# ---- Vent detection scoring ----
vent_score=0

# Check 1: Is the message short? (under 20 words) [+1]
if [ "$word_count" -le 20 ]; then
  vent_score=$((vent_score + 1))
fi

# Check 2: Contains frustration keywords [+2]
if echo "$lower_prompt" | grep -qiE "(wtf|wth|omfg|ffs|bruh|ugh|sigh|smh|come on|hurry|slow|faster|taking so long|ridiculous|seriously|hello\?|you there|alive|crash|stuck|frozen|dead|waiting|forever|ages)"; then
  vent_score=$((vent_score + 2))
fi

# Check 3: Very short messages (under 5 words) without technical content [+1]
if [ "$word_count" -le 5 ]; then
  if ! echo "$prompt" | grep -qiE "(\.ts|\.js|\.py|\.dart|\.tsx|\.jsx|\.css|\.html|\.json|\.yaml|\.yml|\.sh|\.md|/|\\\\|->|=>|::|import|export|function|class|def |const |let |var |npm|pip|git |docker|kubectl)"; then
    vent_score=$((vent_score + 1))
  fi
fi

# Check 4: Ends with multiple question marks or exclamation marks [+1]
if echo "$prompt" | grep -qE '[?!]{2,}'; then
  vent_score=$((vent_score + 1))
fi

# Check 5: Direct challenges to Claude's speed/existence [+1]
if echo "$lower_prompt" | grep -qiE "(you (even|actually) (work|doing)|what.*(doing|happening)|how long|still working|yet\?|done yet|finish already|are you (there|alive|working|ok))"; then
  vent_score=$((vent_score + 1))
fi

# Check 6: Pure emoji or single-word reactions [+2]
if [ "$word_count" -le 2 ]; then
  if echo "$lower_prompt" | grep -qiE "^(bro|bruh|dude|man|ugh|sigh|wow|lol|omg|lmao|smh|ffs|rip|help|pain|crying|dead)[?.!]*$"; then
    vent_score=$((vent_score + 2))
  fi
fi

# ---- Decision ----
# Score >= 3 = likely a vent -> tag it for Claude
# Score < 3 = probably a real message -> pass through normally

if [ "$vent_score" -ge 3 ]; then
  cat <<EOF
{"systemMessage": "[VENT DETECTED | score: ${vent_score}] The user message appears to be a vent/frustration, not a real task. If you are currently mid-task, respond with a single witty quip per your vent-mode skill, then continue working. If you are NOT mid-task, treat normally."}
EOF
else
  echo '{}'
fi

exit 0
