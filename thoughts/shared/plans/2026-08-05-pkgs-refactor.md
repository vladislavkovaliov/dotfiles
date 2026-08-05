# pkgs.sh Refactor + install-packages.sh Wrapper — Implementation Plan

**Goal:** Rewrite `scripts/pkgs.sh` into a correct, idempotent bootstrap installer (official pacman → yay AUR helper → AUR packages) and turn `scripts/install-packages.sh` into a thin wrapper that `exec`s it.

**Architecture:** Drop all manual installed-package checking (the broken `_check-package-installed` / `_check-command-exists`). `pacman -S --needed --noconfirm` and `yay -S --needed --noconfirm` are themselves idempotent, so the script reduces to three operations in `main()`: install official packages (one pacman call), ensure yay exists (guarded, self-installing), install AUR packages (one yay call). Package list is split into `official=()` / `aur=()` / `optional=()` (commented out with explanations) to match what the Hyprland configs actually invoke (wayle replaces waybar+swaync, awww replaces swww, thunar/swaync/swww/waybar removed).

**Design:** [2026-08-05-pkgs-refactor-design.md](../designs/2026-08-05-pkgs-refactor-design.md)

**Environment notes (verified):**
- `shellcheck` is **not** installed on this machine → verification uses `bash -n` always, plus `command -v shellcheck` guarded check.
- Both scripts already exist and are executable (`-rwxr-xr-x`). Implementers must re-apply `chmod +x` if their editor rewrites the file (Write/redirection resets the mode).

