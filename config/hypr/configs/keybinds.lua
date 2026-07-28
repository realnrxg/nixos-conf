local programs = require("configs.programs")
local mainMod = "SUPER"

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(programs.terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("~/.config/hypr/scripts/hyprlock.sh"))

hl.bind("SUPER + ALT + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "toggle" }))

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"))
hl.bind("SUPER + G", hl.dsp.exec_cmd("~/.config/hypr/scripts/wppicker.sh"))
hl.bind("SUPER + ALT + G", hl.dsp.exec_cmd("~/.config/hypr/scripts/FastFetchConf.sh"))
-- hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd("~/.config/hypr/scripts/WaybarStyles.sh"))
-- hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd("~/.config/hypr/scripts/WaybarLayout.sh"))

-- HEADPHONES
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"))

-- PLAYBACK
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("playerctl pause"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -50, y = 0 }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0 }),  { repeating = true })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0, y = -50 }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0, y = 50 }),  { repeating = true })

for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    end

    hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

    hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
    hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- SPECIAL KEYBINDS
    hl.bind("XF86AudioRaiseVolume",   hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh --inc"), { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume",   hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh --dec"), { locked = true, repeating = true })
    hl.bind("XF86AudioMute",          hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh --toggle"), { locked = true, repeating = true })
    hl.bind("XF86AudioMicMute",       hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessUp",    hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh --inc"), { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown",  hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh --dec"), { locked = true, repeating = true })

    hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
    hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
