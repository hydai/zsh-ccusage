#!/bin/bash
# Oh My Zsh 安裝腳本

echo "🚀 Installing zsh-ccusage for Oh My Zsh..."

# 檢查 Oh My Zsh 是否安裝
if [ -z "$ZSH" ]; then
    echo "❌ Oh My Zsh not found. Please install Oh My Zsh first."
    exit 1
fi

PLUGIN_DIR="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ccusage"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

# 如果插件目錄已存在，詢問是否覆蓋
if [ -d "$PLUGIN_DIR" ] || [ -L "$PLUGIN_DIR" ]; then
    echo "⚠️  Plugin directory already exists: $PLUGIN_DIR"
    read -p "Do you want to replace it? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$PLUGIN_DIR"
    else
        echo "Installation cancelled."
        exit 0
    fi
fi

# 創建符號連結
echo "📁 Creating symlink..."
ln -s "$SOURCE_DIR" "$PLUGIN_DIR"

# 檢查是否已在 plugins 列表中
if grep -q "zsh-ccusage" ~/.zshrc; then
    echo "✅ Plugin already in .zshrc"
else
    echo "📝 Adding plugin to .zshrc..."
    # 在 plugins=(...) 中添加 zsh-ccusage
    sed -i.bak 's/^plugins=(\(.*\))/plugins=(\1 zsh-ccusage)/' ~/.zshrc
    echo "✅ Added zsh-ccusage to plugins list"
fi

echo ""
echo "✨ Installation complete!"
echo ""
echo "To activate the plugin, run:"
echo "  source ~/.zshrc"
echo ""
echo "Optional: Add these to your .zshrc before the plugins line:"
echo "  export CCUSAGE_AUTO_UPDATE=true"
echo "  export CCUSAGE_UPDATE_INTERVAL=300"
echo "  export CCUSAGE_DAILY_LIMIT=200"