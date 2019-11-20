# 1piboot
Raspberry Pi customizable firstboot script

## Overview

1piboot leverages the Raspbian Buster rpi-firstboot service to perform early system configuration to help get your Pi up and running quickly, and configured the way you want.

Raspbian runs the rpi-firstboot service during the first boot of the system. Under normal circumstances, the service will not run after the first boot, since the script is renamed.

At the current time, it's easiest to install 1piboot (or to leverage rpi-firstboot via your own mechanism) if you either build your new SD card on a Linux system, or do a small amount of SD card post-configuration on a Linux system before booting the SD card. Still need to figure out a reasonable way to do the installation and configuration onto the SD card on Windows.

## Installation and Use

Copy the files from this github to your local Linux system: rpi-firstboot.sh, 1piboot.conf, and the 0*-*.sh scripts (if desired).

After you have copied the Raspbian distro to your SD card, perform the following steps on a Linux system:

* `sudo mount /dev/sdX1 /mnt` - Mounts the SD card on your Linux system. Change **X** as appropriate on your Linux system

* `sudo cp rpi-firstboot.sh /mnt` - Copies the rpi-firstboot.sh script to /boot on the SD card

* `sudo mkdir /mnt/1piboot` - Makes the configuration directory /boot/1piboot for 1piboot on the SD card

* `sudo cp 1piboot.conf /mnt/1piboot` - Copies the 1piboot configuration script to the SD card. *Be sure to edit the sample 1piboot.conf and change the settings as desired.*

* If there are other scripts that you want to run at first boot, name them in the format `0nn-something.sh` (e.g., 010-domything.sh) and sudo copy them to the /mnt/1piboot directory. Make sure that they are executable (`chmod 755`). These scripts will run as root, so there is no need to use sudo anywhere in them. There are a couple of examples in this github:

    * `010-disable-triggerhappy.sh` - Disables the TriggerHappy service, and can be used if you are not using system-wide hotkeys provided by the TriggerHappy service.
    * `020-ssh-switch.sh` - Disables the sshd service and enables an ssh service that works identically to the sshd service, but is controlled by systemd.
    * `030-disable-rsyslog.sh - Disables the rsyslog service and enables a permanent journal. Use this if you don't need the text logs in /var/log. All system logs are visible with the `journalctl` command.

* `sudo umount /mnt` - Dismounts the SD card boot partition

* `sudo mount /dev/sdX2 /mnt` - Mounts the 2nd SD card partition 

* `sudo ln -s /etc/systemd/system/rpi-firstboot.service /mnt/etc/systemd/system/multi-user.target.wants/rpi-firstboot.service` - Enables the rpi-firstboot service to start on the first boot of the newly built SD card

* `sudo umount /mnt` - Dismounts the SD card, and it's ready to boot

When the system boots the first time, Raspbian starts the rpi-firstboot service, since it was enabled via the *sudo ln* command above. rpi-firstboot.sh performs the system configuration specified in /boot/1piboot/1piboot.conf. If 1piboot.conf has the directive `custom-scripts=True`, rpi-firstboot.sh will also execute each script in /boot/1piboot named `0*-*.sh`.

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
