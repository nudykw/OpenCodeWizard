-- User's custom WezTerm configuration (from backup)
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- User's custom color scheme override
config.colors = {
  background = '#1a1a1a',
  foreground = '#e0e0e0',
}

-- User's custom key binding
config.key_tables = {
  user_table = {
    { key = 'F12', action = wezterm.action.SpawnCommand 'user-custom-command' },
  },
}

-- User's custom startup hook
wezterm.on('user-custom-event', function(window, pane)
  return 'user custom behavior'
end)

return config
