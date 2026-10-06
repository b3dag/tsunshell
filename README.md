# Tsundere Terminal

A bash setup where your terminal insults you when a command fails and grudgingly praises you when things go well. Plain bash, no other shell framework needed, and gets an anime girl in the corner when you use WezTerm.

## What it does

* Random insult when a command fails, and a "did you mean" suggestion on typos
* A happy meter (+1 success, -3 failure). At 10 she turns happy and praises you
* Five affection levels, from cold to smitten, that make her nicer the more you use the terminal
* Panic before dangerous commands like `rm -rf` and force pushes
* Her own reactions to sudo, ping, ssh, git, npm, cargo, docker and more (editable in a text file)
* Specific lines for Ctrl-C, out-of-memory kills, segfaults, timeouts and permission errors, not just a generic failure
* A callout at streak milestones (5, 10, 25, 50...), separate from the best-streak tracking
* Greetings by time of day, bedtime nags, break reminders, and a complaint after a day away
* Git reactions, slow command messages and desktop notifications
* `tsun stats` with lifetime totals, success rate, how many days she's known you, and progress to the next affection level
* `tsun off`, `tsun on`, `tsun say`, `tsun reset`, and `tsun outfit` / `tsun crop` / `tsun size` to change how she looks, live
* In WezTerm, an image in the bottom right with a full expression set, sleepy mode and mute
* Four bundled outfits, switchable without editing any file, new ones picked up automatically, no registration needed
* `tsun talk`, an optional real AI chat (Anthropic or a local Ollama model), aware of what you've been doing in the terminal, that picks her own expression as she replies

All lines are plain text files under `lines/`, one file per mood or reaction, so you can edit or add your own without touching any code, and without hunting through a script full of heredocs to find them.

## Requirements

* bash
* A truecolor terminal
* `shuf` (coreutils) and `python3` for the typo suggestions
* WezTerm for the image (optional)
* `notify-send` for notifications (optional)
* `curl`, only for `tsun talk` (optional)

## Install

```bash
git clone https://github.com/b3dag/tsunshell
cd tsunshell
./install.sh
```

The installer copies everything into your home folder and backs up files it replaces. Use `./install.sh --no-wezterm` or `--no-images` to skip parts. It prints one manual step at the end, one line to add to `~/.bashrc`.

To remove it again, run `./uninstall.sh`.

## Layout

| Path | Purpose |
|---|---|
| `shell/tsundere.sh` | All the shell logic, installed as `~/.config/tsundere/tsundere.sh` |
| `shell/ai.sh` | `tsun ai` / `tsun talk`, installed as `~/.config/tsundere/ai.sh`, loaded only if you use them |
| `lines/*.txt` | Every default phrase file, one file each, edit or add your own freely |
| `scripts/lines.sh` | Copies `lines/*.txt` into `~/.config/tsundere/`, safe to run again |
| `scripts/sprites.sh` | Crops a sprite-sheet art pack into an outfit set for WezTerm, see Images below |
| `wezterm/wezterm.lua` | WezTerm config that swaps the image |
| `images/sprites/` | The bundled outfits, see Images below |
| `docs/SETUP.md` | Full manual with every setting and troubleshooting |

## Images

`images/sprites/` holds the actual art: four bundled outfits (`casual`, `schoolsummer`, `schoolwinter`, `sundress`), each with a full expression set at three crop levels (`full`, `waist`, `bust`), already cropped and installed by `install.sh`. Only publish this repo with these images if you have the rights to them. No ImageMagick or any other tool needed to use what's bundled, pick an outfit at runtime:

```
tsun outfit schoolwinter
tsun crop bust
tsun size bigger
```

Run `tsun outfit` or `tsun crop` with no argument to list what's available, this is a live directory scan, never a hardcoded list, so a new outfit folder shows up the moment it exists. The choice is saved and takes effect immediately in any open WezTerm window, no restart needed. None of this counts as a command towards her mood, stats or affection, and you only get the one confirmation line `tsun` prints itself, not a second automatic reaction on top.

Crop and size are two different things: crop picks how much of her is in frame (more of her body vs. just her face), size is how big that framed image is drawn on screen, as a percent of the window height. Changing crop without also adjusting size can make her look smaller, since a wider crop (more of her body) squeezed into the same on-screen height makes everything in it smaller. `tsun size bigger` / `tsun size smaller` nudge it by 5 points a step (range 10-60, default 30), `tsun size <N>` jumps straight to a value, and `tsun size reset` goes back to the default.

### Using your own sprite pack

If you have a different character art pack with many expressions (a visual novel style sprite sheet set, one full-body PNG per expression, same canvas size, filenames like `prefix_outfit_expression.png`), `scripts/sprites.sh` turns it into an outfit the same way the bundled ones were made:

```bash
./scripts/sprites.sh ~/path/to/the/raw/pngs
```

It finds where the art actually starts per outfit (auto-trimming the empty canvas), crops every expression in that outfit to that same box so she never jumps position when her face changes, and by default generates all three crop levels (`full`, `waist`, `bust`) in one pass into `~/.config/tsundere/sprites/<outfit>/<crop>/`. Pass `--show waist` (or any comma list) to only generate specific ones, `--width` to change the output size, and `--dest` to write somewhere else, for example straight into `images/sprites/` in this repo instead of your live config.

New outfits show up in `tsun outfit` automatically, just by existing as a folder, nothing to register anywhere. `scripts/sprites.sh` also writes `sprites/ratios.txt` (outfit/crop → actual pixel size), which `wezterm/wezterm.lua` reads at startup so she never stretches, also with no hardcoded per-outfit table to maintain. The `MOOD_FILE` table near the top of that same file maps her nine moods (normal, angry, happy, surprised, sleepy, scared, fed up, worried, disgusted) to filenames in a set; sprite packs rarely have an exact drawing for all of them, so pick the closest fit, edit freely. The `TALK_FILE` table below it is optional: an open-mouth variant shown for a couple seconds whenever she actually says a line, for moods that have one.

## Talking to her

`tsun talk <message>` sends one message and prints one reply; `tsun talk` with nothing opens a back-and-forth chat until you type `/bye`. It's off by default, see [`tsun ai`](docs/SETUP.md#part-9-talking-to-her-optional) to point it at either the Anthropic API or a local Ollama model. She's fed a bit of live context (your cwd, her affection level, your last command and whether it worked, and in WezTerm some recent terminal output) so she can actually react to the session instead of just chatting in a vacuum, and every reply ends with a mood tag that updates her picture, same as any other mood change. Each real exchange nudges her affection up a little, capped per day so it can't be farmed. Timeouts, how much terminal output she sees, and Ollama's reply-length cap are all live settings, `tsun aisetup` lists and changes them. All of this lives in `shell/ai.sh`, loaded only the first time you use it, so a terminal that never touches it pays nothing for it.
