hl.monitor({
    output   = "HDMI-A-2",
    mode     = "1920x1080@239.76",
    position = "0x0",
    scale    = 1,
})

-- MY PROGRAMS
local programs = require("configs.programs")

-- AUTOSTART
hl.on("hyprland.start", function()
hl.exec_cmd("nm-applet")
hl.exec_cmd("waybar")
hl.exec_cmd("awww-daemon")
hl.exec_cmd("swaync")
hl.exec_cmd("nvibrant 614 614 614")
hl.exec_cmd("sleep 1 && hyprctl setcursor Afterglow-cursors 24")
end)

-- ENVIRONMENT VARIABLES
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Afterglow-cursors")
hl.env("XCURSOR_PATH", "/home/nrxg/.local/share/icons:/usr/share/icons:/usr/local/share/icons")

hl.env("GTK_THEME", "Adwaita:dark")
hl.env("GTK_APPLICATION_PREFER_DARK_THEME", "1")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_DATA_DIRS", (os.getenv("XDG_DATA_DIRS") or "") ..
":/run/current-system/sw/share/gsettings-schemas/gsettings-desktop-schemas-47.1/share/gsettings-schemas")

-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--     ecosystem = {
--         enforce_permissions = true,
--     },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-- import configs
require("configs.looks")
require("configs.useranim")
require("configs.input")
require("configs.keybinds")

-- smart gaps
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ name = "no-gaps-wtv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
-- hl.window_rule({ name = "no-gaps-f1", match = { float = false, workspace = "f[1]" }, border_size = 0, rounding = 0 })

hl.window_rule({
    name = "dim-vscode",
    match = { class = "^(Code)$" },
               opacity = "0.8 0.7",
})
hl.window_rule({
    name = "dim-vscodium",
    match = { class = "^(codium)$" },
               opacity = "0.8 0.7",
})

hl.config({
    dwindle = {
        -- pseudotile = true,
        preserve_split = true,
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    misc = {
        force_default_wallpaper = 0,
            disable_hyprland_logo = true,
    },
})

hl.config({
    render = {
        new_render_scheduling = true,
    },
})
