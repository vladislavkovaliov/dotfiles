# dotfiles

Personal dotfiles for an **Arch Linux + Hyprland (Wayland)** desktop.

- Window manager: Hyprland (Lua config)
- Desktop shell: wayle (bar + notifications)
- Launcher: rofi-wayland
- Wallpaper: awww
- Terminal / File manager: kitty / dolphin

See `.config/ARCHITECTURE.md` for the full stack breakdown.

## Requirements

- Arch Linux
- `sudo` access
- `git` and `stow` (GNU Stow) for applying the configs

## One-shot setup (fresh machine)

On a new Arch or Manjaro machine, a single command sets everything up —
packages, AUR helper, and configs:

```sh
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./setup.sh
```

`setup.sh` runs the package installer (`scripts/pkgs.sh`) and then applies the
configs with GNU Stow (`./stow.sh`). It is idempotent — re-running it is safe.

> [!NOTE]
> **How symlinks work:** `stow` creates symlinks from `~/dotfiles/.config/*`
> into `~/` (e.g. `~/.config/hypr` → `~/dotfiles/.config/hypr`). Configs are
> "live": edits in `~/dotfiles` take effect immediately. The `--adopt` flag in
> `stow.sh` merges any pre-existing local configs into the repo on the first
> run (on a fresh machine there is normally nothing to merge).

## Manual setup

Clone the repository into your home directory:

```sh
git clone https://github.com/your-user/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 1. Apply the configuration

```sh
./stow.sh
```

This runs `stow -d ~/dotfiles -t ~/ . --adopt`, symlinking every directory
under the repo into your home directory (`.config/hypr` → `~/.config/hypr`, etc.).

### 2. Install the packages

```sh
./scripts/pkgs.sh
```

or the equivalent wrapper:

```sh
./scripts/install-packages.sh
```

The script:

- Installs all **official** packages from the Arch repos in one `pacman` call
- Installs the **yay** AUR helper automatically if it is missing
- Installs all **AUR** packages in one `yay` call

> [!NOTE]
> The script is **idempotent** — re-running it is safe. Already-installed
> packages are skipped via `--needed`.

## Package list

- **Official (pacman):** awww, brightnessctl, btop, dolphin, fastfetch, firefox, flatpak, git, gum, hyprland, hyprlock, jq, kitty, libnotify, libpulse, neovim, networkmanager, opencode, pipewire, pipewire-pulse, playerctl, qt5-wayland, qt6-wayland, ripgrep, rofi-wayland, stow, ttf-fira-code, ttf-fira-sans, ttf-font-awesome, unzip, upower, wget, wireplumber, xdg-desktop-portal-hyprland
- **AUR (yay):** blueman, ttf-firacode-nerd, wayle-bin, wleave, hyprshutdown
- **Optional** (commented out in `scripts/pkgs.sh`): power-profiles-daemon, grim, slurp, swappy, wl-clipboard

To install optional packages, uncomment the `optional=` block in
`scripts/pkgs.sh` and add the entries to the `aur=` array (or a loop).

## After install

Restart Hyprland (or log out and back in) so the new configs take effect:

```sh
hyprctl dispatch exit
```

The desktop shell starts automatically on the next login (`wayle panel start`
runs from `hyprland.lua`).
