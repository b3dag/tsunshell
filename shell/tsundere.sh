# Tsundere terminal
# Save as ~/.config/tsundere/tsundere.sh and load it from .bashrc, any time
# after `shopt -s histappend` or similar, no ble.sh or other preexec library
# needed. Everything, code, phrases and images, lives in ~/.config/tsundere/

# Files
LINES_DIR="$HOME/.config/tsundere"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
STATE_DIR="$CACHE_DIR/tsundere"
METER_FILE="$STATE_DIR/meter"
STATE_FILE="$STATE_DIR/state"
MUTE_FILE="$STATE_DIR/muted"
SEEN_FILE="$STATE_DIR/lastseen"
FIRST_SEEN_FILE="$STATE_DIR/firstseen"
OUTFIT_FILE="$STATE_DIR/outfit"
CROP_FILE="$STATE_DIR/crop"
SIZE_FILE="$STATE_DIR/size"
NAME_FILE="$STATE_DIR/name"
MEMORY_FILE="$STATE_DIR/memories"

# Colors as r;g;b
MY_C_ERR="173;36;118"
MY_C_PRAISE="255;143;199"
MY_C_WARN="255;200;87"
MY_C_INFO="190;150;255"

# Settings
MY_MOOD_MAX=10          # highest the meter can go
MY_MOOD_THRESHOLD=10    # meter value where she turns happy
MY_MOOD_PENALTY=3       # points lost per failure
MY_SLOW_SECS=30         # seconds before a command counts as slow
MY_GIT_DIRTY=10         # changed files before she nags
MY_NIGHT_CHANCE=6       # bedtime nag happens 1 in this many successes at night
MY_RARE_CHANCE=100      # rare sweet line happens 1 in this many successes
MY_BREAK_SECS=7200      # seconds in one terminal before a break reminder
MY_AWAY_SECS=86400      # seconds away before she resets her mood and complains
MY_NOTIFY=1             # 1 for desktop notifications after long commands, 0 for off
MY_NOTIFY_SECS=60       # seconds before a command triggers a notification
MY_LEVEL_AT=(0 100 400 1000 2500)
MY_LEVEL_NAMES=("cold" "warming up" "softening" "dere" "smitten")
MY_STREAK_MILESTONES=(5 10 25 50 100 250 500 1000)
MY_SIZE_DEFAULT=30     # her height as a percent of the window, see tsun size
MY_SIZE_MIN=10
MY_SIZE_MAX=60
MY_SIZE_STEP=5          # change per tsun size bigger/smaller
MY_NAME_LEVEL=3         # minimum affection level before she'll use a pet name
MY_NAME_CHANCE=4        # uses it 1 in this many lines, once unlocked
MY_AMBIENT_CHANCE=20    # checks system state 1 in this many commands
MY_BATTERY_LOW=15       # percent, while actually discharging
MY_DISK_HIGH=90         # percent used, on /
MY_MEMORY_MAX=15        # how many specific moments she keeps at once
MY_MEMORY_CHANCE=150    # callback to one happens 1 in this many successes
MY_GATE_DANGER=1        # 1 to ask [y/N] before rm -rf/git push --force/etc
                        # actually run, 0 for the old after-the-fact-only warning
MY_GATE_JEALOUS=1       # 1 to ask [Y/n] before launching another AI's CLI
MY_JEALOUS_CMDS=(claude claude-desktop chatgpt gemini copilot aider cursor codex)
                        # add more here any time, nothing else to register.
                        # must be the REAL command: an alias (check with
                        # `type -a <name>`) always wins over a same-named
                        # function, so wrapping just the alias's name does
                        # nothing, list whatever it actually points to too

# Lets `history 1` report when each command was entered, in epoch seconds,
# which is how duration and "did a new command actually run" are worked out
# without ble.sh or any other preexec library. Side effect: plain `history`
# now shows that timestamp column too, in every tab, for the rest of the
# session.
HISTTIMEFORMAT='%s '

# ignoredups (part of the common ignoreboth) would make an exact repeat of
# the previous command create no new history entry at all, which is the
# only thing the line above can see - repeat a command and she would stay
# silent on it. Keep ignorespace (leading-space-hides-from-history) if it
# was there, just drop the dups part.
case $HISTCONTROL in
  ignoreboth) HISTCONTROL=ignorespace ;;
  ignoredups) HISTCONTROL= ;;
  *) HISTCONTROL=${HISTCONTROL//ignoredups/} ;;
esac

# State
MY_MOOD_METER=0
MY_LEVEL=0
MY_TOTAL=0
MY_EVER=0
MY_EVER_OK=0
MY_EVER_FAIL=0
MY_S_DATE=
MY_S_OK=0
MY_S_FAIL=0
MY_S_STREAK=0
MY_S_BEST=0
MY_FAIL_STREAK=0
MY_CHAT_TODAY=0
MY_CMD=
MY_PREV_CMD=
MY_PREV_OK=0
MY_LAST_DECLINED=
MY_SPOKE=
MY_LAST_HISTNUM=
MY_LAST_BREAK=$SECONDS
MY_OUTFIT=
MY_CROP=waist
MY_SIZE=$MY_SIZE_DEFAULT
MY_PET_NAME=

# Print a random line from a file in a color, even when muted. Past
# MY_NAME_LEVEL, occasionally leads with whatever pet name is set
# (tsun name), same line otherwise, nothing content files need to care
# about.
function my/say-force {
  [[ -f $1 ]] || return 1
  local line
  line=$(shuf -n1 "$1")
  if [[ $MY_PET_NAME && $MY_LEVEL -ge $MY_NAME_LEVEL ]] && ((RANDOM % MY_NAME_CHANCE == 0)); then
    line="$MY_PET_NAME, $line"
  fi
  printf '\033[1;38;2;%sm%s\033[0m\n' "$2" "$line"
  MY_SPOKE=1
}

# Same, but silent when she is muted
function my/say {
  [[ -e $MUTE_FILE ]] && return 1
  my/say-force "$1" "$2"
}

# Resolves <category> (a lines/<category>/ folder) + the current
# affection level to a file, walking down from the current level to 0 so
# a category that hasn't filled in every tier still degrades to the
# closest one that exists instead of failing outright. Files are named
# 0-4, matching MY_LEVEL directly. Result in REPLY, empty if that
# category has nothing at any level.
function my/pool {
  REPLY=
  local n
  for ((n = MY_LEVEL; n >= 0; n--)); do
    if [[ -f "$LINES_DIR/$1/$n.txt" ]]; then
      REPLY="$LINES_DIR/$1/$n.txt"
      return
    fi
  done
}

# Tells WezTerm which girl image to show, ignored in other terminals
function my/mood {
  [[ $TERM_PROGRAM == WezTerm ]] || return
  local m=$1
  [[ -e $MUTE_FILE ]] && m=off
  printf '\033]1337;SetUserVar=tsun_mood=%s\007' "$(printf '%s' "$m" | base64)"
  printf '\033]1337;SetUserVar=tsun_outfit=%s\007' "$(printf '%s' "$MY_OUTFIT" | base64)"
  printf '\033]1337;SetUserVar=tsun_crop=%s\007' "$(printf '%s' "$MY_CROP" | base64)"
  printf '\033]1337;SetUserVar=tsun_size=%s\007' "$(printf '%s' "$MY_SIZE" | base64)"
  # Lets WezTerm flash an open-mouth variant of the current face for a
  # couple seconds, instead of her always looking the same whether she
  # just said something or not
  if [[ $MY_SPOKE && $m != off ]]; then
    local ts
    printf -v ts '%(%s)T' -1
    printf '\033]1337;SetUserVar=tsun_talk=%s\007' "$(printf '%s' "$ts" | base64)"
  fi
}

# Lists installed outfit names, one per line: every sprites/ subfolder,
# directories only, so stray files like ratios.txt are never mistaken for
# an outfit. This is the only place that needs to know the folder exists,
# so adding a new outfit never means registering it anywhere else.
function my/outfits-list {
  local d
  for d in "$LINES_DIR"/sprites/*/; do
    [[ -d $d ]] || continue
    d=${d%/}
    printf '%s\n' "${d##*/}"
  done
}

