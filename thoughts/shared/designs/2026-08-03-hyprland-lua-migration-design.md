---
date: 2026-08-03
topic: "Hyprland: миграция конфига с hyprlang (.conf) на Lua (.lua)"
status: validated
---

# Миграция конфига Hyprland на Lua

## Problem Statement

Пользователь видит при старте Hyprland 0.56.1 предупреждение о «не поддерживаемом формате конфига». Причина: Hyprland 0.55 перешёл с формата hyprlang (`.conf`) на Lua (`hyprland.lua`). Начиная с 0.57 поддержка `.conf` будет удалена полностью. Плюс в текущем конфиге 2 реальные ошибки (подтверждено `hyprctl configerrors`):

1. `conf/dwindle.conf:2` — `dwindle:pseudotile` удалена в 0.55 («ничего не делала»).
2. `conf/keybindings.conf:11` — диспетчер `togglesplit` удалён в 0.54 (замена: `layoutmsg` / `hl.dsp.layout("togglesplit")`).

## Constraints

- Текущая версия Hyprland: **0.56.1** (Lua API 0.56, стубы в `/usr/share/hypr/stubs/hl.meta.lua`).
- Конфиг живёт в git-репо `~/dotfiles`, файлы в `~/.config/hypr/` — симлинки на `~/dotfiles/.config/hypr/`.
- `.conf` должен остаться нетронутым как фолбэк до полной проверки `.lua`.
- Миграция не должна ломать живую сессию: проверка до перезапуска, откат — удалением `hyprland.lua`.

## Approach

**Конвертер + ручная доводка.** Используем конвертер `hyprmorph` (LuaRocks, целится в API 0.56, сохраняет комментарии, помечает неоднозначное как Lua-комментарии с `WARNING`) для первичной генерации, затем вручную исправляем отмеченные места по таблице маппинга ниже.

**Форма:** один консолидированный `hyprland.lua` с секционными комментариями (вместо `conf/*.conf` + `source`). Конфиг маленький (~14 файлов, большинство крошечные) — `require`-разбиение добавит возни с путями без выгоды. Структуру секций берём из эталона `/usr/share/hypr/hyprland.lua` — пользовательский конфиг является его вариацией, маппинг почти 1:1.

## Architecture (до → после)

**До:**

```
~/.config/hypr/
├── hyprland.conf -> ../../dotfiles/.config/hypr/hyprland.conf   (14× source = conf/*.conf)
├── conf/ -> ../../dotfiles/.config/hypr/conf/                   (14 файлов секций)
├── hyprpaper.conf, swww.conf, wallpaper/, scripts/ ...
```

**После:**

```
~/.config/hypr/
├── hyprland.lua -> ../../dotfiles/.config/hypr/hyprland.lua     (НОВЫЙ, консолидированный)
├── hyprland.conf -> ... (ОСТАЁТСЯ как фолбэк, Hyprland его игнорирует)
├── conf/ -> ... (ОСТАЁТСЯ, не используется)
└── прочее без изменений
```

Логика загрузки Hyprland (из 0.55+): если есть `hyprland.lua` — грузится ТОЛЬКО он; `.conf` игнорируется. Проверка один раз при старте.

## Components (маппинг .conf → Lua)

Все значения из пользовательского конфига. `hl.config({...})` — секции, можно несколько вызовов (мержатся).

