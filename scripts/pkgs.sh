#!/usr/bin/env bash
#
# pkgs.sh — bootstrap installer for the base Arch Linux + Hyprland package set.
# Safe to re-run: pacman/yay --needed skip already-installed packages.
# Requires: sudo access. Installs the yay AUR helper automatically if missing.

set -euo pipefail

# Official packages (Arch Linux repos) — installed via pacman.
official=(
	awww                      # wallpaper daemon (replaces swww)
	brightnessctl             # backlight control (keybindings/scripts)
	btop                      # system monitor
	dolphin                   # file manager
	fastfetch                 # system info
	firefox                   # browser
	flatpak                   # flatpak apps
	git                       # vcs / yay build dependency
	gum                       # shell scripting helper (setup scripts)
	hyprland                  # wayland compositor
	hyprlock                  # screen locker (wlogout)
	jq                        # json processor (wayle modules)
	kitty                     # terminal
	libnotify                 # notify-send (scripts)
	libpulse                  # pactl (volume scripts)
	neovim                    # editor
	networkmanager            # network management (wayle module)
	pipewire                  # audio server
	pipewire-pulse            # pulseaudio compat (wpctl)
	playerctl                 # media control (keybindings)
	qt5-wayland               # qt5 wayland support
	qt6-wayland               # qt6 wayland support
	rofi-wayland              # app launcher / menu
	stow                      # symlink dotfiles into ~ (setup.sh)
	ttf-fira-code             # monospace font
	ttf-fira-sans             # UI font
	ttf-font-awesome          # icon font
	unzip                     # archive extraction
	upower                    # battery info (wayle module)
	wget                      # downloads
	wireplumber               # pipewire session manager
	xdg-desktop-portal-hyprland  # hyprland xdg portal
)

# AUR packages — installed via yay (auto-installed by _install-yay if missing).
aur=(
	blueman            # bluetooth manager (wayle module)
	ttf-firacode-nerd  # nerd-font variant of fira code
	wayle-bin          # status bar / notification daemon (replaces waybar + swaync)
	wleave             # power/logout menu (wlogout-compatible)
	hyprshutdown       # shutdown from keybinding (guarded by command -v in configs)
)

# Optional packages — commented out on purpose; uncomment and wire into a loop
# (or add entries to ${aur[@]}) to install them:
#   power-profiles-daemon  # laptop power-profiles daemon
#   grim                   # screenshot utility (wlroots)
#   slurp                  # region selector for grim
#   swappy                 # screenshot annotation/editor
#   wl-clipboard           # wl-copy / wl-paste clipboard tools
# optional=(
# 	power-profiles-daemon
# 	grim
# 	slurp
# 	swappy
# 	wl-clipboard
# )

# Install the yay AUR helper if it is not already present.
_install-yay() {
	if command -v yay >/dev/null 2>&1; then
		echo ":: yay is already installed."
		return 0
	fi

	echo ":: Installing yay (AUR helper)..."
	sudo pacman -S --needed --noconfirm base-devel

	local clone_dir="$HOME/Downloads/yay"
	mkdir -p "$HOME/Downloads"

	if [[ -d "$clone_dir" ]]; then
		echo ":: yay clone exists — pulling latest..."
		git -C "$clone_dir" pull --ff-only
	else
		git clone https://aur.archlinux.org/yay.git "$clone_dir"
	fi

	(
		cd "$clone_dir" || exit 1
		makepkg -si --noconfirm
	)

	rm -rf "$clone_dir"
	echo ":: yay has been installed successfully."
}

# Install all official (pacman) packages in one call.
_install-official() {
	echo ":: Installing official packages (${#official[@]} total)..."
	sudo pacman -S --needed --noconfirm "${official[@]}"
}

# Install all AUR packages in one call.
_install-aur() {
	echo ":: Installing AUR packages (${#aur[@]} total)..."
	yay -S --needed --noconfirm "${aur[@]}"
}

main() {
	_install-official

	if ! command -v yay >/dev/null 2>&1; then
		_install-yay
	fi

	_install-aur

	echo ":: All packages installed."
}

main "$@"