# Loads the chosen outfit, falling back to whatever outfit sorts first if
# unset or the outfit no longer exists. There is no "no outfit" state,
# every sprites/ subfolder found is a real, usable outfit.
function my/outfit-load {
  MY_OUTFIT=
  [[ -f $OUTFIT_FILE ]] && read -r MY_OUTFIT < "$OUTFIT_FILE"
  if [[ -z $MY_OUTFIT || ! -d "$LINES_DIR/sprites/$MY_OUTFIT" ]]; then
    MY_OUTFIT=$(my/outfits-list | sort | head -n1)
  fi
}

function my/crop-load {
  MY_CROP=waist
  [[ -f $CROP_FILE ]] && read -r MY_CROP < "$CROP_FILE"
  [[ $MY_CROP =~ ^(full|waist|bust)$ ]] || MY_CROP=waist
}

# How big she is on screen, a percent of the window height, independent of
# crop (crop only changes framing, not size, see tsun size)
function my/size-load {
  MY_SIZE=$MY_SIZE_DEFAULT
  [[ -f $SIZE_FILE ]] && read -r MY_SIZE < "$SIZE_FILE"
  [[ $MY_SIZE =~ ^[0-9]+$ ]] && ((MY_SIZE >= MY_SIZE_MIN && MY_SIZE <= MY_SIZE_MAX)) || MY_SIZE=$MY_SIZE_DEFAULT
}

function my/name-load {
  MY_PET_NAME=
  [[ -f $NAME_FILE ]] && read -r MY_PET_NAME < "$NAME_FILE"
}

# Pushes the current mood to WezTerm right now, for tsun outfit/crop/on and startup
function my/sync-now {
  my/meter-load
  if ((MY_MOOD_METER >= MY_MOOD_THRESHOLD)); then my/mood happy; else my/mood normal; fi
}

function my/meter-load {
  MY_MOOD_METER=0
  [[ -f $METER_FILE ]] && read -r MY_MOOD_METER < "$METER_FILE"
  [[ $MY_MOOD_METER =~ ^[0-9]+$ ]] || MY_MOOD_METER=0
  ((MY_MOOD_METER > MY_MOOD_MAX)) && MY_MOOD_METER=$MY_MOOD_MAX
}

function my/meter-save {
  mkdir -p "$STATE_DIR" 2>/dev/null
  printf '%s\n' "$MY_MOOD_METER" > "$METER_FILE"
}

# Daily counters, best streaks, lifetime totals and the long term affection points
function my/state-load {
  local today v
  printf -v today '%(%F)T' -1
  MY_S_DATE=
  MY_S_OK=0
  MY_S_FAIL=0
  MY_S_STREAK=0
  MY_S_BEST=0
  MY_TOTAL=0
  MY_EVER=0
  MY_EVER_OK=0
  MY_EVER_FAIL=0
  MY_CHAT_TODAY=0
  [[ -f $STATE_FILE ]] && read -r MY_S_DATE MY_S_OK MY_S_FAIL MY_S_STREAK MY_S_BEST MY_TOTAL MY_EVER MY_EVER_OK MY_EVER_FAIL MY_CHAT_TODAY < "$STATE_FILE"
  for v in MY_S_OK MY_S_FAIL MY_S_STREAK MY_S_BEST MY_TOTAL MY_EVER MY_EVER_OK MY_EVER_FAIL MY_CHAT_TODAY; do
    [[ ${!v} =~ ^[0-9]+$ ]] || printf -v "$v" '%s' 0
  done
  if [[ $MY_S_DATE != "$today" ]]; then
    MY_S_DATE=$today
    MY_S_OK=0
    MY_S_FAIL=0
    MY_S_STREAK=0
    MY_S_BEST=0
    MY_CHAT_TODAY=0
  fi
}

function my/state-save {
  mkdir -p "$STATE_DIR" 2>/dev/null
  printf '%s %s %s %s %s %s %s %s %s %s\n' "$MY_S_DATE" "$MY_S_OK" "$MY_S_FAIL" "$MY_S_STREAK" "$MY_S_BEST" "$MY_TOTAL" "$MY_EVER" "$MY_EVER_OK" "$MY_EVER_FAIL" "$MY_CHAT_TODAY" > "$STATE_FILE"
}

function my/calc-level {
  local i
  MY_LEVEL=0
  for i in 1 2 3 4; do
    ((MY_TOTAL >= MY_LEVEL_AT[i])) && MY_LEVEL=$i
  done
}

# Creates the first-seen timestamp once, result (epoch) in REPLY
function my/first-seen {
  local now
  printf -v now '%(%s)T' -1
  if [[ -f $FIRST_SEEN_FILE ]]; then
    read -r REPLY < "$FIRST_SEEN_FILE"
    [[ $REPLY =~ ^[0-9]+$ ]] || REPLY=$now
  else
    REPLY=$now
    mkdir -p "$STATE_DIR" 2>/dev/null
    printf '%s\n' "$REPLY" > "$FIRST_SEEN_FILE"
  fi
}

# True for programs you sit in, so they never count as slow commands
function my/is-interactive {
  case ${MY_CMD%% *} in
    vim|vi|nvim|nano|less|man|ssh|mosh|htop|btop|top|tmux|watch|journalctl|tail|fzf|ranger|mpv|python|python3|node) return 0 ;;
  esac
  return 1
}

