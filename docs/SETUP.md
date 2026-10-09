# Tsundere Terminal Setup Manual

A complete guide to a tsundere shell, plain bash plus optionally **WezTerm** for the character image.

> If you use `install.sh` from this repo, the files in parts 2, 3 and 5 are installed for you. Part 1 (installing WezTerm) and the one `.bashrc` line in part 4 are still up to you. The rest of this guide explains what each piece does.

## What you get

| Feature | Where it lives |
|---|---|
| Generic phrase after a command that triggered nothing more specific | `lines/phrases/` |
| Random insult when a command fails | `lines/insults/` |
| Insult and "did you mean" suggestion on mistyped commands | `lines/typo/` |
| Happy meter (+1 success, -3 failure, happy at 10) | `~/.config/tsundere/tsundere.sh` |
| Affection levels that make her nicer over time | `lines/praise/`, `lines/insults/`, `lines/levelup/` |
| Asks before dangerous commands (`rm -rf`, force push, `dd`, `chmod -R 777`, `mkfs`) actually run | `lines/danger-gate/` |
| Gets a little jealous and can ask before launching another AI's CLI | `lines/jealous-gate/` |
| Reactions to specific commands (sudo, ping, ssh, git and more) | `lines/reactions/` |
| Reactions to specific exit codes (Ctrl-C, OOM kill, segfault, timeout...) | `lines/exitcodes/` |
| Streak milestone callout (5, 10, 25, 50 in a row...) | `lines/streak/` |
| Repeating the same command right after the same outcome still reacts, but earns nothing extra | `lines/repeat/`, `lines/repeat-fail/` |
| Greeting by time of day and bedtime nags at night | `lines/morning/`, `lines/afternoon/`, `lines/evening/`, `lines/night/` |
| "Finally done" line after slow commands | `lines/slow/` |
| Git reactions (messy tree, clean tree after push, and `git status` itself) | `lines/git-dirty/`, `lines/git-clean/`, `lines/git-status-clean/`, `lines/git-status-dirty/` |
| Break reminder after long sessions | `lines/break/` |
| "Where were you?" after a day away | `lines/away/` |
| Rare sweet lines, and specific remembered moments brought back up | `lines/rare/`, `lines/memory/` |
| Comments on the machine itself: low battery, full disk, high load | `lines/battery/`, `lines/disk/`, `lines/load/` |
| Desktop notification after long commands | `~/.config/tsundere/tsundere.sh` |
| A pet name once affection is high enough (`tsun name`) | `lines/tsun-name/` |
| `tsun` command for stats, mute, outfit, crop, name, memories, doctor and reset | `~/.config/tsundere/tsundere.sh` |
| `tsun doctor` checks your setup and tells you what's missing or broken | `~/.config/tsundere/tsundere.sh` |
| Mood, stats and affection saved across terminals and reboots | `~/.cache/tsundere/` |
| Anime girl bottom right, and mute | WezTerm |
| Four bundled outfits, each with a full expression set at three crop levels, switchable live with `tsun outfit` / `tsun crop`, plus `tsun size` to change how big she is | `images/sprites/` |
| `tsun talk`, an optional real AI chat aware of your session (Part 9) | `~/.config/tsundere/ai.sh` |

Phrases live in plain text files, so you can add lines any time without touching any code.

## File overview

| File | Purpose |
|---|---|
| `~/.config/tsundere/<category>/0.txt`..`4.txt` | Every phrase category, one folder per mood or reaction, one file per affection level (`phrases`, `insults`, `praise`, `danger-gate`, `jealous-gate`, `reactions`, `exitcodes`, `repeat`, and every other category under `lines/` in this repo, see Part 2) |
| `~/.config/tsundere/ai.sh` | `tsun ai` / `tsun talk` logic, loaded only the first time you use either (Part 9) |
| `~/.config/tsundere/sprites/<outfit>/<crop>/*.png` | The bundled (or your own) outfit sets, picked with `tsun outfit` / `tsun crop` |
| `~/.config/tsundere/sprites/ratios.txt` | Each outfit/crop's actual pixel size, written automatically by `scripts/sprites.sh` |
| `~/.config/tsundere/tsundere.sh` | All the shell logic, loaded like bash_aliases |
| `~/.bashrc` | Loads everything in the right order |
| `~/.config/wezterm/wezterm.lua` | WezTerm config and image swapping |
| `~/.cache/tsundere/` | Saved happy meter, stats, lifetime totals, affection points, first-seen date, last seen time, chosen outfit/crop/size/pet name/AI provider, remembered moments, and the mute flag |

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

