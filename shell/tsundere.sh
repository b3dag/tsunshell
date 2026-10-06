# Tsundere terminal
# Save as ~/.config/tsundere/tsundere.sh and load it from .bashrc after ble.sh is sourced
# Everything, code, phrases and images, lives in ~/.config/tsundere/

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
MY_LEVEL_AT=(0 100 400 1000)
MY_LEVEL_NAMES=("cold" "warming up" "softening" "dere")

# State
MY_MOOD_METER=0
MY_LEVEL=0
MY_TOTAL=0
MY_EVER=0
MY_S_DATE=
MY_S_OK=0
MY_S_FAIL=0
MY_S_STREAK=0
MY_S_BEST=0
MY_RAN=
MY_CMD=
MY_START=$SECONDS
MY_DANGER=
MY_LAST_BREAK=$SECONDS

# Print a random line from a file in a color, even when muted
function my/say-force {
  [[ -f $1 ]] || return 1
  printf '\033[1;38;2;%sm%s\033[0m\n' "$2" "$(shuf -n1 "$1")"
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
      if ((MY_LEVEL >= 3)); then
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
  esac
}

# Tells WezTerm which girl image to show, ignored in other terminals
function my/mood {
  [[ $TERM_PROGRAM == WezTerm ]] || return
  local m=$1
  [[ -e $MUTE_FILE ]] && m=off
  printf '\033]1337;SetUserVar=tsun_mood=%s\007' "$(printf '%s' "$m" | base64)"
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

# Daily counters, best streaks and the long term affection points
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
  [[ -f $STATE_FILE ]] && read -r MY_S_DATE MY_S_OK MY_S_FAIL MY_S_STREAK MY_S_BEST MY_TOTAL MY_EVER < "$STATE_FILE"
  for v in MY_S_OK MY_S_FAIL MY_S_STREAK MY_S_BEST MY_TOTAL MY_EVER; do
    [[ ${!v} =~ ^[0-9]+$ ]] || printf -v "$v" '%s' 0
  done
  if [[ $MY_S_DATE != "$today" ]]; then
    MY_S_DATE=$today
    MY_S_OK=0
    MY_S_FAIL=0
    MY_S_STREAK=0
    MY_S_BEST=0
  fi
}

function my/state-save {
  mkdir -p "$STATE_DIR" 2>/dev/null
  printf '%s %s %s %s %s %s %s\n' "$MY_S_DATE" "$MY_S_OK" "$MY_S_FAIL" "$MY_S_STREAK" "$MY_S_BEST" "$MY_TOTAL" "$MY_EVER" > "$STATE_FILE"
}

function my/calc-level {
  local i
  MY_LEVEL=0
  for i in 1 2 3; do
    ((MY_TOTAL >= MY_LEVEL_AT[i])) && MY_LEVEL=$i
  done
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
  local icon="$LINES_DIR/normal.png"
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
      echo "Tsundere mode is off. Type 'tsun on' to bring her back."
      ;;
    on)
      rm -f "$MUTE_FILE"
      my/mood normal
      printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_INFO" "Hmph, you needed me back already? F-Fine."
      ;;
    stats)
      my/state-load
      my/meter-load
      my/calc-level
      printf 'Today        %s ok, %s failed, best streak %s\n' "$MY_S_OK" "$MY_S_FAIL" "$MY_S_BEST"
      printf 'Record       best streak ever %s\n' "$MY_EVER"
      printf 'Mood         %s of %s (happy at %s)\n' "$MY_MOOD_METER" "$MY_MOOD_MAX" "$MY_MOOD_THRESHOLD"
      printf 'Affection    level %s (%s), %s points\n' "$MY_LEVEL" "${MY_LEVEL_NAMES[MY_LEVEL]}" "$MY_TOTAL"
      if ((MY_LEVEL < 3)); then
        printf 'Next level   at %s points\n' "${MY_LEVEL_AT[MY_LEVEL + 1]}"
      fi
      echo
      if ((MY_S_FAIL > MY_S_OK)); then my/pool insults; else my/pool praise; fi
      my/say-force "$REPLY" "$MY_C_INFO"
      ;;
    say)
      my/say-force "$PHRASES_FILE" "$MY_C_INFO"
      ;;
    reset)
      read -r -p "Reset mood, stats and affection? [y/N] " a
      if [[ $a == [yY]* ]]; then
        rm -f "$METER_FILE" "$STATE_FILE" "$SEEN_FILE"
        MY_MOOD_METER=0
        MY_TOTAL=0
        MY_LEVEL=0
        echo "...Fine. We start from zero, baka."
      fi
      ;;
    *)
      echo "Usage  tsun off | on | stats | say | reset"
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

