local wezterm = require("wezterm")
local config = wezterm.config_builder()

-----------------------------------------
-- Base config
-----------------------------------------
config = {
	color_scheme = "Tokyo Night",
	quick_select_remove_styling = true,
	-- scroll
	enable_scroll_bar = true,
	scrollback_lines = 50000,
	-- Opacity
	window_background_opacity = 0.92,
	macos_window_background_blur = 8,
	text_background_opacity = 1.0,
	-- font
	font = wezterm.font("JetBrains Mono"),
	font_size = 12.5,
	--aerospace compatibility
	window_decorations = "RESIZE",

	leader = { key = "a", mods = "CTRL" },
	keys = {
		-- Make Option-<arrow equivalent to Alt-b which many line editors interpret as backward-word
		{ key = "LeftArrow", mods = "ALT", action = wezterm.action({ SendString = "\x1bb" }) },
		{ key = "RightArrow", mods = "ALT", action = wezterm.action({ SendString = "\x1bf" }) },
		-- pane management
		{
			key = "v",
			mods = "LEADER",
			action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "x",
			mods = "LEADER",
			action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "q",
			mods = "LEADER",
			action = wezterm.action.CloseCurrentPane({ confirm = false }),
		},
		-- Prompt for a name to use for a new workspace and switch to it.
		{
			key = "W",
			mods = "LEADER",
			action = wezterm.action.PromptInputLine({
				description = wezterm.format({
					{ Attribute = { Intensity = "Bold" } },
					{ Foreground = { AnsiColor = "Fuchsia" } },
					{ Text = "Enter name for new workspace" },
				}),
				action = wezterm.action_callback(function(window, pane, line)
					-- line will be `nil` if they hit escape without entering anything
					-- An empty string if they just hit enter
					-- Or the actual line of text they wrote
					if line then
						window:perform_action(
							wezterm.action.SwitchToWorkspace({
								name = line,
							}),
							pane
						)
					end
				end),
			}),
		},
		-- Save workspace
		{
			key = "s",
			mods = "LEADER",
			action = wezterm.action_callback(function(win, pane)
				wezterm.log_info("Debug: Leader+s pressed, showing pane info: " .. pane:get_title())
				resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
				resurrect.window_state.save_window_action()
			end),
		},
		-- Load workspace via fuzzy finder
		{
			key = "l",
			mods = "LEADER",
			action = wezterm.action_callback(function(win, pane)
				resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
					wezterm.log_info("Debug: Leader+l pressed, showing pane info: " .. pane:get_title())
					local type = string.match(id, "^([^/]+)") -- match before '/'
					id = string.match(id, "([^/]+)$") -- match after '/'
					id = string.match(id, "(.+)%..+$") -- remove file extention
					local opts = {
						relative = true,
						restore_text = true,
						on_pane_restore = resurrect.tab_state.default_on_pane_restore,
					}
					if type == "workspace" then
						local state = resurrect.state_manager.load_state(id, "workspace")
						resurrect.workspace_state.restore_workspace(state, opts)
					elseif type == "window" then
						local state = resurrect.state_manager.load_state(id, "window")
						resurrect.window_state.restore_window(pane:window(), state, opts)
					elseif type == "tab" then
						local state = resurrect.state_manager.load_state(id, "tab")
						resurrect.tab_state.restore_tab(pane:tab(), state, opts)
					end
				end)
			end),
		},
		{
			-- Delete a saved session using a fuzzy finder
			key = "d",
			mods = "LEADER",
			action = wezterm.action_callback(function(win, pane)
				wezterm.log_info("Debug: Leader+d pressed, showing pane info: " .. pane:get_title())
				resurrect.fuzzy_load(win, pane, function(id)
					resurrect.delete_state(id)
				end, {
					title = "Delete State",
					description = "Select session to delete and press Enter = accept, Esc = cancel, / = filter",
					fuzzy_description = "Search session to delete: ",
					is_fuzzy = true,
				})
			end),
		},
	},

	-- SSH domains loaded from ~/.wezterm_ssh_domain.lua (local-only, not committed)
	ssh_domains = (function()
		local f = io.open(wezterm.home_dir .. "/.wezterm_ssh_domain.lua", "r")
		if f then
			f:close()
			return dofile(wezterm.home_dir .. "/.wezterm_ssh_domain.lua")
		end
		return {}
	end)(),
}

-----------------------------------------
-- Terminal URI Receip
-----------------------------------------
local function is_shell(foreground_process_name)
	local shell_names = { "bash", "zsh", "fish", "sh", "ksh", "dash" }
	local process = string.match(foreground_process_name, "[^/\\]+$") or foreground_process_name
	for _, shell in ipairs(shell_names) do
		if process == shell then
			return true
		end
	end
	return false
end

wezterm.on("open-uri", function(window, pane, uri)
	local editor = "nvim"

	if uri:find("^file:") == 1 and not pane:is_alt_screen_active() then
		-- We're processing an hyperlink and the uri format should be: file://[HOSTNAME]/PATH[#linenr]
		-- Also the pane is not in an alternate screen (an editor, less, etc)
		local url = wezterm.url.parse(uri)
		if is_shell(pane:get_foreground_process_name()) then
			-- A shell has been detected. Wezterm can check the file type directly
			-- figure out what kind of file we're dealing with
			local success, stdout, _ = wezterm.run_child_process({
				"file",
				"--brief",
				"--mime-type",
				url.file_path,
			})
			if success then
				if stdout:find("directory") then
					pane:send_text(wezterm.shell_join_args({ "cd", url.file_path }) .. "\r")
					pane:send_text(wezterm.shell_join_args({
						"ls",
						"-a",
						"-p",
						"--group-directories-first",
					}) .. "\r")
					return false
				end

				if stdout:find("text") then
					if url.fragment then
						pane:send_text(wezterm.shell_join_args({
							editor,
							"+" .. url.fragment,
							url.file_path,
						}) .. "\r")
					else
						pane:send_text(wezterm.shell_join_args({ editor, url.file_path }) .. "\r")
					end
					return false
				end
			end
		else
			-- No shell detected, we're probably connected with SSH, use fallback command
			local edit_cmd = url.fragment and editor .. " +" .. url.fragment .. ' "$_f"' or editor .. ' "$_f"'
			local cmd = '_f="'
				.. url.file_path
				.. '"; { test -d "$_f" && { cd "$_f" ; ls -a -p --hyperlink --group-directories-first; }; } '
				.. '|| { test "$(file --brief --mime-type "$_f" | cut -d/ -f1 || true)" = "text" && '
				.. edit_cmd
				.. "; }; echo"
			pane:send_text(cmd .. "\r")
			return false
		end
	end

	-- without a return value, we allow default actions
end)

config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
	-- Disable the 'Down' event of CTRL-Click to avoid weird program behaviors
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.Nop,
	},
}

-----------------------------------------
-- MUX lag debugging
-----------------------------------------
wezterm.on("update-right-status", function(window, pane)
	window:set_right_status(window:active_workspace())
end)

-----------------------------------------
-- MUX lag debugging
-----------------------------------------
-- config.front_end = 'OpenGL' -- Use OpenGL instead of WebGpu
config.max_fps = 120 -- Improve responsiveness

-----------------------------------------
-- UI not updating debugging
-----------------------------------------
config.front_end = "WebGpu" -- Or "OpenGL"
config.webgpu_power_preference = "HighPerformance"

return config
