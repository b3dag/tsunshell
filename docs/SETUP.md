# Tsundere Terminal Setup Manual

A complete guide to a tsundere shell using **ble.sh**, **Starship** and **WezTerm**.

> If you use `install.sh` from this repo, the files in parts 2, 3, 4 and 8 are installed for you. Part 1 (installing the tools) and the four `.bashrc` lines in part 5 are still up to you. The rest of this guide explains what each piece does.

## What you get

| Feature | Where it lives |
|---|---|
| Random phrase at the end of the path line | Starship |
| Random insult when a command fails | `~/.config/tsundere/tsundere.sh` |
| Insult and "did you mean" suggestion on mistyped commands | `~/.config/tsundere/tsundere.sh` |
| Happy meter (+1 success, -3 failure, happy at 10) | `~/.config/tsundere/tsundere.sh` |
| Affection levels that make her nicer over time | `~/.config/tsundere/tsundere.sh` |
| Panic before dangerous commands (rm -rf, force push and more) | `~/.config/tsundere/tsundere.sh` |
| Reactions to specific commands (sudo, ping, ssh, git and more) | `reactions.txt` |
| Greeting by time of day and bedtime nags at night | `~/.config/tsundere/tsundere.sh` |
| "Finally done" line after slow commands | `~/.config/tsundere/tsundere.sh` |
| Git reactions (messy tree, clean tree after push) | `~/.config/tsundere/tsundere.sh` |
| Break reminder after long sessions | `~/.config/tsundere/tsundere.sh` |
| "Where were you?" after a day away | `~/.config/tsundere/tsundere.sh` |
| Rare sweet lines | `~/.config/tsundere/tsundere.sh` |
| Desktop notification after long commands | `~/.config/tsundere/tsundere.sh` |
| `tsun` command for stats, mute and reset | `~/.config/tsundere/tsundere.sh` |
| Mood, stats and affection saved across terminals and reboots | `~/.cache/tsundere/` |
| Custom sudo wrong password message and prompt | sudoers |
| Goodbye line on logout | `~/.bash_logout` |
| Anime girl bottom right with five expressions, sleepy mode and mute | WezTerm |

Phrases live in plain text files, so you can add lines any time without touching any code.

## File overview

| File | Purpose |
|---|---|
| `~/.config/tsundere/phrases.txt` | Phrases for the Starship line and `tsun say` |
| `~/.config/tsundere/insults.txt` | Insults for errors (affection level 0 and 1) |
| `~/.config/tsundere/praise.txt` | Nice words while she is happy (level 0) |
| `~/.config/tsundere/*.txt` | All the other lines (danger, morning, afternoon, evening, night, slow, git, typo, break, away, rare, levelup, praise-1 to 3, insults-2 and 3, reactions) |
| `~/.config/tsundere/*.png` | Girl images |
| `~/.config/starship.toml` | Starship prompt config |
| `~/.config/tsundere/tsundere.sh` | All the shell logic, loaded like bash_aliases |
| `~/.bashrc` | Loads everything in the right order |
| `~/.config/wezterm/wezterm.lua` | WezTerm config and image swapping |
| `~/.cache/tsundere/` | Saved happy meter, stats, affection points, last seen time and the mute flag |

---

## Part 1. Install everything

### 1.1 Install ble.sh

You need git, make and gawk for the build.

```bash
git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
make -C ble.sh install PREFIX=~/.local
rm -rf ble.sh
```

This installs it to `~/.local/share/blesh/ble.sh`.

### 1.2 Install Starship

```bash
curl -sS https://starship.rs/install.sh | sh
```

Check with `starship --version`.

### 1.3 Install WezTerm

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

### 1.4 Other requirements

* **bash** as your login shell. Check with `echo $SHELL`, and if needed run `chsh -s /bin/bash` and log in again.
* **python3** for the "did you mean" suggestions (almost always installed).
* **shuf** from coreutils (part of every normal Linux system).
* **notify-send** for desktop notifications (optional, see Part 9).
* A truecolor terminal. Check that `echo $COLORTERM` says `truecolor` or `24bit`.

