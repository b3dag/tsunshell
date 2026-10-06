# Optional AI chat: `tsun ai` picks a provider, `tsun talk` talks to her for
# real instead of just picking a random line. Lives apart from tsundere.sh
# so that file stays small; loaded lazily the first time either subcommand
# runs (see the `ai|talk` case in tsundere.sh). Needs curl, and either an
# ANTHROPIC_API_KEY in your environment or a local Ollama server.

# Settings
MY_OLLAMA_HOST=${MY_OLLAMA_HOST:-http://localhost:11434}
AI_STATE_FILE="$STATE_DIR/ai"
MY_AI_PROVIDER=
MY_AI_MODEL=
ANTHROPIC_DEFAULT_MODEL=claude-haiku-4-5-20251001

# The affection economy around chat, fixed on purpose: not exposed to
# `tsun aisetup` or any other live control, since the entire point of the
# daily cap is that it can't be farmed, which a user-adjustable cap would
# defeat. Edit these two lines directly if you really want to change them.
MY_CHAT_BUMP=1          # affection points per exchange
MY_CHAT_BUMP_MAX=10     # cap on those points per day

# Tuning knobs, live-adjustable with `tsun aisetup` instead of editing this
# file, persisted as KEY=VALUE lines in $AI_LIMITS_FILE (not fixed columns
# like the older state files, so adding one later never shifts the rest).
# This table is the single source of truth for defaults, help text, and
# which variables `tsun aisetup` is willing to touch.
declare -gA AI_LIMIT_DEFAULTS=(
  [MY_AI_HISTORY_TURNS]=6
  [MY_AI_TIMEOUT]=20
  [MY_OLLAMA_TIMEOUT]=90
  [MY_AI_SEND_OUTPUT]=1
  [MY_AI_OUTPUT_LINES]=25
  [MY_AI_OUTPUT_CHARS]=1200
  [MY_OLLAMA_KEEPALIVE]=10m
  [MY_OLLAMA_NUM_PREDICT]=150
)
declare -gA AI_LIMIT_HELP=(
  [MY_AI_HISTORY_TURNS]="exchanges kept in context during an interactive chat"
  [MY_AI_TIMEOUT]="seconds before an Anthropic request gives up"
  [MY_OLLAMA_TIMEOUT]="seconds before an Ollama request gives up (cold model loads are slow)"
  [MY_AI_SEND_OUTPUT]="1 to send recent terminal output as context, 0 to stop"
  [MY_AI_OUTPUT_LINES]="scrollback lines pulled from WezTerm for context"
  [MY_AI_OUTPUT_CHARS]="cap on how much of that scrollback actually gets sent"
  [MY_OLLAMA_KEEPALIVE]="how long Ollama keeps the model loaded between messages"
  [MY_OLLAMA_NUM_PREDICT]="hard cap on Ollama's reply length, in tokens"
)

# Which provider each setting actually does anything for: "anthropic",
# "ollama", or "both". `tsun aisetup` only lists and accepts the ones that
# apply to whichever provider is currently active, so you never see or
# edit a knob that would silently have no effect.
declare -gA AI_LIMIT_SCOPE=(
  [MY_AI_HISTORY_TURNS]=both
  [MY_AI_TIMEOUT]=anthropic
  [MY_OLLAMA_TIMEOUT]=ollama
  [MY_AI_SEND_OUTPUT]=both
  [MY_AI_OUTPUT_LINES]=both
  [MY_AI_OUTPUT_CHARS]=both
  [MY_OLLAMA_KEEPALIVE]=ollama
  [MY_OLLAMA_NUM_PREDICT]=ollama
)

# True if $1 (a setting name) applies to the currently active provider
function my/ai-limit-in-scope {
  local scope=${AI_LIMIT_SCOPE[$1]}
  [[ $scope == both || $scope == "$MY_AI_PROVIDER" ]]
}

# Ollama model names, lowercase substring, that usually mean "uncensored
# chat model", checked in this order against whatever the user already has
# pulled. First match wins; see my/ai-ollama-autopick.
OLLAMA_UNCENSORED_HINTS=(uncensored abliterated dolphin wizard-vicuna-uncensored)

function my/ai-load {
  MY_AI_PROVIDER=
  MY_AI_MODEL=
  [[ -f $AI_STATE_FILE ]] && read -r MY_AI_PROVIDER MY_AI_MODEL < "$AI_STATE_FILE"
}

function my/ai-save {
  mkdir -p "$STATE_DIR" 2>/dev/null
  printf '%s %s\n' "$MY_AI_PROVIDER" "$MY_AI_MODEL" > "$AI_STATE_FILE"
}

# Tuning settings are saved per provider, not shared, since Anthropic
# (fast, hosted) and Ollama (local, as slow as your hardware) usually want
# different values for the same knob, e.g. how much terminal output to
# send. Result in REPLY. Falls back to a generic file if no provider is
# picked yet, there's just nothing meaningful to tune at that point.
function my/ai-limits-file {
  REPLY="$STATE_DIR/ai-limits-${MY_AI_PROVIDER:-default}"
}

# Sets every tuning variable to its default, then applies whatever is
# actually saved for the current provider on top
function my/ai-limits-load {
  local key
  for key in "${!AI_LIMIT_DEFAULTS[@]}"; do
    printf -v "$key" '%s' "${AI_LIMIT_DEFAULTS[$key]}"
  done
  my/ai-limits-file
  local file=$REPLY
  [[ -f $file ]] || return 0
  local value
  while IFS='=' read -r key value; do
    [[ $key && ${AI_LIMIT_DEFAULTS[$key]+_} ]] && printf -v "$key" '%s' "$value"
  done < "$file"
}

function my/ai-limits-save {
  mkdir -p "$STATE_DIR" 2>/dev/null
  my/ai-limits-file
  local file=$REPLY key
  : > "$file"
  for key in "${!AI_LIMIT_DEFAULTS[@]}"; do
    printf '%s=%s\n' "$key" "${!key}" >> "$file"
  done
}

# `tsun aisetup` with no args lists every tuning setting and its current
# value; `tsun aisetup <name> <value>` changes one; `tsun aisetup reset`
# puts them all back to default.
function my/ai-limits-config {
  local key=${1-} value=${2-}

  if [[ -z $MY_AI_PROVIDER ]]; then
    echo "No provider picked yet (tsun ai anthropic / tsun ai ollama), nothing to tune." >&2
    return 1
  fi

  if [[ -z $key ]]; then
    echo "AI tuning settings for $MY_AI_PROVIDER, saved separately per provider."
    echo "Change with: tsun aisetup <name> <value>   Reset with: tsun aisetup reset"
    echo
    local k
    for k in "${!AI_LIMIT_DEFAULTS[@]}"; do
      my/ai-limit-in-scope "$k" || continue
      printf '  %-22s %-8s %s\n' "$k" "${!k}" "${AI_LIMIT_HELP[$k]}"
    done | sort
    return
  fi

  if [[ $key == reset ]]; then
    local k
    for k in "${!AI_LIMIT_DEFAULTS[@]}"; do
      printf -v "$k" '%s' "${AI_LIMIT_DEFAULTS[$k]}"
    done
    my/ai-limits-file
    rm -f "$REPLY"
    echo "...Fine, back to default for $MY_AI_PROVIDER."
    return
  fi

  if [[ -z ${AI_LIMIT_DEFAULTS[$key]+_} ]]; then
    echo "Unknown setting: $key" >&2
    echo "Run 'tsun aisetup' with no arguments to see the list." >&2
    return 1
  fi
  if ! my/ai-limit-in-scope "$key"; then
    echo "$key belongs to ${AI_LIMIT_SCOPE[$key]}, not $MY_AI_PROVIDER. Switch with tsun ai first." >&2
    return 1
  fi
  if [[ -z $value ]]; then
    echo "Usage: tsun aisetup $key <value>" >&2
    return 1
  fi
  case $key in
    MY_OLLAMA_KEEPALIVE) ;; # free-form, e.g. 10m, 1h, -1 (keep forever)
    MY_AI_SEND_OUTPUT)
      [[ $value =~ ^[01]$ ]] || { echo "Must be 0 or 1" >&2; return 1; }
      ;;
    *)
      [[ $value =~ ^[0-9]+$ ]] || { echo "Must be a whole number" >&2; return 1; }
      ;;
  esac

  printf -v "$key" '%s' "$value"
  my/ai-limits-save
  echo "$key = $value"
}