if [[ ${BLE_VERSION-} ]]; then

  # Runs only when a real command is executed, so empty Enter is ignored
  function my/tsundere-preexec {
    MY_RAN=1
    MY_START=$SECONDS
    MY_CMD=$1
    [[ -e $MUTE_FILE ]] && return

    # Panic before dangerous commands
    case $1 in
      *"rm -rf"*|*"rm -fr"*|*"rm -r "*|*"git push"*" --force"*|*"git push"*" -f"*|*mkfs*|*"dd if="*|*"chmod -R 777"*)
        MY_DANGER=1
        my/say "$LINES_DIR/danger.txt" "$MY_C_WARN"
        my/mood surprised
        ;;
    esac
  }

  function my/tsundere-precmd {
    local status=$?

    # Nothing ran (first prompt or empty Enter)
    [[ $MY_RAN ]] || return
    MY_RAN=

    # Muted, keep the image hidden and do nothing else
    if [[ -e $MUTE_FILE ]]; then
      MY_DANGER=
      my/mood off
      return
    fi

    local dur=$((SECONDS - MY_START))
    local danger=$MY_DANGER
    MY_DANGER=
    local face=normal said= oldlevel now

    # Reload shared state so several terminals agree
    my/meter-load
    my/state-load
    my/calc-level
    oldlevel=$MY_LEVEL
    printf -v now '%(%s)T' -1
    printf '%s\n' "$now" > "$SEEN_FILE"

    if ((status != 0)); then
      ((MY_MOOD_METER -= MY_MOOD_PENALTY))
      ((MY_MOOD_METER < 0)) && MY_MOOD_METER=0
      ((MY_S_FAIL++))
      MY_S_STREAK=0
      ((MY_TOTAL > 0)) && ((MY_TOTAL--))

      # Status 127 already got an insult and a suggestion from the handler
      if ((status != 127)); then
        if ! my/react fail; then
          my/pool insults
          my/say "$REPLY" "$MY_C_ERR"
        fi
        if ((dur >= MY_NOTIFY_SECS)) && ! my/is-interactive; then
          my/notify "Command failed" "${MY_CMD%% *} failed after ${dur}s. $(shuf -n1 "$INSULTS_FILE" 2>/dev/null)"
        fi
      fi
      face=angry
    else
      ((MY_MOOD_METER++))
      ((MY_MOOD_METER > MY_MOOD_MAX)) && MY_MOOD_METER=$MY_MOOD_MAX
      ((MY_S_OK++))
      ((MY_S_STREAK++))
      ((MY_S_STREAK > MY_S_BEST)) && MY_S_BEST=$MY_S_STREAK
      ((MY_S_STREAK > MY_EVER)) && MY_EVER=$MY_S_STREAK
      ((MY_TOTAL++))
      my/calc-level

      # New affection level
      if ((MY_LEVEL > oldlevel)); then
        my/say "$LINES_DIR/levelup.txt" "$MY_C_PRAISE" && said=1
        face=happy
      fi

      if [[ $danger ]]; then
        # She survived the scary command
        face=surprised
      else
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
            my/say "$LINES_DIR/git-dirty.txt" "$MY_C_WARN" && said=1
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
            my/say "$LINES_DIR/night.txt" "$MY_C_INFO"
          fi
        fi
      fi
    fi

    # Break reminder after a long session
    if ((SECONDS - MY_LAST_BREAK >= MY_BREAK_SECS)); then
      my/say "$LINES_DIR/break.txt" "$MY_C_WARN"
      MY_LAST_BREAK=$SECONDS
    fi

    my/meter-save
    my/state-save
    my/mood "$face"
  }

  blehook PREEXEC+=my/tsundere-preexec
  blehook PRECMD+=my/tsundere-precmd

  # Startup, load state, greet or complain about the absence, set the face
  mkdir -p "$STATE_DIR" 2>/dev/null
  my/meter-load
  my/state-load
  my/calc-level
  if ((SHLVL <= 1)); then
    my/away-check || my/greet
  fi
  my/meter-load
  if ((MY_MOOD_METER >= MY_MOOD_THRESHOLD)); then my/mood happy; else my/mood normal; fi

fi
