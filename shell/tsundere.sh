# Tsundere terminal
# Save as ~/.config/tsundere/tsundere.sh and load it from .bashrc, any time
# after `shopt -s histappend` or similar, no ble.sh or other preexec library
# needed. Everything, code, phrases and images, lives in ~/.config/tsundere/

# Files
LINES_DIR="$HOME/.config/tsundere"
INSULTS_FILE="$LINES_DIR/insults.txt"
PRAISE_FILE="$LINES_DIR/praise.txt"
PHRASES_FILE="$LINES_DIR/phrases.txt"
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

# Lets `history 1` report when each command was entered, in epoch seconds,
# which is how duration and "did a new command actually run" are worked out
# without ble.sh or any other preexec library. Side effect: plain `history`
# now shows that timestamp column too, in every tab, for the rest of the
# session. Known gap: if HISTCONTROL drops an exact repeat of the previous
# command (ignoredups), that repeat is invisible here too, since there is
# no new history entry to notice.
HISTTIMEFORMAT='%s '

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
MY_SPOKE=
MY_LAST_HISTNUM=0
MY_LAST_BREAK=$SECONDS
MY_OUTFIT=
MY_CROP=waist
MY_SIZE=$MY_SIZE_DEFAULT

# Print a random line from a file in a color, even when muted
function my/say-force {
  [[ -f $1 ]] || return 1
  printf '\033[1;38;2;%sm%s\033[0m\n' "$2" "$(shuf -n1 "$1")"
  MY_SPOKE=1
}

# Same, but silent when she is muted
function my/say {
  [[ -e $MUTE_FILE ]] && return 1
  my/say-force "$1" "$2"
}

# Pick the line file for the current affection level, result in REPLY
function my/pool {
  REPLY=
  case $1 in
    insults)
      if ((MY_LEVEL >= 4)); then
        REPLY="$LINES_DIR/insults-4.txt"
      elif ((MY_LEVEL >= 3)); then
        REPLY="$LINES_DIR/insults-3.txt"
      elif ((MY_LEVEL >= 2)); then
        REPLY="$LINES_DIR/insults-2.txt"
      fi
      [[ -f $REPLY ]] || REPLY=$INSULTS_FILE
      ;;
    praise)
      if ((MY_LEVEL >= 1)); then
        REPLY="$LINES_DIR/praise-$MY_LEVEL.txt"
      fi
      [[ -f $REPLY ]] || REPLY=$PRAISE_FILE
      ;;
    levelup)
      REPLY="$LINES_DIR/levelup-$MY_LEVEL.txt"
      [[ -f $REPLY ]] || REPLY="$LINES_DIR/levelup.txt"
      ;;
  esac
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
  local file="$LINES_DIR/reactions.txt" pat when msg
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

# Reaction to a specific exit code from exitcodes.txt, regardless of command
# Prints one matching line and returns 0, or returns 1 when nothing matches
function my/exit-reaction {
  local file="$LINES_DIR/exitcodes.txt" code msg
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
    my/say "$LINES_DIR/morning.txt" "$MY_C_INFO"
  elif ((h >= 12 && h < 17)); then
    my/say "$LINES_DIR/afternoon.txt" "$MY_C_INFO"
  elif ((h >= 17 && h < 23)); then
    my/say "$LINES_DIR/evening.txt" "$MY_C_INFO"
  elif ((h >= 23 || h < 5)); then
    my/say "$LINES_DIR/night.txt" "$MY_C_INFO"
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
    my/say "$LINES_DIR/away.txt" "$MY_C_WARN"
    return 0
  fi
  return 1
}