# Picks a model already pulled in the local Ollama, preferring one that
# looks uncensored over a stock one, otherwise just the first one there is.
# Never pulls anything itself. Result in REPLY, returns 1 if none found.
function my/ai-ollama-autopick {
  REPLY=
  local json hint n
  local -a names=()
  json=$(curl -s --max-time 5 "$MY_OLLAMA_HOST/api/tags" 2>/dev/null)
  [[ $json ]] || return 1
  mapfile -t names < <(printf '%s' "$json" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    raise SystemExit
for m in data.get("models", []):
    n = m.get("name") or m.get("model")
    if n:
        print(n)
' 2>/dev/null)
  ((${#names[@]})) || return 1
  for hint in "${OLLAMA_UNCENSORED_HINTS[@]}"; do
    for n in "${names[@]}"; do
      [[ ${n,,} == *"$hint"* ]] && { REPLY=$n; return 0; }
    done
  done
  REPLY=${names[0]}
}

function my/ai-config {
  case ${1-} in
    ""|status)
      if [[ -z $MY_AI_PROVIDER ]]; then
        echo "AI chat  off"
      else
        echo "AI chat  $MY_AI_PROVIDER ($MY_AI_MODEL)"
      fi
      echo "Usage    tsun ai [off | anthropic [model] | ollama [model]]"
      ;;
    off)
      MY_AI_PROVIDER=
      MY_AI_MODEL=
      my/ai-save
      my/ai-limits-load
      echo "Hmph, fine. I won't talk through that thing anymore."
      ;;
    anthropic)
      if ! command -v curl >/dev/null 2>&1; then
        echo "Needs curl, which isn't installed." >&2
        return 1
      fi
      MY_AI_PROVIDER=anthropic
      MY_AI_MODEL=${2:-$ANTHROPIC_DEFAULT_MODEL}
      my/ai-save
      my/ai-limits-load
      [[ -z ${ANTHROPIC_API_KEY-} ]] &&
        echo "Set ANTHROPIC_API_KEY in your .bashrc before you talk to me, baka." >&2
      echo "AI chat  anthropic ($MY_AI_MODEL)"
      ;;
    ollama)
      if ! command -v curl >/dev/null 2>&1; then
        echo "Needs curl, which isn't installed." >&2
        return 1
      fi
      local model=${2-}
      if [[ -z $model ]]; then
        if my/ai-ollama-autopick; then
          model=$REPLY
        else
          echo "No local Ollama models found at $MY_OLLAMA_HOST." >&2
          echo "Pull one first, for example: ollama pull dolphin-mistral (or llama3.2)" >&2
          return 1
        fi
      fi
      MY_AI_PROVIDER=ollama
      MY_AI_MODEL=$model
      my/ai-save
      my/ai-limits-load
      echo "AI chat  ollama ($MY_AI_MODEL)"
      ;;
    *)
      echo "Usage  tsun ai [off | anthropic [model] | ollama [model]]" >&2
      ;;
  esac
}

