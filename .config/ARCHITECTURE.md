# ARCHITECTURE.md

## Overview

Personal dotfiles for an **Arch Linux + Hyprland (Wayland)** desktop. All configuration
lives under `.config/` and is installed into `~` via **GNU Stow**. The repo also contains
helper shell scripts for volume/brightness control, wallpaper selection, IP display, and
package installation.

## Tech Stack

| Area | Tech |
|------|------|
| Window manager | [Hyprland](https://hyprland.org) (dwindle layout, Lua config) |
| Desktop shell (bar) | wayle (panel, notify, systray, media) |
| Launcher | rofi-wayland (rasi theme) |
| Notifications | wayle notify (built-in) |
| Wallpaper | awww (former swww) |
| Power menu | wleave (wlogout-compatible) |
| Lock screen | hyprlock |
| Terminal / FM | kitty / dolphin |
| Editor | nvim (AstroNvim + lazy.nvim) |
| AI coding agent | opencode |
| Audio | PipeWire via `pactl`, `wpctl` |
| Backlight | `brightnessctl` |
| Media keys | `playerctl` |
| Package mgr | pacman + yay (AUR) |

## Directory Structure

```
~/dotfiles/
├── .config/                  # stow target: ~/.config/...
│   ├── gtk-3.0/              # settings.ini (Adwaita theme)
│   ├── hypr/                 # Hyprland WM config (Lua entry + conf/*.conf)
│   │   ├── hyprland.lua      # entry point (Hyprland 0.56 Lua API)
│   │   ├── hyprland.conf     # legacy .conf entry point (rollback fallback)
│   │   ├── conf/             # one file per concern (see below)
│   │   ├── scripts/          # volume/brightness/wallpaper/lock shell scripts
│   │   ├── wallpaper/        # image assets (png/jpg)
│   │   ├── hyprlock.conf     # lock screen config
│   │   └── swww.conf         # legacy wallpaper daemon defaults (awww)
│   ├── nvim/                 # AstroNvim config (lazy.nvim, mason LSP)
│   ├── opencode/             # opencode AI agent config (profiles/, plugins)
│   ├── rofi/                 # config.rasi theme
│   ├── wayle/                # bar/notify shell: runtime.toml + styles + themes
│   ├── wleave/               # power menu: layout.json + style.css
│   └── wlogout/              # legacy power menu (wleave-compatible fallback)
├── scripts/
│   ├── pkgs.sh               # installs official (pacman) + AUR (yay) packages
│   └── install-packages.sh   # thin wrapper → pkgs.sh
├── setup.sh                  # one-shot: pkgs.sh + stow.sh
├── stow.sh                   # stow -d ~/dotfiles -t ~/ . --adopt
└── README.md
```

### Hyprland modular config

`hyprland.lua` is the active entry point (Hyprland 0.56 Lua API). The legacy
`hyprland.conf` + `conf/*.conf` are kept as a rollback fallback. The 14 `conf/*.conf`
files each cover a single concern:

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
| `autostart.conf` | exec-once: awww-daemon + wallpaper (wayle via hyprland.lua) |

## Core Components

### Hyprland (`~/.config/hypr`)
- Active entry point `hyprland.lua` (Lua API) with `conf/*.conf` as rollback fallback.
- Variables `$terminal` (kitty), `$fileManager` (dolphin), `$menu` (rofi) defined in
  `autostart.conf` and used in `keybindings.conf`.
- NVIDIA-specific env vars in `env.conf` (GBM_BACKEND, VK_LAYER, etc.).

### wayle (`~/.config/wayle`)
- Desktop shell: `wayle shell` runs the bar, `wayle notify` handles notifications.
- `runtime.toml` — bar layout: left (hyprland-workspaces), center (clock), right
  (bluetooth, network, volume, battery, power → `wleave -b 1`).
- `styles/index.scss` — custom styling overrides.
- Replaces both Waybar and swaync.

### Shell scripts (`~/.config/hypr/scripts`)
- `volume-control.sh` — `pactl` sink volume/mute; persists notification ID to
  `~/.config/hypr/volume_id` so notify-send replaces the previous popup.
- `brightness-control.sh` — `brightnessctl` up/down/max/min; same notification
  ID-replacement pattern (`~/.config/hypr/brightness_id`).
- `wallpaper-selector.sh` — finds images in `~/.config/hypr/wallpaper`, shows a rofi
  `-dmenu`, applies selection via `awww img --transition-type grow`.

### Package bootstrap (`~/dotfiles/scripts/pkgs.sh`)
- `official` array (pacman) + `aur` array (yay) + commented-out `optional` array.
- `set -euo pipefail`; idempotent via `--needed`.
- `_install-yay` bootstraps the AUR helper from source if missing, then a single
  `yay -S --needed --noconfirm "${aur[@]}"` call installs all AUR packages.

### wleave (`~/.config/wleave`)
- Power menu (wlogout-compatible, GTK4). Launched from the wayle bar's power
  module: `wleave -b 1`.
- `layout.json` — buttons (lock/hibernate/logout/shutdown/suspend/reboot) with
  keybinds and per-action fallbacks; suspend chains `lockscreen.sh && systemctl
  suspend`. `style.css` — GTK CSS (libadwaita vars, one-dark palette).

### nvim (`~/.config/nvim`)
- AstroNvim distribution (lazy.nvim bootstrap in `init.lua`, plugins in `lua/plugins/`).
- LSP servers via mason (`lua/plugins/mason.lua`), `lazy-lock.json` pins versions.

### opencode (`~/.config/opencode`)
- AI coding agent (terminal). `opencode.jsonc` selects model + DCP plugin; per-profile
  config in `profiles/{default,micode}/`.

## Data Flow

```
Boot/Hyprland start
  └─ hyprland.lua (Lua API)
       └─ hyprland.start event:
            wayle panel start  (bar + notifications)
            awww-daemon + awww img <wallpaper>

User input
  └─ keybindings.conf / hyprland.lua binds:
       $mainMod SPACE → rofi -show drun   (launcher)
       XF86Audio*     → volume-control.sh (pactl → notify)
       XF86Brightness → brightness-control.sh (brightnessctl → notify)
       $mainMod ALT W → wallpaper-selector.sh (rofi → awww img)
       power module   → wleave -b 1 (lock/suspend/logout/shutdown/reboot)
```

## External Integrations

- **pactl / wpctl** (PipeWire) — audio volume/mute
- **brightnessctl** — backlight control
- **awww** — wallpaper daemon
- **rofi** — dmenu launcher
- **notify-send** (libnotify) / wayle notify — desktop notifications
- **playerctl** — media player controls
- **hyprctl** — Hyprland IPC (dispatch/exec)
- **nmcli/nmtui** (NetworkManager) — network config from wayle on-click
- **yay** (AUR) — package installs

## Configuration

- **Stow layout**: `stow.sh` runs `stow -d ~/dotfiles -t ~/ . --adopt`.
  Each directory under `~/dotfiles/` maps 1:1 onto `~/` (e.g. `.config/hypr` →
  `~/.config/hypr`).
- **No env vars / secrets** — all paths hardcoded to `~/.config/...`.
- **Palette**: One Dark, single source of truth in
  `wayle/styles/` (`@define-color`), hardcoded hex reused in
  `wlogout/style.css` and Hyprland `general.conf`.

## Build & Deploy

```sh
# Apply symlinks (writes into $HOME, uses --adopt)
./stow.sh

# Install all packages (Arch, requires yay)
./scripts/pkgs.sh

# Manually restart the bar
wayle panel restart
```

No CI, no tests, no linter configs exist in this repo.

## Known Inconsistencies (observed, not judged)

- `swww.conf` has a hardcoded wallpaper path `wallpaper = /home/hypr/...` (wrong user).
- `hyprland.conf` + `conf/*.conf` are legacy rollback; active config is `hyprland.lua`.
- `wlogout/` is legacy — the active power menu is `wleave/` (kept as compatible fallback).