# The tsun command, type tsun for the list
function tsun {
  local a
  case ${1-} in
    off)
      mkdir -p "$STATE_DIR"
      : > "$MUTE_FILE"
      my/mood off
      my/say-force "$LINES_DIR/tsun-off.txt" "$MY_C_INFO" ||
        echo "Tsundere mode is off. Type 'tsun on' to bring her back."
      ;;
    on)
      rm -f "$MUTE_FILE"
      my/sync-now
      my/say-force "$LINES_DIR/tsun-on.txt" "$MY_C_INFO" ||
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
      my/say-force "$PHRASES_FILE" "$MY_C_INFO"
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
        my/say-force "$LINES_DIR/tsun-outfit.txt" "$MY_C_INFO" ||
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
        my/say-force "$LINES_DIR/tsun-crop.txt" "$MY_C_INFO" ||
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
      sizeline=$(shuf -n1 "$LINES_DIR/tsun-size.txt" 2>/dev/null)
      [[ $sizeline ]] || sizeline='Hmph, happy now? (%s%)'
      printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_INFO" "${sizeline//%s/$MY_SIZE}"
      ;;
    reset)
      read -r -p "Reset mood, stats, affection and how long she's known you? [y/N] " a
      if [[ $a == [yY]* ]]; then
        rm -f "$METER_FILE" "$STATE_FILE" "$SEEN_FILE" "$FIRST_SEEN_FILE"
        MY_MOOD_METER=0
        MY_TOTAL=0
        MY_LEVEL=0
        MY_EVER_OK=0
        MY_EVER_FAIL=0
        echo "...Fine. We start from zero, baka."
      fi
      ;;
    ai|talk|aisetup)
      # Lives in its own file so this one doesn't keep growing, loaded only
      # the first time any of these is actually used
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
    *)
      echo "Usage  tsun off | on | stats | say | reset | outfit [name] | crop [name] | size [bigger|smaller|reset|N] | ai [anthropic|ollama|off] [model] | talk [message] | aisetup [name value|reset]"
      ;;
  esac
}

