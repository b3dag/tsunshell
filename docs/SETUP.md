# Tsundere Terminal Setup Manual

A complete guide to a tsundere shell, plain bash plus optionally **WezTerm** for the character image.

> If you use `install.sh` from this repo, the files in parts 2, 3 and 5 are installed for you. Part 1 (installing WezTerm) and the one `.bashrc` line in part 4 are still up to you. The rest of this guide explains what each piece does.

## What you get

| Feature | Where it lives |
|---|---|
| Generic phrase after a command that triggered nothing more specific | `~/.config/tsundere/tsundere.sh` |
| Random insult when a command fails | `~/.config/tsundere/tsundere.sh` |
| Insult and "did you mean" suggestion on mistyped commands | `~/.config/tsundere/tsundere.sh` |
| Happy meter (+1 success, -3 failure, happy at 10) | `~/.config/tsundere/tsundere.sh` |
| Affection levels that make her nicer over time | `~/.config/tsundere/tsundere.sh` |
| Panic before dangerous commands (rm -rf, force push and more) | `~/.config/tsundere/tsundere.sh` |
| Reactions to specific commands (sudo, ping, ssh, git and more) | `reactions.txt` |
| Reactions to specific exit codes (Ctrl-C, OOM kill, segfault, timeout...) | `exitcodes.txt` |
| Streak milestone callout (5, 10, 25, 50 in a row...) | `streak.txt` |
| Greeting by time of day and bedtime nags at night | `~/.config/tsundere/tsundere.sh` |
| "Finally done" line after slow commands | `~/.config/tsundere/tsundere.sh` |
| Git reactions (messy tree, clean tree after push) | `~/.config/tsundere/tsundere.sh` |
| Break reminder after long sessions | `~/.config/tsundere/tsundere.sh` |
| "Where were you?" after a day away | `~/.config/tsundere/tsundere.sh` |
| Rare sweet lines | `~/.config/tsundere/tsundere.sh` |
| Desktop notification after long commands | `~/.config/tsundere/tsundere.sh` |
| `tsun` command for stats, mute, outfit, crop and reset | `~/.config/tsundere/tsundere.sh` |
| Mood, stats and affection saved across terminals and reboots | `~/.cache/tsundere/` |
| Anime girl bottom right, sleepy mode and mute | WezTerm |
| Four bundled outfits, each with a full expression set at three crop levels, switchable live with `tsun outfit` / `tsun crop`, plus `tsun size` to change how big she is | `images/sprites/` |

Phrases live in plain text files, so you can add lines any time without touching any code.

## File overview

