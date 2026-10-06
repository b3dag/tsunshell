local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local dir = wezterm.home_dir .. '/.config/tsundere/'

-- Seconds without activity before she falls asleep
local SLEEP_AFTER = 300

-- How tall she is as a share of the window height (0.30 means 30 percent)
local HEIGHT_PCT = 0.30

-- Width divided by height of the image files (they are 280 by 368)
local RATIO = 280 / 368

-- Background color layer, change the hex to your taste
local function bg(img, w, h)
  local color = {
    source = { Color = '#1e1e2e' },
    width = '100%',
    height = '100%',
  }
  -- Muted with the tsun off command, no girl at all
  if img == 'off.png' then
    return { color }
  end
  return {
    color,
    {
      source = { File = dir .. img },
      vertical_align = 'Bottom',
      horizontal_align = 'Right',
      repeat_x = 'NoRepeat',
      repeat_y = 'NoRepeat',
      width = w,
      height = h,
      opacity = 0.9,
    },
  }
end

-- Starting size until the first status update measures the window
config.background = bg('normal.png', 210, 276)
config.status_update_interval = 1000

local state = {}

-- Runs every second. Reads the mood the shell sent, sizes her to the
-- window and swaps the image. Activity is detected from cursor movement
-- and mood changes.
wezterm.on('update-status', function(window, pane)
  local id = window:window_id()
  local dims = window:get_dimensions()
  local h = math.floor(dims.pixel_height * HEIGHT_PCT)
  local w = math.floor(h * RATIO)
  if h < 50 then
    return
  end

  local pos = pane:get_cursor_position()
  local mood = pane:get_user_vars().tsun_mood or 'normal'
  local sig = pos.x .. ',' .. pos.y .. ',' .. mood
  local now = os.time()

  local st = state[id]
  if not st then
    st = { sig = sig, t = now, shown = '', h = 0 }
    state[id] = st
  end

  if st.sig ~= sig then
    st.sig = sig
    st.t = now
  end

  local want = mood
  if mood ~= 'off' and now - st.t >= SLEEP_AFTER then
    want = 'sleepy'
  end

  if st.shown ~= want or st.h ~= h then
    st.shown = want
    st.h = h
    local overrides = window:get_config_overrides() or {}
    overrides.background = bg(want .. '.png', w, h)
    window:set_config_overrides(overrides)
  end
end)

return config
