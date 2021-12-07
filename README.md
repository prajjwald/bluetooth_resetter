# Bluetooth Resetter

## A Brute Force Attempt to Reconnect Bluetooth and Get Bluetooth Audio Working Without Restarting

### Overview

This script attempts to solve a very annoying problem in Ubuntu 20.04+, where bluetooth devices (I have had problems with multiple headphones) - bluetooth audio either mysteriously stops playing after a while, then refuses to reconnect, or I have to un-pair, then re-pair my headphones, or I have to restart the computer entirely to get it working.

This is how it does it (with reasonable success for me):

- turn bluetooth off using ```rfkill```
- unload as many bluetooth modules as it can using ```rmmod```
- sleep for 3 seconds, which can be overridden in the command line
- load the unloaded bluetooth modules again, using ```modprobe```
- turn bluetooth on using ```rfkill```

### QuickStart

```bash
git clone https://github.com/prajjwald/bluetooth_resetter.git
cd bluetooth_resetter
#default is 3 seconds, but let's do 10, just to be safe
sudo bin/bluetooth_reset.sh 10
```

Or do as I do (I think you're going to need this more than once, unfortunately):

```bash
sudo cp bin/bluetooth_reset.sh
#default is 3 seconds, but let's do 10, just to be safe
sudo bluetooth_reset.sh 10
```


### Recommendations 

- The *blueman* utility is very helpful, and is easy to install - just run ```sudo apt -y install blueman``` - this is **highly recommended**

- Even if this script works for you, do skim through my **[bluetooth notes](bluetooth_notes.md)** - they have some general observations/helpful links I found.  They are pretty basic though.

Feel free to share/suggest your own notes too.  I really hope this helps you (if you're here, I assume you're suffering, just like I was).

#### Some Observations Leading to the Script

- blueman has helped - it works better than the Gnome applet/settings when things go awry. Error messages are also more helpful.
- even when connected - the bluetooth audio might stop working after some inactivity(?) - though it has also stopped working at times even when I was using it (audio switched to speakers)
- a restart seems to fix the problem temporarily
- blueman has shown me that my bluetooth connection doesn't seem too optimal
- turning Bluetooth Off and then back on doesn't seem to help
- a combination of rmmod with lsmod seems to fix the issue without rebooting

With these observations at hand, [this](bin/bluetooth_reset.sh) is my current attempt at a script that seems to somewhat help.

### Some Things That Would Be Nice To Have (but Aren’t There Yet)

#### Upgraded (or Even Downgraded) bluez

From reading forums online (seems I didn't bookmark that particular link 😥)I did read that bluez version I have (5.60) has a known bug - I should either downgrade to 5.58 iirc (21.10 only has 5.60), or upgrade to git (I did try building it a bit, but gave up - didn't want to fight the build too much).  The other option was to add the ppa - ```sudo add-apt-repository ppa:bluetooth/bluez``` - **unfortunately, they don't have a release for impish yet**.
