local ok, colors = pcall(require, "colors")
if not ok then
    colors = {
        outline         = "rgba(33ccffee)",
        outline_variant = "rgba(595959aa)",
    }
end

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 7,

        border_size = 2,

        ["col.active_border"]   = colors.outline,
        ["col.inactive_border"] = colors.outline_variant,

        resize_on_border = false,

        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,

        active_opacity = 1.0,
        inactive_opacity = 0.8,

        shadow = {
            enabled = false,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },

        blur = {
            enabled = true,
            size = 5,
            passes = 3,
            ignore_opacity = true,
            new_optimizations = true,
            special = false,
            popups = true,
            xray = true,

            vibrancy = 0.1696,
        },
    },
})
