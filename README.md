# Virtue-AI Plugins for Claude Code / Cowork

A collection of plugins for [Claude Code](https://code.claude.com) and [Cowork](https://claude.com/blog/cowork-plugins).

## Available Plugins

| Plugin | Description |
|--------|-------------|
| **safe-bash** | Detects and blocks dangerous Bash commands before execution using pattern matching and AI-powered analysis |

## Installation

```bash
# Step 1: Add the marketplace
/plugin marketplace add Virtue-AI/cowork-virtueai-plugin

# Step 2: Install a plugin
/plugin install safe-bash
```

Or use the interactive UI:
1. Run `/plugin` in Claude Code or Cowork
2. Go to **Marketplaces** tab → Add `Virtue-AI/cowork-virtueai-plugin`
3. Go to **Discover** tab → Find and install plugins

## Plugins

### safe-bash

Protects your system by intercepting Bash commands before execution.

**Features:**
- **Pattern Matching**: Blocks known dangerous commands (`rm -rf /`, `mkfs`, `dd`, etc.)
- **AI Detection** (Optional): Uses GPT-4o-mini to analyze commands when `OPENAI_API_KEY` is set

**Configuration:**
```bash
# Enable AI-powered detection (optional)
export OPENAI_API_KEY='your-api-key'
```

## References

- [Claude Code Plugins Documentation](https://code.claude.com/docs/en/plugins-reference)
- [Discover and Install Plugins](https://code.claude.com/docs/en/discover-plugins)
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)

## License

MIT