---
## Part 2. Phrase files

All lines come from one script. Save it as `~/tsundere-lines.sh` and run it.

```bash
bash ~/tsundere-lines.sh
```

It only creates files that do not exist yet, so you can run it again after an update and your own additions stay untouched. Any file you delete is created again with the default lines.

The script:

```bash
#!/usr/bin/env bash
# Creates all phrase files for the tsundere terminal.
# Everything lives in one folder, ~/.config/tsundere/.
# Files that already exist are left alone, so your own additions stay.
mkdir -p ~/.config/tsundere

mk() {
  if [ -f "$1" ]; then
    echo "kept     $1"
  else
    cat > "$1"
    echo "created  $1"
  fi
}

mk ~/.config/tsundere/phrases.txt << 'EOF'
(•̀⤙•́ ) Hmph!
D-Don't look at me!
B-Baka...
Fine, type something.
It's not like I was waiting for you!
Hurry up, I don't have all day!
W-Well? Say something!
Hmph, you're late.
I-I'm only here because I have to be!
Don't get the wrong idea, idiot.
...Welcome back. N-Not that I missed you!
What do you want now?!
Tch. Make it a good command.
Don't break anything this time!
I'm watching you, baka.
Ugh, you again?
Oi, you're still here?
Hmph, don't make me say it twice.
W-Whatever. Just get started already.
I'm not bored watching you. Shut up.
EOF

mk ~/.config/tsundere/insults.txt << 'EOF'
A-Are you stupid?! That's not a valid command!
It failed... completely your fault, baka!
Don't blame me just because you can't type.
I-It's not like I want you to succeed, but check your syntax!
Tch. Did you even read the man page?!
I-I'm not worried about you, but that was embarrassing!
Wow, you really messed that up, idiot.
Don't look at me like that! It's YOUR typo!
Hmph! Even a beginner wouldn't do that.
W-Why do I always have to watch you fail?!
Seriously?! Try again, and this time use your brain!
It's not like I'm disappointed or anything... baka.
Ugh, you're hopeless. Fix it already!
That command doesn't exist, just like your common sense.
I-I'm only telling you because I can't stand watching this.
Pathetic. Hmph. ...Try again, I guess.
Do I have to do everything for you?! Check your spelling!
N-Nobody asked you to break things, you dummy!
Hmph! Did your fingers forget how to type?
Th-That's embarrassing, even for you.
I-I'm not mad. I'm just disappointed. ...Okay, a little mad.
Read the error message, baka! It's right there!
EOF

mk ~/.config/tsundere/praise.txt << 'EOF'
N-Not bad... I guess.
D-Don't get used to this, but good job.
I-It's not like I'm proud of you or anything!
Hmph. You're... actually not that hopeless.
T-Thanks for not breaking anything, idiot.
F-Fine, I'll admit that was pretty good.
Y-You're doing great, b-but only because I'm watching!
Keep it up, o-or whatever.
I-I guess I'm a little happy right now. Just a little!
That was... c-cool. Don't let it go to your head!
S-See? You can do it when you actually try.
Hmph, a-as expected from someone I'm watching over.
O-Okay, that one was actually impressive.
Hmph, don't expect compliments like this every time!
I-I guess you're not completely useless.
W-Well done. D-Don't make a big deal out of it!
EOF

mk ~/.config/tsundere/danger.txt << 'EOF'
W-Wait! Are you sure about that?!
H-Hey! That's dangerous, you idiot!
D-Don't blame me if everything disappears!
Y-You better have a backup, baka!
Eh?! Th-Think about what you're doing!
I-I'm not saving you if this goes wrong!
Hmph, last chance to back out, baka!
I-I swear if this breaks something...
Y-You know what you're doing... right?!
EOF

mk ~/.config/tsundere/morning.txt << 'EOF'
Hmph, you're up early. N-Not that I noticed.
G-Good morning... I guess. Don't read into it!
Did you even sleep? Whatever, let's work.
Hmph, early bird, huh? N-Not that I'm impressed.
Don't skip breakfast just to type faster, idiot.
M-Morning. ...Don't say I didn't greet you first.
EOF

mk ~/.config/tsundere/afternoon.txt << 'EOF'
Hmph, back again? D-Don't slack off this afternoon.
Still at it? ...G-Good, I guess.
Working hard, or hardly working? Tch.
Don't waste the whole day, idiot.
Did you even eat lunch, baka?
Hmph, halfway through the day already.
D-Don't tell me you napped instead of working.
EOF

mk ~/.config/tsundere/evening.txt << 'EOF'
Evening already? Hmph, don't glue yourself to this all night.
Still working this late? ...I-I guess that's kind of dedicated.
Don't forget dinner, idiot.
Winding down soon? Hmph, you better be.
Hmph, the sun's basically gone and you're still here.
D-Don't overdo it before dinner, baka.
EOF

mk ~/.config/tsundere/night.txt << 'EOF'
Go to sleep already, baka!
It's late! I-I'm not worried, you just look terrible.
Hmph, up this late again? Idiot.
D-Don't ruin your health on my account!
It's way past a reasonable hour, baka.
Hmph, insomnia or just stubborn? Probably both.
D-Don't say I didn't warn you about tomorrow morning.
EOF

mk ~/.config/tsundere/slow.txt << 'EOF'
F-Finally done, I was getting bored!
Hmph, that took forever. N-Not that I was waiting.
It's done... a-and I didn't even fall asleep. Barely.
Took you long enough, idiot.
Hmph, I almost forgot what we were doing.
EOF

mk ~/.config/tsundere/git-dirty.txt << 'EOF'
Commit your stuff already, baka! That's a mess!
S-So many changed files... do you ever clean up?!
That working tree is a disaster, idiot.
Hmph, is this a repo or a junk drawer?
C-Commit something already, it's not hard!
EOF

mk ~/.config/tsundere/git-clean.txt << 'EOF'
Hmph. A clean tree. N-Not bad.
Everything's committed? ...G-Good. I guess.
Y-You actually cleaned up. I'm... mildly impressed.
Hmph, spotless. ...Who are you and what did you do with my baka?
N-Not a single stray file. Suspicious, but good.
EOF

mk ~/.config/tsundere/typo.txt << 'EOF'
D-Did you mean `%s`? Idiot.
Hmph, it's obviously `%s`, baka!
It's `%s`. Can't you even spell?!
I-I guess you meant `%s`... don't thank me!
Hmph, you meant `%s`, obviously.
Try `%s` next time, baka, and get it right.
EOF

mk ~/.config/tsundere/break.txt << 'EOF'
You've been here for hours, baka! Stand up and drink some water.
Take a break already! ...I-I'm not worried, your posture just looks terrible.
Hmph, your eyes will fall out. Look at something far away for a minute!
S-Stretch your back at least, idiot!
Hmph, get up already, your chair isn't going anywhere.
D-Don't make me remind you again, idiot.
EOF

mk ~/.config/tsundere/away.txt << 'EOF'
Where were you?! ...N-Not that I was waiting or anything!
You disappeared for a whole day, baka! I-I didn't miss you!
Hmph, so you finally remembered I exist. Don't leave for so long next time!
Hmph, I almost forgot what your typing sounded like.
D-Don't disappear like that again, baka!
EOF

mk ~/.config/tsundere/rare.txt << 'EOF'
...You know, you're not that bad at this. D-Don't let it get to your head!
I-I kind of like watching you work. Just a little! Shut up!
Th-That was actually really cool... forget I said that!
D-Don't smile at the screen like that! ...I-I'm smiling too, I guess.
H-Hey... I'm glad you're here. Don't make this weird.
Hmph, moments like this make it almost worth it.
EOF

mk ~/.config/tsundere/levelup.txt << 'EOF'
...Fine. I'll be a little nicer to you now. J-Just a little!
You've earned some respect, baka. D-Don't get cocky!
Hmph. I-I guess we're getting along better. N-Not that I care!
Hmph, look at you, improving and everything.
D-Don't think this changes everything, baka!
EOF

# Affection levels. Level 0 uses the main files in ~/.config/tsundere

mk ~/.config/tsundere/praise-1.txt << 'EOF'
Not bad at all. ...D-Don't let it go to your head!
You're improving, baka. I-I noticed.
G-Good job. That's all I'm saying!
Keep going. I-I'm kind of impressed.
Hmph, you're actually getting the hang of this.
N-Not bad for someone who used to mess up constantly.
EOF

mk ~/.config/tsundere/praise-2.txt << 'EOF'
That was really good! ...I-I mean, it was okay.
I-I'm actually proud of you. A little! Just a little!
Y-You're getting good at this. I'm not surprised... much.
Great work. ...Don't make me say it twice!
Hmph, I'm almost used to you doing well now.
Y-You've come a long way, I guess. Don't cry about it.
EOF

mk ~/.config/tsundere/praise-3.txt << 'EOF'
Y-You did great today! I'm really happy to watch you work.
That was perfect. ...I-I like it when you do well.
Keep it up, okay? I'll be right here cheering for you!
I-I'm proud of you. Really. Don't look at me like that!
I-I mean it when I say I'm proud of you.
Hmph, you've earned every bit of this. Don't you dare doubt it.
EOF

mk ~/.config/tsundere/insults-2.txt << 'EOF'
It failed... b-but everyone makes typos. Try again.
Hmph, that was close. Check your spelling, okay?
D-Don't give up, baka. Fix it and run it again.
...That wasn't your best. I-I know you can do better.
Tch. Just a small mistake. Read the error message!
Hmph, a slip-up. It happens. Try again.
D-Don't sweat it too much, just fix it, okay?
EOF

mk ~/.config/tsundere/insults-3.txt << 'EOF'
O-Oh no, it failed... a-are you okay? Try again!
It's alright. Everyone fails sometimes... I-I'll wait.
D-Don't be sad! Look at the error, we'll fix it together.
...Y-You'll get it next time. I believe in you. J-Just a bit!
I-It's okay. Take a breath and try once more.
Hey... it's okay. Mistakes happen to everyone.
Hmph, I'm not even mad. Just try again, okay?
EOF

# Command specific reactions
# Format  pattern|when|message
# pattern is a glob matched against the whole command line
# when is ok, fail or any

mk ~/.config/tsundere/reactions.txt << 'EOF'
sudo *|ok|S-So you needed admin rights again? Don't break the system!
sudo *|ok|Hmph, admin privileges... d-don't go breaking things now!
sudo *|ok|Hmph, I trust you... a little. Don't abuse it.
sudo *|fail|You couldn't even get sudo right, baka!
sudo *|fail|Hmph, wrong password again? You're hopeless.
sudo *|fail|Tch, typing your own password wrong? Unbelievable.
*apt update*|ok|Fine, the package lists are fresh. N-Not that I care.
*apt update*|ok|Lists updated. Don't act like that makes you responsible.
*apt update*|ok|Hmph, fresh lists. I-I guess that's something.
*apt upgrade*|ok|Updating everything again? A-As long as nothing breaks, I guess.
*apt upgrade*|ok|Hmph, upgraded. I-I hope you read the changelog first.
*apt upgrade*|ok|D-Don't skip this next time, baka.
*pacman -Syu*|ok|A full system update? Pray that nothing breaks, idiot.
*pacman -Syu*|ok|Hmph, the whole system updated. D-Don't blame me if something breaks now.
*pacman -Syu*|ok|Hmph, brave of you. Glad it worked.
*dnf upgrade*|ok|All updated. D-Don't thank me, it's your job.
*dnf upgrade*|ok|Hmph, everything's current. N-Not that I was keeping track.
*dnf upgrade*|ok|I-I suppose that was responsible of you.
ping *|ok|Hmph, the connection works. D-Don't thank me.
ping *|ok|S-See? The network's fine. I-I wasn't worried.
ping *|ok|Hmph, of course it works. Did you doubt me?
ping *|fail|Your internet is dead, idiot. Or the host is. Check the cable!
ping *|fail|Nothing answered, baka. Check your connection!
ping *|fail|Hmph, typical. Check the DNS too, idiot.
ssh *|fail|It refused you, baka. Check the host, the user and your key!
ssh *|fail|Hmph, locked out again? Check your key, idiot.
ssh *|fail|D-Don't just keep retrying blindly, baka.
cd *|fail|That folder doesn't exist, idiot. Look before you jump!
cd *|fail|Hmph, wrong path again? Pay attention, baka.
cd *|fail|Hmph, use tab completion next time, idiot.
vim *|ok|Done editing? ...Did you at least save it?
vim *|ok|Hmph, finished already? I-I hope you didn't just quit without saving.
vim *|ok|:wq, right? ...Right?!
nvim *|ok|Done editing? ...Did you at least save it?
nvim *|ok|Hmph, finished already? I-I hope you didn't just quit without saving.
nvim *|ok|:wq, right? ...Right?!
git status*|ok|Just checking up on things? Hmph, fine, I guess that's responsible.
git status*|ok|Checking again? Hmph, I-I suppose that's not a bad habit.
git status*|ok|Hmph, can't you just remember what you changed?
git push*|ok|P-Pushed? Fine. Hopefully the tests passed this time.
git push*|ok|Hmph, pushed. D-Don't make me worry about a broken build.
git push*|ok|D-Don't get used to me being proud of your pushes.
git push*|fail|The push failed, baka. Did you pull first?!
git push*|fail|Rejected? Hmph, pull first, idiot!
git push*|fail|Hmph, did you even check CI first?
git commit*|ok|A commit... with a good message, I hope?!
git commit*|ok|Hmph, committed. I-I hope you didn't just write "fix stuff".
git commit*|ok|I-I hope that message isn't just 'asdf'.
make*|fail|The build failed. Read the first error, not the last one, idiot!
make*|fail|Hmph, it didn't compile. D-Don't just stare at it, fix it!
make*|fail|Hmph, check your includes, baka.
docker *|fail|Docker complained. Is the daemon even running, baka?
docker *|fail|Hmph, that failed. Check your Dockerfile, idiot.
docker *|fail|D-Don't just restart it blindly, read the logs!
rm *|ok|It's gone for good, you know. ...I-I hope you meant it.
rm *|ok|Hmph, deleted. N-No undo button, you know.
rm *|ok|Hmph, I hope you didn't need that.
EOF

echo "Done."
```

