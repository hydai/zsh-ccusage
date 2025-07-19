#!/bin/bash
# 測試主題整合是否成功

echo "🔍 檢查主題整合..."

# 檢查函數是否存在
echo -n "檢查 prompt_ccusage 函數... "
if zsh -c 'source ~/.oh-my-zsh/custom/themes/hydai.zsh-theme; type prompt_ccusage &>/dev/null'; then
    echo "✅"
else
    echo "❌"
fi

# 檢查 RIGHT_PROMPT_ELEMENTS
echo -n "檢查 RIGHT_PROMPT_ELEMENTS 設定... "
if grep -q "ccusage" ~/.oh-my-zsh/custom/themes/hydai.zsh-theme; then
    echo "✅"
else
    echo "❌"
fi

# 檢查 precmd 整合
echo -n "檢查 precmd 整合... "
if grep -q "ccusage_precmd" ~/.oh-my-zsh/custom/themes/hydai.zsh-theme; then
    echo "✅"
else
    echo "❌"
fi

echo ""
echo "✨ 整合完成！請執行以下命令重新載入配置："
echo "  source ~/.zshrc"
echo ""
echo "或開啟新的終端視窗來查看效果。"
echo ""
echo "如果想要調整 ccusage 的顯示顏色，可以編輯主題文件中的 prompt_ccusage 函數："
echo "  第 389 行: \$1_prompt_segment \$0 \"237\" \"white\" \"\$ccusage_info\""
echo "  - \"237\" 是背景色（深灰）"
echo "  - \"white\" 是前景色（白色）"