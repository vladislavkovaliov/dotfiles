# Hyprland Lua Migration Implementation Plan

**Goal:** Migrate the Hyprland config from hyprlang (`.conf`) to the consolidated Lua format (`hyprland.lua`) on Hyprland 0.56.1, keeping the `.conf` files untouched as rollback fallback, and verifying via `--verify-config` + `hyprctl reload`/`configerrors` without disrupting the live session.

**Architecture:** A single consolidated `hyprland.lua` reproducing 1:1 every setting from the 14 sourced `.conf` files, structured section-by-section following the shipped reference `/usr/share/hypr/hyprland.lua`. Hyprland 0.55+ loads `hyprland.lua` preferentially and ignores `.conf`. A symlink `~/.config/hypr/hyprland.lua -> ../../dotfiles/.config/hypr/hyprland.lua` (matching the existing symlink pattern) makes the live session pick it up. Rollback = delete the symlink + file.

**Design:** [2026-08-03-hyprland-lua-migration-design.md](../designs/2026-08-03-hyprland-lua-migration-design.md)

---

## Research Findings & Decisions (verified against source, stubs, and wiki)

| Topic | Design said | Verified reality | Decision |
|---|---|---|---|
| Autostart | `hl.exec_once("waybar")` | **`hl.exec_once` does not exist** in the 0.56 Lua API. Wiki (Autostart page), both converters (hyprlang2lua, hyprland-config), and the forum all map `exec-once` → `hl.on("hyprland.start", function() hl.exec_cmd(...) end)`. Stub `HL.API` has no `exec_once`. | Use the `hl.on("hyprland.start", ...)` pattern. Same semantics: fires once at session start, not on reload. |
| `gestures { workspace_swipe_* }` | "No confirmed Lua equivalent — preserve as comments" | **Resolved:** stubs `HL.ConfigOpt.Gestures` (hl.meta.lua:1499-1512) define all 6 used fields (`workspace_swipe_distance`, `_cancel_ratio`, `_min_speed_to_force`, `_create_new`, `_forever`, `_invert`). | Include actively via `hl.config({ gestures = { ... } })`. |
| Converter | hyprmorph (luarocks) primary, hand-write fallback | `luarocks` not installed; `go` present but building hyprlang2lua adds risk/time. Config is small; reference covers it 1:1. | **Hand-write** the Lua. No converter dependency. |
| Error #1 `dwindle:pseudotile` | Drop it | Already absent from current `dwindle.conf` (only `preserve_split = true` remains; file edited 2026-08-03 22:15). | Lua naturally excludes it — no action beyond not including it. |
| Error #2 `togglesplit` | Map to `hl.dsp.layout("togglesplit")` | `hl.dsp.layout` confirmed ("Send a layout message"); reference line 265 uses exactly this. Source has the bind commented (disabled due to the old error). | **Activate** `hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))` — the design's fix, and its test list expects SUPER+J functional. Documented; easy to comment out. |
| Env vars | "10 шт." | 12 `env` lines in `env.conf`. | Reproduce all 12. |
| `--verify-config` | "if available" | Available in binary (`Hyprland --help`). | Primary pre-symlink validation. |

---

## Dependency Graph

```
Batch 1 (1 implementer): Task 1  — write hyprland.lua (foundation, everything depends on it)
Batch 2 (2 parallel):    Task 2  — syntax + --verify-config check
                         Task 3  — create live symlink
Batch 3 (1 implementer): Task 4  — live reload + configerrors + functional smoke tests
Batch 4 (optional):      Task 5  — git commit
```

No file conflicts between tasks; Tasks 2 and 3 are independent of each other once Task 1 exists.

---

## Batch 1: Foundation

### Task 1: Write the consolidated `hyprland.lua`
**File:** `/home/vlad/dotfiles/.config/hypr/hyprland.lua` (NEW — does not exist yet)
**Test:** n/a (config file; verified in Tasks 2–4)
**Depends:** none
**Commit:** `feat(hypr): migrate config to hyprland.lua (Hyprland 0.56 Lua API)`

Write this file **exactly** as follows:

