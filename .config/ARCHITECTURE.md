# ARCHITECTURE.md

## Overview

Personal dotfiles for an **Arch Linux + Hyprland (Wayland)** desktop. All configuration
lives under `.config/` and is installed into `~` via **GNU Stow**. The repo also contains
helper shell scripts for volume/brightness control, wallpaper selection, IP display, and
package installation.

## Tech Stack

| Area | Tech |
|------|------|
| Window manager | [Hyprland](https://hyprland.org) (dwindle layout) |
| Status bar | Waybar (GTK3/CSS) |
| Launcher | rofi-wayland (rasi theme) |
| Notifications | Dunst (dunstrc) + swaync autostarted |
| Wallpaper | swww + swww-daemon |
| Power menu | wlogout |
| Shell widgets | ags (Astal/GTK4, `main.tsx`) |
| Terminal / FM | kitty / dolphin, thunar |
| Audio | PipeWire via `pactl`, `wpctl` |
| Backlight | `brightnessctl` |
| Media keys | `playerctl` |
| Package mgr | pacman + yay (AUR) |

## Directory Structure

```
~/dotfiles/
├── .config/                  # stow target: ~/.config/...
│   ├── ags/                  # Astal shell widget (main.tsx)
│   ├── dunst/                # dunstrc notification daemon config
│   ├── gtk-3.0/              # settings.ini (cursor theme)
│   ├── hypr/                 # Hyprland WM config (modular)
│   │   ├── hyprland.conf     # entry point — sources all conf/*.conf
│   │   ├── conf/             # one file per concern (see below)
│   │   ├── scripts/          # volume/brightness/wallpaper shell scripts
│   │   ├── wallpaper/        # image assets (png/jpg)
│   │   └── swww.conf         # wallpaper daemon defaults
│   ├── rofi/                 # config.rasi theme
│   ├── waybar/               # bar: config.jsonc, style.css, colors/
│   │   └── scripts/ip/       # custom network module script
│   └── wlogout/              # power menu: layout + style.css + icons/
├── scripts/
│   ├── pkgs.sh               # installs the full package list via yay
│   └── install-packages.sh   # placeholder (shebang only)
├── stow.sh                   # stow -d ~/dotfiles -t ~/ . --adopt
└── README.md                 # empty
```

### Hyprland modular config

`hyprland.conf` is a thin entry point that only `source`s the 14 files in `conf/`,
each covering a single concern:

| File | Concern |
|------|---------|
| `monitor.conf` | displays (preferred, auto, 1) |
| `env.conf` | environment vars (NVIDIA/Wayland cursors) |
| `general.conf` | gaps, border size/colors, layout |
| `animations.conf` | bezier curves + animation definitions |
| `decoration.conf` | rounding, opacity |
| `dwindle.conf` | pseudotile, preserve_split |
| `master.conf` | master layout behavior |
| `input.conf` | keyboard layout (us,ru + grp ctrl_space toggle), touchpad |
| `gesture.conf` | 3-finger horizontal gesture → workspace |
| `device.conf` | per-device input tweaks |
| `misc.conf` | disable logo/splash/default wallpaper |
| `keybindings.conf` | all binds (workspaces, media keys, scratchpad) |
| `windowrules.conf` | per-window rules (float, no-focus, move) |
| `autostart.conf` | exec-once: waybar, swaync, swww-daemon + wallpaper |

## Core Components

### Hyprland (`~/.config/hypr`)
- Single entry point `hyprland.conf` sourcing modular `conf/*.conf`.
- Variables `$terminal` (kitty), `$fileManager` (dolphin), `$menu` (rofi) defined in
  `autostart.conf` and used in `keybindings.conf`.
- NVIDIA-specific env vars in `env.conf` (GBM_BACKEND, VK_LAYER, etc.).

### Waybar (`~/.config/waybar`)
- `config.jsonc` — JSONC config: left (appmenu, workspaces, quicklinks group), center
  (window title with rewrite rules), right (audio, network, hw, clock, exit).
- `style.css` — imports `colors/default.css` (One Dark palette via `@define-color`),
  sectioned with `/* ---- Name ---- */` comments.
- `start.sh` — restarts the bar (`pkill waybar` → `hyprctl dispatch exec waybar`).
- `scripts/ip/ip.sh` — emits `{"text","class"}` JSON for the network module.

### Shell scripts (`~/.config/hypr/scripts`)
- `volume-control.sh` — `pactl` sink volume/mute; persists notification ID to
  `~/.config/hypr/volume_id` so notify-send replaces the previous popup.
- `brightness-control.sh` — `brightnessctl` up/down/max/min; same notification
  ID-replacement pattern (`~/.config/hypr/brightness_id`).
- `wallpaper-selector.sh` — finds images in `~/.config/hypr/wallpaper`, shows a rofi
  `-dmenu`, applies selection via `swww img --transition-type random`.

### Package bootstrap (`~/dotfiles/scripts/pkgs.sh`)
- `general` array = full package list (WM stack + utils, see Tech Stack).
- Helpers: `_check-command-exists`, `_check-package-installed`, `_install-yay`,
  `_install-packages` (runs `yay -S --noconfirm` per missing package).

## Data Flow

```
Boot/Hyprland start
  └─ hyprland.conf sources conf/*.conf
       └─ autostart.conf exec-once:
            waybar (reads config.jsonc + style.css + colors/default.css)
            swaync (notifications)
            swww-daemon + swww img <wallpaper>

User input
  └─ keybindings.conf binds:
       $mainMod SPACE → rofi -show drun   (launcher)
       XF86Audio*     → volume-control.sh (pactl → notify-send, ID-replaced)
       XF86Brightness → brightness-control.sh (brightnessctl → notify-send)
       $mainMod ALT W → wallpaper-selector.sh (rofi → swww img)
       custom/exit    → wlogout (layout actions: lock/logout/shutdown/reboot)
```

## External Integrations

- **pactl / wpctl** (PipeWire) — audio volume/mute
- **brightnessctl** — backlight control
- **swww** — wallpaper daemon
- **rofi** — dmenu launcher
- **notify-send** (libnotify) — desktop notifications
- **playerctl** — media player controls
- **hyprctl** — Hyprland IPC (dispatch/exec)
- **nmcli/nmtui** (NetworkManager) — network config from Waybar on-click
- **yay** (AUR) — package installs

## Configuration

- **Stow layout**: `stow.sh` runs `stow -d ~/dotfiles -t ~/ . --adopt`.
  Each directory under `~/dotfiles/` maps 1:1 onto `~/` (e.g. `.config/hypr` →
  `~/.config/hypr`).
- **No env vars / secrets** — all paths hardcoded to `~/.config/...`.
- **Palette**: One Dark, single source of truth in
  `waybar/colors/default.css` (`@define-color`), hardcoded hex reused in
  `dunstrc`, `wlogout/style.css`, and Hyprland `general.conf`.

## Build & Deploy

```sh
# Apply symlinks (writes into $HOME, uses --adopt)
./stow.sh

# Install all packages (Arch, requires yay)
./scripts/pkgs.sh

# Manually restart the bar
~/.config/waybar/start.sh
```

No CI, no tests, no linter configs exist in this repo.

## Known Inconsistencies (observed, not judged)

- `dunstrc` comments are in Russian; config keys otherwise English.
- `swww.conf` has a hardcoded wallpaper path `wallpaper = /home/hypr/...` (wrong user).
- Waybar config references `~/.config/ml4w/scripts/...` paths which do not exist here.
- `scripts/install-packages.sh` is an empty shell (shebang only); real logic is in
  `scripts/pkgs.sh`.
- `autostart.conf` starts both `swaync` and Dunst is configured (`dunstrc` exists) —
  one daemon may shadow the other.
