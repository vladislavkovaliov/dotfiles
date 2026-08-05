#!/usr/bin/env bash
#
# setup.sh — one-shot bootstrap for a fresh Arch/Manjaro machine.
# Installs all packages and applies the dotfiles via GNU Stow.
#
# Usage:
#   git clone <repo-url> ~/dotfiles
#   cd ~/dotfiles
#   ./setup.sh
#
# Safe to re-run: package installs skip already-installed packages,
# and stow only manages symlinks for files tracked in this repo.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

echo ":: Setting up dotfiles from $REPO_DIR"

# 1. Install all packages (official + AUR via yay, includes stow).
./scripts/pkgs.sh

# 2. Apply the configs as symlinks into $HOME.
echo ":: Applying configs with GNU Stow..."
./stow.sh

echo ""
echo ":: All done!"
echo "   Log out and back in (or run 'hyprctl dispatch exit' and login again)."