```lua
-- ============================================================================
-- Hyprland Lua config (Hyprland 0.56.1, Lua API 0.56)
-- Consolidated from conf/*.conf (monitor, env, general, decoration, animations,
-- dwindle, master, input, gesture, device, misc, autostart, keybindings, windowrules).
-- hyprland.conf and conf/*.conf are kept untouched as rollback fallback.
-- Rollback: delete ~/.config/hypr/hyprland.lua symlink + this file, restart Hyprland.
-- ============================================================================

------------------
---- MONITORS ----
------------------
-- source: conf/monitor.conf  (monitor=,preferred,auto,1)
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

---------------------
---- MY PROGRAMS ----
---------------------
-- source: conf/autostart.conf ($terminal/$fileManager/$menu)
local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "rofi -show drun"

-------------------
---- AUTOSTART ----
-------------------
-- source: conf/autostart.conf (exec-once x4)
-- NOTE: hl.exec_once does not exist in the 0.56 Lua API. exec-once semantics
-- (run once at session start, not on reload) map to the hyprland.start event.
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("swww-daemon --format xrgb")
    hl.exec_cmd("swww img ~/.config/hypr/wallpaper/Space-Nebula.png --transition-type grow --transition-duration 1.5 --transition-fps 60")
end)

--------------------------------
---- ENVIRONMENT VARIABLES -----
--------------------------------
-- source: conf/env.conf (12 env lines, kept verbatim)
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
hl.env("__VK_LAYER_NV_optimus", "NVIDIA_only")
hl.env("WLR_NO_HARDWARE_CURSORS", "1") -- legacy; superseded by cursor.no_hardware_cursors
hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")
hl.env("MOZ_DISABLE_RDD_SANDBOX", "1")
hl.env("EGL_PLATFORM", "wayland")

-----------------------
---- LOOK AND FEEL ----
-----------------------
-- source: conf/general.conf, conf/decoration.conf, conf/animations.conf
hl.config({
    cursor = {
        no_hardware_cursors = true, -- source: conf/env.conf cursor block
    },
    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 1,
        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },
    decoration = {
        rounding         = 8,
        rounding_power   = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
    },
    animations = {
        enabled = true, -- source: `enabled = yes, please :)`
    },
})

-- Curves (source: conf/animations.conf bezier x5 — user's own control points)
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.76, 1}, {0.24, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })

-- Animations (source: conf/animations.conf animation x17 — user's own speeds/curves)
hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 5,    bezier = "default",      style = "slidefade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

----------------------
---- LAYOUTS ---------
----------------------
-- source: conf/dwindle.conf (dwindle:pseudotile was removed in 0.55 — intentionally omitted)
hl.config({
    dwindle = {
        preserve_split = true,
    },
})

-- source: conf/master.conf (new_status confirmed in stubs: master.new_status is a string)
hl.config({
    master = {
        new_status = "master",
    },
})

----------------
---- MISC ------
----------------
-- source: conf/misc.conf
hl.config({
    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },
})

----------------
---- INPUT -----
----------------
-- source: conf/input.conf
hl.config({
    input = {
        kb_layout   = "us,ru",
        kb_variant  = "",
        kb_model    = "",
        kb_options  = "grp:ctrl_space_toggle",
        kb_rules    = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
            scroll_factor  = 0.2,
        },
    },
})

-- source: conf/gesture.conf  (gesture = 3, horizontal, workspace)
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- source: conf/gesture.conf gestures block (macbook-style swipe tuning).
-- Confirmed available in Lua API 0.56 via stubs: HL.ConfigOpt.Gestures
-- (hl.meta.lua lines 1499-1512). All 6 options map 1:1.
hl.config({
    gestures = {
        workspace_swipe_distance          = 300,
        workspace_swipe_cancel_ratio      = 0.4,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_create_new        = false,
        workspace_swipe_forever           = false,
        workspace_swipe_invert            = true,
    },
})

-- source: conf/device.conf (per-device input config)
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

---------------------
---- KEYBINDINGS ----
---------------------
-- source: conf/keybindings.conf  ($mainMod = SUPER)
local mainMod = "SUPER"

hl.bind(mainMod .. " + Q",     hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C",     hl.dsp.window.close()) -- killactive
hl.bind(mainMod .. " + M",     hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
hl.bind(mainMod .. " + E",     hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",     hl.dsp.window.float({ action = "toggle" })) -- togglefloating
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P",     hl.dsp.window.pseudo()) -- pseudo, dwindle only

-- FIX (design error #2): `togglesplit` dispatcher was removed in 0.54.
-- Correct 0.56 Lua mapping is hl.dsp.layout("togglesplit") (see reference line 265).
-- Note: conf/keybindings.conf has this bind commented out (was erroring before);
-- it is re-enabled here with the corrected dispatcher per the design.
hl.bind(mainMod .. " + J",     hl.dsp.layout("togglesplit")) -- dwindle only

-- Wallpaper selector
hl.bind(mainMod .. " + ALT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper-selector.sh"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging (bindm)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys (bindel -> { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-control.sh up"),      { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-control.sh down"),    { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-control.sh mute"),    { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),      { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness-control.sh up"),  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness-control.sh down"),{ locked = true, repeating = true })

-- Requires playerctl (bindl -> { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
-- source: conf/windowrules.conf (4 rules, block syntax -> hl.window_rule)
hl.window_rule({
    name  = "Google Chrome",
    match = { class = "google-chrome" },
    float = true,
})

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})
```

