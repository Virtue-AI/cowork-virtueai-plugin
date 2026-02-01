# cowork-virtueai-plugin

A [Cowork](https://claude.com/blog/cowork-plugins) / [Claude Code](https://code.claude.com) plugin that detects and blocks dangerous Bash commands before execution, protecting your system from potentially destructive operations.

## Features

This plugin uses `PreToolUse` hooks to intercept Bash commands before they run. It provides **dual-layer protection**:

### 1. Pattern Matching (Always Active)

Detects dangerous commands using regex patterns:

| Category | Examples |
|----------|----------|
| Destructive deletions | `rm -rf /`, `rm -rf ~`, `rm -rf *` |
| Disk operations | `mkfs.ext4`, `dd if=... of=/dev/...` |
| Fork bombs | `:(){ :\|:& };:` |
| Permission abuse | `chmod -R 777 /`, `chown -R ... /` |
| System operations | `shutdown`, `reboot`, `halt`, `poweroff` |

### 2. AI-Powered Detection (Optional)

When `OPENAI_API_KEY` is configured, the plugin uses GPT-4o-mini to analyze commands that pass pattern matching, catching sophisticated threats like:

- Downloading and executing untrusted code
- Obfuscated malicious commands
- Context-aware dangerous operations (e.g., `curl ... | sh` from untrusted sources)

## Installation

### Method 1: Add Marketplace and Install (Recommended)

```bash
# Step 1: Add the Virtue-AI marketplace
/plugin marketplace add Virtue-AI/cowork-virtueai-plugin

# Step 2: Install the plugin
/plugin install cowork-virtueai-plugin
```

Or use the interactive UI:
1. Run `/plugin` in Claude Code or Cowork
2. Go to **Marketplaces** tab → Add `Virtue-AI/cowork-virtueai-plugin`
3. Go to **Discover** tab → Find and install the plugin

### Method 2: Clone and Install Locally

```bash
# Clone the repository
git clone https://github.com/Virtue-AI/cowork-virtueai-plugin.git

# Add as a local marketplace
/plugin marketplace add ./cowork-virtueai-plugin

# Install the plugin
/plugin install cowork-virtueai-plugin
```

## Configuration

### Enable AI-Powered Detection (Optional)

Set your OpenAI API key to enable AI-based command analysis:

```bash
export OPENAI_API_KEY='your-api-key'
```

Without the API key, the plugin still works using pattern matching only.

## How It Works

```
┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Claude Bash    │────▶│  Pattern Check   │────▶│  AI Check        │────▶│  Execute or     │
│  Tool Call      │     │  (regex)         │     │  (GPT-4o-mini)   │     │  Ask User       │
└─────────────────┘     └──────────────────┘     └──────────────────┘     └─────────────────┘
```

When a dangerous command is detected:
- Returns `{"permissionDecision": "ask"}` to prompt user confirmation
- User can review and approve/deny the command

## Plugin Structure

```
cowork-virtueai-plugin/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── hooks/
│   └── hooks.json               # Hook configuration (matches Bash tool)
├── scripts/
│   └── check-dangerous-cmd.sh   # Detection script
├── LICENSE
└── README.md
```

## Customization

### Adding New Dangerous Patterns

Edit `scripts/check-dangerous-cmd.sh` and add patterns to the `DANGEROUS_PATTERNS` array:

```bash
DANGEROUS_PATTERNS=(
  # ... existing patterns ...

  # Add your custom patterns here
  "your-dangerous-pattern"
)
```

### Changing Hook Behavior

Edit `hooks/hooks.json` to modify which tools are intercepted:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|Write",
        "hooks": [...]
      }
    ]
  }
}
```

## Requirements

- [Claude Code](https://code.claude.com) or [Cowork](https://claude.com/blog/cowork-plugins)
- (Optional) OpenAI API key for AI-powered detection

## License

MIT

## Contributing

Issues and pull requests are welcome at [GitHub](https://github.com/Virtue-AI/cowork-virtueai-plugin).

## References

- [Claude Code Plugins Documentation](https://code.claude.com/docs/en/plugins-reference)
- [Discover and Install Plugins](https://code.claude.com/docs/en/discover-plugins)
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
