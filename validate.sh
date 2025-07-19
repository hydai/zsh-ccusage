#!/usr/bin/env bash
# Simple validation script for zsh plugin

echo "🔍 Validating zsh-ccusage plugin..."

# Check for syntax errors
echo -n "Checking syntax... "
for file in *.zsh init.zsh lib/*.zsh functions/*; do
    if [[ -f "$file" ]]; then
        if ! zsh -n "$file" 2>/dev/null; then
            echo "❌ Syntax error in $file"
            exit 1
        fi
    fi
done
echo "✅"

# Check for required files
echo -n "Checking required files... "
required_files=(
    "zsh-ccusage.plugin.zsh"
    "README.md"
    "init.zsh"
)
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "❌ Missing required file: $file"
        exit 1
    fi
done
echo "✅"

# Check plugin structure
echo -n "Checking plugin structure... "
required_dirs=(
    "functions"
    "lib"
    "docs"
)
for dir in "${required_dirs[@]}"; do
    if [[ ! -d "$dir" ]]; then
        echo "❌ Missing required directory: $dir"
        exit 1
    fi
done
echo "✅"

# Check for common issues
echo -n "Checking for common issues... "

# Check for hardcoded paths
if grep -r "\/home\/" *.zsh lib/*.zsh functions/* 2>/dev/null | grep -v "HOME"; then
    echo "⚠️  Found hardcoded paths"
fi

# Check for proper quoting in variable expansions
if grep -E '\$[A-Za-z_][A-Za-z0-9_]*[^}"]' *.zsh lib/*.zsh 2>/dev/null | grep -v '${' | grep -v 'SC[0-9]'; then
    echo "⚠️  Found unquoted variables"
fi

echo "✅"

# Performance check
echo -n "Checking load time... "
start_time=$(date +%s.%N)
zsh -c "source ./zsh-ccusage.plugin.zsh"
end_time=$(date +%s.%N)
load_time=$(echo "$end_time - $start_time" | bc)
if (( $(echo "$load_time < 0.1" | bc -l) )); then
    echo "✅ (${load_time}s)"
else
    echo "⚠️  Load time exceeds 100ms (${load_time}s)"
fi

echo ""
echo "✨ Validation complete!"