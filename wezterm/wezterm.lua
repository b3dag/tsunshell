local wezterm = require 'wezterm'
local config = wezterm.config_builder()

local HOME = wezterm.home_dir
local SPRITES_DIR = HOME .. '/.config/tsundere/sprites/'
local RATIOS_FILE = SPRITES_DIR .. 'ratios.txt'

-- Used only if the shell has not sent a tsun_outfit yet (or for testing
-- this file on its own). In normal use the shell always picks a real
-- outfit at startup, so this almost never matters. Switch outfit/crop/size
-- live with `tsun outfit <name>` / `tsun crop <name>` / `tsun size <N>`.
local DEFAULT_OUTFIT = ''
local DEFAULT_CROP = 'waist'
local DEFAULT_SIZE = 30 -- percent of window height

-- Which file inside a sprite outfit each mood shows.
local MOOD_FILE = {
  normal = 'pout',
  angry = 'poutangry',
  happy = 'blushsmile',
  surprised = 'noclue',
  sleepy = 'hah',
  scared = 'fear',       -- a dangerous command that failed
  fedup = 'sad',         -- three or more failures in a row
  worried = 'worried',   -- bedtime nag, long-session break reminder
  disgusted = 'disgusted', -- git repo too dirty for her taste
}

-- Briefly shown instead of the file above while she's actively saying
-- something, for moods that have a matching open-mouth drawing in the pack.
-- A mood with no entry here just keeps its idle face while talking.
local TALK_FILE = {
  normal = 'normaltalking',
  angry = 'angrytalking',
  happy = 'blushtalking',
  fedup = 'sadtalking',
}

-- How long after she speaks the talking face stays up
local TALK_SECONDS = 2.5

-- Seconds without activity before she falls asleep
local SLEEP_AFTER = 300

-- outfit/crop -> width/height, read fresh from sprites/ratios.txt, written
-- automatically by scripts/sprites.sh for every outfit it crops. Adding a
-- new outfit never needs editing this file, re-run that script and reload
-- the WezTerm config (Ctrl+Shift+R) to pick it up.
local function load_ratios()
  local t = {}
  local f = io.open(RATIOS_FILE, 'r')
  if not f then
    return t
  end
  for line in f:lines() do
    local key, w, h = line:match('^(%S+)%s+(%d+)%s+(%d+)$')
    if key then
      t[key] = tonumber(w) / tonumber(h)
    end
  end
  f:close()
  return t
end

local RATIOS = load_ratios()

-- Resolves (outfit, crop, mood) to a directory, filename and aspect ratio.
-- Returns nil if that outfit/crop has no known size yet (nothing drawn).
local function resolve(outfit, crop, mood, talking)
  local ratio = RATIOS[outfit .. '/' .. crop]
  if not ratio then
    return nil
  end
  local name = (talking and TALK_FILE[mood]) or MOOD_FILE[mood] or mood
  local file = name .. '.png'
  return SPRITES_DIR .. outfit .. '/' .. crop .. '/', file, ratio
end

-- Background color layer, change the hex to your taste
local function bg(dir, file, mood, w, h)
  local color = {
    source = { Color = '#1e1e2e' },
    width = '100%',
    height = '100%',
  }
  -- Muted with the tsun off command, or nothing resolved yet, no girl at all
  if mood == 'off' or not dir then
    return { color }
  end
  return {
    color,
    {
      source = { File = dir .. file },
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

-- Blank until the first status update resolves a real outfit and measures
-- the window, so a placeholder never flashes on screen for a moment first
config.background = bg(nil, nil, 'off', 0, 0)
config.status_update_interval = 1000

local state = {}

-- Runs every second. Reads the mood, outfit, crop and size the shell sent,
-- sizes her to the window and swaps the image. Activity is detected from
-- cursor movement and mood changes. Size only ever scales the SAME crop, it
-- never changes which part of her is in frame, that is crop's job.
wezterm.on('update-status', function(window, pane)
  local id = window:window_id()
  local dims = window:get_dimensions()

  local pos = pane:get_cursor_position()
  local uv = pane:get_user_vars()
  local mood = uv.tsun_mood or 'normal'
  local outfit = uv.tsun_outfit or DEFAULT_OUTFIT
  local crop = uv.tsun_crop or DEFAULT_CROP
  local size = tonumber(uv.tsun_size) or DEFAULT_SIZE
  local sig = pos.x .. ',' .. pos.y .. ',' .. mood .. ',' .. outfit .. ',' .. crop .. ',' .. size
  local now = os.time()
  local talk_ts = tonumber(uv.tsun_talk)
  local talking = talk_ts ~= nil and (now - talk_ts) < TALK_SECONDS

  local h = math.floor(dims.pixel_height * (size / 100))
  if h < 50 then
    return
  end

  local st = state[id]
  if not st then
    st = { sig = sig, t = now, shown = '' }
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

  local dir, file, ratio = resolve(outfit, crop, want, talking)
  local w = ratio and math.floor(h * ratio) or 0
  local shown = want .. '|' .. tostring(talking) .. '|' .. outfit .. '|' .. crop .. '|' .. h

  if st.shown ~= shown then
    st.shown = shown
    local overrides = window:get_config_overrides() or {}
    overrides.background = bg(dir, file, want, w, h)
    window:set_config_overrides(overrides)
  end
end)

return config
