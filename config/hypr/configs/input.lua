hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity = 0.5,
        accel_profile = "flat",
        scroll_factor = 0.7,

        touchpad = {
            natural_scroll = false,
        },
    },
})


hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})
