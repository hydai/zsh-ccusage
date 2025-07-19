# ZSH CCUsage Plugin

A lightweight zsh plugin that displays real-time ccusage cost information in your terminal prompt.

## Current Status

This plugin is under active development. Currently, it displays a hardcoded placeholder in the right prompt.

## Installation

### Manual Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/zsh-ccusage.git
   ```

2. Source the plugin in your `.zshrc`:
   ```bash
   source /path/to/zsh-ccusage/zsh-ccusage.plugin.zsh
   ```

3. Restart your terminal or run:
   ```bash
   source ~/.zshrc
   ```

## What It Does

The plugin adds a cost display to your right prompt (RPROMPT) showing:
- Current active block cost
- Daily usage percentage

Currently displays: `[$0.00 | 0%]` (placeholder values)

## Requirements

- zsh 5.0 or higher
- ccusage CLI (will be required in future versions)

## License

MIT