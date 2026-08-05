---
date: 2026-08-05
topic: "Refactor scripts/pkgs.sh (variant B) + fix package list"
status: validated
---

# Refactor scripts/pkgs.sh + Fix Package List

## Problem Statement

`scripts/pkgs.sh` — bootstrap-скрипт установки базового набора пакетов для Arch Linux + Hyprland (dotfiles repo). Скрипт содержит критические баги и устаревший список пакетов:

- `_check-package-installed` сломана: `"${$1}"` — синтаксическая ошибка, внутри используется несуществующая переменная `package`. Функция всегда возвращает «не установлен».
- `_install-yay` определена, но нигде не вызывается → на свежей системе без yay скрипт падает на первой итерации.
- Семантика return перепутана (`return 1 #true`), результат читается через `$()` из пустого stdout.
- Нет `set -u` / `set -o pipefail`.
- `_install-yay`: `cd ~/Downloads` без проверки, `makepkg -si` без `--noconfirm`, нет очистки.
- Список пакетов рассинхронизирован с конфигами (см. Constraints).

## Constraints

- Скрипт должен работать на свежей установке Arch (без yay, без зависимостей).
- Повторный запуск (идемпотентность) должен быть безопасным.
- Список пакетов должен покрывать все бинарники, вызываемые из конфигов:
  - hyprland.lua (active entry): `wayle panel start`, `awww-daemon`, `awww img`, `kitty`, `dolphin`, `rofi`, `playerctl`, `wpctl`, `brightnessctl`, скрипты volume/brightness/wallpaper
  - keybindings.conf: `playerctl`, `wpctl`, `hyprshutdown` (optional, guarded by command -v)
  - scripts/*.sh: `pactl`, `brightnessctl`, `notify-send`, `rofi`, `awww`, `find`, `basename`
  - wlogout layout: `hyprlock`, `hyprctl dispatch exit`, `systemctl suspend/poweroff/hibernate/reboot`, `lockscreen.sh` (не в репо — внешний)
  - wayle bar modules (ARCHITECTURE.md): bluetooth, network, volume, battery, power
- Замены по ARCHITECTURE.md: wayle заменяет waybar и swaync; awww заменил swww.

## Approach

Убрать ручную проверку установки полностью — `pacman/yay -S --needed` сам пропускает установленные пакеты. Логика сводится к трём операциям: установка официальных пакетов, гарантия наличия yay, установка AUR-пакетов. Разделение на official/AUR ускоряет установку (official не дёргает AUR-поиск) и позволяет ставить official до появления yay.

Отклонено: вариант A (минимальный фикс) — сохраняет сломанную архитектуру проверок; вариант C (вынос списка в отдельный файл) — избыточен для 30-40 пакетов.

## Architecture

```
scripts/pkgs.sh
├── official=()   # pacman -S --needed --noconfirm
├── aur=()        # yay -S --needed --noconfirm
├── optional=()   # закомментированы, с пояснением
├── _install-yay()
├── _install-official()
├── _install-aur()
└── main()
```

`scripts/install-packages.sh` → тонкая обёртка: `exec "$(dirname "$0")/pkgs.sh"`.

## Components

- **`_install-yay`**: guard `command -v yay`; `sudo pacman -S --needed --noconfirm base-devel`; `mkdir -p "$HOME/Downloads"`; clone yay (если каталог существует — `git -C ... pull` или пропуск); `makepkg -si --noconfirm`; `rm -rf` после установки.
- **`_install-official`**: один вызов `sudo pacman -S --needed --noconfirm "${official[@]}"`.
- **`_install-aur`**: один вызов `yay -S --needed --noconfirm "${aur[@]}"`.
- **`main`**: `_install-official` → `_install-yay` (если нет) → `_install-aur`. Прогресс-вывод по секциям (`:: Installing official packages...`).
- Шапка с `set -euo pipefail`.

## Data Flow

1. Запуск `./scripts/pkgs.sh`
2. Установка всех official-пакетов одним pacman-вызовом
3. Проверка `command -v yay` → при отсутствии `_install-yay`
4. Установка всех AUR-пакетов одним yay-вызовом
5. Exit 0

## Package List

**official (pacman):** awww, brightnessctl, btop, dolphin, fastfetch, firefox, flatpak, git, gum, hyprland, hyprlock, jq, kitty, libnotify, libpulse, neovim, networkmanager, pipewire, pipewire-pulse, playerctl, qt5-wayland, qt6-wayland, rofi-wayland, ttf-fira-code, ttf-fira-sans, ttf-font-awesome, unzip, upower, wget, wireplumber, wlogout, xdg-desktop-portal-hyprland

**aur (yay):** blueman, ttf-firacode-nerd, wayle-bin, wleave, hyprshutdown

**optional (закомментированы):** power-profiles-daemon, grim, slurp, swappy, wl-clipboard

**Убраны:** swww (→ awww), waybar (→ wayle), swaync (→ wayle), thunar (не используется конфигами).

## Error Handling

- `set -euo pipefail` — ловит необъявленные переменные и падения пайпов.
- Отсутствие yay не роняет скрипт — он доставляется автоматически.
- Повторный запуск безопасен: `--needed` пропускает установленные.
- `_install-yay` защищена от существующего каталога клона и отсутствующего `~/Downloads`.

## Testing Strategy

- `bash -n scripts/pkgs.sh` — проверка синтаксиса.
- `shellcheck scripts/pkgs.sh` — если установлен.
- Ручной прогон на системе: вывод должен содержать «already up to date»/«Nothing to do» для уже установленных пакетов.
- Проверка, что `scripts/install-packages.sh` вызывает `pkgs.sh` (обёртка).

## Open Questions

- `lockscreen.sh` вызывается из wlogout layout (suspend), но файла нет в репозитории — вне скоупа, отмечено в отчёте пользователю.
- Список AUR-пакетов (wayle-bin vs wayle) может потребовать уточнения имени при установке; wayle-bin выбран как бинарная сборка по документации wayle.app.
