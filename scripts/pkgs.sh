#!/usr/bin/env bash

general=(
	"blueman"
	"brightnessctl"
	"btop"
	"dunst"
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
	"swww"
	"swaync"
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
    package="$1"
    
	check="$(sudo pacman -Qs --color always "${package}" | grep "local" | grep "${package} ")"
    
	if [ -n "${check}" ]; then
        echo 0
        return #true
    fi
    
	echo 1
    
	return #false
}

_install-yay() {
    _installPackages "base-devel"
    
	SCRIPT=$(realpath "$0")
    
	temp_path=$(dirname "$SCRIPT")
    
	git clone https://aur.archlinux.org/yay.git $download_folder/yay
    
	cd $download_folder/yay
    
	makepkg -si
    
	cd $temp_path
    
	echo ":: yay has been installed successfully."
}

_install-packages() {
    toInstall=()
    
	for pkg; do
        if [[ $(_isInstalled "${pkg}") == 0 ]]; then
            echo ":: ${pkg} is already installed."
    
	        continue
        fi
    
	    echo "Package not installed: ${pkg}"
    
	    yay --noconfirm -S "${pkg}"
    done
}

clear

echo -e "${GREEN}"

cat <<"EOF"
   ____    __          
  / __/__ / /___ _____ 
 _\ \/ -_) __/ // / _ \
/___/\__/\__/\_,_/ .__/
                /_/    

EOF
echo -e "${NONE}"