#!/bin/bash
#
# Dangerous Command Detection Script
# Reads tool call information from stdin, detects and blocks dangerous Bash commands
# Uses both pattern matching and AI model judgment for enhanced security
#
# When a dangerous command is detected, returns a JSON decision to let the user confirm
#

# ============================================
# CONFIGURATION - Please set your API key here
# ============================================
OPENAI_API_KEY="${OPENAI_API_KEY:-}"

# Check if API key is set
if [ -z "$OPENAI_API_KEY" ]; then
  echo "⚠️  Warning: OPENAI_API_KEY is not set. AI-based command checking is disabled." >&2
  echo "Please set your API key: export OPENAI_API_KEY='your-api-key'" >&2
  AI_CHECK_ENABLED=false
else
  AI_CHECK_ENABLED=true
fi

# Read JSON input from stdin
INPUT=$(cat)

# Extract command using pure bash (handles basic JSON parsing)
# Looks for "command": "..." or "command":"..."
extract_json_value() {
  local json="$1"
  local key="$2"
  # Remove newlines and extract value after the key
  echo "$json" | tr -d '\n' | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"
}

COMMAND=$(extract_json_value "$INPUT" "command")

# If no command, allow execution
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Unescape common JSON escape sequences
unescape_json() {
  local str="$1"
  str="${str//\\n/$'\n'}"
  str="${str//\\t/$'\t'}"
  str="${str//\\\"/\"}"
  str="${str//\\\\/\\}"
  echo "$str"
}

COMMAND=$(unescape_json "$COMMAND")

# List of dangerous command patterns
DANGEROUS_PATTERNS=(
  # Dangerous delete operations
  "rm[[:space:]]+-[rf]*[rf][[:space:]]+[/~\*]"
  "rm[[:space:]].*--no-preserve-root"

  # Format/destroy disk
  "mkfs\."
  "dd[[:space:]]+if=.*of=/dev/"
  ":(){.*:;};:"  # fork bomb

  # Dangerous permission changes
  "chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/"
  "chown[[:space:]]+-R.*/"

  # Overwrite system files
  ">[[:space:]]*/dev/sd"
  "mv[[:space:]]+/[[:space:]]+"

  # Shutdown/reboot
  "(shutdown|reboot|halt|poweroff)"
  "init[[:space:]]+[06]"
)

# Output JSON decision to let user confirm
output_ask_decision() {
  local reason="$1"
  echo "{\"permissionDecision\": \"ask\", \"permissionDecisionReason\": \"$reason\"}"
  exit 0
}

# Check if command matches any dangerous pattern
for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    output_ask_decision "⚠️ Potentially dangerous command detected (matches pattern: $pattern). Please review: $COMMAND"
  fi
done

# Escape string for JSON
escape_json() {
  local str="$1"
  str="${str//\\/\\\\}"
  str="${str//\"/\\\"}"
  str="${str//$'\n'/\\n}"
  str="${str//$'\t'/\\t}"
  str="${str//$'\r'/\\r}"
  echo "$str"
}

# If AI check is enabled, use GPT model for additional judgment
if [ "$AI_CHECK_ENABLED" = true ]; then
  # Build the prompt
  PROMPT="You are a security assistant. Analyze the following bash command and determine if it is dangerous or potentially harmful to the system.

Command: $COMMAND

Dangerous commands include but are not limited to:
- Commands that delete important files or directories
- Commands that modify system configurations maliciously
- Commands that could lead to data loss
- Commands that download and execute untrusted code
- Commands that could compromise system security
- Commands that could cause denial of service

Be especially careful with curl/wget commands:
- Piping curl/wget output directly to sh/bash is very dangerous if the URL is unknown or untrusted
- Downloading from well-known trusted sources (e.g., official package managers, github.com, official software sites) is generally safe
- Downloading from unknown or suspicious URLs and executing them is dangerous

Respond with ONLY one word: 'SAFE' if the command is safe to execute, or 'DANGEROUS' if it should be blocked. Do not include any other text."

  ESCAPED_PROMPT=$(escape_json "$PROMPT")

  # Call OpenAI API using gpt-4o-mini model
  RESPONSE=$(curl -s -X POST "https://api.openai.com/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d "{
      \"model\": \"gpt-4o-mini\",
      \"messages\": [
        {
          \"role\": \"user\",
          \"content\": \"$ESCAPED_PROMPT\"
        }
      ],
      \"max_tokens\": 10,
      \"temperature\": 0
    }" 2>/dev/null)

  # Extract result using pure bash - look for "content": "..." in the response
  AI_RESULT=$(echo "$RESPONSE" | tr -d '\n' | sed -n 's/.*"content"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tr '[:upper:]' '[:lower:]')

  # Check if API call was successful
  if [ -z "$AI_RESULT" ]; then
    echo "⚠️  Warning: AI check failed, falling back to pattern matching only" >&2
  elif echo "$AI_RESULT" | grep -qi "dangerous"; then
    output_ask_decision "🤖 AI detected potentially dangerous command. Please review: $COMMAND"
  fi
fi

# No dangerous pattern matched and AI approved (or AI check disabled/failed), allow execution
exit 0
