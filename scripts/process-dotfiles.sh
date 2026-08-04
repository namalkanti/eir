#!/usr/bin/env bash
set -euo pipefail

# Expected variables passed in or defined in Nix context:
# $out, $dotfiles, $fzf_bin

mkdir -p "$out"

# Shell
cp -rL "$dotfiles"/.zshrc          "$out"/.zshrc
cp -rL "$dotfiles"/.bashrc         "$out"/.bashrc
cp -rL "$dotfiles"/.bash_aliases   "$out"/.bash_aliases
cp -rL "$dotfiles"/.p10k.zsh       "$out"/.p10k.zsh

# Strip oh-my-zsh self-management lines — NixOS handles these
sed -i '/^export ZSH=/d'                "$out"/.zshrc
sed -i '/^source \$ZSH\/oh-my-zsh.sh/d' "$out"/.zshrc

# tmux — strip tpm plugin declarations, run line, and default-shell; NixOS manages plugins and shell
cp -rL "$dotfiles"/.tmux.conf "$out"/.tmux.conf
sed -i '/set -g @plugin/d'                         "$out"/.tmux.conf
sed -i "/run '~\/.tmux\/plugins\/tpm\/tpm'/d"      "$out"/.tmux.conf
sed -i '/set-option -g default-shell/d'            "$out"/.tmux.conf

# neovim — strip vim-plug block and patch fzf path; NixOS manages plugins
cp -rL "$dotfiles"/.vimrc "$out"/.vimrc
sed -i '/^call plug#begin/,/^call plug#end/d' "$out"/.vimrc
sed -i "s|/bin/fzf|${fzf_bin}|g"              "$out"/.vimrc
cp -rL "$dotfiles"/.vim "$out"/.vim

# Editor / terminal / file manager configs
cp -rL "$dotfiles"/.config/wezterm         "$out"/wezterm
chmod u+w "$out"/wezterm
sed -i "s/MesloLGS NF/MesloLGS Nerd Font/g" "$out"/wezterm/wezterm.lua
cp -rL "$dotfiles"/.config/lf              "$out"/lf

# Claude — resolve symlinks, inject AGENTS.md, fix CLAUDE.md reference
cp -rL "$dotfiles"/.claude       "$out"/.claude
chmod u+w "$out"/.claude
cp -rL "$dotfiles"/.pi/agent/AGENTS.md "$out"/.claude/AGENTS.md
echo '@~/.claude/AGENTS.md' > "$out"/.claude/CLAUDE.md
