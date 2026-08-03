# CODE_STYLE.md

Guidelines inferred from the existing dotfiles. This repo is **config + bash**, so
"code style" covers shell scripts, config file conventions, and CSS. There are **no
linters, formatters, or CI** configured — follow the observed conventions below.

## Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| Config dirs | lowercase, one word | `hypr`, `waybar`, `rofi` |
| Hyprland conf files | lowercase, one concern per file | `keybindings.conf`, `windowrules.conf` |
| Shell scripts | `kebab-case.sh` | `volume-control.sh`, `wallpaper-selector.sh` |
| Shell functions | `_snake_case` (leading underscore) | `_check-package-installed`, `_install-yay` |
| Shell arrays/vars | `snake_case` | `general`, `msgTag`, `ID_FILE` |
| Waybar CSS ids | `#kebab-case` matching module name | `#custom-exit`, `#pulseaudio` |
| Waybar colors | `@define-color` short names | `bg0`, `fg`, `blue`, `red` |
| Wallpaper assets | `Pascal-Case` | `Space-Nebula.png`, `desert-red-sun.jpg` |

## File Organization

- **One concern per file.** Hyprland splits config into `conf/*.conf` sourced from a
  single `hyprland.conf` entry point. Keep this pattern when adding settings.
- **Scripts live next to their config.** `hypr/scripts/`, `waybar/scripts/`,
  `wlogout/icons/`.
- **Assets colocated** with the tool that uses them (`hypr/wallpaper/`).
- **Palette centralized** in `waybar/colors/default.css`; reference it rather than
  duplicating hex values.

## Import / Source Style

- Hyprland: `source = ~/.config/hypr/conf/<name>.conf` at the top of `hyprland.conf`.
- CSS: `@import './colors/default.css';` at the top of `style.css`.
- Shell: `#!/usr/bin/env bash` (or `#!/bin/bash`) shebang on line 1.

## Code Patterns

### Shell scripts
- `set -e` at top of install scripts (`pkgs.sh`).
- `case "$1" in up|down|mute|...) esac` for subcommand dispatch
  (`volume-control.sh`, `brightness-control.sh`).
- Guard clauses with early `exit 1` + `notify-send "Error"` for missing prereqs
  (`wallpaper-selector.sh`).
- Notification ID-replacement pattern — persist last notification ID to a file so
  `notify-send -r` replaces the previous popup:

```bash
ID_FILE="$HOME/.config/hypr/volume_id"
if [ -f "$ID_FILE" ]; then notif_id=$(cat "$ID_FILE"); else notif_id=0; fi
new_id=$(notify-send -r "$notif_id" -u low -i "$icon" "Volume" "$text" -p | head -n1)
echo "$new_id" > "$ID_FILE"
```

- Waybar custom modules emit JSON: `echo "{\"text\":\"...\",\"class\":\"...\"}"`
  (`waybar/scripts/ip/ip.sh`).

### Hyprland config
- Define reusable vars with `$name = value` (`$mainMod = SUPER`, `$terminal = kitty`).
- Group related binds; comment each section (`# Workspaces`, `# Media keys`).
- Use `bindel` for repeatable (volume/brightness) and `bindl` for locked media binds.

### CSS (Waybar / Wlogout)
- Section headers: `/* ---- Section Name ---- */`.
- One selector per rule block, consistent `margin`/`padding`/`border-radius` rhythm.
- Colors referenced via `@define-color` variables, not raw hex.

## Error Handling

- Shell: check prerequisites, `notify-send "Error" "<msg>"`, then `exit 1`.
- `pkgs.sh` uses `set -e` and helper functions returning `0`/`1` for checks.
- No try/catch anywhere (bash); rely on exit codes and `command -v` guards.

## Logging

- No formal logging framework. User feedback is via **`notify-send`** desktop
  notifications (with `--urgency=low` for transient events).
- Install scripts print progress with `echo ":: message..."`.

## Testing

- **No tests exist.** Validation is manual: run `./stow.sh`, restart Waybar
  (`start.sh`), or trigger scripts via keybinds.

## Do's

- Keep one concern per Hyprland conf file; source it from `hyprland.conf`.
- Use `kebab-case` for script filenames, `_snake_case` for shell functions.
- Centralize the color palette in `waybar/colors/default.css`.
- Use the notification ID-replacement pattern for volume/brightness feedback.
- Use `#!/usr/bin/env bash` shebangs and `set -e` in install scripts.

## Don'ts

- Don't hardcode absolute paths that reference other users (`swww.conf` currently has
  `/home/hypr/...` — should be `~/.config/hypr/...`).
- Don't reference `~/.config/ml4w/...` paths (leftover from another setup; not present
  in this repo).
- Don't duplicate hex colors when a `@define-color` exists.
- Don't add a second notification daemon config without reconciling swaync vs Dunst.

## Docs

[hyperland](https://github.com/hyprwm/Hyprland)
[hyperland-wiki](https://wiki.hypr.land/)
[waybar](https://github.com/Alexays/Waybar/wiki)