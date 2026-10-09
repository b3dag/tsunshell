#!/usr/bin/env bash
# Exercises every reaction category tsundere.sh has, one at a time, inside
# a disposable sandbox - never touches your real ~/.config/tsundere or
# ~/.cache/tsundere. Safe to run any time, as many times as you like.
#
# Plain bash has no preexec/precmd hook of its own (see docs/SETUP.md,
# Part 3) - every reaction below actually fires from `my/tsundere-precmd`,
# normally driven automatically by PROMPT_COMMAND between prompts on a
# real interactive terminal. A script has no such prompt loop to drive
# that automatically, so this instead drives the exact same function by
# hand after each test command: run it for real, record it in `history`
# the same way a real prompt would, restore its exit status, then call
# `my/tsundere-precmd` directly. Functionally identical to what typing the
# command at a real prompt and pressing Enter does.
#
# A few categories (battery/disk/load, bedtime nag, the morning/afternoon/
# evening/night greeting) depend on real hardware state or the actual
# wall-clock hour and can't be forced deterministically from a script;
# those are shown by calling the line-picking function directly instead,
# clearly marked below, rather than through the real trigger path.
#
# Run this from inside WezTerm to also watch her picture change through
# every section live.
#
# Usage: bash scripts/test-reactions.sh [--keep]
#   --keep   don't delete the sandbox afterwards, print its path instead
set -o pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SBOX=$(mktemp -d "${TMPDIR:-/tmp}/tsundere-test.XXXXXX")
KEEP=0
[[ ${1-} == --keep ]] && KEEP=1

cleanup() {
  if ((KEEP)); then
    echo
    echo "Sandbox kept at $SBOX"
  else
    command rm -rf "$SBOX" 2>/dev/null
  fi
}
trap cleanup EXIT