To add more lines of any kind later, just append to the files. In `typo.txt`, every `%s` is replaced by the suggested command.

`reactions.txt` has one reaction per line in the form `pattern|when|message`.

| Part | Meaning |
|---|---|
| `pattern` | A glob matched against the whole command line, for example `sudo *` or `*apt upgrade*` |
| `when` | `ok` after success, `fail` after failure, `any` for both |
| `message` | What she says. If several lines match, one is picked at random |

Lines that start with `#` are comments.

---
## Part 3. Starship config

Replace `~/.config/starship.toml` with this. If you already have your own settings, keep them and only add the `custom.tsundere` block plus `${custom.tsundere}` in your format.

```toml
format = """
$directory$git_branch$git_status$cmd_duration ${custom.tsundere}
$character"""

[custom.tsundere]
command = "shuf -n1 $HOME/.config/tsundere/phrases.txt"
when = '[ ! -e "${XDG_CACHE_HOME:-$HOME/.cache}/tsundere/muted" ]'
format = "[$output]($style)"
style = "bold #AD2476"
```

The `when` line hides the phrase while she is muted with `tsun off`.

If the path disappears, run `STARSHIP_LOG=error starship prompt` to see the config error. Also check `echo $STARSHIP_CONFIG`, because if it is set, Starship reads that file instead.