Every mood or reaction is a folder under `lines/` in this repo (`lines/phrases/`, `lines/danger/`, `lines/reactions/`, and so on), holding one file per affection level: `0.txt` (coldest) through `4.txt` (warmest), matching `MY_LEVEL` directly. `scripts/lines.sh` copies whichever files are missing into `~/.config/tsundere/<category>/`.

```bash
./scripts/lines.sh
```

It only creates files that do not exist yet, so you can run it again after an update and your own additions stay untouched. Any file you delete is created again with the default lines. A category doesn't need every level filled in — `my/pool` in `shell/tsundere.sh` walks down from the current level to the closest one that exists, so a folder with only `0.txt` and `2.txt` still works fine at every level, it just reuses the nearest tier below. To add a brand new category, drop a new `lines/<name>/` folder with its own `0.txt`..`4.txt` in the repo, nothing else to register, the next run of `scripts/lines.sh` picks it up. The script itself is short, see [`scripts/lines.sh`](../scripts/lines.sh) in this repo rather than a copy pasted in here, so this guide can't go stale against it.

To add more lines of any kind later, just append to the files. In `typo/`, every `%s` is replaced by the suggested command.

`reactions/` and `exitcodes/` are the two categories shaped differently: each level's file is a full table, one reaction per line in the form `pattern|when|message` (or `code|message` for exit codes), not a plain list of phrases. Same patterns/codes across all 5 levels, just reworded per level, since those two react to a specific command or exit code rather than being a random pick.

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

Sprite packs rarely have an exact drawing for every mood; check the `MOOD_FILE` table near the top of `wezterm/wezterm.lua`, it maps her eight moods (`normal`, `angry`, `happy`, `surprised`, `scared`, `fedup`, `worried`, `disgusted`) to filenames in a set, pick the closest fit for any that are missing, it is just a lookup table. The `TALK_FILE` table right below it is optional, an open-mouth variant shown for a couple seconds whenever she actually says something, for moods that have one in the pack; a mood with no entry there just keeps its idle face while talking.

### 5.2 Config file

Create the folder with `mkdir -p ~/.config/wezterm`, then save a copy of [`wezterm/wezterm.lua`](../wezterm/wezterm.lua) from this repo as `~/.config/wezterm/wezterm.lua`, read it there rather than here, so this guide can't drift out of sync with it.

WezTerm reloads this file automatically when you save it. If you already had a config at `~/.wezterm.lua`, merge your settings into this file, because WezTerm prefers the one in `~/.config/wezterm/`.

### 5.3 How it works

After every command, the shell sends a hidden escape code with the current mood. WezTerm reads it once per second and swaps the background image. Because it is a real background and not text, nothing ghosts on resize.

### 5.4 Limits

* A wrong sudo password cannot trigger a mood change by itself, since sudo handles it and the shell never sees it. The failed sudo command afterwards sets a nonzero status, so she turns angry right after.
* Inside tmux the escape code needs passthrough enabled (`set -g allow-passthrough on`).
* Desktop notifications cannot tell whether the terminal is in the foreground, so you also get one when you are looking at it. Set `MY_NOTIFY=0` in `~/.config/tsundere/tsundere.sh` to turn them off.

---
## Part 6. How the mood works

### Mood meter