# Insult and suggestion on mistyped command names (status 127)
command_not_found_handle() {
  if [[ -e $MUTE_FILE ]]; then
    echo "bash: $1: command not found" >&2
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
      line=$(shuf -n1 "$LINES_DIR/typo.txt" 2>/dev/null)
      [[ $line ]] || line='D-Did you mean `%s`? Idiot.'
      printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_ERR" "${line//%s/$s}" >&2
    fi
  fi
  return 127
}

# Runs on every prompt. Figures out from `history` whether a new command
# actually ran since the last prompt (plain bash has no preexec hook, so
# this is checked after the fact, not before), reacts to it, then updates
# mood, stats and affection.
function my/tsundere-precmd {
  local status=$?

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

  local face=normal said= oldlevel
  MY_SPOKE=

  # Reload shared state so several terminals agree
  my/meter-load
  my/state-load
  my/calc-level
  oldlevel=$MY_LEVEL
  printf '%s\n' "$now" > "$SEEN_FILE"

  if ((status != 0)); then
    ((MY_MOOD_METER -= MY_MOOD_PENALTY))
    ((MY_MOOD_METER < 0)) && MY_MOOD_METER=0
    ((MY_S_FAIL++))
    ((MY_EVER_FAIL++))
    MY_S_STREAK=0
    ((MY_FAIL_STREAK++))
    ((MY_TOTAL > 0)) && ((MY_TOTAL--))

    [[ $danger ]] && my/say "$LINES_DIR/danger.txt" "$MY_C_WARN"

    # Status 127 already got an insult and a suggestion from the handler
    if ((status != 127)); then
      if ! my/exit-reaction "$status" && ! my/react fail; then
        my/pool insults
        my/say "$REPLY" "$MY_C_ERR"
      fi
      if ((dur >= MY_NOTIFY_SECS)) && ! my/is-interactive; then
        my/notify "Command failed" "${MY_CMD%% *} failed after ${dur}s. $(shuf -n1 "$INSULTS_FILE" 2>/dev/null)"
      fi
    fi

    if [[ $danger ]]; then
      face=scared
    elif ((MY_FAIL_STREAK >= 3)); then
      face=fedup
    else
      face=angry
    fi
  else
    ((MY_MOOD_METER++))
    ((MY_MOOD_METER > MY_MOOD_MAX)) && MY_MOOD_METER=$MY_MOOD_MAX
    ((MY_S_OK++))
    ((MY_EVER_OK++))
    MY_FAIL_STREAK=0
    ((MY_S_STREAK++))
    ((MY_S_STREAK > MY_S_BEST)) && MY_S_BEST=$MY_S_STREAK
    ((MY_S_STREAK > MY_EVER)) && MY_EVER=$MY_S_STREAK
    ((MY_TOTAL++))
    my/calc-level

    # New affection level
    if ((MY_LEVEL > oldlevel)); then
      my/pool levelup
      my/say "$REPLY" "$MY_C_PRAISE" && said=1
      face=happy
    fi

    if [[ $danger ]]; then
      # She survived the scary command
      my/say "$LINES_DIR/danger.txt" "$MY_C_WARN"
      face=surprised
    else
      # Streak milestone
      if [[ -z $said ]]; then
        local m line
        for m in "${MY_STREAK_MILESTONES[@]}"; do
          if ((MY_S_STREAK == m)); then
            line=$(shuf -n1 "$LINES_DIR/streak.txt" 2>/dev/null)
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
        my/say "$LINES_DIR/rare.txt" "$MY_C_PRAISE" && said=1
        face=happy
      fi

      # Slow command finished, skip interactive programs
      if ((dur >= MY_SLOW_SECS)) && ! my/is-interactive; then
        if [[ -z $said ]]; then
          my/say "$LINES_DIR/slow.txt" "$MY_C_INFO" && said=1
        fi
        if ((dur >= MY_NOTIFY_SECS)); then
          my/notify "Command finished" "${MY_CMD%% *} finished after ${dur}s. $(shuf -n1 "$LINES_DIR/slow.txt" 2>/dev/null)"
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
          my/say "$LINES_DIR/git-dirty.txt" "$MY_C_WARN" && { said=1; face=disgusted; }
        elif [[ $MY_CMD == "git push"* || $MY_CMD == "git commit"* ]] && ((n == 0)); then
          my/say "$LINES_DIR/git-clean.txt" "$MY_C_PRAISE" && said=1
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
          my/say "$LINES_DIR/night.txt" "$MY_C_INFO" && { said=1; face=worried; }
        fi
      fi

      # Nothing else fired, fall back to a generic phrase
      if [[ -z $said ]]; then
        my/say "$PHRASES_FILE" "$MY_C_INFO"
      fi
    fi
  fi

  # Break reminder after a long session
  if ((SECONDS - MY_LAST_BREAK >= MY_BREAK_SECS)); then
    my/say "$LINES_DIR/break.txt" "$MY_C_WARN" && face=worried
    MY_LAST_BREAK=$SECONDS
  fi

  my/meter-save
  my/state-save
  my/mood "$face"
}

# Run first, before anything else in PROMPT_COMMAND, so $? still reflects
# the command that just ran rather than something PROMPT_COMMAND itself did.
# Strip any copy this file already added before, so re-sourcing (a second
# `source ~/.bashrc`, for example) never piles up duplicate entries.
PROMPT_COMMAND=${PROMPT_COMMAND//my\/tsundere-precmd/}
PROMPT_COMMAND=$(sed -E 's/(; )+/; /g; s/^; //; s/; $//' <<< "$PROMPT_COMMAND")
PROMPT_COMMAND="my/tsundere-precmd${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# Startup, load state, greet or complain about the absence, set the face
mkdir -p "$STATE_DIR" 2>/dev/null
read -r MY_LAST_HISTNUM _ <<< "$(builtin history 1 2>/dev/null)"
[[ $MY_LAST_HISTNUM =~ ^[0-9]+$ ]] || MY_LAST_HISTNUM=0
my/meter-load
my/state-load
my/calc-level
my/first-seen
my/outfit-load
my/crop-load
my/size-load
if ((SHLVL <= 1)); then
  my/away-check || my/greet
fi
my/sync-now