| File | Purpose |
|---|---|
| `~/.config/tsundere/phrases.txt` | The generic fallback line after a quiet command, and `tsun say` |
| `~/.config/tsundere/insults.txt` | Insults for errors (affection level 0 and 1) |
| `~/.config/tsundere/praise.txt` | Nice words while she is happy (level 0) |
| `~/.config/tsundere/*.txt` | All the other lines (danger, morning, afternoon, evening, night, slow, git, typo, break, away, rare, streak, levelup and levelup-1 to 4, praise-1 to 4, insults-2 to 4, reactions, exitcodes, and tsun-off/on/outfit/crop/size for the tsun command's own feedback) |
| `~/.config/tsundere/sprites/<outfit>/<crop>/*.png` | The bundled (or your own) outfit sets, picked with `tsun outfit` / `tsun crop` |
| `~/.config/tsundere/sprites/ratios.txt` | Each outfit/crop's actual pixel size, written automatically by `scripts/sprites.sh` |
| `~/.config/tsundere/tsundere.sh` | All the shell logic, loaded like bash_aliases |
| `~/.bashrc` | Loads everything in the right order |
| `~/.config/wezterm/wezterm.lua` | WezTerm config and image swapping |
| `~/.cache/tsundere/` | Saved happy meter, stats, lifetime totals, affection points, first-seen date, last seen time, chosen outfit and crop, and the mute flag |

---

## Part 1. Install everything

### 1.1 Install WezTerm

Pick the method that matches your distro.

**Debian or Ubuntu (apt repo)**

```bash
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg
sudo apt update
sudo apt install wezterm
```

**Arch**

```bash
sudo pacman -S wezterm
```

**Fedora**

```bash
sudo dnf copr enable wezfurlong/wezterm-nightly
sudo dnf install wezterm
```

**Any distro (Flatpak)**

```bash
flatpak install flathub org.wezfurlong.wezterm
```

The Flatpak is sandboxed, so file access can be restricted. If the girl images do not load, use one of the native packages above.

Check with `wezterm --version`, then launch WezTerm from your app menu.

### 1.2 Other requirements

* **bash** as your login shell. Check with `echo $SHELL`, and if needed run `chsh -s /bin/bash` and log in again.
* **python3** for the "did you mean" suggestions (almost always installed).
* **shuf** from coreutils (part of every normal Linux system).
* **notify-send** for desktop notifications (optional, see Part 6).
* A truecolor terminal. Check that `echo $COLORTERM` says `truecolor` or `24bit`.
* **ImageMagick** (`convert` and `identify`), only if you want to crop your own sprite pack with `scripts/sprites.sh`. Not needed to use the bundled outfits, those are already cropped.
* **curl**, only if you turn on `tsun talk` (see Part 9). Not needed for anything else.

---
## Part 2. Phrase files

Every default line lives in its own plain text file under `lines/` in this repo (`lines/phrases.txt`, `lines/danger.txt`, `lines/reactions.txt`, and so on), one file per mood or reaction. `scripts/lines.sh` copies whichever ones are missing into `~/.config/tsundere/`.

```bash
./scripts/lines.sh
```

It only creates files that do not exist yet, so you can run it again after an update and your own additions stay untouched. Any file you delete is created again with the default lines. To add a brand new phrase file, drop a new `lines/<name>.txt` in the repo, nothing else to register, the next run of `scripts/lines.sh` picks it up. The script itself is short, see [`scripts/lines.sh`](../scripts/lines.sh) in this repo rather than a copy pasted in here, so this guide can't go stale against it.

To add more lines of any kind later, just append to the files. In `typo.txt`, every `%s` is replaced by the suggested command.

`reactions.txt` has one reaction per line in the form `pattern|when|message`.

| Part | Meaning |
|---|---|
| `pattern` | A glob matched against the whole command line, for example `sudo *` or `*apt upgrade*` |
| `when` | `ok` after success, `fail` after failure, `any` for both |
| `message` | What she says. If several lines match, one is picked at random |

Lines that start with `#` are comments.

---
## Part 3. The shell file

This is the whole brain of the setup, installed as `~/.config/tsundere/tsundere.sh`. It's long enough that keeping a copy here would only go stale, so read it straight from the repo: [`shell/tsundere.sh`](../shell/tsundere.sh). The settings sit at the top, see Part 6 for what they do.

[`shell/ai.sh`](../shell/ai.sh) is a separate file, installed alongside it as `~/.config/tsundere/ai.sh`, holding everything behind `tsun ai` and `tsun talk` (Part 9). It's only ever loaded the first time you actually run one of those, so it costs nothing in a normal terminal that never uses it.

---

## Part 4. Load order in .bashrc

Add this line anywhere in `~/.bashrc` (the end is fine).

```bash
[[ -f ~/.config/tsundere/tsundere.sh ]] && source ~/.config/tsundere/tsundere.sh
```

No particular order needed, no other tool to source first. If you still have older `source ble.sh` or `starship init` lines from a previous setup, remove them, neither is required anymore. Then run `source ~/.bashrc`.

---

## Part 5. WezTerm config with the changing girl

### 5.1 Images

There is no flat 5-PNG mode anymore, every outfit is a full expression set under `~/.config/tsundere/sprites/<outfit>/<crop>/`. `images/sprites/` ships four already-cropped outfits (`casual`, `schoolsummer`, `schoolwinter`, `sundress`), each at three crop levels (`full`, `waist`, `bust`). `install.sh` copies the whole tree to `~/.config/tsundere/sprites/` for you, no ImageMagick or any other tool needed to use them. Pick one live, from any shell:

```
tsun outfit schoolwinter
tsun crop bust
tsun size bigger
```

Run `tsun outfit` or `tsun crop` with no argument to list what is available and what is currently selected, this is a live scan of the `sprites/` folder, nothing hardcoded, so a new outfit folder is picked up the moment it exists. The choice is saved to `~/.cache/tsundere/outfit` and `~/.cache/tsundere/crop`, applies to every open WezTerm window within a second (no restart), and survives restarts. There is always some outfit selected; if you have never run `tsun outfit`, the shell picks whichever one sorts first.

When she is muted with `tsun off`, no image is shown at all, so nothing extra is needed for that. The very first instant a WezTerm window opens, before the shell has sent its first mood, the background is deliberately blank rather than showing any particular outfit, so nothing wrong flashes on screen for that one frame.

Crop and size are deliberately separate: crop picks how much of her is in frame (her whole body vs. just her face), size is how big that framed image is drawn, as a percent of the window height (`~/.cache/tsundere/size`, default 30, range 10-60). They interact though, since the display box is always that same percentage of the window regardless of crop: switching from `bust` to `full` crop squeezes her whole body into the same box a tight headshot used to fill, so everything in it looks smaller even though "more of her" is now visible. `tsun size bigger` (or `smaller`, `reset`, or a number) compensates, 5 points a step.

#### Building your own outfit from a different sprite pack

If you have a different character art pack with many expressions, for example a visual novel style sprite sheet set with one full-body image per expression per outfit, all the same canvas size and named `prefix_outfit_expression.png`, run `scripts/sprites.sh` on the folder of raw images the same way the bundled outfits were made.

```bash
./scripts/sprites.sh ~/path/to/the/raw/pngs
```

For each outfit found, it auto-trims one reference expression (`--ref`, default `normal`) to find where the art actually starts, then applies that exact same crop box to every expression in that outfit, so nothing jumps position or size when her face changes. By default it generates all three crop levels (`full`, `waist`, `bust`) in one pass; pass `--show waist` (or a comma list) to only generate specific ones. `--width` controls the output pixel width (default 400), and `--dest` the output location (default `~/.config/tsundere/sprites`, point it at `images/sprites` in this repo to bundle a new outfit the same way).

It also writes `sprites/ratios.txt`, one `outfit/crop width height` line per combination, merging in with whatever was already there so cropping just one new outfit never drops the others. `wezterm/wezterm.lua` reads this file to know her aspect ratio, so a new outfit never needs any hardcoded table edited by hand, just a WezTerm config reload (Ctrl+Shift+R) to pick up the new file. `tsun outfit` likewise just scans the `sprites/` folder for subdirectories, so the new outfit shows up there immediately, no restart needed on the shell side.

Sprite packs rarely have an exact drawing for every mood; check the `MOOD_FILE` table near the top of `wezterm/wezterm.lua`, it maps her nine moods (`normal`, `angry`, `happy`, `surprised`, `sleepy`, `scared`, `fedup`, `worried`, `disgusted`) to filenames in a set, pick the closest fit for any that are missing, it is just a lookup table. The `TALK_FILE` table right below it is optional, an open-mouth variant shown for a couple seconds whenever she actually says something, for moods that have one in the pack; a mood with no entry there just keeps its idle face while talking.

### 5.2 Config file

Create the folder with `mkdir -p ~/.config/wezterm`, then save a copy of [`wezterm/wezterm.lua`](../wezterm/wezterm.lua) from this repo as `~/.config/wezterm/wezterm.lua`, read it there rather than here, so this guide can't drift out of sync with it.

WezTerm reloads this file automatically when you save it. If you already had a config at `~/.wezterm.lua`, merge your settings into this file, because WezTerm prefers the one in `~/.config/wezterm/`.

### 5.3 How it works

After every command, the shell sends a hidden escape code with the current mood. WezTerm reads it once per second and swaps the background image. Because it is a real background and not text, nothing ghosts on resize. Sleepy mode works by watching the cursor position, so typing wakes her up.

### 5.4 Limits

* A wrong sudo password cannot trigger a mood change by itself, since sudo handles it and the shell never sees it. The failed sudo command afterwards sets a nonzero status, so she turns angry right after.
* Inside tmux the escape code needs passthrough enabled (`set -g allow-passthrough on`).
* Long running commands count as no activity, so she can fall asleep during a build.
* Desktop notifications cannot tell whether the terminal is in the foreground, so you also get one when you are looking at it. Set `MY_NOTIFY=0` in `~/.config/tsundere/tsundere.sh` to turn them off.

---
## Part 6. How the mood works

### Mood meter

| Event | Meter | Face and extras |
|---|---|---|
| Command succeeds | +1 (max 10) | Normal, or happy at 10 with a praise line |
| Command fails | -3 (min 0) | Angry and an insult |
| Mistyped command name | -3 | Angry, insult and a "did you mean" suggestion |
| Command fails with a code in `exitcodes.txt` (130 Ctrl-C, 137 OOM, 139 segfault...) | -3 | Angry and a line for that specific exit code, checked before `reactions.txt` |
| 3 or more failures in a row | -3 each | Fed up face instead of angry, once it hits 3 |
| Dangerous command succeeds | +1 | Panic line, surprised face |
| Dangerous command fails | -3 | Panic line, insult, scared face |
| Command over 30 seconds | +1 | "Finally done" line |
| Success streak hits a length in `MY_STREAK_MILESTONES` | +1 | Streak callout and a happy face |
| Git command with 10 or more changed files | +1 | Nag line, disgusted face |
| `git push` or `git commit` leaving a clean tree | +1 | Compliment |
| Command listed in `reactions.txt` | +1 or -3 | Her own line for that command |
| 1 in 100 successful commands | +1 | Rare sweet line and a happy face |
| Occasional nag late at night | No change | Worried face |
| Long session (break reminder) | No change | Worried face |
| Empty Enter | No change | Nothing happens |

She also briefly switches to an open-mouth "talking" variant of whatever face she's showing for about 2.5 seconds any time she actually says a line (see `TALK_FILE` in [5.1](#51-images)).

### Affection levels

Every successful command gives 1 affection point and every failure takes 1 away (never below 0). Points are saved, so they survive restarts. At each level her lines change.

| Level | Name | Points | How she talks |
|---|---|---|---|
| 0 | cold | 0 | Mean insults and grudging praise |
| 1 | warming up | 100 | Warmer praise |
| 2 | softening | 400 | Milder insults and proud praise |
| 3 | dere | 1000 | Soft, encouraging lines |
| 4 | smitten | 2500 | Barely insults at all, mostly affectionate |

Reaching a new level shows a special line, tried in this order: `levelup-N.txt` for the level just reached, falling back to the generic `levelup.txt`. The day-to-day lines for each level are in `praise-1.txt` to `praise-4.txt` and `insults-2.txt` to `insults-4.txt`.

### Settings

The settings sit at the top of `~/.config/tsundere/tsundere.sh`.

| Variable | Default | Meaning |
|---|---|---|
| `MY_MOOD_MAX` | 10 | Highest the meter can go |
| `MY_MOOD_THRESHOLD` | 10 | Meter value where she turns happy |
| `MY_MOOD_PENALTY` | 3 | Points lost per failure |
| `MY_SLOW_SECS` | 30 | Seconds before a command counts as slow |
| `MY_GIT_DIRTY` | 10 | Changed files before she nags |
| `MY_NIGHT_CHANCE` | 6 | Bedtime nag happens 1 in this many successes at night |
| `MY_RARE_CHANCE` | 100 | Rare sweet line happens 1 in this many successes |
| `MY_BREAK_SECS` | 7200 | Seconds in one terminal before a break reminder |
| `MY_AWAY_SECS` | 86400 | Seconds away before she resets her mood and complains |
| `MY_NOTIFY` | 1 | Set to 0 to turn desktop notifications off |
| `MY_NOTIFY_SECS` | 60 | Seconds before a command triggers a notification |
| `MY_LEVEL_AT` | 0 100 400 1000 2500 | Points needed for each affection level |
| `MY_STREAK_MILESTONES` | 5 10 25 50 100 250 500 1000 | Streak lengths that get a special callout |
| `MY_SIZE_DEFAULT` | 30 | Starting size, percent of window height, see `tsun size` |
| `MY_SIZE_MIN` / `MY_SIZE_MAX` | 10 / 60 | Range `tsun size` is clamped to |
| `MY_SIZE_STEP` | 5 | Change per `tsun size bigger`/`smaller` |

### Other behavior

* After a day without any command (`MY_AWAY_SECS`), the next terminal sets the meter back to 0 and she asks where you were. Affection points are kept.
* After two hours in the same terminal (`MY_BREAK_SECS`), she tells you to take a break, then again every two hours.
* Between 23:00 and 05:00 she sometimes nags you to go to sleep. She greets you when you open a terminal any time of day: morning (05:00-12:00), afternoon (12:00-17:00), evening (17:00-23:00), or night (23:00-05:00), each with its own lines.
* Notifications need `notify-send` (package `libnotify-bin` on Debian and Ubuntu, `libnotify` on Arch and Fedora).
* Several terminals share the same meter and stats through the files in `~/.cache`. If two commands finish at exactly the same moment, one count can get lost, which does not matter.

To reset everything, run `tsun reset`.

---
## Part 7. The tsun command

| Command | What it does |
|---|---|
| `tsun stats` | Shows how many days she's known you, lifetime and today's successes and failures, best streaks, mood, affection level with progress to the next one, and a comment from her |
| `tsun off` | Mutes her completely, no lines and no image. Good for screen sharing |
| `tsun on` | Brings her back |
| `tsun say` | Prints a random phrase |
| `tsun outfit [name]` | No name lists outfits (a live scan of `sprites/`) and shows the current one; a name switches to it live |
| `tsun crop [name]` | No name lists crop levels (`full`, `waist`, `bust`) and shows the current one; a name switches to it live |
| `tsun size [bigger\|smaller\|reset\|N]` | No argument shows the current size; `bigger`/`smaller` step it by 5, `reset` goes back to 30, or jump straight to a number (range 10-60) |
| `tsun reset` | Asks first, then resets mood, stats, affection and how long she's known you |
| `tsun ai [off\|anthropic [model]\|ollama [model]]` | No argument shows the current AI provider; picks or turns off who `tsun talk` talks to (Part 9) |
| `tsun talk [message]` | A message gets one reply; no message opens a back-and-forth chat until you type `/bye` (Part 9) |
| `tsun aisetup [name value\|reset]` | No argument lists every AI tuning setting and its current value; a name and value changes one; `reset` puts them all back to default (Part 9) |

The mute, outfit, crop, size and AI provider settings are each a file, so they apply to all terminals at once and survive restarts.

Running `tsun` itself, with any subcommand, never counts as a command: it does not touch the mood meter, the daily or lifetime stats, affection points, or the current streak, and you only ever get the one line `tsun` printed, not a second automatic reaction on top of it (`my/tsundere-precmd` returns immediately for anything starting with `tsun`). `off`, `on`, `outfit`, `crop` and `size` each pick their confirmation line from their own pool (`tsun-off.txt`, `tsun-on.txt`, `tsun-outfit.txt`, `tsun-crop.txt`, `tsun-size.txt`) instead of always printing the same fixed line. `tsun talk` is the one exception to "never counts": each exchange nudges affection up a little on its own, separate from and on top of this rule, see Part 9.

---
## Part 8. Test checklist

Open a **new** WezTerm window, then try each of these.

| Test | Expected result |
|---|---|
| Open a new terminal | Greeting (morning, afternoon/evening or night), background starts blank then fills in within a second, no placeholder flash |
| `asdfgh` | Insult, suggestion if a close command exists, angry girl |
| `gti status` | Insult and "did you mean `git`" |
| `ls /nonexistent` | Insult and angry girl |
| `echo hi` five times in a row | On the 5th, a streak callout and happy girl (then more praise building to happy at 10) |
| `sleep 100` then Ctrl-C | Her Ctrl-C line (exit code 130), not a generic insult |
| `rm -rf /tmp/nothing` | Panic line and surprised girl |
| `sleep 31` | "Finally done" line afterwards |
| `sleep 61` with another window in front | Desktop notification (needs notify-send) |
| `ping -c1 nonexistent.invalid` | Her ping line |
| `sudo true` | Her sudo line |
| `git status` in a messy repo | Nag line |
| `tsun stats` | Counters, level and a comment |
| `tsun outfit` | Lists the four bundled outfits and says which one is current |
| `tsun outfit schoolwinter` | She switches outfit within a second, no restart needed |
| `tsun crop bust` | She switches crop level the same way |
| `tsun size bigger` a few times | She visibly grows, same crop and outfit |
| `tsun size reset` | Back to 30 |
| `tsun outfit sundress` | A different outfit entirely, not just a crop/size change |
| `tsun off` then a command | No lines, no girl |
| `tsun on` | She is back |
| Leave the terminal alone for 5 minutes | Sleepy girl, typing wakes her |
| `tsun ai ollama` (Ollama installed and running) | Picks a model already pulled, prefers one with an uncensored-sounding name |
| `tsun talk hows it going` | One in-character reply, her picture updates to match its tone |
| `tsun talk` then a few messages, then `/bye` | Back-and-forth chat, remembers earlier messages in the same session, goodbye line on exit |

---
## Part 9. Talking to her (optional)

`tsun talk` is a real AI chat, not just a random line, and it is off by default. It lives entirely in its own file, [`shell/ai.sh`](../shell/ai.sh), installed as `~/.config/tsundere/ai.sh` and only loaded the first time you actually run `tsun ai` or `tsun talk`, so it costs nothing if you never touch it. It needs `curl`.

### Picking a provider

```bash
tsun ai anthropic             # uses claude-haiku-4-5-20251001 by default
tsun ai anthropic claude-opus-5   # or name a specific model
tsun ai ollama                 # auto-picks a model you already have pulled
tsun ai ollama llama3.2         # or name one yourself
tsun ai off                     # back to off
tsun ai                         # shows the current provider and model
```

The choice is saved to `~/.cache/tsundere/ai` and applies to every terminal, same as outfit/crop/size.

**Anthropic** needs `ANTHROPIC_API_KEY` set in your environment (export it from `.bashrc`, same convention as every other tool that uses it). The key is never written to any file this project creates.

**Ollama** needs a local server (`ollama serve`) reachable at `MY_OLLAMA_HOST` (default `http://localhost:11434`, edit that setting at the top of `ai.sh` to change it). Run `tsun ai ollama` with no model name and it looks at what you already have pulled (`ollama list`), prefers one that looks uncensored (name containing `uncensored`, `abliterated`, `dolphin`, or similar), and otherwise just uses whatever is there. It never pulls a model on its own; if nothing is pulled yet, it tells you a couple of names to try, for example `ollama pull dolphin-mistral`.

### What she actually sends

Every message includes a short system prompt built from live session state: your working directory, her current affection level, today's success/fail counts, and the text and outcome of your last command. With Anthropic this leaves your machine; with Ollama it stays local. The interactive chat (`tsun talk` with no message) also keeps the last `MY_AI_HISTORY_TURNS` exchanges (default 6) in context for that session only, nothing is saved to disk once you leave.

**In WezTerm, she can also see recent terminal output**, so she can actually explain an error instead of only knowing the command's name and exit code. This reads straight from WezTerm's own scrollback via `wezterm cli get-text` (`my/ai-recent-output` in `ai.sh`), the last `MY_AI_OUTPUT_LINES` lines (default 25), capped to `MY_AI_OUTPUT_CHARS` (default 1200 characters). It never redirects any file descriptor to get this, so nothing about color detection, pagers, or full-screen programs like `vim`/`less` changes, unlike the usual way of logging a shell's output. It does mean more of what's actually on your screen can leave the machine whenever an AI provider is in use (with Anthropic) — `tsun aisetup MY_AI_SEND_OUTPUT 0` turns this part off and keeps everything else.

The output and timeout defaults are deliberately conservative because a small local CPU model can take tens of seconds just to read a long prompt, before it even starts replying — see **Tuning it** below if you're on Anthropic or a beefier local setup and want more context.

### Her picture reacts too

Every reply ends with a `[mood: ...]` tag the model is instructed to add, picked from the same nine moods already wired up to real art (`normal`, `angry`, `happy`, `surprised`, `sleepy`, `scared`, `fedup`, `worried`, `disgusted`, see Part 6). `my/ai-say` in `ai.sh` strips the tag before printing and uses it to update her picture live, same as every other mood change, and is lenient about the exact format (a bare `[happy]` works too, not just `[mood: happy]`, since smaller local models don't always follow instructions precisely) as long as the word is one of those nine. If the tag is missing or not recognized, it just falls back to normal rather than guessing.

### Affection

Unlike every other `tsun` subcommand, each real exchange with `tsun talk` adds a small amount of affection (`MY_CHAT_BUMP`, 1 point), capped at `MY_CHAT_BUMP_MAX` per day (10) so it can't be farmed by spamming messages. Past the cap, chatting keeps working, it just stops raising affection until the next day. Unlike the settings below, these two are fixed, not exposed to `tsun aisetup` or anything else live — a user-adjustable cap would defeat the entire point of having one. Edit the two lines directly at the top of `ai.sh` if you genuinely want to change them.

### Ending a chat

In the interactive loop, type `/bye`, `/exit` or `/quit`, or just press Ctrl-D.

### Tuning it

Everything above that's a number or an on/off switch is a live setting, changed with `tsun aisetup` instead of editing `ai.sh`:

```bash
tsun aisetup                          # list every setting and its current value
tsun aisetup MY_OLLAMA_NUM_PREDICT 80 # change one
tsun aisetup reset                    # back to defaults
```

`tsun aisetup` only ever shows and accepts the rows that apply to whichever provider `tsun ai` currently has active (the "Applies to" column below) — asking for an Ollama-only setting while on Anthropic, or the other way round, is refused with a message telling you to switch providers first, rather than silently doing nothing.

| Setting | Default | Applies to | What it does |
|---|---|---|---|
| `MY_AI_HISTORY_TURNS` | 6 | both | Exchanges kept in context during an interactive chat |
| `MY_AI_TIMEOUT` | 20 | anthropic | Seconds before an Anthropic request gives up |
| `MY_OLLAMA_TIMEOUT` | 90 | ollama | Seconds before an Ollama request gives up (cold model loads are slow) |
| `MY_AI_SEND_OUTPUT` | 1 | both | 1 to send recent terminal output as context, 0 to stop |
| `MY_AI_OUTPUT_LINES` | 25 | both | Scrollback lines pulled from WezTerm for context |
| `MY_AI_OUTPUT_CHARS` | 1200 | both | Cap on how much of that scrollback actually gets sent |
| `MY_OLLAMA_KEEPALIVE` | `10m` | ollama | How long Ollama keeps the model loaded between messages |
| `MY_OLLAMA_NUM_PREDICT` | 150 | ollama | Hard cap on Ollama's reply length, in tokens |

**Settings are saved per provider**, not shared, since Anthropic (fast, hosted) and Ollama (as slow as your hardware) usually want different values for the same knob — for example a much bigger `MY_AI_OUTPUT_CHARS` with Anthropic than you'd want on a small local model. Each provider gets its own file, `~/.cache/tsundere/ai-limits-anthropic` / `~/.cache/tsundere/ai-limits-ollama`, and `tsun aisetup` always shows and edits whichever provider is currently active with `tsun ai` — switching providers with `tsun ai anthropic`/`tsun ai ollama` applies that provider's own saved values immediately, no restart needed. `MY_OLLAMA_HOST` (default `http://localhost:11434`) is the one connection detail that isn't here, since it's not really a "limit" — change it at the top of `ai.sh` if your Ollama server lives somewhere else.

---
## Troubleshooting

| Problem | Fix |
|---|---|
| Nothing happens at all | Check `echo $PROMPT_COMMAND` includes `my/tsundere-precmd`, meaning the tsundere line in `.bashrc` actually ran |
| Meter never goes up | Check `history 1` shows a growing number after each command; if it never changes, history is probably disabled (`shopt -s history`, `HISTSIZE` not 0) |
| She never panics on `rm -rf` | The warning fires after the command runs now, not before, so it should still show up right after, just later than you expect |
| Two insults on a typo | The precmd must skip status 127, as in Part 3 |
| No "did you mean" line | Check `python3 --version` and that `typo.txt` exists |
| No reaction for a command | Check the pattern in `reactions.txt`. It is matched against the whole command line, so use `sudo *` and not `sudo` |
| Lines are missing | Run `./scripts/lines.sh` again, it only creates the missing files |
| No notification | Check `command -v notify-send`, and that `MY_NOTIFY` is 1 and the command ran longer than `MY_NOTIFY_SECS` |
| She stays muted | Run `tsun on`, or delete `~/.cache/tsundere/muted` |
| Colors look wrong | Check `echo $COLORTERM` shows `truecolor` or `24bit` |
| Girl never changes | Check `echo $TERM_PROGRAM` says `WezTerm` and that `sprites/ratios.txt` has an entry for the current outfit/crop |
| Background looks broken | Press `Ctrl+Shift+L` in WezTerm to open the debug overlay and read the error |
| No greeting | It only shows when `SHLVL` is 1, and only between 5 and 12 or 23 and 5 |
| `shuf` not found | Install coreutils |
| `tsun talk` always fails | Check `command -v curl`, `tsun ai` shows a provider, and (Anthropic) `echo $ANTHROPIC_API_KEY` is set, or (Ollama) `curl http://localhost:11434/api/tags` responds |
| `tsun ai ollama` finds no models | `ollama list` is empty, pull one first (`ollama pull dolphin-mistral` or any model name) |
| Her picture doesn't change during chat | The reply is missing a valid `[mood: ...]` tag, she falls back to normal; check `ai.sh`'s system prompt still asks for it |
| Ghost lines in scrollback | Run `clear` once, old ghosts do not vanish on their own |
| Running the exact same command twice in a row only reacts once | Expected if `HISTCONTROL` includes `ignoredups`, the repeat never becomes a new history entry so there is nothing new to notice |
| `history` now shows a timestamp column | Expected, `HISTTIMEFORMAT` is set so duration and "did anything run" can be worked out without ble.sh |