| Event | Meter | Face and extras |
|---|---|---|
| Command succeeds | +1 (max 10) | Normal, or happy at 10 with a praise line |
| Command fails | -3 (min 0) | Angry and an insult |
| Mistyped command name | -3 | Angry, insult and a "did you mean" suggestion |
| Command fails with a code in `lines/exitcodes/` (130 Ctrl-C, 137 OOM, 139 segfault...) | -3 | Angry and a line for that specific exit code, checked before `lines/reactions/` |
| 3 or more failures in a row | -3 each | Fed up face instead of angry, once it hits 3 |
| Dangerous command (asked `[y/N]` first by default, see "Asking before a command actually runs" below) succeeds | +1 | Panic line, surprised face |
| Dangerous command fails | -3 | Panic line, insult, scared face |
| Command over 30 seconds | +1 | "Finally done" line |
| Success streak hits a length in `MY_STREAK_MILESTONES` | +1 | Streak callout and a happy face |
| Git command with 10 or more changed files | +1 | Nag line, disgusted face |
| `git status` itself, clean tree or fewer than 10 changed files | +1 | A status-specific line, lighter than the nag above |
| `git push` or `git commit` leaving a clean tree | +1 | Compliment |
| Command listed in `lines/reactions/` | +1 or -3 | Her own line for that command |
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

Reaching a new level shows a special line from `lines/levelup/<N>.txt`, same `my/pool` mechanism as everything else (Part 2). The day-to-day lines for each level live in `lines/praise/<N>.txt` and `lines/insults/<N>.txt`.

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
* Running another AI's CLI (`claude`, `chatgpt`, `gemini`, `copilot`, `aider`, `cursor`, `codex`) triggers its own reaction, same mechanism as the git/sudo/ping reactions, see `lines/reactions/`.
* Once in a while (`MY_AMBIENT_CHANCE`) she checks the machine itself instead of your command: battery low and actually discharging (`MY_BATTERY_LOW`), `/` getting full (`MY_DISK_HIGH`), or load average at or above core count. Cheap sysfs/proc reads, no new dependency.
* New best streak, leveling up, and a dangerous command surviving or not, each get saved as a specific memory (`tsun memories`, capped at `MY_MEMORY_MAX`); once in a while (`MY_MEMORY_CHANCE`) she brings one back up, and `tsun talk` can reference them too.
* Typing the exact same command twice in a row still gets a reaction, but only when the one right before it had the same outcome too — it does not move the mood meter, streak, or affection total a second time, in either direction. Spamming a known-good command is not a free way to farm points (`lines/repeat/`), and spamming a known-bad one (habit, up-arrow+enter without changing anything) does not keep stacking the same penalty either (`lines/repeat-fail/`). A command that actually changes outcome from the one before it (fixed, or newly broken) is unaffected and reacts normally.

### Asking before a command actually runs

Everything above reacts after the fact — plain bash has no preexec hook (that's the whole reason ble.sh isn't a dependency here anymore, see Part 4), so there's no general way to intercept a command before it runs. There is one narrow exception: a bash function with the same name as a real command replaces it for anything typed directly at the prompt, which is reliable for a short, specific list.

`rm -rf`/`-fr`/`-r`/`-R`, `git push --force`/`-f`, `dd`, `chmod -R 777`, and `mkfs` each ask `[y/N]` first (`MY_GATE_DANGER`, default on); declining skips the real command without touching anything, and still flows into the normal post-command reaction as a success, not a failure, since nothing destructive happened. The commands in `MY_JEALOUS_CMDS` (`claude`, `chatgpt`, `gemini`, `copilot`, `aider`, `cursor`, `codex` by default, add more any time) ask `[Y/n]` instead (`MY_GATE_JEALOUS`, default on) — pressing Enter alone lets it through, this one's just for the bit, not a real restriction. Both prompts pick their wording from `lines/danger-gate/` and `lines/jealous-gate/`, level-tiered like everything else, and she reacts to your actual answer immediately too, from `lines/danger-gate-yes/` / `-no/` and `lines/jealous-gate-yes/` / `-no/` — not left to whatever else happens to fire afterward in the normal post-command reaction. In WezTerm, her picture changes too: worried while a danger prompt is waiting on you, staying worried if you go ahead or switching to surprised (relief) if you back out; sad (the `fedup` mood) while a jealousy prompt waits, staying sad if you go anyway or switching to happy if you stay. Only visible for a moment, the next real command's reaction always has the final say over her picture once it runs.

