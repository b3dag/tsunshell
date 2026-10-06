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

Sprite packs rarely have an exact "surprised" or "sleepy" drawing; check the `MOOD_FILE` table near the top of `wezterm/wezterm.lua`, it maps her five moods to filenames in a set, and pick the closest fit for those two if needed, it is just a lookup table.

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
| Dangerous command | +1 if it succeeds | Panic line before it runs, surprised face |
| Command over 30 seconds | +1 | "Finally done" line |
| Success streak hits a length in `MY_STREAK_MILESTONES` | +1 | Streak callout and a happy face |
| Git command with 10 or more changed files | +1 | Nag line |
| `git push` or `git commit` leaving a clean tree | +1 | Compliment |
| Command listed in `reactions.txt` | +1 or -3 | Her own line for that command |
| 1 in 100 successful commands | +1 | Rare sweet line and a happy face |
| Empty Enter | No change | Nothing happens |

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

The mute, outfit, crop and size settings are each a file, so they apply to all terminals at once and survive restarts.

Running `tsun` itself, with any subcommand, never counts as a command: it does not touch the mood meter, the daily or lifetime stats, affection points, or the current streak, and you only ever get the one line `tsun` printed, not a second automatic reaction on top of it (`my/tsundere-precmd` returns immediately for anything starting with `tsun`). `off`, `on`, `outfit`, `crop` and `size` each pick their confirmation line from their own pool (`tsun-off.txt`, `tsun-on.txt`, `tsun-outfit.txt`, `tsun-crop.txt`, `tsun-size.txt`) instead of always printing the same fixed line.

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
| Ghost lines in scrollback | Run `clear` once, old ghosts do not vanish on their own |
| Running the exact same command twice in a row only reacts once | Expected if `HISTCONTROL` includes `ignoredups`, the repeat never becomes a new history entry so there is nothing new to notice |
| `history` now shows a timestamp column | Expected, `HISTTIMEFORMAT` is set so duration and "did anything run" can be worked out without ble.sh |