mkdir -p "$SBOX/.config/tsundere" "$SBOX/.cache/tsundere" "$SBOX/repo" "$SBOX/bin"
cp -r "$HERE"/lines/* "$SBOX/.config/tsundere/"
cp "$HERE/shell/tsundere.sh" "$SBOX/.config/tsundere/tsundere.sh"
cp "$HERE/shell/ai.sh" "$SBOX/.config/tsundere/ai.sh"
[[ -d "$HERE/images/sprites" ]] && ln -s "$HERE/images/sprites" "$SBOX/.config/tsundere/sprites"
sed -i 's/^MY_NOTIFY=1/MY_NOTIFY=0 # no real desktop popups for this test/' "$SBOX/.config/tsundere/tsundere.sh"

# Fake binaries for the jealousy-gate commands, so the gate has something
# real to approve into without needing claude/gemini/etc actually installed
cat > "$SBOX/bin/claude" <<'BIN'
#!/bin/sh
exit 0
BIN
cp "$SBOX/bin/claude" "$SBOX/bin/gemini"
chmod +x "$SBOX/bin/claude" "$SBOX/bin/gemini"

export HOME="$SBOX"
export PATH="$SBOX/bin:$PATH"
cd "$SBOX/repo"
git init -q
git config user.email "test@test"
git config user.name "tsun test"
git commit -q --allow-empty -m init

HISTTIMEFORMAT='%s '
HISTCONTROL=${HISTCONTROL-}
PROMPT_COMMAND=${PROMPT_COMMAND-}
# Driven by hand below (see header), auto-recording would only get in the
# way - every test calls `history -s` itself at exactly the right moment
set +o history

source "$SBOX/.config/tsundere/tsundere.sh"

# A fresh shell's first call to precmd only learns where history currently
# stands and returns (see the comment in my/tsundere-precmd) - get that
# out of the way once, same as a real first prompt would, before any of
# the real tests below.
my/tsundere-precmd

n=0
section() {
  ((n++))
  echo
  printf '\033[1m[%02d] %s\033[0m\n' "$n" "$1"
}

note() {
  printf '    (%s)\n' "$1"
}

# Runs $1 for real, feeding it $2 as stdin if given (for a gate's [y/N]
# prompt - empty for anything else), records it in history the way a real
# prompt would, restores its real exit status, then drives precmd by hand.
run() {
  local cmd=$1 input=${2-}
  printf '    $ %s\n' "$cmd"
  if [[ -n $input ]]; then
    printf '%s\n' "$input" | eval "$cmd"
  else
    eval "$cmd"
  fi
  local status=$?
  history -s "$cmd"
  (exit "$status")
  my/tsundere-precmd
}

# Directly calls a line-picking function, for categories that can't be
# forced through their real trigger condition from a script (see header)
show() {
  "$@"
}

echo "Sandbox: $SBOX"
echo "(TERM_PROGRAM=${TERM_PROGRAM:-unset} - her picture only actually updates inside WezTerm)"

section "Generic phrase, nothing more specific matched (lines/phrases/)"
run "true"

section "Insult on a plain failure (lines/insults/)"
run "(exit 1)"

section "Mistyped command: insult + \"did you mean\" (command_not_found_handle, lines/typo/)"
run "gitt status"

section "Specific exit code, checked before the generic insult (lines/exitcodes/)"
note "130 below is Ctrl-C's exit code, simulated without a real SIGINT"
run "(exit 130)"

section "3 failures in a row: fedup face instead of angry (no new line, just the face)"
run "(exit 2)"
run "(exit 3)"
run "(exit 4)"

section "Command-specific reaction from lines/reactions/ (cat matches a pattern there)"
run "cat /etc/hostname"

section "Danger gate: declining rm -rf (lines/danger-gate/, lines/danger-gate-no/)"
mkdir -p keep_this_dir
run "rm -rf keep_this_dir" "n"
note "declined, so keep_this_dir should still exist: $([[ -d keep_this_dir ]] && echo yes || echo NO)"

section "Danger gate: approving rm -rf (lines/danger-gate/, lines/danger-gate-yes/)"
mkdir -p delete_this_dir
run "rm -rf delete_this_dir" "y"
note "approved, so delete_this_dir should be gone: $([[ -d delete_this_dir ]] && echo STILL_THERE || echo yes)"

section "Jealousy gate: declining another AI's CLI (lines/jealous-gate/, lines/jealous-gate-no/)"
run "claude --help" "n"

section "Jealousy gate: approving another AI's CLI (lines/jealous-gate/, lines/jealous-gate-yes/)"
run "gemini --version" "y"
note "the generic reactions/ claude*/gemini* lines are deliberately skipped here, the gate already said her piece - see my/react"

section "git status, tree heavily dirty: the shared git-dirty nag (lines/git-dirty/)"
for i in $(seq 1 12); do touch "messy$i.txt"; done
run "git status # heavily-dirty"

section "git status, a few changes but below the nag threshold (lines/git-status-dirty/)"
command rm -f messy{3..12}.txt
run "git status # lightly-dirty"

section "git status, clean tree (lines/git-status-clean/)"
git add -A >/dev/null 2>&1
git commit -q -m "clean up for the test"
run "git status # clean"

section "git commit leaving a clean tree (lines/git-clean/)"
run "git commit --allow-empty -m 'another one'"

echo
echo "Forcing the probabilistic/threshold categories one at a time below -"
echo "each one's chance is set to always-fire just for its own test, then"
echo "put back, so they don't compete with each other for the same command."

section "Streak milestone (lines/streak/), forced to the first one in MY_STREAK_MILESTONES"
MY_S_STREAK=$((${MY_STREAK_MILESTONES[0]} - 1))
my/state-save
run "true # streak"

section "Rare sweet line (lines/rare/), chance forced to 1-in-1"
MY_RARE_CHANCE=1
run "true # rare"
MY_RARE_CHANCE=100

section "Specific remembered moment brought back up (lines/memory/), chance forced to 1-in-1"
note "needs an existing memory - the streak milestone above already added one"
MY_MEMORY_CHANCE=1
run "true # memory"
MY_MEMORY_CHANCE=150