This only catches the command when it's the one actually typed at this prompt — not inside a script, an alias, a pipeline, piped through `xargs`, or invoked by another tool. It is a convenience, not a security boundary. Set `MY_GATE_DANGER=0` / `MY_GATE_JEALOUS=0` at the top of `tsundere.sh` to turn either off and go back to the old after-the-fact-only warning.

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
| `tsun name [name\|off]` | No argument shows the current pet name; a name sets it, `off` clears it. Only actually used in speech once affection reaches `MY_NAME_LEVEL` (default level 3, "dere") |
| `tsun memories` | Lists the specific moments she's kept (new best streak, leveling up, a close call survived or not), newest-capped at `MY_MEMORY_MAX` |
| `tsun doctor` | Checks requirements, the precmd hook, WezTerm/sprites, and AI chat setup, reports what's missing or broken |
| `tsun reset` | Asks first, then resets mood, stats, affection, how long she's known you, and her remembered moments |
| `tsun ai [off\|anthropic [model]\|ollama [model]]` | No argument shows the current AI provider; picks or turns off who `tsun talk` talks to (Part 9) |
| `tsun ai setup [name value\|reset]` | No argument lists that provider's tuning settings and their current value; a name and value changes one; `reset` puts them all back to default (Part 9) |
| `tsun talk [message]` | A message gets one reply; no message opens a back-and-forth chat until you type `/bye` (Part 9) |

Tab completion is built in (`tsun <Tab>` lists subcommands, `tsun outfit <Tab>` lists installed outfits, and so on), registered at the bottom of `tsundere.sh`.

The mute, outfit, crop, size, pet name and AI provider settings are each a file, so they apply to all terminals at once and survive restarts.

Running `tsun` itself, with any subcommand, never counts as a command: it does not touch the mood meter, the daily or lifetime stats, affection points, or the current streak, and you only ever get the one line `tsun` printed, not a second automatic reaction on top of it (`my/tsundere-precmd` returns immediately for anything starting with `tsun`). `off`, `on`, `outfit`, `crop`, `size` and `name` each pick their confirmation line from their own `lines/tsun-*/` category instead of always printing the same fixed line. `tsun talk` is the one exception to "never counts": each exchange nudges affection up a little on its own, separate from and on top of this rule, see Part 9.

---
## Part 8. Test checklist

`bash scripts/test-reactions.sh` runs through every reaction category in one pass, inside a disposable sandbox that never touches your real stats - good for a quick "did I break anything" check after editing `tsundere.sh` or the phrase files. It drives `my/tsundere-precmd` by hand for each one (a script has no real prompt loop to trigger it automatically, see the comment at the top of that file), so a handful of categories that depend on real hardware state or the actual wall-clock hour (battery/disk/load, the bedtime nag, the time-of-day greeting) are shown directly rather than through their real trigger condition. For everything else, actually trying it in a real terminal is still the better test:

Open a **new** WezTerm window, then try each of these.