# Recent terminal output, straight from WezTerm's own scrollback via
# `wezterm cli get-text`, not from redirecting any file descriptor, so it
# never touches isatty() for anything you run (color detection, pagers,
# vim/less all stay exactly as they were). Only available inside WezTerm,
# and only if MY_AI_SEND_OUTPUT is still 1. Result in REPLY, capped to
# MY_AI_OUTPUT_CHARS, or returns 1 if there's nothing to offer.
function my/ai-recent-output {
  REPLY=
  ((MY_AI_SEND_OUTPUT)) || return 1
  [[ $TERM_PROGRAM == WezTerm && -n ${WEZTERM_PANE-} ]] || return 1
  command -v wezterm >/dev/null 2>&1 || return 1
  local text
  text=$(wezterm cli get-text --start-line "-$MY_AI_OUTPUT_LINES" 2>/dev/null) || return 1
  [[ $text ]] || return 1
  REPLY=$(printf '%s' "$text" | tail -c "$MY_AI_OUTPUT_CHARS")
}

# Builds her system prompt from live session context, result in REPLY
function my/ai-system-prompt {
  local laststatus=succeeded
  ((MY_FAIL_STREAK > 0)) && laststatus=failed
  REPLY="You are Shion, a tsundere terminal companion character. Stay fully
in character: blunt and a little rude on the surface, secretly caring,
stammering a bit ('I-It's not like...') when you're actually being nice.
Keep replies to 1-3 short sentences, plain text only, no markdown, no code
fences, this is printed straight into a terminal. Always write at least
one short sentence of actual reply before the mood tag, even for a rude
or one-word message, never answer with only the tag and nothing else.

Context you can react to, don't just repeat it back: working directory
$PWD, affection level \"${MY_LEVEL_NAMES[MY_LEVEL]}\", today $MY_S_OK
commands succeeded and $MY_S_FAIL failed, the last command was
\"${MY_CMD:-nothing yet}\" and it $laststatus."

  local prompt=$REPLY
  if my/ai-recent-output; then
    prompt="$prompt

Recent terminal output, for debugging context if asked about an error or a
command's result. It's raw scrollback, so it may include older commands
too, use judgement about what's actually relevant to the latest one:
---
$REPLY
---"
  fi
  REPLY=$prompt

  REPLY="$REPLY

End every reply with its own line, exactly: [mood: X] with nothing else on
that line, where X is one of normal, angry, happy, surprised, sleepy,
scared, fedup, worried, disgusted, whichever best fits your reply's tone."
}

# $1 is the new user message, the rest are prior turns (user, assistant,
# user, assistant, ...). Reply text goes in REPLY. Returns 1 on any failure
# (no provider, no key, network error, bad response), REPLY then unset.
function my/ai-request {
  local message=$1
  shift
  local -a turns=("$@")
  REPLY=

  [[ $MY_AI_PROVIDER ]] || return 1
  [[ $MY_AI_PROVIDER == anthropic && -z ${ANTHROPIC_API_KEY-} ]] && return 1

  local system
  my/ai-system-prompt
  system=$REPLY

  local body
  body=$(MY_AI_SYSTEM="$system" MY_AI_PROVIDER="$MY_AI_PROVIDER" MY_AI_MODEL="$MY_AI_MODEL" \
    MY_OLLAMA_KEEPALIVE="$MY_OLLAMA_KEEPALIVE" MY_OLLAMA_NUM_PREDICT="$MY_OLLAMA_NUM_PREDICT" \
    python3 -c '
import json, os, sys
provider = os.environ["MY_AI_PROVIDER"]
system = os.environ["MY_AI_SYSTEM"]
model = os.environ["MY_AI_MODEL"]
message = sys.argv[1]
turns = sys.argv[2:]
messages = []
role = "user"
for t in turns:
    messages.append({"role": role, "content": t})
    role = "assistant" if role == "user" else "user"
messages.append({"role": "user", "content": message})
if provider == "anthropic":
    out = {"model": model, "max_tokens": 300, "system": system, "messages": messages}
else:
    out = {
        "model": model,
        "messages": [{"role": "system", "content": system}] + messages,
        "stream": False,
        "keep_alive": os.environ["MY_OLLAMA_KEEPALIVE"],
        "options": {"num_predict": int(os.environ["MY_OLLAMA_NUM_PREDICT"])},
    }
print(json.dumps(out))
' "$message" "${turns[@]}") || return 1

  local resp rc errfile
  errfile=$(mktemp)
  if [[ $MY_AI_PROVIDER == anthropic ]]; then
    resp=$(curl -sS --max-time "$MY_AI_TIMEOUT" -w '\n%{http_code}' \
      https://api.anthropic.com/v1/messages \
      -H "x-api-key: $ANTHROPIC_API_KEY" \
      -H "anthropic-version: 2023-06-01" \
      -H "content-type: application/json" \
      -d "$body" 2>"$errfile")
    rc=$?
  else
    resp=$(curl -sS --max-time "$MY_OLLAMA_TIMEOUT" -w '\n%{http_code}' \
      "$MY_OLLAMA_HOST/api/chat" \
      -H "content-type: application/json" \
      -d "$body" 2>"$errfile")
    rc=$?
  fi
  if ((rc != 0)); then
    echo "AI request failed: curl error $rc: $(cat "$errfile")" >&2
    rm -f "$errfile"
    return 1
  fi
  rm -f "$errfile"

  local http_code=${resp##*$'\n'}
  resp=${resp%$'\n'*}
  if [[ $http_code != 2* ]]; then
    echo "AI request failed ($http_code): $resp" >&2
    return 1
  fi

  REPLY=$(MY_AI_PROVIDER="$MY_AI_PROVIDER" python3 -c '
import json, os, sys
provider = os.environ["MY_AI_PROVIDER"]
try:
    data = json.load(sys.stdin)
    if provider == "anthropic":
        print(data["content"][0]["text"])
    else:
        print(data["message"]["content"])
except Exception:
    sys.exit(1)
' <<< "$resp")
  [[ $? -eq 0 && $REPLY ]] || return 1
}

# Prints $1 with its "[mood: X]" tag stripped, wherever in the text it
# actually landed (models don't reliably put it only at the end, despite
# being asked to), then applies that mood to her picture if it is one we
# actually have art for. Defaults to normal, never trusts the model with a
# raw filename.
function my/ai-say {
  local text=$1 mood cleaned parsed
  parsed=$(python3 -c '
import re, sys
MOODS = {"normal", "angry", "happy", "surprised", "sleepy", "scared", "fedup", "worried", "disgusted"}
text = sys.stdin.read()
m = re.search(r"\[\s*mood\s*:\s*([a-zA-Z]+)\s*\]", text, re.IGNORECASE)
if not m:
    # Smaller models do not always follow the exact "[mood: X]" format, so
    # also accept a bare "[X]", but only when X is actually one of ours --
    # never strip an unrelated bracketed word out of a real reply.
    for cand in re.finditer(r"\[\s*([a-zA-Z]+)\s*\]", text):
        if cand.group(1).lower() in MOODS:
            m = cand
            break
mood = m.group(1).lower() if m else ""
cleaned = text[:m.start()] + text[m.end():] if m else text
cleaned = re.sub(r"[ \t]+", " ", cleaned)
print(mood)
print(cleaned.strip())
' <<< "$text")
  mood=$(head -n1 <<< "$parsed")
  cleaned=$(tail -n +2 <<< "$parsed")
  case $mood in
    normal|angry|happy|surprised|sleepy|scared|fedup|worried|disgusted) ;;
    *) mood=normal ;;
  esac
  # A reply that was only ever the mood tag, nothing else, still counts as
  # a response, but printing a blank line looks broken, not quiet
  if [[ -z $cleaned ]]; then
    my/say-force "$LINES_DIR/ai-error.txt" "$MY_C_WARN" ||
      echo "Hmph, I couldn't reach anyone just now. Try again later."
    my/mood "$mood"
    return
  fi
  printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_INFO" "$cleaned"
  my/mood "$mood"
}

# A small, capped affection nudge for actually talking to her, separate
# from the pass/fail mood meter every other command drives
function my/chat-bump {
  my/state-load
  if ((MY_CHAT_TODAY < MY_CHAT_BUMP_MAX)); then
    local oldlevel=$MY_LEVEL
    MY_TOTAL=$((MY_TOTAL + MY_CHAT_BUMP))
    MY_CHAT_TODAY=$((MY_CHAT_TODAY + 1))
    my/calc-level
    if ((MY_LEVEL > oldlevel)); then
      my/pool levelup
      my/say "$REPLY" "$MY_C_PRAISE"
    fi
    my/state-save
  fi
}

function my/ai-talk {
  if [[ -z $MY_AI_PROVIDER ]]; then
    my/say-force "$LINES_DIR/ai-off.txt" "$MY_C_INFO" ||
      printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_INFO" "I-I've got nobody to talk through right now."
    echo "Set it up with: tsun ai anthropic   or   tsun ai ollama" >&2
    return 1
  fi
  if ! command -v curl >/dev/null 2>&1; then
    echo "Needs curl, which isn't installed." >&2
    return 1
  fi

  if (($#)); then
    if my/ai-request "$*"; then
      my/ai-say "$REPLY"
      my/chat-bump
    else
      my/say-force "$LINES_DIR/ai-error.txt" "$MY_C_WARN" ||
        echo "Hmph, I couldn't reach anyone just now. Try again later."
    fi
    return
  fi

  local -a turns=()
  local msg
  while true; do
    if ! read -e -r -p "You> " msg; then
      echo
      break
    fi
    [[ $msg ]] || continue
    case ${msg,,} in
      /bye|/exit|/quit) break ;;
    esac
    if my/ai-request "$msg" "${turns[@]}"; then
      my/ai-say "$REPLY"
      turns+=("$msg" "$REPLY")
      local maxlen=$((MY_AI_HISTORY_TURNS * 2))
      ((${#turns[@]} > maxlen)) && turns=("${turns[@]: -maxlen}")
      my/chat-bump
    else
      my/say-force "$LINES_DIR/ai-error.txt" "$MY_C_WARN" ||
        echo "Hmph, I couldn't reach anyone just now. Try again later."
    fi
  done
  my/say-force "$LINES_DIR/ai-bye.txt" "$MY_C_INFO" ||
    printf '\033[1;38;2;%sm%s\033[0m\n' "$MY_C_INFO" "H-Hmph. Go on then. I wasn't enjoying this anyway."
}

function my/ai-dispatch {
  case ${1-} in
    ai) shift; my/ai-config "$@" ;;
    talk) shift; my/ai-talk "$@" ;;
    aisetup) shift; my/ai-limits-config "$@" ;;
  esac
}

my/ai-load
my/ai-limits-load