section "Slow command finished (lines/slow/), threshold forced to 0 seconds"
MY_SLOW_SECS=0
run "true # slow"
MY_SLOW_SECS=30

section "Praise while her mood meter is maxed out (lines/praise/)"
MY_MOOD_METER=$((MY_MOOD_THRESHOLD - 1))
my/meter-save
run "true # praise"

section "Leveling up (lines/levelup/), affection forced to just below the level 1 threshold"
MY_TOTAL=$((MY_LEVEL_AT[1] - 1))
my/state-save
run "true # levelup"

section "Exact repeat of a command that just succeeded: no extra credit (lines/repeat/)"
run "true # repeat-ok"
run "true # repeat-ok"

section "Exact repeat of a command that just failed: no extra penalty (lines/repeat-fail/)"
run "(exit 5) # repeat-fail"
run "(exit 5) # repeat-fail"

section "Exact repeat of a mistyped command (lines/repeat-fail/, via command_not_found_handle)"
run "notarealcommandxyz"
run "notarealcommandxyz"

section "Break reminder after a long session (lines/break/), forced to fire immediately"
MY_BREAK_SECS=0
MY_LAST_BREAK=0
run "true # break"
MY_BREAK_SECS=7200

section "Pet name worked into a line, once affection is high enough (tsun name)"
MY_PET_NAME=testname
MY_NAME_CHANCE=1
MY_TOTAL=${MY_LEVEL_AT[MY_NAME_LEVEL]}
my/state-save
run "true # name"
MY_NAME_CHANCE=4

section "Away complaint after not being seen for a long time (lines/away/)"
note "normally checked once per terminal at startup, called directly here"
echo "100000000" > "$STATE_DIR/lastseen"
show my/away-check

section "Greeting by time of day (lines/morning/, afternoon/, evening/, night/)"
note "picks the real category for whatever hour it actually is right now"
show my/greet

section "Bedtime nag (lines/night/)"
note "only actually fires between 23:00 and 05:00 - shown directly here regardless of the real hour"
my/pool night
my/say "$REPLY" "$MY_C_WARN"

section "Ambient comment on the machine itself, not the command"
note "battery/disk/load each depend on real hardware state crossing a threshold - shown directly here"
my/pool battery; my/say "$REPLY" "$MY_C_WARN"
my/pool disk; my/say "$REPLY" "$MY_C_WARN"
my/pool load; my/say "$REPLY" "$MY_C_WARN"

echo
echo "tsun subcommands (each prints its own feedback directly, none of"
echo "these go through my/tsundere-precmd or touch mood/stats/streak):"

section "tsun off / tsun on (lines/tsun-off/, lines/tsun-on/)"
tsun off
tsun on

section "tsun say (lines/phrases/, same pool as the generic fallback)"
tsun say

section "tsun outfit (lines/tsun-outfit/)"
tsun outfit
first_outfit=$(my/outfits-list | sort | head -n1)
if [[ -n $first_outfit ]]; then
  tsun outfit "$first_outfit"
else
  note "no sprite outfits found, skipped (images/sprites/ not present in this repo checkout?)"
fi

section "tsun crop (lines/tsun-crop/)"
tsun crop bust

section "tsun size (lines/tsun-size/)"
tsun size bigger

section "tsun name (lines/tsun-name/)"
tsun name buddy

section "tsun stats"
tsun stats

section "tsun memories"
tsun memories

section "tsun doctor"
note "expect exactly one 'bad': history is deliberately off in this harness (see header) - that's this script, not a real problem"
tsun doctor

section "tsun reset (answers y to its own confirmation prompt)"
printf 'y\n' | tsun reset

echo
printf '\033[1mDone. %d sections.\033[0m\n' "$n"
echo "Not covered: tsun ai / tsun talk (needs a real Anthropic key or a running Ollama server - see docs/SETUP.md Part 9)."
