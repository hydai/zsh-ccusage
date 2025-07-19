# Plugin Manager Compatibility

The zsh-ccusage plugin has been tested and is compatible with the following ZSH plugin managers and frameworks:

## Oh My Zsh

### Installation
```bash
git clone https://github.com/yourusername/zsh-ccusage ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ccusage
```

Add to your `.zshrc`:
```bash
plugins=(... zsh-ccusage)
```

### Compatibility Notes
- Automatically detected when `$ZSH` environment variable is set
- Plugin follows Oh My Zsh naming conventions
- Functions are automatically available in the shell

## Prezto

### Installation
```bash
git clone https://github.com/yourusername/zsh-ccusage ~/zsh-ccusage
ln -s ~/zsh-ccusage ~/.zprezto/modules/zsh-ccusage
```

Add to your `.zpreztorc`:
```bash
zstyle ':prezto:load' pmodule \
  ... \
  'zsh-ccusage'
```

### Compatibility Notes
- Includes `init.zsh` file for Prezto module compatibility
- Automatically detected when `$ZPREZTODIR` is set or `~/.zprezto` exists
- Sets proper zstyle for module loading status

## Zinit

### Installation
```bash
zinit light yourusername/zsh-ccusage
```

Or with turbo mode:
```bash
zinit ice wait lucid
zinit light yourusername/zsh-ccusage
```

### Compatibility Notes
- Automatically detected when `zinit` function is available
- Supports ice modifiers for advanced loading
- Compatible with turbo mode for faster shell startup

## Zplug

### Installation
```bash
zplug "yourusername/zsh-ccusage"
```

### Compatibility Notes
- Automatically detected when `zplug` function is available
- Works with zplug's lazy loading features

## Antigen

### Installation
```bash
antigen bundle yourusername/zsh-ccusage
```

### Compatibility Notes
- Automatically detected when `antigen` function is available
- Compatible with antigen's bundle system

## Manual Installation

For users not using a plugin manager:

```bash
git clone https://github.com/yourusername/zsh-ccusage.git ~/zsh-ccusage
echo 'source ~/zsh-ccusage/zsh-ccusage.plugin.zsh' >> ~/.zshrc
```

## Framework Detection

The plugin automatically detects which framework is being used through the `ccusage_detect_framework()` function. This ensures proper initialization for each environment.

Detected framework is stored in `$CCUSAGE_FRAMEWORK` variable with possible values:
- `oh-my-zsh`
- `prezto`
- `zinit`
- `zplug`
- `antigen`
- `none` (manual installation or unknown framework)

## Compatibility Features

1. **Multiple Load Prevention**: The plugin includes guards to prevent multiple initialization
2. **Function Path Management**: Automatically adds functions directory to `$fpath`
3. **Lazy Loading**: Components are loaded only when needed to improve startup time
4. **Hook Management**: Properly manages `precmd_functions` array to avoid duplicates

## Testing

The plugin has been tested with:
- ZSH 5.0+
- Oh My Zsh (latest)
- All major plugin managers
- Various terminal emulators (iTerm2, Terminal.app, Alacritty, etc.)

## Troubleshooting

If the plugin doesn't load properly:

1. Check framework detection:
   ```bash
   echo $CCUSAGE_FRAMEWORK
   ```

2. Verify plugin loaded:
   ```bash
   echo $CCUSAGE_LOADED
   ```

3. Check for function availability:
   ```bash
   which ccusage-refresh
   ```

4. For debugging, enable verbose loading:
   ```bash
   export CCUSAGE_DEBUG=true
   source ~/.zshrc
   ```