-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config = {
  -- color --
  color_scheme = "Tokyo Night",
  -- scroll bar --
  enable_scroll_bar = true,
  -- How many lines of scrollback you want to retain per tab
  scrollback_lines = 3500,
  -- Opacity
  window_background_opacity = 0.97,
  text_background_opacity = 1.0,
  -- font
  font = wezterm.font("FiraCode Nerd Font"),
  -- full screen behavior --
  native_macos_fullscreen_mode = true,
  leader = { key = "a", mods = "CTRL" },
  keys = {
    -- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
    { key = "LeftArrow", mods = "OPT", action = wezterm.action({ SendString = "\x1bb" }) },
    -- Make Option-Right equivalent to Alt-f; forward-word
    { key = "RightArrow", mods = "OPT", action = wezterm.action({ SendString = "\x1bf" }) },
    -- Testing from here --
    -- spawn pane
    {
      key = "s",
      mods = "CMD",
      action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
    },
    {
      key = "s",
      mods = "CMD|SHIFT",
      action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
    },
    -- kill pane
    {
      key = "s",
      mods = "LEADER",
      action = wezterm.action.CloseCurrentPane({ confirm = true }),
    },
    -- pane selection
    {
      key = "m",
      mods = "CMD",
      action = wezterm.action.PaneSelect,
    },
  },
}

-- Show domain on tab
wezterm.on("format-tab-title", function(tab)
  local pane = tab.active_pane
  local title = pane.title
  if pane.domain_name then
    title = title .. " - (" .. pane.domain_name .. ")"
  end
  return title
end)

-- and finally, return the configuration to wezterm
return config
