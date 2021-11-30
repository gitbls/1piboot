# 1piboot
Raspberry Pi customizable firstboot script

## Overview

1piboot uses a one-time service to perform early system configuration to help get your Pi up and running quickly, and configured the way you want.

**NOTE:** 1piboot has been superseded by [sdm](https://github.com/gitbls/sdm), which does everything that 1piboot does and much, much more. Check it out!

1piboot easily configures the new host hostname, locale, keymap, timezone, and wifi-country. Custom scripts enable more complex modifications (see examples).

Raspbian runs the rpi-firstboot service during the first boot of the system. Under normal circumstances, the service will only run during the first boot.

Currently you need to install 1piboot (or to leverage rpi-firstboot via your own mechanism) if you either build your new SD card on a Linux system, or do the small amount of 1piboot preparation on a Linux system before booting the SD card. Still need to sort out a reasonable, no-prerequisites required method on Windows to do the SD Card installation and     configuration.

## Installation and Use

This section describes how to prepare and install 1piboot onto your SD card.

### One-time Preparation

You'll need to copy the 1piboot files from GitHub.

* Copy the files from this GitHub to your local Linux system in an empty directory of your choice: 

    * `mkdir /path/to/mydir`
    * `cd /path/to/mydir`
    * `curl -l https://raw.githubusercontent.com/gitbls/1piboot/master/download-1piboot -o download-1piboot`
    * `bash download-1piboot`

    * To download the files manually, use:
        * `curl -L https://raw.githubusercontent.com/gitbls/1piboot/master/Install1piboot -o Install1piboot`
        * `curl -L https://raw.githubusercontent.com/gitbls/1piboot/master/rpi-firstboot.sh -o rpi-firstboot.sh`
        * `curl -L https://raw.githubusercontent.com/gitbls/1piboot/master/1piboot.conf -o 1piboot.conf`
        * `curl -L https://raw.githubusercontent.com/gitbls/1piboot/master/010-disable-triggerhappy.sh -o 010-disable-triggerhappy.sh`
        * `curl -L https://raw.githubusercontent.com/gitbls/1piboot/master/020-ssh-switch.sh -o 020-ssh-switch.sh`
        * `curl -L https://raw.githubusercontent.com/gitbls/1piboot/master/030-disable-rsyslog.sh -o 030-disable-rsyslog.sh`
        * `chmod 755 Install1piboot rpi-firstboot.sh 0*.sh`

* If there are other custom scripts that you want to run at first boot, name them in the format `0nn-something.sh` (e.g., 001-domything.sh) and place them in this same directory. These scripts will run during firstboot as root, so there is no need to use sudo anywhere in them. The 3 digits in the filename can be used for ordering the script execution (lower to higher).

* You can inhibit a 0*-*.sh custom script from being copied to the SD card by prepending a "." to the front of the name. For example, `mv 030-disable-rsyslog.sh .030-disable-rsyslog.sh`.

There are a couple of custom script examples in this github. You can use all or none of them, as desired.

* `010-disable-triggerhappy.sh` - Disables the TriggerHappy service. TriggerHappy can be disabled if you are not using the system-wide hotkeys provided by the TriggerHappy service.

* `020-ssh-switch.sh` - Disables the sshd service and enables a systemd-controlled ssh service that works identically to the sshd service, but is controlled by more lightweight.

* `030-disable-rsyslog.sh` - Disables the rsyslog service and enables a permanent journal. Use this if you don't need the text logs in /var/log. All system logs are visible with the `journalctl` command.

### Simple, Nearly Automatic One-command SD Card Configuration

* Copy the Raspbian distro to your SD card with whatever mechanism works for you
* Edit 1piboot.conf to set the configuration as desired. Leave the hostname as xxxxx, and it will be updated on the SD card when Install1piboot is run. See the section below for details on the format and contents of 1piboot.conf.

* `/path/to/Install1piboot /dev/sdX /path/to/mydir newhostname` - Copies the files to the Raspbian SD Card in /dev/sdX (replace **X** with the appropriate device letter). The new host will be named 'newhostname'

## What Happens When the System Boots the First Time?

When the system boots the first time, Raspbian starts the rpi-firstboot service, since it was enabled by Install1piboot. rpi-firstboot.sh performs the system configuration specified in /boot/1piboot/1piboot.conf. If 1piboot.conf has the directive `custom-scripts=True`, rpi-firstboot.sh will also execute each script in /boot/1piboot named `0*-*.sh`.

When rpi-firstboot.sh has completed, systemd will rename /boot/rpi-firstboot.sh to /boot/rpi-firstboot.sh.done so that the service does not execute again. This can be observed in the service file /etc/systemd/system/rpi-firstboot.service

1piboot's rpi-firstboot.sh actions are logged and can be reviewed in the system log after the system has completed booting.

After the first boot has completed and you've reviewed the logs, reboot the system and you're ready to go. Optionally, you can now disable the rpi-firstboot service with `sudo systemctl disable rpi-firstboot`

## 1piboot.conf

1piboot.conf directives are specified one per line. Each directive must be followed by a ':' or '='. Spaces are not allowed. hostname, locale, keymap, timezone, and wifi-country use code lifted directly from `raspi-config` to configure these settings.

* `hostname:xxxxx` - Sets the system host name to the specified name
* `locale:xxxxx` - Sets the system locale to the specified locale (e.g., *en_US.UTF-8*, etc)
* `keymap:xx` - Sets the keyboard keymap as specified (e.g., *us*)
* `timezone:xxxxx` - Sets the system timezone as specified (e.g., *America/Los_Angeles*)
* `wifi-country:XX` - Sets the WiFi country and enables WiFi (e.g., *US*)
* `service-enable:name` - Enables the specified service. A 1piboot.conf can contain multiple service-enable directives
* `service-disable:name` - Disables the specified service. A 1piboot.conf can contain multiple service-disable directives
* `custom-scripts:True` or `custom-scripts:False` - Specifies whether 1piboot should run any additional configuration scripts (named `0*-*.sh` and in /boot/1piboot)
