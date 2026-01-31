# cowork-virtueai-plugin

A [Cowork](https://claude.com/blog/cowork-plugins) plugin that detects and blocks dangerous Bash commands before execution, protecting your system from potentially destructive operations.

## Features

This plugin uses `PreToolUse` hooks to intercept Bash commands before they run and blocks dangerous patterns including:

| Category | Examples |
|----------|----------|
| Destructive deletions | `rm -rf /`, `rm -rf ~`, `rm -rf *` |
| Disk operations | `mkfs.ext4`, `dd if=... of=/dev/...` |
| Fork bombs | `:(){ :\|:& };:` |
| Permission abuse | `chmod -R 777 /`, `chown -R ... /` |
| Pipe execution | `curl ... \| sh`, `wget ... \| bash` |
| System operations | `shutdown`, `reboot`, `halt`, `poweroff` |
| Log tampering | `history -c`, `> /var/log/...` |

## Installation

### Method 1: Install from Plugin Marketplace (Recommended)

```bash
claude plugins add Virtue-AI/cowork-virtueai-plugin
```

### Method 2: Clone and Install Manually

```bash
# Clone the repository
git clone https://github.com/Virtue-AI/cowork-virtueai-plugin.git

# Install the plugin
claude plugins add ./cowork-virtueai-plugin
```

### Method 3: Direct Download

1. Download this repository as a ZIP file
2. Extract to your preferred location
3. In Cowork, click **Plugins** → **Upload plugin** and select the extracted folder

## How It Works

The plugin registers a `PreToolUse` hook that intercepts all Bash tool calls:

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Claude Bash    │────▶│  PreToolUse Hook │────▶│  Execute or     │
│  Tool Call      │     │  (this plugin)   │     │  Block Command  │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

- **Exit code 0**: Command is safe, allow execution
- **Exit code 2**: Command is dangerous, block execution and notify Claude

## Plugin Structure

```
cowork-virtueai-plugin/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── hooks/
│   └── hooks.json               # Hook configuration (matches Bash tool)
├── scripts/
│   └── check-dangerous-cmd.sh   # Detection script
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
        "matcher": "Bash|Write",  // Match multiple tools
        "hooks": [...]
      }
    ]
  }
}
```

## Requirements

- [Cowork](https://claude.com/blog/cowork-plugins) (Claude Desktop with Cowork enabled)
- `jq` command-line tool (for JSON parsing)

## License

MIT

## Contributing

Issues and pull requests are welcome at [GitHub](https://github.com/Virtue-AI/cowork-virtueai-plugin).