---
## Part 4. The shell file

Save this as `~/.config/tsundere/tsundere.sh`. It is the whole brain of the setup. The settings sit at the top, see Part 9 for what they do.

```bash
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
```

---

## Part 5. Load order in .bashrc

The order matters. Put these four lines at the **very end** of `~/.bashrc`.

```bash
source ~/.local/share/blesh/ble.sh --noattach
eval "$(starship init bash)"
[[ -f ~/.config/tsundere/tsundere.sh ]] && source ~/.config/tsundere/tsundere.sh
[[ ${BLE_VERSION-} ]] && ble-attach
```

Why this order works.

1. ble.sh is sourced first, so `BLE_VERSION` is set.
2. Starship initializes after ble.sh.
3. Your tsundere file loads once ble.sh exists.
4. `ble-attach` runs last, which is what `--noattach` was waiting for.

Remove any older `source ble.sh` lines elsewhere in the file. Then run `source ~/.bashrc`.

---

## Part 6. Sudo insults

Run `sudo visudo` and add these near the other `Defaults` lines.

```
Defaults badpass_message="A-Are you serious?! You can't even type your own password, baka!"
Defaults passprompt="Password, baka: "
Defaults lecture=always
Defaults lecture_file=/etc/sudo_lecture
```

Then create the lecture file.