**Do NOT** modify or delete `hyprland.conf`, `conf/*.conf`, or anything else in the repo. This task creates exactly one new file.

**Verify (syntax sanity only, file is not yet live):**
```bash
# Lua syntax check (skip if `luac` is not installed)
luac -p /home/vlad/dotfiles/.config/hypr/hyprland.lua && echo "SYNTAX OK"

# Semantic check against the real parser (does not run the compositor)
Hyprland --verify-config --config /home/vlad/dotfiles/.config/hypr/hyprland.lua
# Expect: no errors printed, exit 0 (or "config ok"-style output)
```

---

## Batch 2: Validation & Activation (parallel — 2 implementers)

Both tasks are independent once Task 1 is done.

### Task 2: Static validation of `hyprland.lua`
**File:** none created — read-only verification of `/home/vlad/dotfiles/.config/hypr/hyprland.lua`
**Depends:** 1

**Verify:**
```bash
# 1. Pure Lua syntax
luac -p /home/vlad/dotfiles/.config/hypr/hyprland.lua && echo "SYNTAX OK"   # or skip if luac absent

# 2. Real parser check (prints config errors without starting the compositor)
Hyprland --verify-config --config /home/vlad/dotfiles/.config/hypr/hyprland.lua

# 3. Cross-check every section key against the installed stubs (sanity grep)
grep -c "workspace_swipe_distance\|workspace_swipe_cancel_ratio" /usr/share/hypr/stubs/hl.meta.lua
# Expect count >= 2 (proves gestures.* keys exist in the API)
```

If `--verify-config` fails with a **keyboard/display init** error rather than a config error (possible on some builds when no Wayland session is reachable), fall back to Task 4's `hyprctl reload` verification and record it — the config may still be fine.

### Task 3: Create the live symlink
**File:** `/home/vlad/.config/hypr/hyprland.lua` (NEW symlink)
**Depends:** 1

Create the symlink matching the existing pattern used by `hyprland.conf` (`hyprland.conf -> ../../dotfiles/.config/hypr/hyprland.conf`):

```bash
ln -s ../../dotfiles/.config/hypr/hyprland.lua /home/vlad/.config/hypr/hyprland.lua
```

**Verify:**
```bash
ls -la /home/vlad/.config/hypr/hyprland.lua
# Expect: lrwxrwxrwx ... hyprland.lua -> ../../dotfiles/.config/hypr/hyprland.lua
readlink -f /home/vlad/.config/hypr/hyprland.lua   # must resolve to the dotfiles file
```

Do NOT remove or alter the existing `hyprland.conf` symlink — it stays as rollback fallback (Hyprland ignores it while `hyprland.lua` exists).

---

## Batch 3: Live Session Verification

### Task 4: Reload and verify the live session (no restart)
**File:** none — verification only
**Depends:** 2, 3

```bash
# 1. Live reload (safe: re-reads hyprland.lua, does not restart the session)
hyprctl reload

# 2. Config errors must be EMPTY
hyprctl configerrors
# Expect: no output / empty (the current .conf produces 0 errors after the user's edits)

# 3. Confirm the running session is actually using the Lua config (config path check)
hyprctl systeminfo | grep -i config   # or: hyprctl getoption animations:enabled
# Expect: hyprland.lua referenced / Lua-loaded options responding

# 4. Functional smoke tests (from design testing strategy)
#    SUPER+J  -> split toggle works (fix #2 verified)
#    SUPER+P  -> pseudo toggle
#    SUPER+V  -> float toggle
#    3-finger horizontal swipe -> workspace switch
#    Google Chrome opens floating (window rule)
#    waybar/swaync/swww running (autostart worked at last session start; NOTE: exec-once
#    does not re-fire on reload — verify via pidof waybar; if not running, they were
#    started by the previous .conf session and will start on next real login)
```