| Файл .conf | Lua (0.56) |
|---|---|
| `monitor=,preferred,auto,1` | `hl.monitor({ output="", mode="preferred", position="auto", scale=1 })` |
| `env = XCURSOR_SIZE,24` и др. (10 шт.) | `hl.env("XCURSOR_SIZE", "24")` — по одной на каждую |
| `cursor { no_hardware_cursors = true }` | `hl.config({ cursor = { no_hardware_cursors = true } })` |
| `general { ... }` | `hl.config({ general = { gaps_in=4, gaps_out=8, border_size=1, col={active_border={colors={"rgba(33ccffee)","rgba(00ff99ee)"}, angle=45}, inactive_border="rgba(595959aa)"}, resize_on_border=false, allow_tearing=false, layout="dwindle" } })` |
| `decoration { ... }` | `hl.config({ decoration = { rounding=8, rounding_power=2, active_opacity=1.0, inactive_opacity=1.0 } })` |
| `dwindle { pseudotile... }` | **УДАЛИТЬ** `pseudotile` (нет в API). `hl.config({ dwindle = { preserve_split = true } })` |
| `master { new_status = master }` | `hl.config({ master = { new_status = "master" } })` — подтверждено в стубах |
| `misc { ... }` | `hl.config({ misc = { force_default_wallpaper=0, disable_hyprland_logo=true, disable_splash_rendering=true } })` |
| `input { ... }` | `hl.config({ input = { kb_layout="us,ru", kb_variant="", kb_model="", kb_options="grp:ctrl_space_toggle", kb_rules="", follow_mouse=1, sensitivity=0, touchpad={natural_scroll=false, scroll_factor=0.2} } })` |
| `device { name=epic-mouse-v1, sensitivity=-0.5 }` | `hl.device({ name="epic-mouse-v1", sensitivity=-0.5 })` |
| `gesture { gesture = 3, horizontal, workspace }` | `hl.gesture({ fingers=3, direction="horizontal", action="workspace" })` |
| `gestures { workspace_swipe_* }` (5 опций) | **РУЧНАЯ ПРОВЕРКА** — в новом gesture API прямого эквивалента нет; конвертер пометит. Оставить как Lua-комментарий с пометкой, swipe работает с дефолтами |
| `animations { bezier = ... }` (5 шт.) | `hl.curve("easeOutQuint", { type="bezier", points={{0.76,1},{0.24,1}} })` и т.д. |
| `animations { animation = ... }` (17 шт.) | `hl.animation({ leaf="global", enabled=true, speed=10, bezier="default" })` и т.д. — таблица из рефа 07 |
| `exec-once = waybar` и др. (4 шт.) | `hl.exec_once("waybar")`, `hl.exec_once("swaync")`, `hl.exec_once("swww-daemon --format xrgb")`, `hl.exec_once("swww img ~/.config/hypr/wallpaper/Space-Nebula.png --transition-type grow --transition-duration 1.5 --transition-fps 60")` |
| `bind = $mainMod, Q, exec, $terminal` и др. | `hl.bind("SUPER + Q", hl.dsp.exec_cmd("kitty"))` — переменные `local terminal="kitty"` и т.д. |
| `bind = $mainMod, J, togglesplit` | **ФИКС:** `hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))` (см. эталон, строка 265) |
| `bind = $mainMod, V, togglefloating` | `hl.dsp.window.float({ action = "toggle" })` |
| `bind = $mainMod, C, killactive` | `hl.dsp.window.close()` |
| `bind = $mainMod, P, pseudo` | `hl.dsp.window.pseudo()` |
| `bind = $mainMod, left, movefocus, l` | `hl.dsp.focus({ direction = "left" })` |
| `bind = $mainMod, 1, workspace, 1` (10 шт.) | `hl.dsp.focus({ workspace = i })` — цикл `for i=1,10` (эталон 275-279) |
| `bind = $mainMod SHIFT, 1, movetoworkspace, 1` | `hl.dsp.window.move({ workspace = i })` |
| `bind = $mainMod, S, togglespecialworkspace, magic` | `hl.dsp.workspace.toggle_special("magic")` |
| `bind = $mainMod SHIFT, S, movetoworkspace, special:magic` | `hl.dsp.window.move({ workspace = "special:magic" })` |
| `bind = $mainMod, mouse_down, workspace, e+1` | `hl.dsp.focus({ workspace = "e+1" })` |
| `bindm = $mainMod, mouse:272, movewindow` | `hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })` |
| `bindel = ,XF86AudioRaiseVolume, exec, script` | `hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("..."), { locked=true, repeating=true })` |
| `bindl = , XF86AudioNext, exec, playerctl next` | `hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked=true })` |
| `windowrule { name=..., match:class=..., float=on }` (4 шт.) | `hl.window_rule({ name=..., match={ class="google-chrome" }, float=true })` — синтаксис из эталона 317-356 |

Примечание к биндам мультимедиа: `bindel`/`bindl` с пустым модификатором в Lua пишется как `hl.bind("XF86AudioRaiseVolume", ...)` (без префикса `+`), см. эталон 294-305.

## Data Flow

1. Старт Hyprland → проверка `~/.config/hypr/hyprland.lua` → есть → грузится Lua-конфиг, `.conf` игнорируется.
2. Lua-конфиг через `hl.*` API регистрирует: мониторы, env, автозапуск, секции, кривые/анимации, жесты, устройства, бинды, оконные правила.
3. `hyprctl reload` перечитывает `hyprland.lua` на лету (не перезагружая сессию).
4. Откат: удалить `hyprland.lua` (+ симлинк) → при следующем старте вернётся `.conf`.

## Error Handling

- **Проверка до применения:** `Hyprland --verify-config --config hyprland.lua` (указан hyprmorph) и `hyprctl reload && hyprctl configerrors` — должно быть пусто.
- **Ошибки конвертера:** все `WARNING` от hyprmorph (`--check` режим, exit 2) разбираем вручную по таблице выше. `pseudotile` и `togglesplit` — известные фиксы.
- **Откат:** `.conf` не трогаем. При проблеме — удалить `hyprland.lua` и симлинк, перезапустить Hyprland.
- **Сессия:** не перезапускать Hyprland до успешной проверки.

## Testing Strategy

1. `hyprmorph --check` на конвертированном выводе — 0 флагов на ручную проверку (кроме известных).
2. `Hyprland --verify-config --config hyprland.lua` — без ошибок.
3. `hyprctl reload && hyprctl configerrors` — пусто.
4. Функциональные пробы: бинд `SUPER+J` (split), `SUPER+P` (pseudo), swipe 3 пальцами, автозапуск waybar/swaync/swww, правило Chrome (float), XWayland-правило.
5. Перезапуск Hyprland в конце — предупреждение о формате конфига должно исчезнуть.

## Open Questions

- Нужны ли `workspace_swipe_*` тюнинги из gesture.conf — в новом API прямого эквивалента не найдено (требует сверки с wiki/стубами при исполнении; если есть — добавить поля в `hl.gesture`).
- Доступность конвертера: `hyprmorph` требует `luarocks` (не установлен). Альтернативы: `hyprlang2lua` (Go, `go install`), либо ручное написание по таблице — конфиг мал, эталон в `/usr/share/hypr/hyprland.lua` покрывает ~95% строк 1:1.