```bash
echo "D-Don't mess anything up, idiot." | sudo tee /etc/sudo_lecture
```

The bad password message is one fixed line. Random lines would need a wrapper around sudo, which is flaky, so it is skipped here.

---

## Part 7. Goodbye line

Add this to `~/.bash_logout` (create the file if it does not exist).

```bash
echo "Hmph, leaving already? N-Not that I care."
```

---

## Part 8. WezTerm config with the changing girl

### 8.1 Images

You need five PNGs with transparent backgrounds in `~/.config/tsundere/`, all the same size (280 by 368 pixels in this guide). Keep them the same size, otherwise the image jumps around when her expression changes. Draw them yourself or use art you have the rights to.

| File | Shown when |
|---|---|
| `normal.png` | Default, last command succeeded |
| `angry.png` | Last command failed |
| `happy.png` | Meter is at 10 |
| `surprised.png` | A dangerous command was typed or just finished |
| `sleepy.png` | 5 minutes without activity |

When she is muted with `tsun off`, no image is shown at all, so nothing extra is needed for that.

To test before you have real art, copy any PNG to all five names.

```bash
cd ~/.config/tsundere
for n in normal angry happy surprised sleepy; do cp ~/Downloads/yourimage.png $n.png; done
```

The config below sizes her as a percentage of the window height, 30 percent by default, and keeps the ratio of the images (280 by 368) so she never gets stretched. Change `HEIGHT_PCT` to make her bigger or smaller, and update `RATIO` if your own images have a different shape.