**Rollback procedure if anything fails:** do not panic — the live session is not restarted. Remove the symlink only:
```bash
rm /home/vlad/.config/hypr/hyprland.lua
hyprctl reload   # returns to hyprland.conf for the current session
# Next login uses hyprland.conf again. The dotfiles repo file can stay or be deleted.
```

---

## Batch 4: Commit (optional, user-triggered)

### Task 5: Commit the migration
**Files:** `/home/vlad/dotfiles/.config/hypr/hyprland.lua` (new)
**Depends:** 4 (only after verification passes)

```bash
cd /home/vlad/dotfiles
git add .config/hypr/hyprland.lua
git commit -m "feat(hypr): migrate config to hyprland.lua (Hyprland 0.56 Lua API)"
```

Only after the user confirms the live session works correctly. Optionally also commit the design + this plan under `thoughts/`.

---

## Full .conf → Lua Mapping Reference (audit checklist)

| # | .conf source | Lua equivalent in file | Status |
|---|---|---|---|
| 1 | `monitor=,preferred,auto,1` | `hl.monitor({ output="", mode="preferred", position="auto", scale=1 })` | done |
| 2 | 12× `env = NAME,value` | `hl.env(...)` × 12 | done |
| 3 | `cursor { no_hardware_cursors=true }` | `hl.config({ cursor = { no_hardware_cursors = true } })` | done |
| 4 | `general { ... }` (gaps 4/8, border 1, colors, resize_on_border, allow_tearing, layout) | `hl.config({ general = { ... } })` | done |
| 5 | `decoration { ... }` (rounding 8, power 2, opacity 1.0) | `hl.config({ decoration = { ... } })` | done |
| 6 | `animations { enabled = yes }` + 5 beziers + 17 animations | `animations.enabled=true` + `hl.curve` ×5 + `hl.animation` ×17 (user's values) | done |
| 7 | `dwindle { preserve_split = true }` | `hl.config({ dwindle = { preserve_split = true } })` — **no pseudotile** | done |
| 8 | `master { new_status = master }` | `hl.config({ master = { new_status = "master" } })` | done |
| 9 | `misc { ... }` ×3 | `hl.config({ misc = { ... } })` | done |
| 10 | `input { ... }` (us,ru; grp:ctrl_space_toggle; touchpad) | `hl.config({ input = { ... } })` incl. `touchpad.scroll_factor=0.2` | done |
| 11 | `gesture { gesture = 3, horizontal, workspace }` | `hl.gesture({ fingers=3, direction="horizontal", action="workspace" })` | done |
| 12 | `gestures { workspace_swipe_* }` ×6 | `hl.config({ gestures = { ... } })` — **confirmed in stubs** | done |
| 13 | `device { name=epic-mouse-v1, sensitivity=-0.5 }` | `hl.device({ name="epic-mouse-v1", sensitivity=-0.5 })` | done |
| 14 | `exec-once` ×4 | `hl.on("hyprland.start", ...)` — **corrected from design's `hl.exec_once`** | done |
| 15 | `bind = $mainMod, Q, exec, $terminal` etc. | `hl.bind("SUPER + Q", hl.dsp.exec_cmd(terminal))` + locals | done |
| 16 | `bind = $mainMod, J, togglesplit` | `hl.dsp.layout("togglesplit")` — **fix #2** (activated) | done |
| 17 | `bindm`/`bindel`/`bindl` variants | `hl.bind(..., { mouse=true })` / `{ locked=true, repeating=true }` / `{ locked=true }` | done |
| 18 | `windowrule` ×4 (incl. Google Chrome, fix-xwayland-drags) | `hl.window_rule({ name=..., match=..., ... })` ×4 | done |

## Constraints honored
- ✅ No Hyprland restart / no live-session disruption — only `hyprctl reload` + `configerrors`.
- ✅ `hyprland.conf` and `conf/*.conf` untouched (rollback fallback).
- ✅ Hand-written Lua (no converter dependency); `--verify-config` + stubs used as ground truth.
- ✅ Known errors handled: `pseudotile` omitted, `togglesplit` → `hl.dsp.layout("togglesplit")`.
