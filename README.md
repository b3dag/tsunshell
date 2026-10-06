# Tsundere Terminal

A bash setup where your terminal insults you when a command fails and grudgingly praises you when things go well. It works with ble.sh and Starship, and gets an anime girl in the corner when you use WezTerm.

## What it does

* Random insult when a command fails, and a "did you mean" suggestion on typos
* A happy meter (+1 success, -3 failure). At 10 she turns happy and praises you
* Affection levels that make her nicer over time
* Panic before dangerous commands like `rm -rf` and force pushes
* Her own reactions to sudo, ping, ssh, git, apt and more (editable in a text file)
* Greetings by time of day, bedtime nags, break reminders, and a complaint after a day away
* Git reactions, slow command messages and desktop notifications
* `tsun stats`, `tsun off`, `tsun on`, `tsun say` and `tsun reset`
* In WezTerm, an image in the bottom right with five expressions, sleepy mode and mute

All lines are plain text files, so you can add your own without touching any code.

## Requirements

* bash, with [ble.sh](https://github.com/akinomyoga/ble.sh) and [Starship](https://starship.rs)
* A truecolor terminal
* `shuf` (coreutils) and `python3` for the typo suggestions
* WezTerm for the image (optional)
* `notify-send` for notifications (optional)

## Install

```bash
git clone https://github.com/b3dag/tsunshell
cd tsunshell
./install.sh
```

The installer copies everything into your home folder and backs up files it replaces. Use `./install.sh --no-wezterm` or `--no-images` to skip parts. It prints one manual step at the end, four lines to add to `~/.bashrc`.

To remove it again, run `./uninstall.sh`.

## Layout

| Path | Purpose |
|---|---|
| `shell/tsundere.sh` | All the shell logic, installed as `~/.config/tsundere/tsundere.sh` |
| `scripts/lines.sh` | Creates all phrase files, safe to run again |
| `wezterm/wezterm.lua` | WezTerm config that swaps the image |
| `starship/starship.toml` | Starship config with the phrase on the path line |
| `images/` | The five expressions, 280 by 368 PNGs with transparency |
| `docs/SETUP.md` | Full manual with every setting and troubleshooting |

## Images

The files in `images/` are placeholders for whatever art you want to use. Only publish the repo with these images if you have the rights to them. Replace them with your own PNGs of the same size, named `normal`, `angry`, `happy`, `surprised` and `sleepy`.
