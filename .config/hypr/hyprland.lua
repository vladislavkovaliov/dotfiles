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

----------------------------
---- PERSISTENT WORKSPACES --
----------------------------
-- Replaces waybar's persistent-workspaces ("*": 5): workspaces 1-5 always exist.
-- The waybar ext/workspaces module (wlr protocol) has no persistent-workspaces
-- option, so Hyprland-side rules keep the bar showing 1-5 at all times.
for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), persistent = true })
end

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
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("awww img ~/.config/hypr/wallpaper/Space-Nebula.png --transition-type grow --transition-duration 1.5 --transition-fps 60")
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
