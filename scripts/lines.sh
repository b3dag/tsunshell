#!/usr/bin/env bash
# Creates all phrase files for the tsundere terminal.
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

# Main files in ~/.config

mk ~/.config/tsundere-phrases.txt << 'EOF'
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
EOF

mk ~/.config/tsundere-insults.txt << 'EOF'
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
EOF

mk ~/.config/tsundere-praise.txt << 'EOF'
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
EOF

# Extra lines in ~/.config/tsundere

mk ~/.config/tsundere/danger.txt << 'EOF'
W-Wait! Are you sure about that?!
H-Hey! That's dangerous, you idiot!
D-Don't blame me if everything disappears!
Y-You better have a backup, baka!
Eh?! Th-Think about what you're doing!
I-I'm not saving you if this goes wrong!
EOF

mk ~/.config/tsundere/morning.txt << 'EOF'
Hmph, you're up early. N-Not that I noticed.
G-Good morning... I guess. Don't read into it!
Did you even sleep? Whatever, let's work.
EOF

mk ~/.config/tsundere/night.txt << 'EOF'
Go to sleep already, baka!
It's late! I-I'm not worried, you just look terrible.
Hmph, up this late again? Idiot.
D-Don't ruin your health on my account!
EOF

mk ~/.config/tsundere/slow.txt << 'EOF'
F-Finally done, I was getting bored!
Hmph, that took forever. N-Not that I was waiting.
It's done... a-and I didn't even fall asleep. Barely.
EOF

mk ~/.config/tsundere/git-dirty.txt << 'EOF'
Commit your stuff already, baka! That's a mess!
S-So many changed files... do you ever clean up?!
That working tree is a disaster, idiot.
EOF

mk ~/.config/tsundere/git-clean.txt << 'EOF'
Hmph. A clean tree. N-Not bad.
Everything's committed? ...G-Good. I guess.
Y-You actually cleaned up. I'm... mildly impressed.
EOF

mk ~/.config/tsundere/typo.txt << 'EOF'
D-Did you mean `%s`? Idiot.
Hmph, it's obviously `%s`, baka!
It's `%s`. Can't you even spell?!
I-I guess you meant `%s`... don't thank me!
EOF

mk ~/.config/tsundere/break.txt << 'EOF'
You've been here for hours, baka! Stand up and drink some water.
Take a break already! ...I-I'm not worried, your posture just looks terrible.
Hmph, your eyes will fall out. Look at something far away for a minute!
S-Stretch your back at least, idiot!
EOF

mk ~/.config/tsundere/away.txt << 'EOF'
Where were you?! ...N-Not that I was waiting or anything!
You disappeared for a whole day, baka! I-I didn't miss you!
Hmph, so you finally remembered I exist. Don't leave for so long next time!
EOF

mk ~/.config/tsundere/rare.txt << 'EOF'
...You know, you're not that bad at this. D-Don't let it get to your head!
I-I kind of like watching you work. Just a little! Shut up!
Th-That was actually really cool... forget I said that!
D-Don't smile at the screen like that! ...I-I'm smiling too, I guess.
EOF

mk ~/.config/tsundere/levelup.txt << 'EOF'
...Fine. I'll be a little nicer to you now. J-Just a little!
You've earned some respect, baka. D-Don't get cocky!
Hmph. I-I guess we're getting along better. N-Not that I care!
EOF

# Affection levels. Level 0 uses the main files in ~/.config

mk ~/.config/tsundere/praise-1.txt << 'EOF'
Not bad at all. ...D-Don't let it go to your head!
You're improving, baka. I-I noticed.
G-Good job. That's all I'm saying!
Keep going. I-I'm kind of impressed.
EOF

mk ~/.config/tsundere/praise-2.txt << 'EOF'
That was really good! ...I-I mean, it was okay.
I-I'm actually proud of you. A little! Just a little!
Y-You're getting good at this. I'm not surprised... much.
Great work. ...Don't make me say it twice!
EOF

mk ~/.config/tsundere/praise-3.txt << 'EOF'
Y-You did great today! I'm really happy to watch you work.
That was perfect. ...I-I like it when you do well.
Keep it up, okay? I'll be right here cheering for you!
I-I'm proud of you. Really. Don't look at me like that!
EOF

mk ~/.config/tsundere/insults-2.txt << 'EOF'
It failed... b-but everyone makes typos. Try again.
Hmph, that was close. Check your spelling, okay?
D-Don't give up, baka. Fix it and run it again.
...That wasn't your best. I-I know you can do better.
Tch. Just a small mistake. Read the error message!
EOF

mk ~/.config/tsundere/insults-3.txt << 'EOF'
O-Oh no, it failed... a-are you okay? Try again!
It's alright. Everyone fails sometimes... I-I'll wait.
D-Don't be sad! Look at the error, we'll fix it together.
...Y-You'll get it next time. I believe in you. J-Just a bit!
I-It's okay. Take a breath and try once more.
EOF

# Command specific reactions
# Format  pattern|when|message
# pattern is a glob matched against the whole command line
# when is ok, fail or any

mk ~/.config/tsundere/reactions.txt << 'EOF'
sudo *|ok|S-So you needed admin rights again? Don't break the system!
sudo *|fail|You couldn't even get sudo right, baka!
*apt update*|ok|Fine, the package lists are fresh. N-Not that I care.
*apt upgrade*|ok|Updating everything again? A-As long as nothing breaks, I guess.
*pacman -Syu*|ok|A full system update? Pray that nothing breaks, idiot.
*dnf upgrade*|ok|All updated. D-Don't thank me, it's your job.
ping *|ok|Hmph, the connection works. D-Don't thank me.
ping *|fail|Your internet is dead, idiot. Or the host is. Check the cable!
ssh *|fail|It refused you, baka. Check the host, the user and your key!
cd *|fail|That folder doesn't exist, idiot. Look before you jump!
vim *|ok|Done editing? ...Did you at least save it?
nvim *|ok|Done editing? ...Did you at least save it?
git push*|ok|P-Pushed? Fine. Hopefully the tests passed this time.
git push*|fail|The push failed, baka. Did you pull first?!
git commit*|ok|A commit... with a good message, I hope?!
make*|fail|The build failed. Read the first error, not the last one, idiot!
docker *|fail|Docker complained. Is the daemon even running, baka?
rm *|ok|It's gone for good, you know. ...I-I hope you meant it.
EOF

echo "Done."
