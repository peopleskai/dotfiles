-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.color_scheme = "Solarized Dark - Patched"
config.window_background_opacity = 0.90
config.text_background_opacity = 1.0
config.font = wezterm.font("FiraCode Nerd Font")

-- and finally, return the configuration to wezterm
return config
