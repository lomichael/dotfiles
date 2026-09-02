#!/usr/bin/env bash
# Idempotent dotfiles installer. Safe to re-run any time.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        echo "ok      $dest"
        return
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        local backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
        mv "$dest" "$backup"
        echo "backed up existing $dest -> $backup"
    fi

    ln -s "$src" "$dest"
    echo "linked  $dest -> $src"
}

echo "==> Symlinking dotfiles from $DOTFILES"
link "$DOTFILES/.zshrc"                       "$HOME/.zshrc"
link "$DOTFILES/.tmux.conf"                   "$HOME/.tmux.conf"
link "$DOTFILES/ghostty/config"               "$HOME/.config/ghostty/config"
link "$DOTFILES/nvim/init.lua"                "$HOME/.config/nvim/init.lua"
link "$DOTFILES/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"

chmod +x "$DOTFILES/claude/statusline-command.sh"

echo "==> Configuring Claude Code status line"
settings="$HOME/.claude/settings.json"
mkdir -p "$(dirname "$settings")"
[ -f "$settings" ] || echo '{}' > "$settings"

if command -v jq >/dev/null 2>&1; then
    tmp="$(mktemp)"
    jq '.statusLine = {"type": "command", "command": "bash ~/.claude/statusline-command.sh"} | .theme = "light"' "$settings" > "$tmp"
    mv "$tmp" "$settings"
    echo "ok      $settings (statusLine + theme set)"
else
    echo "!! jq not found - add this to $settings manually:"
    echo '   "statusLine": {"type": "command", "command": "bash ~/.claude/statusline-command.sh"},'
    echo '   "theme": "light"'
fi

echo "==> Installing tmux plugin manager (tpm)"
tpm_dir="$HOME/.tmux/plugins/tpm"
if [ -d "$tpm_dir" ]; then
    echo "ok      tpm already installed"
else
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    echo "installed tpm -> $tpm_dir"
fi

echo "==> Done. Remaining manual steps:"
echo "   - restart your shell: exec zsh"
echo "   - open nvim once to let lazy.nvim install plugins"
echo "   - in tmux, press prefix (Ctrl-s) + I to install tmux plugins"