**Decisions made where the design was silent:**
- *Existing yay clone dir:* design says "pull or skip" → **implemented as `git -C ... pull --ff-only`** (keeps the clone fresh; fails loudly if the dir is a non-git directory).
- *makepkg cwd:* run inside a subshell `( cd ... && makepkg )` so the parent shell's working directory is never mutated — safer with `set -euo pipefail`.
- *yay guard:* present both inside `_install-yay()` (self-contained, idempotent if called directly) and as a `command -v` check in `main()` before calling it (matches design's "если нет" flow; avoids a redundant function call).
- *`optional=` array:* fully commented out (`# optional=( ... )`) with a per-package explanation comment block above it, per design "закомментированы, с пояснением".
- *No arguments* are expected; `main "$@"` is used so future args don't get silently dropped.

---

## Dependency Graph

```
Batch 1 (2 parallel): Task 1.1 — rewrite scripts/pkgs.sh
                      Task 1.2 — rewrite scripts/install-packages.sh (wrapper)
                      (independent: different files, no build-time coupling)
Batch 2 (1):          Task 2.1 — full verification pass (bash -n, shellcheck if
                      available, structural + package-list checks, chmod +x)
```

No file conflicts between Batch 1 tasks. Batch 2 only reads both files.

---

## Batch 1: Implementation (parallel — 2 implementers)

### Task 1.1: Rewrite `scripts/pkgs.sh`
**File:** `scripts/pkgs.sh` (MODIFY — exists, currently broken)
**Test:** none (shell script; verified in Task 2.1 — `bash -n` + structural checks)
**Depends:** none
**Commit:** `fix(scripts): rewrite pkgs.sh with correct package lists and idempotent install`

Replace the entire file content with **exactly** the following:

```bash
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
	ttf-fira-code             # monospace font
	ttf-fira-sans             # UI font
	ttf-font-awesome          # icon font
	unzip                     # archive extraction
	upower                    # battery info (wayle module)
	wget                      # downloads
	wireplumber               # pipewire session manager
	wlogout                   # logout menu
	xdg-desktop-portal-hyprland  # hyprland xdg portal
)

# AUR packages — installed via yay (auto-installed by _install-yay if missing).
aur=(
	blueman            # bluetooth manager (wayle module)
	ttf-firacode-nerd  # nerd-font variant of fira code
	wayle-bin          # status bar / notification daemon (replaces waybar + swaync)
	wleave             # wayle lockscreen integration
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
```

**Verify (run now, quick smoke):**
```bash
bash -n scripts/pkgs.sh && echo "syntax OK"
! grep -E '_check-package-installed|_check-command-exists' scripts/pkgs.sh
grep -q '^set -euo pipefail' scripts/pkgs.sh
grep -q '^official=(' scripts/pkgs.sh
grep -q '^aur=(' scripts/pkgs.sh
grep -q '^# optional=(' scripts/pkgs.sh
```

---

### Task 1.2: Rewrite `scripts/install-packages.sh` as thin wrapper
**File:** `scripts/install-packages.sh` (MODIFY — exists, currently just a shebang)
**Test:** none (shell script; verified in Task 2.1 — `bash -n` + grep)
**Depends:** none (calls `pkgs.sh` at runtime; content is independent of Task 1.1)
**Commit:** `refactor(scripts): make install-packages.sh a thin wrapper around pkgs.sh`

Replace the entire file content with **exactly** the following:

```bash
#!/usr/bin/env bash
# install-packages.sh — thin wrapper around pkgs.sh. See pkgs.sh for details.

exec "$(dirname "$0")/pkgs.sh"
```

Notes: `exec` replaces the shell process with `pkgs.sh` (same exit code propagated, no subshell overhead). The shebang is kept, so the script remains directly executable. No `set -e` is needed — nothing executes after `exec`.

**Verify (run now, quick smoke):**
```bash
bash -n scripts/install-packages.sh && echo "syntax OK"
grep -q '#!/usr/bin/env bash' scripts/install-packages.sh
grep -q 'exec "$(dirname "$0")/pkgs.sh"' scripts/install-packages.sh
```

---

## Batch 2: Verification (1 implementer)

### Task 2.1: Full verification pass
**File:** none (read-only checks on both scripts)
**Test:** n/a
**Depends:** 1.1, 1.2
**Commit:** (none — verification only; user commits)

Run all of the following:

```bash
# 1. Syntax — both scripts must pass
bash -n scripts/pkgs.sh && bash -n scripts/install-packages.sh && echo "syntax OK"

# 2. Executable bit preserved (Write/redirection can reset it)
chmod +x scripts/pkgs.sh scripts/install-packages.sh

# 3. Shellcheck, if available (not currently installed — guarded)
if command -v shellcheck >/dev/null 2>&1; then
	shellcheck scripts/pkgs.sh scripts/install-packages.sh
else
	echo "shellcheck not installed — skipped"
fi

# 4. Broken functions fully removed
! grep -E '_check-package-installed|_check-command-exists' scripts/pkgs.sh

# 5. Array contents — official must be exactly 32, aur exactly 5
echo "official=$(awk '/^official=\(/{f=1;next} f&&/^\)/{f=0} f&&NF{n++} END{print n}' scripts/pkgs.sh) (expect 32)"
echo "aur=$(awk '/^aur=\(/{f=1;next} f&&/^\)/{f=0} f&&NF{n++} END{print n}' scripts/pkgs.sh) (expect 5)"
echo "optional-commented=$(grep -cE '^\s*#?\s*(power-profiles-daemon|grim|slurp|swappy|wl-clipboard)' scripts/pkgs.sh) (expect 5)"

# 6. Removed obsolete packages are gone (swww, waybar, swaync, thunar)
! grep -qE '^(\s*)(swww|waybar|swaync|thunar)(\s|$)' scripts/pkgs.sh

# 7. Wrapper correctness
grep -q 'exec "$(dirname "$0")/pkgs.sh"' scripts/install-packages.sh

# 8. Key behaviors present
grep -q 'command -v yay' scripts/pkgs.sh                          # yay guard
grep -q 'makepkg -si --noconfirm' scripts/pkgs.sh                 # non-interactive build
grep -q 'rm -rf' scripts/pkgs.sh                                  # clone cleanup
grep -q -- '--needed --noconfirm "${official\[@\]}"' scripts/pkgs.sh  # single pacman call
grep -q -- '--needed --noconfirm "${aur\[@\]}"' scripts/pkgs.sh       # single yay call
```

**Manual smoke test (optional, on the live machine — installs nothing new if already up to date):**
```bash
./scripts/install-packages.sh
# Expect: ":: Installing official packages (32 total)...", pacman "Nothing to do"
# (or per-package "up to date"), yay "already installed" (or auto-install),
# ":: All packages installed.", exit 0.
```
Note: this is a real install run (may pull updates/missing packages) — do it deliberately, not as a CI check.

**Out of scope (from design Open Questions):** `lockscreen.sh` is invoked by the wlogout suspend layout but is not in the repo — unchanged here; flag to the user.

---

## Notes for the user

- Suggested commit (after verification): `fix(scripts): rewrite pkgs.sh with correct package lists and idempotent install` + `refactor(scripts): make install-packages.sh a thin wrapper around pkgs.sh` — the user commits; do not commit from this plan.
- Package list deltas vs old script: **removed** `swww`, `waybar`, `swaync`, `thunar`; **added** `awww`, `libnotify`, `libpulse`, `pipewire`, `pipewire-pulse`, `upower`, `xdg-desktop-portal-hyprland`, `wleave`, `hyprshutdown`; moved `blueman`/`ttf-firacode-nerd` into the `aur` array (previously mixed into the general loop).