### 8.2 Config file

Create the folder with `mkdir -p ~/.config/wezterm`, then save this as `~/.config/wezterm/wezterm.lua`.

```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local dir = wezterm.home_dir .. '/.config/tsundere/'

-- Seconds without activity before she falls asleep
local SLEEP_AFTER = 300

-- How tall she is as a share of the window height (0.30 means 30 percent)
local HEIGHT_PCT = 0.30

-- Width divided by height of the image files (they are 280 by 368)
local RATIO = 280 / 368

-- Background color layer, change the hex to your taste
local function bg(img, w, h)
  local color = {
    source = { Color = '#1e1e2e' },
    width = '100%',
    height = '100%',
  }
  -- Muted with the tsun off command, no girl at all
  if img == 'off.png' then
    return { color }
  end
  return {
    color,
    {
      source = { File = dir .. img },
      vertical_align = 'Bottom',
      horizontal_align = 'Right',
      repeat_x = 'NoRepeat',
      repeat_y = 'NoRepeat',
      width = w,
      height = h,
      opacity = 0.9,
    },
  }
end

-- Starting size until the first status update measures the window
config.background = bg('normal.png', 210, 276)
config.status_update_interval = 1000

local state = {}

-- Runs every second. Reads the mood the shell sent, sizes her to the
-- window and swaps the image. Activity is detected from cursor movement
-- and mood changes.
wezterm.on('update-status', function(window, pane)
  local id = window:window_id()
  local dims = window:get_dimensions()
  local h = math.floor(dims.pixel_height * HEIGHT_PCT)
  local w = math.floor(h * RATIO)
  if h < 50 then
    return
  end

  local pos = pane:get_cursor_position()
  local mood = pane:get_user_vars().tsun_mood or 'normal'
  local sig = pos.x .. ',' .. pos.y .. ',' .. mood
  local now = os.time()

  local st = state[id]
  if not st then
    st = { sig = sig, t = now, shown = '', h = 0 }
    state[id] = st
  end

  if st.sig ~= sig then
    st.sig = sig
    st.t = now
  end

  local want = mood
  if mood ~= 'off' and now - st.t >= SLEEP_AFTER then
    want = 'sleepy'
  end

  if st.shown ~= want or st.h ~= h then
    st.shown = want
    st.h = h
    local overrides = window:get_config_overrides() or {}
    overrides.background = bg(want .. '.png', w, h)
    window:set_config_overrides(overrides)
  end
end)

return config
```