| Test | Expected result |
|---|---|
| Open a new terminal | Greeting (morning, afternoon/evening or night), background starts blank then fills in within a second, no placeholder flash |
| `asdfgh` | Insult, suggestion if a close command exists, angry girl |
| `gti status` | Insult and "did you mean `git`" |
| `ls /nonexistent` | Insult and angry girl |
| `echo hi` five times in a row | On the 5th, a streak callout and happy girl (then more praise building to happy at 10) |
| `sleep 100` then Ctrl-C | Her Ctrl-C line (exit code 130), not a generic insult |
| `echo hi` right after an identical earlier success | A `lines/repeat/` line, not a fresh phrase; `tsun stats` confirms it didn't move |
| `asdfgh` again right after the first `asdfgh` | A `lines/repeat-fail/` line instead of a fresh insult and "did you mean" |
| `rm -rf /tmp/nothing` | Asks `[y/N]` first (worried face); answering no cancels (surprised/relieved face), answering yes runs it for real (stays worried) |
| `git push --force` in any repo | Same `[y/N]` prompt as `rm -rf` |
| `sleep 31` | "Finally done" line afterwards |
| `sleep 61` with another window in front | Desktop notification (needs notify-send) |
| `ping -c1 nonexistent.invalid` | Her ping line |
| `sudo true` | Her sudo line |
| `git status` in a clean repo | A `lines/git-status-clean/` line, different from the push/commit `lines/git-clean/` praise |
| `git status` with a few uncommitted files (fewer than `MY_GIT_DIRTY`) | A `lines/git-status-dirty/` line |
| `git status` in a repo with `MY_GIT_DIRTY` or more changed files | The heavier `lines/git-dirty/` nag line, disgusted face |
| `tsun stats` | Counters, level and a comment |
| `tsun name sweetie` then enough successes to reach level 3 ("dere") | She starts using the name in some of her lines |
| `tsun memories` | Lists at least the new-best-streak moment from the `echo hi` test above |
| `tsun doctor` | Reports on bash/WezTerm/AI setup, no unexpected "bad" rows |
| A CLI in `MY_JEALOUS_CMDS` (`claude`, `gemini`, ...) if installed | Asks `[Y/n]` first (sad/fedup face), pressing Enter alone lets it through |
| `tsun outfit` | Lists the four bundled outfits and says which one is current |
| `tsun outfit schoolwinter` | She switches outfit within a second, no restart needed |
| `tsun crop bust` | She switches crop level the same way |
| `tsun size bigger` a few times | She visibly grows, same crop and outfit |
| `tsun size reset` | Back to 30 |
| `tsun outfit sundress` | A different outfit entirely, not just a crop/size change |
| `tsun off` then a command | No lines, no girl |
| `tsun on` | She is back |
| `tsun ai ollama` (Ollama installed and running) | Picks a model already pulled, prefers one with an uncensored-sounding name |
| `tsun talk hows it going` | One in-character reply, her picture updates to match its tone |
| `tsun talk` then a few messages, then `/bye` | Back-and-forth chat, remembers earlier messages in the same session, goodbye line on exit |

---
## Part 9. Talking to her (optional)

`tsun talk` is a real AI chat, not just a random line, and it is off by default. It lives entirely in its own file, [`shell/ai.sh`](../shell/ai.sh), installed as `~/.config/tsundere/ai.sh` and only loaded the first time you actually run `tsun ai` or `tsun talk`, so it costs nothing if you never touch it. It needs `curl`. She replies all at once rather than streaming token by token, by design, to keep this one file simple.

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

**In WezTerm, she can also see recent terminal output**, so she can actually explain an error instead of only knowing the command's name and exit code. This reads straight from WezTerm's own scrollback via `wezterm cli get-text` (`my/ai-recent-output` in `ai.sh`), the last `output_lines` lines (default 25), capped to `output_chars` (default 1200 characters). It never redirects any file descriptor to get this, so nothing about color detection, pagers, or full-screen programs like `vim`/`less` changes, unlike the usual way of logging a shell's output. It does mean more of what's actually on your screen can leave the machine whenever an AI provider is in use (with Anthropic) — `tsun ai setup send_output 0` turns this part off and keeps everything else.

The output and timeout defaults are deliberately conservative because a small local CPU model can take tens of seconds just to read a long prompt, before it even starts replying — see **Tuning it** below if you're on Anthropic or a beefier local setup and want more context.

### Her picture reacts too