# Desktop notification, needs notify-send
function my/notify {
  ((MY_NOTIFY)) || return
  command -v notify-send >/dev/null 2>&1 || return
  local icon="$LINES_DIR/sprites/$MY_OUTFIT/$MY_CROP/normal.png"
  [[ -f $icon ]] || icon=
  notify-send ${icon:+-i "$icon"} "$1" "$2" >/dev/null 2>&1
}

# Command specific reactions from reactions.txt, $1 is ok or fail
# Prints one matching line and returns 0, or returns 1 when nothing matches
function my/react {
  # The jealousy gate (my/gate, when MY_GATE_JEALOUS is on) already said her
  # piece on this exact command before it ran; reactions/ still has its own
  # claude*/gemini*/etc. "any" entries for when the gate is off, but with it
  # on they would just be a redundant second line right after the gate's own
  if ((MY_GATE_JEALOUS)); then
    local jc
    for jc in "${MY_JEALOUS_CMDS[@]}"; do
      [[ ${MY_CMD%% *} == "$jc" ]] && return 1
    done
  fi

  my/pool reactions
  local file=$REPLY pat when msg
  local -a hits=()
  [[ -f $file ]] || return 1
  while IFS='|' read -r pat when msg; do
    [[ -z $pat || $pat == \#* ]] && continue
    [[ $when == any || $when == "$1" ]] || continue
    # shellcheck disable=SC2053
    [[ $MY_CMD == $pat ]] && hits+=("$msg")
  done < "$file"
  ((${#hits[@]})) || return 1
  printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_INFO" "${hits[RANDOM % ${#hits[@]}]}"
}

# Reaction to a specific exit code from lines/exitcodes/, regardless of
# command. Prints one matching line and returns 0, or returns 1 when
# nothing matches
function my/exit-reaction {
  my/pool exitcodes
  local file=$REPLY code msg
  local -a hits=()
  [[ -f $file ]] || return 1
  while IFS='|' read -r code msg; do
    [[ -z $code || $code == \#* ]] && continue
    [[ $code == "$1" ]] && hits+=("$msg")
  done < "$file"
  ((${#hits[@]})) || return 1
  printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_ERR" "${hits[RANDOM % ${#hits[@]}]}"
}

# Greeting once per terminal, depending on the time of day
function my/greet {
  local h
  printf -v h '%(%H)T' -1
  h=$((10#$h))
  if ((h >= 5 && h < 12)); then
    my/pool morning; my/say "$REPLY" "$MY_C_INFO"
  elif ((h >= 12 && h < 17)); then
    my/pool afternoon; my/say "$REPLY" "$MY_C_INFO"
  elif ((h >= 17 && h < 23)); then
    my/pool evening; my/say "$REPLY" "$MY_C_INFO"
  elif ((h >= 23 || h < 5)); then
    my/pool night; my/say "$REPLY" "$MY_C_INFO"
  fi
}

# After a long absence she resets her mood and complains, returns 0 if it fired
function my/away-check {
  local now last=0
  printf -v now '%(%s)T' -1
  [[ -f $SEEN_FILE ]] && read -r last < "$SEEN_FILE"
  [[ $last =~ ^[0-9]+$ ]] || last=0
  mkdir -p "$STATE_DIR" 2>/dev/null
  printf '%s\n' "$now" > "$SEEN_FILE"
  if ((last > 0 && now - last >= MY_AWAY_SECS)); then
    MY_MOOD_METER=0
    my/meter-save
    my/pool away; my/say "$REPLY" "$MY_C_WARN"
    return 0
  fi
  return 1
}

# Occasional comment on the machine itself rather than the command, cheap
# sysfs/proc reads so only worth the trouble 1 in MY_AMBIENT_CHANCE times.
# Checks battery, then disk, then load, says at most one line, returns 0
# if it said anything.
function my/ambient-check {
  ((RANDOM % MY_AMBIENT_CHANCE == 0)) || return 1

  local bat cap status
  for bat in /sys/class/power_supply/BAT*; do
    [[ -d $bat ]] || continue
    cap= status=
    [[ -f "$bat/capacity" ]] && read -r cap < "$bat/capacity"
    [[ -f "$bat/status" ]] && read -r status < "$bat/status"
    if [[ $status == Discharging && $cap =~ ^[0-9]+$ ]] && ((cap <= MY_BATTERY_LOW)); then
      my/pool battery
      my/say "$REPLY" "$MY_C_WARN" && return 0
    fi
    break
  done

  local disk_pct
  disk_pct=$(df -P / 2>/dev/null | awk 'NR==2 { gsub("%", "", $5); print $5 }')
  if [[ $disk_pct =~ ^[0-9]+$ ]] && ((disk_pct >= MY_DISK_HIGH)); then
    my/pool disk
    my/say "$REPLY" "$MY_C_WARN" && return 0
  fi

  local load1 cores
  read -r load1 _ < /proc/loadavg 2>/dev/null
  cores=$(nproc 2>/dev/null) || cores=1
  if [[ $load1 ]] && ((${load1%.*} >= cores)); then
    my/pool load
    my/say "$REPLY" "$MY_C_WARN" && return 0
  fi

  return 1
}

# Records a specific moment, oldest trimmed off past MY_MEMORY_MAX. Keep
# $1 generic and safe to persist to disk indefinitely, never the actual
# command text (it could contain a path, a secret, anything).
function my/memory-add {
  mkdir -p "$STATE_DIR" 2>/dev/null
  local now
  printf -v now '%(%s)T' -1
  printf '%s|%s\n' "$now" "$1" >> "$MEMORY_FILE"
  local trimmed
  trimmed=$(tail -n "$MY_MEMORY_MAX" "$MEMORY_FILE")
  printf '%s\n' "$trimmed" > "$MEMORY_FILE"
}

# Picks one memory at random, detail text (the part after the
# timestamp) in REPLY. Returns 1 if there are none yet.
function my/memory-recall {
  REPLY=
  [[ -s $MEMORY_FILE ]] || return 1
  local line
  line=$(shuf -n1 "$MEMORY_FILE" 2>/dev/null)
  [[ $line ]] || return 1
  REPLY=${line#*|}
}

# Asks a real [y/N] (or [Y/n] if $2 is Y) question, the line itself drawn
# from <category>'s current level same as any other pool, so the exact
# wording warms up with affection too. Reacts to the actual answer right
# away too, from <category>-yes or <category>-no, rather than leaving
# that to whatever else happens to fire in the normal post-command
# reaction. Returns 0 to proceed, 1 to cancel. Never touches mood/stats
# itself, see the two command wrappers below for how a cancel still
# flows into the usual post-command reaction.
function my/gate {
  my/pool "$1"
  local line hint="y/N" a approved=
  line=$(shuf -n1 "$REPLY" 2>/dev/null)
  [[ $line ]] || line="Are you sure about that?"
  [[ $2 == Y ]] && hint="Y/n"
  [[ $1 == danger-gate ]] && my/mood worried
  [[ $1 == jealous-gate ]] && my/mood fedup
  read -r -p "$(printf '\033[1;38;2;%sm%s [%s] \033[0m' "$MY_C_WARN" "$line" "$hint")" a
  if [[ -z $a ]]; then
    [[ $2 == Y ]] && approved=1
  else
    [[ $a == [yY]* ]] && approved=1
  fi
  my/pool "$1-$([[ $approved ]] && echo yes || echo no)"
  my/say "$REPLY" "$MY_C_WARN"
  # The next real precmd cycle has the final say on her picture once the
  # command (or the decision not to run it) actually finishes, this is
  # just what she looks like for the moment, while you're deciding and
  # right after you answer
  case $1 in
    danger-gate) [[ $approved ]] && my/mood worried || my/mood surprised ;;
    jealous-gate) [[ $approved ]] && my/mood fedup || my/mood happy ;;
  esac
  [[ $approved ]]
}

# Checks requirements and setup, reports what's missing or broken.
# Doesn't touch mood/stats, same as every other tsun subcommand.
function my/doctor {
  local bad=0 warn=0

  row() { printf '%-15s %s\n' "$1" "$2"; }

  echo "Requirements"
  row "bash" "ok ($BASH_VERSION)"
  if command -v shuf >/dev/null 2>&1; then
    row "shuf" "ok"
  else
    row "shuf" "MISSING, install coreutils"; ((bad++))
  fi
  if command -v python3 >/dev/null 2>&1; then
    row "python3" "ok ($(python3 --version 2>&1 | awk '{print $2}'))"
  else
    row "python3" "missing, typo suggestions and AI chat won't work"; ((warn++))
  fi
  if [[ $COLORTERM == truecolor || $COLORTERM == 24bit ]]; then
    row "truecolor" "ok ($COLORTERM)"
  else
    row "truecolor" "not detected (\$COLORTERM=${COLORTERM:-unset}), colors may look wrong"; ((warn++))
  fi

  echo
  echo "Shell hook"
  if [[ $PROMPT_COMMAND == *my/tsundere-precmd* ]]; then
    row "precmd hook" "ok"
  else
    row "precmd hook" "MISSING, source tsundere.sh from .bashrc"; ((bad++))
  fi
  if [[ -o history ]]; then
    row "history" "ok"
  else
    row "history" "off, mood tracking needs it (set -o history)"; ((bad++))
  fi

  echo
  echo "WezTerm (optional, for the picture)"
  if [[ $TERM_PROGRAM == WezTerm ]]; then
    row "running in" "ok (WezTerm)"
    if command -v wezterm >/dev/null 2>&1; then
      row "wezterm cli" "ok"
    else
      row "wezterm cli" "not found, AI chat won't get recent-output context"; ((warn++))
    fi
    local outfits
    outfits=$(my/outfits-list 2>/dev/null | tr '\n' ' ')
    if [[ $outfits ]]; then
      row "outfits" "ok ($outfits)"
    else
      row "outfits" "none installed, run scripts/sprites.sh or install.sh with images"; ((warn++))
    fi
    if [[ -f "$LINES_DIR/sprites/ratios.txt" ]]; then
      row "ratios.txt" "ok"
    else
      row "ratios.txt" "missing, the picture will stay blank"; ((warn++))
    fi
  else
    row "running in" "not WezTerm (\$TERM_PROGRAM=${TERM_PROGRAM:-unset}), picture disabled, rest still works"
  fi

  echo
  echo "Command gates"
  if ((MY_GATE_DANGER)); then
    if declare -F rm >/dev/null && declare -F git >/dev/null; then
      row "danger gate" "ok (rm, git, dd, chmod, mkfs wrapped)"
    else
      row "danger gate" "MY_GATE_DANGER is on but the wrappers aren't defined, re-source tsundere.sh"; ((bad++))
    fi
  else
    row "danger gate" "off (MY_GATE_DANGER=0), old after-the-fact warning only"
  fi
  if ((MY_GATE_JEALOUS)); then
    local jc jc_alias wrapped=() shadowed=()
    for jc in "${MY_JEALOUS_CMDS[@]}"; do
      jc_alias=$(alias "$jc" 2>/dev/null)
      if [[ $jc_alias ]]; then
        shadowed+=("$jc")
      elif declare -F "$jc" >/dev/null; then
        wrapped+=("$jc")
      fi
    done
    if ((${#wrapped[@]})); then
      row "jealous gate" "ok (${wrapped[*]})"
    else
      row "jealous gate" "on, but none of MY_JEALOUS_CMDS are installed"
    fi
    if ((${#shadowed[@]})); then
      row "" "${shadowed[*]} aliased, wrapping does nothing, add what the alias points to instead"
      ((warn++))
    fi
  else
    row "jealous gate" "off (MY_GATE_JEALOUS=0)"
  fi

  echo
  echo "AI chat (optional)"
  if command -v curl >/dev/null 2>&1; then
    row "curl" "ok"
  else
    row "curl" "missing, needed for tsun talk"; ((warn++))
  fi
  if [[ -f "$LINES_DIR/ai.sh" ]]; then
    row "ai.sh" "ok"
  else
    row "ai.sh" "missing, tsun ai/talk won't work"; ((warn++))
  fi
  local ai_provider= ai_model=
  [[ -f "$STATE_DIR/ai" ]] && read -r ai_provider ai_model < "$STATE_DIR/ai"
  if [[ -z $ai_provider ]]; then
    row "provider" "off (tsun ai anthropic / tsun ai ollama)"
  else
    row "provider" "ok ($ai_provider, $ai_model)"
    if [[ $ai_provider == anthropic ]]; then
      if [[ -n ${ANTHROPIC_API_KEY-} ]]; then
        row "ANTHROPIC_API_KEY" "ok"
      else
        row "ANTHROPIC_API_KEY" "not set, tsun talk will fail"; ((bad++))
      fi
    elif [[ $ai_provider == ollama ]]; then
      local host=${MY_OLLAMA_HOST:-http://localhost:11434}
      if command -v curl >/dev/null 2>&1 && curl -s --max-time 3 "$host/api/tags" >/dev/null 2>&1; then
        row "ollama" "ok ($host reachable)"
      else
        row "ollama" "can't reach $host, is 'ollama serve' running?"; ((bad++))
      fi
    fi
  fi

  unset -f row
  echo
  if ((bad)); then
    printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_ERR" "Hmph, $bad thing(s) actually broken. Fix those first, baka."
  elif ((warn)); then
    printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_WARN" "Mostly fine, $warn thing(s) you might want to look at."
  else
    printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_PRAISE" "Hmph, everything checks out. Don't let it go to your head."
  fi
}

# The tsun command, type tsun for the list
function tsun {
  local a
  case ${1-} in
    off)
      mkdir -p "$STATE_DIR"
      : > "$MUTE_FILE"
      my/mood off
      my/pool tsun-off
      my/say-force "$REPLY" "$MY_C_INFO" ||
        echo "Tsundere mode is off. Type 'tsun on' to bring her back."
      ;;
    on)
      rm -f "$MUTE_FILE"
      my/sync-now
      my/pool tsun-on
      my/say-force "$REPLY" "$MY_C_INFO" ||
        printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_INFO" "Hmph, you needed me back already? F-Fine."
      ;;
    stats)
      my/state-load
      my/meter-load
      my/calc-level
      my/first-seen
      local since=$REPLY now days ever_cmds rate top
      printf -v now '%(%s)T' -1
      days=$(((now - since) / 86400 + 1))
      ever_cmds=$((MY_EVER_OK + MY_EVER_FAIL))
      rate=0
      ((ever_cmds > 0)) && rate=$((MY_EVER_OK * 100 / ever_cmds))
      top=$((${#MY_LEVEL_AT[@]} - 1))

      printf 'Known you    for %s day%s\n' "$days" "$([[ $days == 1 ]] || echo s)"
      printf 'Lifetime     %s ok, %s failed (%s%% success)\n' "$MY_EVER_OK" "$MY_EVER_FAIL" "$rate"
      printf 'Today        %s ok, %s failed, best streak %s\n' "$MY_S_OK" "$MY_S_FAIL" "$MY_S_BEST"
      printf 'Record       best streak ever %s\n' "$MY_EVER"
      printf 'Mood         %s of %s (happy at %s)\n' "$MY_MOOD_METER" "$MY_MOOD_MAX" "$MY_MOOD_THRESHOLD"
      printf 'Affection    level %s (%s), %s points\n' "$MY_LEVEL" "${MY_LEVEL_NAMES[MY_LEVEL]}" "$MY_TOTAL"
      if ((MY_LEVEL < top)); then
        printf 'Next level   at %s points (%s to go)\n' "${MY_LEVEL_AT[MY_LEVEL + 1]}" "$((MY_LEVEL_AT[MY_LEVEL + 1] - MY_TOTAL))"
      else
        printf 'Next level   none, this is as warm as she gets\n'
      fi
      echo
      if ((MY_S_FAIL > MY_S_OK)); then my/pool insults; else my/pool praise; fi
      my/say-force "$REPLY" "$MY_C_INFO"
      ;;
    say)
      my/pool phrases
      my/say-force "$REPLY" "$MY_C_INFO"
      ;;
    outfit)
      local target=${2-}
      if [[ -z $target ]]; then
        local list
        list=$(my/outfits-list | tr '\n' ' ')
        if [[ -z $list ]]; then
          echo "No sprite outfits installed. Run scripts/sprites.sh on an art pack first."
        else
          echo "Outfits  $list"
          echo "Current  $MY_OUTFIT"
        fi
      elif [[ -d "$LINES_DIR/sprites/$target" ]]; then
        MY_OUTFIT=$target
        mkdir -p "$STATE_DIR"
        printf '%s\n' "$MY_OUTFIT" > "$OUTFIT_FILE"
        my/sync-now
        my/pool tsun-outfit
        my/say-force "$REPLY" "$MY_C_INFO" ||
          printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_INFO" "Hmph, this one? F-Fine, I guess it suits me."
      else
        echo "No such outfit: $target" >&2
        echo "Outfits  $(my/outfits-list | tr '\n' ' ')" >&2
      fi
      ;;
    crop)
      local target=${2-}
      if [[ -z $target ]]; then
        echo "Crop levels  full waist bust"
        echo "Current      $MY_CROP"
      elif [[ $target =~ ^(full|waist|bust)$ ]]; then
        MY_CROP=$target
        mkdir -p "$STATE_DIR"
        printf '%s\n' "$MY_CROP" > "$CROP_FILE"
        my/sync-now
        my/pool tsun-crop
        my/say-force "$REPLY" "$MY_C_INFO" ||
          printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_INFO" "Hmph, don't stare too much, idiot."
      else
        echo "Unknown crop: $target (use full, waist or bust)" >&2
      fi
      ;;
    size)
      local target=${2-}
      if [[ -z $target ]]; then
        echo "Size   $MY_SIZE (range $MY_SIZE_MIN-$MY_SIZE_MAX, percent of window height)"
      elif [[ $target == bigger ]]; then
        MY_SIZE=$((MY_SIZE + MY_SIZE_STEP))
        ((MY_SIZE > MY_SIZE_MAX)) && MY_SIZE=$MY_SIZE_MAX
      elif [[ $target == smaller ]]; then
        MY_SIZE=$((MY_SIZE - MY_SIZE_STEP))
        ((MY_SIZE < MY_SIZE_MIN)) && MY_SIZE=$MY_SIZE_MIN
      elif [[ $target == reset ]]; then
        MY_SIZE=$MY_SIZE_DEFAULT
      elif [[ $target =~ ^[0-9]+$ ]] && ((target >= MY_SIZE_MIN && target <= MY_SIZE_MAX)); then
        MY_SIZE=$target
      else
        echo "Usage: tsun size [bigger | smaller | reset | <$MY_SIZE_MIN-$MY_SIZE_MAX>]" >&2
        return
      fi
      mkdir -p "$STATE_DIR"
      printf '%s\n' "$MY_SIZE" > "$SIZE_FILE"
      my/sync-now
      local sizeline
      my/pool tsun-size
      sizeline=$(shuf -n1 "$REPLY" 2>/dev/null)
      [[ $sizeline ]] || sizeline='Hmph, happy now? (%s%)'
      printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_INFO" "${sizeline//%s/$MY_SIZE}"
      ;;
    name)
      local target=${2-}
      if [[ -z $target ]]; then
        if [[ $MY_PET_NAME ]]; then
          echo "Pet name  $MY_PET_NAME"
        else
          echo "No pet name set. Usage: tsun name <name> | off"
        fi
      elif [[ $target == off ]]; then
        MY_PET_NAME=
        rm -f "$NAME_FILE"
        echo "Fine. Back to baka/idiot, I guess."
      else
        MY_PET_NAME=$target
        mkdir -p "$STATE_DIR"
        printf '%s\n' "$MY_PET_NAME" > "$NAME_FILE"
        my/pool tsun-name
        my/say-force "$REPLY" "$MY_C_INFO" ||
          printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_INFO" "Hmph, $MY_PET_NAME? Fine, I guess I'll call you that."
      fi
      ;;
    memories)
      if [[ -s $MEMORY_FILE ]]; then
        echo "Things she remembers:"
        while IFS='|' read -r ts detail; do
          printf '  %s\n' "$detail"
        done < "$MEMORY_FILE"
      else
        echo "Nothing yet. Give her something worth remembering, baka."
      fi
      ;;
    reset)
      read -r -p "Reset mood, stats, affection and how long she's known you? [y/N] " a
      if [[ $a == [yY]* ]]; then
        rm -f "$METER_FILE" "$STATE_FILE" "$SEEN_FILE" "$FIRST_SEEN_FILE" "$MEMORY_FILE"
        MY_MOOD_METER=0
        MY_TOTAL=0
        MY_LEVEL=0
        MY_EVER_OK=0
        MY_EVER_FAIL=0
        echo "...Fine. We start from zero, baka."
      fi
      ;;
    ai|talk)
      # Lives in its own file so this one doesn't keep growing, loaded only
      # the first time either of these is actually used. `tsun ai setup`
      # (tuning settings) lives under here too, see ai.sh.
      if ! declare -F my/ai-dispatch >/dev/null; then
        if [[ -f "$LINES_DIR/ai.sh" ]]; then
          source "$LINES_DIR/ai.sh"
        else
          echo "AI chat isn't installed (missing ai.sh)." >&2
          return 1
        fi
      fi
      my/ai-dispatch "$@"
      ;;
    doctor)
      my/doctor
      ;;
    *)
      echo "Usage  tsun off | on | stats | say | reset | outfit [name] | crop [name] | size [bigger|smaller|reset|N] | name [name|off] | memories | ai [anthropic|ollama|off|setup] [model|name value] | talk [message] | doctor"
      ;;
  esac
}

# Insult and suggestion on mistyped command names (status 127)
command_not_found_handle() {
  if [[ -e $MUTE_FILE ]]; then
    echo "bash: $1: command not found" >&2
    return 127
  fi

  # Exact repeat of the last attempt, which also failed: bash always
  # routes a not-found command here before my/tsundere-precmd ever runs,
  # so precmd's own repeat_of_fail check never gets a chance to react for
  # these - mirror it here instead, or retyping the same typo gets a
  # brand new insult and "did you mean" every single time
  if [[ "$*" == "$MY_PREV_CMD" && $MY_PREV_OK == 0 ]]; then
    my/pool repeat-fail
    my/say-force "$REPLY" "$MY_C_WARN" >&2
    return 127
  fi

  my/pool insults
  my/say-force "$REPLY" "$MY_C_ERR" >&2

  if command -v python3 >/dev/null 2>&1; then
    local s line
    s=$(compgen -c | python3 -c '
import sys
w = sys.argv[1]
cands = {l.strip() for l in sys.stdin if l.strip()}
limit = 1 if len(w) <= 4 else 2

def osa(a, b):
    la, lb = len(a), len(b)
    d = [[0] * (lb + 1) for _ in range(la + 1)]
    for i in range(la + 1):
        d[i][0] = i
    for j in range(lb + 1):
        d[0][j] = j
    for i in range(1, la + 1):
        for j in range(1, lb + 1):
            cost = 0 if a[i - 1] == b[j - 1] else 1
            d[i][j] = min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost)
            if i > 1 and j > 1 and a[i - 1] == b[j - 2] and a[i - 2] == b[j - 1]:
                d[i][j] = min(d[i][j], d[i - 2][j - 2] + 1)
    return d[la][lb]

best = None
for c in cands:
    if c == w or abs(len(c) - len(w)) > limit:
        continue
    d = osa(w, c)
    if d <= limit:
        k = (d, sorted(c) != sorted(w), c[0] != w[0], c)
        if best is None or k < best:
            best = k
print(best[-1] if best else "")
' "$1")
    if [[ $s ]]; then
      my/pool typo
      line=$(shuf -n1 "$REPLY" 2>/dev/null)
      [[ $line ]] || line='D-Did you mean `%s`? Idiot.'
      printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_ERR" "${line//%s/$s}" >&2
    fi
  fi
  return 127
}

# Tab completion for `tsun`. Outfit names are a live scan same as `tsun
# outfit` itself; the `ai setup` names are listed by hand since reading
# them out of ai.sh would mean loading it just for a tab press. If a
# setting gets added there, add its short name here too.
function _tsun_complete {
  local cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=()
  if ((COMP_CWORD == 1)); then
    COMPREPLY=($(compgen -W "off on stats say outfit crop size name memories reset ai talk doctor" -- "$cur"))
    return
  fi
  case ${COMP_WORDS[1]} in
    outfit)
      ((COMP_CWORD == 2)) &&
        COMPREPLY=($(compgen -W "$(my/outfits-list 2>/dev/null | tr '\n' ' ')" -- "$cur"))
      ;;
    crop)
      ((COMP_CWORD == 2)) && COMPREPLY=($(compgen -W "full waist bust" -- "$cur"))
      ;;
    size)
      ((COMP_CWORD == 2)) && COMPREPLY=($(compgen -W "bigger smaller reset" -- "$cur"))
      ;;
    name)
      ((COMP_CWORD == 2)) && COMPREPLY=($(compgen -W "off" -- "$cur"))
      ;;
    ai)
      if ((COMP_CWORD == 2)); then
        COMPREPLY=($(compgen -W "anthropic ollama off setup" -- "$cur"))
      elif [[ ${COMP_WORDS[2]} == setup ]] && ((COMP_CWORD == 3)); then
        local provider= names="timeout history_turns send_output output_lines output_chars reply_limit reset"
        [[ -f "$STATE_DIR/ai" ]] && read -r provider _ < "$STATE_DIR/ai"
        [[ $provider == ollama ]] && names="$names keepalive"
        COMPREPLY=($(compgen -W "$names" -- "$cur"))
      fi
      ;;
  esac
}
complete -F _tsun_complete tsun

# Runs on every prompt. Figures out from `history` whether a new command
# actually ran since the last prompt (plain bash has no preexec hook, so
# this is checked after the fact, not before), reacts to it, then updates
# mood, stats and affection.
function my/tsundere-precmd {
  local status=$?

  # First-ever call for this shell: just learn where history currently
  # stands and stop. This has to happen here, not at source time, because
  # .bashrc can run before bash has finished loading $HISTFILE into memory
  # - capture it too early and this reads back empty, the baseline falls
  # back to "nothing happened yet", and the first real prompt then treats
  # whatever is last in the history FILE (maybe from hours ago, maybe from
  # a different terminal) as a command that just ran, old timestamp and
  # all. By the time this function is called at all, bash is already about
  # to show a prompt, which means history is guaranteed to be loaded.
  if [[ -z $MY_LAST_HISTNUM ]]; then
    read -r MY_LAST_HISTNUM _ <<< "$(builtin history 1 2>/dev/null)"
    [[ $MY_LAST_HISTNUM =~ ^[0-9]+$ ]] || MY_LAST_HISTNUM=0
    return
  fi

  # Did anything new actually run? (first prompt, or an empty Enter, leave
  # the history count unchanged; see the HISTTIMEFORMAT comment above for
  # the one case this can miss)
  local histline histnum ts
  histline=$(builtin history 1 2>/dev/null)
  read -r histnum ts MY_CMD <<< "$histline"
  [[ $histnum =~ ^[0-9]+$ ]] || return
  [[ $histnum == "$MY_LAST_HISTNUM" ]] && return
  MY_LAST_HISTNUM=$histnum

  # The tsun command handles its own feedback. It must not count towards
  # the mood meter, stats or affection, and must not get a second,
  # automatic reaction on top of whatever it already said.
  [[ $MY_CMD == tsun || $MY_CMD == "tsun "* ]] && return

  # Muted, keep the image hidden and do nothing else
  if [[ -e $MUTE_FILE ]]; then
    my/mood off
    return
  fi

  # Exact repeat of the last command, same outcome as last time too - still
  # reacts below, but doesn't move the mood meter/streak/affection again.
  # Spamming a known-good command would otherwise be a free way to farm
  # points, and spamming a known-bad one (habit, up-arrow+enter without
  # changing anything) would otherwise keep stacking the same penalty for
  # the one mistake she already reacted to.
  local repeat_of_ok= repeat_of_fail=
  if [[ $MY_CMD == "$MY_PREV_CMD" ]]; then
    [[ $MY_PREV_OK == 1 ]] && repeat_of_ok=1
    [[ $MY_PREV_OK == 0 ]] && repeat_of_fail=1
  fi

  local now
  printf -v now '%(%s)T' -1
  local dur=$((now - ts))
  ((dur < 0)) && dur=0

  # A dangerous command, noticed here rather than before it runs, since
  # nothing short of ble.sh or a similar library can catch it ahead of
  # time, and the old warning never actually stopped it from running
  # either. Still worth a reaction.
  local danger=
  case $MY_CMD in
    *"rm -rf"*|*"rm -fr"*|*"rm -r "*|*"git push"*" --force"*|*"git push"*" -f"*|*mkfs*|*"dd if="*|*"chmod -R 777"*)
      danger=1
      ;;
  esac

  # Same idea as $danger above: the jealousy gate already said her piece on
  # this exact command before it ran, when it's on
  local jealous=
  if ((MY_GATE_JEALOUS)); then
    local jc
    for jc in "${MY_JEALOUS_CMDS[@]}"; do
      [[ ${MY_CMD%% *} == "$jc" ]] && { jealous=1; break; }
    done
  fi

  local face=normal said= oldlevel
  MY_SPOKE=

  # Reload shared state so several terminals agree
  my/meter-load
  my/state-load
  my/calc-level
  oldlevel=$MY_LEVEL
  printf '%s\n' "$now" > "$SEEN_FILE"

  if ((status != 0)) && [[ -z $repeat_of_fail ]]; then
    ((MY_MOOD_METER -= MY_MOOD_PENALTY))
    ((MY_MOOD_METER < 0)) && MY_MOOD_METER=0
    ((MY_S_FAIL++))
    ((MY_EVER_FAIL++))
    MY_S_STREAK=0
    ((MY_FAIL_STREAK++))
    ((MY_TOTAL > 0)) && ((MY_TOTAL--))

    # The gate (my/gate, when MY_GATE_DANGER is on) already said her piece
    # before this ran, so this would just be a redundant second warning
    if [[ $danger ]] && ((!MY_GATE_DANGER)); then
      my/pool danger
      my/say "$REPLY" "$MY_C_WARN"
    fi

    # Status 127 already got an insult and a suggestion from the handler
    if ((status != 127)); then
      if ! my/exit-reaction "$status" && ! my/react fail; then
        my/pool insults
        my/say "$REPLY" "$MY_C_ERR"
      fi
      if ((dur >= MY_NOTIFY_SECS)) && ! my/is-interactive; then
        my/pool insults
        my/notify "Command failed" "${MY_CMD%% *} failed after ${dur}s. $(shuf -n1 "$REPLY" 2>/dev/null)"
      fi
    fi

    if [[ $danger ]]; then
      face=scared
      my/memory-add "that scary command that went wrong"
    elif ((MY_FAIL_STREAK >= 3)); then
      face=fedup
    else
      face=angry
    fi
  elif ((status != 0)); then
    # Same failing command as last time - she already reacted to this
    # exact mistake once, no need to pile the penalty on again. Status 127
    # already got its own reaction from command_not_found_handle above,
    # same exception the normal fail branch makes.
    if ((status != 127)); then
      my/pool repeat-fail
      my/say "$REPLY" "$MY_C_WARN"
    fi
  elif [[ $repeat_of_ok ]]; then
    # Same command, same result as last time - still worth a word, but
    # no extra mood/streak/affection, see repeat_of_ok above
    my/pool repeat
    my/say "$REPLY" "$MY_C_INFO"
  else
    ((MY_MOOD_METER++))
    ((MY_MOOD_METER > MY_MOOD_MAX)) && MY_MOOD_METER=$MY_MOOD_MAX
    ((MY_S_OK++))
    ((MY_EVER_OK++))
    MY_FAIL_STREAK=0
    ((MY_S_STREAK++))
    ((MY_S_STREAK > MY_S_BEST)) && MY_S_BEST=$MY_S_STREAK
    if ((MY_S_STREAK > MY_EVER)); then
      MY_EVER=$MY_S_STREAK
      my/memory-add "the time you hit a $MY_EVER-command streak"
    fi
    ((MY_TOTAL++))
    my/calc-level

    # New affection level
    if ((MY_LEVEL > oldlevel)); then
      my/pool levelup
      my/say "$REPLY" "$MY_C_PRAISE" && said=1
      face=happy
      my/memory-add "the day you reached '${MY_LEVEL_NAMES[MY_LEVEL]}'"
    fi

    if [[ $danger ]]; then
      # She already said her piece in the gate (my/gate) if that's on;
      # only give the old standalone reaction when it's off
      ((MY_GATE_DANGER)) || { my/pool danger; my/say "$REPLY" "$MY_C_WARN"; }
      face=surprised
      my/memory-add "that dangerous command you survived"
    elif [[ $jealous ]]; then
      : # she already said everything that needed saying, in the gate
    else
      # Streak milestone
      if [[ -z $said ]]; then
        local m line
        for m in "${MY_STREAK_MILESTONES[@]}"; do
          if ((MY_S_STREAK == m)); then
            my/pool streak
            line=$(shuf -n1 "$REPLY" 2>/dev/null)
            if [[ $line ]]; then
              printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_PRAISE" "${line//%s/$m}"
              said=1
              face=happy
              MY_SPOKE=1
            fi
            break
          fi
        done
      fi

      # Rare sweet line
      if [[ -z $said ]] && ((RANDOM % MY_RARE_CHANCE == 0)); then
        my/pool rare
        my/say "$REPLY" "$MY_C_PRAISE" && said=1
        face=happy
      fi

      # Occasional callback to a specific remembered moment
      if [[ -z $said ]] && ((RANDOM % MY_MEMORY_CHANCE == 0)) && my/memory-recall; then
        local detail=$REPLY mline
        my/pool memory
        mline=$(shuf -n1 "$REPLY" 2>/dev/null)
        if [[ $mline ]]; then
          printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_PRAISE" "${mline//%s/$detail}"
          said=1
          face=happy
          MY_SPOKE=1
        fi
      fi

      # Slow command finished, skip interactive programs
      if ((dur >= MY_SLOW_SECS)) && ! my/is-interactive; then
        my/pool slow
        if [[ -z $said ]]; then
          my/say "$REPLY" "$MY_C_INFO" && said=1
        fi
        if ((dur >= MY_NOTIFY_SECS)); then
          my/notify "Command finished" "${MY_CMD%% *} finished after ${dur}s. $(shuf -n1 "$REPLY" 2>/dev/null)"
        fi
      fi

      # Command specific reactions
      if [[ -z $said ]] && my/react ok; then
        said=1
      fi

      # Git reactions
      if [[ -z $said && $MY_CMD == git\ * ]] && git rev-parse --is-inside-work-tree &>/dev/null; then
        local n
        n=$(git status --porcelain 2>/dev/null | wc -l)
        if ((n >= MY_GIT_DIRTY)); then
          my/pool git-dirty
          my/say "$REPLY" "$MY_C_WARN" && { said=1; face=disgusted; }
        elif [[ $MY_CMD == "git status"* ]]; then
          if ((n == 0)); then
            my/pool git-status-clean
            my/say "$REPLY" "$MY_C_PRAISE" && said=1
          else
            my/pool git-status-dirty
            my/say "$REPLY" "$MY_C_INFO" && said=1
          fi
        elif [[ $MY_CMD == "git push"* || $MY_CMD == "git commit"* ]] && ((n == 0)); then
          my/pool git-clean
          my/say "$REPLY" "$MY_C_PRAISE" && said=1
        fi
      fi

      # Praise while she is happy
      if ((MY_MOOD_METER >= MY_MOOD_THRESHOLD)); then
        face=happy
        if [[ -z $said ]]; then
          my/pool praise
          my/say "$REPLY" "$MY_C_PRAISE" && said=1
        fi
      fi

      # Occasional bedtime nag at night
      if [[ -z $said ]]; then
        local h
        printf -v h '%(%H)T' -1
        h=$((10#$h))
        if ((h >= 23 || h < 5)) && ((RANDOM % MY_NIGHT_CHANCE == 0)); then
          my/pool night
          my/say "$REPLY" "$MY_C_INFO" && { said=1; face=worried; }
        fi
      fi

      # Nothing else fired, fall back to a generic phrase
      if [[ -z $said ]]; then
        my/pool phrases
        my/say "$REPLY" "$MY_C_INFO"
      fi
    fi
  fi

  MY_PREV_CMD=$MY_CMD
  # A declined gate (rm -rf, git push --force, another AI's CLI...) counts
  # as a success below so it doesn't read as a failure, but nothing actually
  # ran - leave MY_PREV_OK empty rather than 1, so actually approving the
  # same command next time isn't mistaken for a repeat of something that
  # never happened
  if [[ $MY_LAST_DECLINED ]]; then
    MY_PREV_OK=
    MY_LAST_DECLINED=
  else
    MY_PREV_OK=$((status == 0 ? 1 : 0))
  fi

  # Break reminder after a long session
  if ((SECONDS - MY_LAST_BREAK >= MY_BREAK_SECS)); then
    my/pool break
    my/say "$REPLY" "$MY_C_WARN" && face=worried
    MY_LAST_BREAK=$SECONDS
  fi

  # Rare comment on the machine itself (battery/disk/load), not the command
  my/ambient-check && face=worried

  my/meter-save
  my/state-save
  my/mood "$face"
}

# Gated commands: a plain bash function can't intercept a command before
# it runs in general (there's no preexec hook without ble.sh or similar),
# but it CAN intercept itself -- define a function with the same name as
# a real command and it runs instead, for anything typed directly at this
# prompt. `command <name> "$@"` below calls the real one when approved.
# Cancelling returns 0 (not 1): nothing destructive happened, so it reads
# to the precmd hook as "survived", not "failed".
if ((MY_GATE_DANGER)); then
  function rm {
    case " $* " in
      *" -rf "*|*" -fr "*|*" -r "*|*" -R "*)
        my/gate danger-gate || { MY_LAST_DECLINED=1; return 0; }
        ;;
    esac
    command rm "$@"
  }

  function git {
    if [[ $1 == push ]]; then
      local arg
      for arg in "$@"; do
        [[ $arg == --force || $arg == -f ]] && { my/gate danger-gate || { MY_LAST_DECLINED=1; return 0; }; break; }
      done
    fi
    command git "$@"
  }

  function dd { my/gate danger-gate || { MY_LAST_DECLINED=1; return 0; }; command dd "$@"; }

  function chmod {
    [[ " $* " == *" -R "*777* || " $* " == *777*" -R "* ]] && { my/gate danger-gate || { MY_LAST_DECLINED=1; return 0; }; }
    command chmod "$@"
  }

  function mkfs { my/gate danger-gate || { MY_LAST_DECLINED=1; return 0; }; command mkfs "$@"; }
fi

if ((MY_GATE_JEALOUS)); then
  for __my_jealous_cmd in "${MY_JEALOUS_CMDS[@]}"; do
    command -v "$__my_jealous_cmd" >/dev/null 2>&1 || continue
    eval "function $__my_jealous_cmd {
      my/gate jealous-gate Y || { MY_LAST_DECLINED=1; return 0; }
      command $__my_jealous_cmd \"\$@\"
    }"
  done
  unset __my_jealous_cmd
fi

# Run first, before anything else in PROMPT_COMMAND, so $? still reflects
# the command that just ran rather than something PROMPT_COMMAND itself did.
# Strip any copy this file already added before, so re-sourcing (a second
# `source ~/.bashrc`, for example) never piles up duplicate entries.
PROMPT_COMMAND=${PROMPT_COMMAND//my\/tsundere-precmd/}
PROMPT_COMMAND=$(sed -E 's/(; )+/; /g; s/^; //; s/; $//' <<< "$PROMPT_COMMAND")
PROMPT_COMMAND="my/tsundere-precmd${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# Startup, load state, greet or complain about the absence, set the face
mkdir -p "$STATE_DIR" 2>/dev/null
my/meter-load
my/state-load
my/calc-level
my/first-seen
my/outfit-load
my/crop-load
my/size-load
my/name-load
if ((SHLVL <= 1)); then
  my/away-check || my/greet
fi
my/sync-now