WezTerm reloads this file automatically when you save it. If you already had a config at `~/.wezterm.lua`, merge your settings into this file, because WezTerm prefers the one in `~/.config/wezterm/`.

### 8.3 How it works

After every command, the shell sends a hidden escape code with the current mood. WezTerm reads it once per second and swaps the background image. Because it is a real background and not text, nothing ghosts on resize. Sleepy mode works by watching the cursor position, so typing wakes her up.

### 8.4 Limits

* A wrong sudo password cannot trigger a mood change by itself, since sudo handles it and the shell never sees it. The failed sudo command afterwards sets a nonzero status, so she turns angry right after.
* Inside tmux the escape code needs passthrough enabled (`set -g allow-passthrough on`).
* Long running commands count as no activity, so she can fall asleep during a build.
* Desktop notifications cannot tell whether the terminal is in the foreground, so you also get one when you are looking at it. Set `MY_NOTIFY=0` in `~/.config/tsundere/tsundere.sh` to turn them off.

---
## Part 9. How the mood works

### Mood meter

| Event | Meter | Face and extras |
|---|---|---|
| Command succeeds | +1 (max 10) | Normal, or happy at 10 with a praise line |
| Command fails | -3 (min 0) | Angry and an insult |
| Mistyped command name | -3 | Angry, insult and a "did you mean" suggestion |
| Dangerous command | +1 if it succeeds | Panic line before it runs, surprised face |
| Command over 30 seconds | +1 | "Finally done" line |
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

Reaching a new level shows a special line. The lines for each level are in `praise-1.txt` to `praise-3.txt` and `insults-2.txt` and `insults-3.txt`.

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
| `MY_LEVEL_AT` | 0 100 400 1000 | Points needed for each affection level |

### Other behavior

* After a day without any command (`MY_AWAY_SECS`), the next terminal sets the meter back to 0 and she asks where you were. Affection points are kept.
* After two hours in the same terminal (`MY_BREAK_SECS`), she tells you to take a break, then again every two hours.
* Between 23:00 and 05:00 she sometimes nags you to go to sleep. She greets you when you open a terminal any time of day: morning (05:00-12:00), afternoon (12:00-17:00), evening (17:00-23:00), or night (23:00-05:00), each with its own lines.
* Notifications need `notify-send` (package `libnotify-bin` on Debian and Ubuntu, `libnotify` on Arch and Fedora).
* Several terminals share the same meter and stats through the files in `~/.cache`. If two commands finish at exactly the same moment, one count can get lost, which does not matter.