Every reply ends with a `[mood: ...]` tag the model is instructed to add, picked from the same eight moods already wired up to real art (`normal`, `angry`, `happy`, `surprised`, `scared`, `fedup`, `worried`, `disgusted`, see Part 6). `my/ai-say` in `ai.sh` strips the tag before printing and uses it to update her picture live, same as every other mood change, and is lenient about the exact format (a bare `[happy]` works too, not just `[mood: happy]`, since smaller local models don't always follow instructions precisely) as long as the word is one of those eight. If the tag is missing or not recognized, it just falls back to normal rather than guessing.

### Affection

Unlike every other `tsun` subcommand, each real exchange with `tsun talk` adds a small amount of affection (`MY_CHAT_BUMP`, 1 point), capped at `MY_CHAT_BUMP_MAX` per day (10) so it can't be farmed by spamming messages. Past the cap, chatting keeps working, it just stops raising affection until the next day. Unlike the settings below, these two are fixed, not exposed to `tsun ai setup` or anything else live — a user-adjustable cap would defeat the entire point of having one. Edit the two lines directly at the top of `ai.sh` if you genuinely want to change them.

### Ending a chat

In the interactive loop, type `/bye`, `/exit` or `/quit`, or just press Ctrl-D.

### Tuning it

Everything above that's a number or an on/off switch is a live setting, changed with `tsun ai setup` instead of editing `ai.sh`:

```bash
tsun ai setup                   # list the active provider's settings and their values
tsun ai setup reply_limit 80    # change one
tsun ai setup reset             # back to defaults for the active provider
```

**The setting name is the same regardless of which provider you're on** — `tsun ai setup timeout 45` works whether you're currently on `tsun ai anthropic` or `tsun ai ollama`, it just changes whichever underlying variable actually matters for that provider. A setting that only makes sense for one provider (`keepalive` has no Anthropic equivalent, say) just doesn't show up while the other one is active, and asking for it anyway is refused with a message telling you to switch providers first, rather than silently doing nothing.

| Setting | Anthropic default | Ollama default | What it does |
|---|---|---|---|
| `timeout` | 20 | 90 | Seconds before a request gives up (Ollama's is higher since a cold model load can be slow) |
| `history_turns` | 6 | 6 | Exchanges kept in context during an interactive chat |
| `send_output` | 1 | 1 | 1 to send recent terminal output as context, 0 to stop |
| `output_lines` | 25 | 25 | Scrollback lines pulled from WezTerm for context |
| `output_chars` | 1200 | 1200 | Cap on how much of that scrollback actually gets sent |
| `reply_limit` | 300 | 150 | Hard cap on her reply length, in tokens (Anthropic's `max_tokens`, Ollama's `num_predict`) |
| `keepalive` | — (not applicable) | `10m` | How long Ollama keeps the model loaded between messages |

**Settings are saved per provider**, not shared, since Anthropic (fast, hosted) and Ollama (as slow as your hardware) usually want different values for the same knob — for example a much bigger `output_chars` with Anthropic than you'd want on a small local model. Each provider gets its own file, `~/.cache/tsundere/ai-limits-anthropic` / `~/.cache/tsundere/ai-limits-ollama`, and `tsun ai setup` always shows and edits whichever provider is currently active — switching providers with `tsun ai anthropic`/`tsun ai ollama` applies that provider's own saved values immediately, no restart needed. `MY_OLLAMA_HOST` (default `http://localhost:11434`) is the one connection detail that isn't here, since it's not really a "limit" — change it at the top of `ai.sh` if your Ollama server lives somewhere else.

---
## Troubleshooting

| Problem | Fix |
|---|---|
| Nothing happens at all | Check `echo $PROMPT_COMMAND` includes `my/tsundere-precmd`, meaning the tsundere line in `.bashrc` actually ran |
| Meter never goes up | Check `history 1` shows a growing number after each command; if it never changes, history is probably disabled (`shopt -s history`, `HISTSIZE` not 0) |
| She never panics on `rm -rf` | The warning fires after the command runs now, not before, so it should still show up right after, just later than you expect |
| Two insults on a typo | `command_not_found_handle` already reacted once; `my/tsundere-precmd` is supposed to skip status 127 entirely since it already got its reaction, check that check is still there |
| No "did you mean" line | Check `python3 --version` and that `lines/typo/` has a file for the current level |
| No reaction for a command | Check the pattern in `lines/reactions/`. It is matched against the whole command line, so use `sudo *` and not `sudo` |
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
| `history` now shows a timestamp column | Expected, `HISTTIMEFORMAT` is set so duration and "did anything run" can be worked out without ble.sh |
| `HISTCONTROL` lost `ignoredups`/`ignoreboth` | Expected, tsundere.sh strips that part on source so an exact repeat of the last command still gets a reaction instead of silently vanishing (see "Repeating a command" below); `ignorespace` is left alone |
