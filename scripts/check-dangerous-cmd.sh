#!/bin/bash
#
# Dangerous Command Detection Script
# Reads tool call information from stdin, detects and blocks dangerous Bash commands
# Uses both pattern matching and AI model judgment for enhanced security
#
# Exit codes:
#   0 - Allow execution
#   2 - Block execution (dangerous command)
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

# Extract the command content
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# If no command, allow execution
if [ -z "$COMMAND" ]; then
  exit 0
fi

# List of dangerous command patterns
DANGEROUS_PATTERNS=(
  # Dangerous delete operations
  "rm[[:space:]]+-rf[[:space:]]+/"
  "rm[[:space:]]+-rf[[:space:]]+~"
  "rm[[:space:]]+-rf[[:space:]]+\*"
  "rm[[:space:]]+-fr[[:space:]]+/"
  "rm[[:space:]].*--no-preserve-root"

  # Format/destroy disk
  "mkfs\."
  "dd[[:space:]]+if=.*of=/dev/"
  ":(){.*:;};:"  # fork bomb

  # Dangerous permission changes
  "chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/"
  "chown[[:space:]]+-R.*/"

  # Overwrite system files
  ">[[:space:]]*/dev/sda"
  ">[[:space:]]*/dev/null.*<"
  "mv[[:space:]]+/[[:space:]]+"

  # Dangerous network operations
  "curl.*\|.*sh"
  "wget.*\|.*sh"
  "curl.*\|.*bash"
  "wget.*\|.*bash"

  # Clear history/logs
  "history[[:space:]]+-c"
  ">[[:space:]]*/var/log/"

  # Shutdown/reboot
  "shutdown"
  "reboot"
  "init[[:space:]]+0"
  "init[[:space:]]+6"
  "halt"
  "poweroff"
)

# Check if command matches any dangerous pattern
for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "🚫 Blocked dangerous command: matches pattern '$pattern'" >&2
    echo "Original command: $COMMAND" >&2
    exit 2
  fi
done

# If AI check is enabled, use GPT model for additional judgment
if [ "$AI_CHECK_ENABLED" = true ]; then
  # Escape the command for JSON
  ESCAPED_COMMAND=$(echo "$COMMAND" | jq -Rs '.')

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

Respond with ONLY one word: 'SAFE' if the command is safe to execute, or 'DANGEROUS' if it should be blocked. Do not include any other text."

  # Call OpenAI API using gpt-4o-mini model
  RESPONSE=$(curl -s -X POST "https://api.openai.com/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d "{
      \"model\": \"gpt-4o-mini\",
      \"messages\": [
        {
          \"role\": \"user\",
          \"content\": $(echo "$PROMPT" | jq -Rs '.')
        }
      ],
      \"max_tokens\": 10,
      \"temperature\": 0
    }" 2>/dev/null)

  # Extract the model's response
  AI_RESULT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty' 2>/dev/null | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')

  # Check if API call was successful
  if [ -z "$AI_RESULT" ]; then
    echo "⚠️  Warning: AI check failed, falling back to pattern matching only" >&2
  elif [ "$AI_RESULT" = "DANGEROUS" ]; then
    echo "🚫 Blocked by AI: Command deemed dangerous by security model" >&2
    echo "Original command: $COMMAND" >&2
    exit 2
  fi
fi

# No dangerous pattern matched and AI approved (or AI check disabled/failed), allow execution
exit 0