To reset everything, run `tsun reset`.

---
## Part 10. The tsun command

| Command | What it does |
|---|---|
| `tsun stats` | Shows today's successes and failures, best streaks, mood, affection level and a comment from her |
| `tsun off` | Mutes her completely, no lines, no phrase on the path line and no image. Good for screen sharing |
| `tsun on` | Brings her back |
| `tsun say` | Prints a random phrase |
| `tsun reset` | Asks first, then resets mood, stats and affection to zero |

The mute setting is a file, so it applies to all terminals at once and survives restarts.

---
## Part 11. Test checklist

Open a **new** WezTerm window, then try each of these.

| Test | Expected result |
|---|---|
| Open a new terminal | Greeting (morning, afternoon/evening or night), phrase on the path line |
| `asdfgh` | Insult, suggestion if a close command exists, angry girl |
| `gti status` | Insult and "did you mean `git`" |
| `ls /nonexistent` | Insult and angry girl |
| `echo hi` ten times in a row | Praise lines and happy girl at the 10th |
| `rm -rf /tmp/nothing` | Panic line and surprised girl |
| `sleep 31` | "Finally done" line afterwards |
| `sleep 61` with another window in front | Desktop notification (needs notify-send) |
| `ping -c1 nonexistent.invalid` | Her ping line |
| `sudo true` | Her sudo line |
| `git status` in a messy repo | Nag line |
| `tsun stats` | Counters, level and a comment |
| `tsun off` then a command | No lines, no girl, no phrase on the path line |
| `tsun on` | She is back |
| `sudo true` with a wrong password | Custom bad password message |
| Leave the terminal alone for 5 minutes | Sleepy girl, typing wakes her |
| `exit` | Goodbye line |

---
## Troubleshooting

| Problem | Fix |
|---|---|
| Nothing happens at all | Run `echo $BLE_VERSION`. If empty, ble.sh is not loaded before the tsundere line in `.bashrc` |
| Meter never goes up | Make sure you use the PREEXEC version of the script. Repeated commands are fine with it |
| She never panics on `rm -rf` | ble.sh may not pass the command to the PREEXEC hook. Tell me and I will switch the check |
| Two insults on a typo | The precmd must skip status 127, as in Part 4 |
| No "did you mean" line | Check `python3 --version` and that `typo.txt` exists |
| No reaction for a command | Check the pattern in `reactions.txt`. It is matched against the whole command line, so use `sudo *` and not `sudo` |
| Lines are missing | Run `bash ~/tsundere-lines.sh` again, it only creates the missing files |
| No notification | Check `command -v notify-send`, and that `MY_NOTIFY` is 1 and the command ran longer than `MY_NOTIFY_SECS` |
| She stays muted | Run `tsun on`, or delete `~/.cache/tsundere/muted` |
| Colors look wrong | Check `echo $COLORTERM` shows `truecolor` or `24bit` |
| Path missing in the prompt | Run `STARSHIP_LOG=error starship prompt` and check `$STARSHIP_CONFIG` |
| Phrase on the path line stays while muted | Update the `when` line in `starship.toml` as in Part 3 |
| Girl never changes | Check `echo $TERM_PROGRAM` says `WezTerm` and that all five PNG names match exactly |
| Background looks broken | Press `Ctrl+Shift+L` in WezTerm to open the debug overlay and read the error |
| No greeting | It only shows when `SHLVL` is 1, and only between 5 and 12 or 23 and 5 |
| `shuf` not found | Install coreutils |
| Ghost lines in scrollback | Run `clear` once, old ghosts do not vanish on their own |
