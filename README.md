# Claude Code Statusline

A minimal, vibrant statusline for Claude Code with context tracking, cost monitoring, and token stats.

## Quick Install

```bash
npx claude-code-statusline init
```

This will:
1. Create `.claude/statusline.sh` in your project
2. Update `.claude/settings.json` to use the statusline
3. Restart Claude Code to see your new statusline

## Features

- Model name display with spinner animation when streaming
- Directory path (abbreviated)
- Git branch
- Context window remaining (%) with color-coded progress bar
- Session cost with burn rate ($/hour)
- Total token count

## Prerequisites

**Required:**
- Node.js 16+
- Claude Code

**Recommended:**
- **jq** - enables context tracking, token stats, and cost calculations

### Installing jq

Without jq, many features will be unavailable.

**macOS:**
```bash
brew install jq
```

**Linux:**
```bash
# Debian/Ubuntu
apt-get install jq

# RHEL/CentOS
yum install jq
```

**Windows:**
```bash
# Chocolatey
choco install jq

# Scoop
scoop install jq
```

Verify installation:
```bash
jq --version
```

## Installation Options

### Project-level (default)
```bash
npx claude-code-statusline init
```

Installs to `./.claude/` in your current project.

### Global
```bash
npx claude-code-statusline init --global
```

Installs to `~/.claude/` for use across all projects.

### Script only (no settings update)
```bash
npx claude-code-statusline init --no-install
```

Generates the script without modifying settings.json.

### Custom output path
```bash
npx claude-code-statusline init -o ./my-statusline.sh
```

## Statusline Display

```
* Opus 4.5 │ > …/my-project │ ^ main │ ~ 85% ▰▰▰▰▰▱ │ $1.23 ($4.56/h) │ # 12.3K
```

| Element | Description |
|---------|-------------|
| `*` | Model indicator (spinner when streaming) |
| `>` | Current directory |
| `^` | Git branch |
| `~` | Context remaining with progress bar |
| `$` | Session cost with burn rate |
| `#` | Total tokens used |

## Color Legend

- **Green** progress bar: >40% context remaining
- **Yellow** progress bar: 21-40% context remaining
- **Red** progress bar: <=20% context remaining

## Manual Installation

If you prefer to install manually:

1. Copy the statusline script to your `.claude/` directory:
   ```bash
   curl -o .claude/statusline.sh https://raw.githubusercontent.com/adamramberg/claude-code-statusline/main/templates/statusline.sh
   chmod +x .claude/statusline.sh
   ```

2. Add to your `.claude/settings.json`:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": ".claude/statusline.sh",
       "padding": 0
     }
   }
   ```

3. Restart Claude Code.

## License

MIT
