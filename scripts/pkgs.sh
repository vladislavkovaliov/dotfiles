#!/usr/bin/env bash

set -e 

general=(
	"blueman"
	"brightnessctl"
	"btop"
	"fastfetch"
	"firefox"
	"flatpak"
	"git"
	"gum"
	"hyprland"
	"hyprlock"
	"jq"
	"kitty"
	"neovim"
	"networkmanager"
	"qt5-wayland"
	"qt6-wayland"
	"rofi-wayland"
	"swaync"
	"swww"
	"thunar"
	"ttf-fira-code"
	"ttf-fira-sans"
	"ttf-firacode-nerd"
	"ttf-font-awesome"
	"unzip"
	"waybar"
	"wget"
	"wireplumber"
	"wlogout"
	"xdg-desktop-portal-hyprland"
)


_check-command-exists() {
    cmd="$1"
    
	if ! command -v "$cmd" >/dev/null; then
            echo 1
    
	    return
        fi
    
	echo 0
    
	return
}


_check-package-installed() {
	check="$(sudo pacman -Qs --color always "${$1}" | grep "local" | grep "${package} ")"
    
	if [ -n "${check}" ]; then
           return 1 #true
        fi
    
	return 0 #false
}

_install-yay() {
	echo ":: Installing yay..."    
    
	sudo pacman -S --needed --noconfirm base-devel    
	
	cd "$HOME/Downloads"    
	
	git clone https://aur.archlinux.org/yay.git    
	
	cd yay
    	
	makepkg -si
	
	cd ~
	
	echo ":: yay has been installed successfully."
}

_install-packages() {
    
	for pkg in "${general[@]}"; do
        
	if [[ $(_check-package-installed "$pkg") == 0 ]]; then
            	echo ":: ${pkg} is already installed."
	    	continue
        else
		echo ":: Install $pkg ..."
		yay -S --noconfirm "$pkg"
	fi
	done
}


_install-packages


