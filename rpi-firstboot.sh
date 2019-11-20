#!/bin/bash
#
# Runs on first RPi boot to configure system on the first boot
#
# Config file: /boot/1piboot/1piboot.conf
#    Separate keyword and value with '=' or ':'
#
#    locale=en_US.UTF-8
#    hostname:xxxxx
#    keymap=us
#    timezone=America/Los_Angeles
#    wifi-country=US
#    service-enable=servicename
#    service-disable=servicename
#    custom-scripts=True or False (must be in /boot/1piboot, executable [chmod 755], and named 0*-*.sh)

list_wlan_interfaces() {
  for dir in /sys/class/net/*/wireless; do
    if [ -d "$dir" ]; then
      basename "$(dirname "$dir")"
    fi
  done
}

IFS=":="
cfgfile="/boot/1piboot/1piboot.conf"
[ ! -f $cfgfile ] && logger "1piboot Config file $cfgfile not found...skipping" && exit
logger "1piboot Starting Configuration..."
while read rpifun value
do
    case "$rpifun" in
	locale)
	    logger "1piboot Setting locale to $value..."
	    LOCALE="$value"
	    LOCALE_LINE="$(grep "^$LOCALE " /usr/share/i18n/SUPPORTED)"
	    ENCODING="$(echo $LOCALE_LINE | cut -f2 -d " ")"
	    echo "$LOCALE $ENCODING" > /etc/locale.gen
	    sed -i "s/^\s*LANG=\S*/LANG=$LOCALE/" /etc/default/locale
	    dpkg-reconfigure -f noninteractive locales
	    declare -x LANG="$LOCALE"
	;;
	hostname)
	    logger "1piboot Setting hostname to $value..."
	    NEW_HOSTNAME="$value"
	    CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
	    echo $NEW_HOSTNAME > /etc/hostname
	    sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
	    echo "$(date +'%Y%m%d-%H%M%S') Disk for $NEW_HOSTNAME built" > /DISKINFO
	;;
	keymap)
	    logger "1piboot Setting keyboard to $value..."
	    KEYMAP="$value"
	    sed -i /etc/default/keyboard -e "s/^XKBLAYOUT.*/XKBLAYOUT=\"$KEYMAP\"/"
	    dpkg-reconfigure -f noninteractive keyboard-configuration
	    invoke-rc.d keyboard-setup start
	    setsid sh -c 'exec setupcon -k --force <> /dev/tty1 >&0 2>&1'
	    udevadm trigger --subsystem-match=input --action=change
	;;
	timezone)
	    logger "1piboot Setting timezone to $value..."
	    TIMEZONE="$value"
	    rm /etc/localtime
	    echo "$TIMEZONE" > /etc/timezone
	    dpkg-reconfigure -f noninteractive tzdata
	;;
	wifi-country)
	    logger "1piboot Setting WiFi country to $value..."
	    IFACE="$(list_wlan_interfaces | head -n 1)"
	    if [ -z "$IFACE" ]; then
		logger "1piboot No wireless interface found"
	    else
		if ! wpa_cli -i "$IFACE" status > /dev/null 2>&1; then
		    logger "1piboot Could not communicate with wpa_supplicant"
		else
		    COUNTRY="$value"
		    wpa_cli -i "$IFACE" set country "$COUNTRY"
		    iw reg set "$COUNTRY" 2> /dev/null
		    rfkill unblock wifi
		    wpa_cli -i "$IFACE" save_config > /dev/null 2>&1
		fi
	    fi
	;;
	service-enable)
	    logger "1piboot Enabling service $value"
	    systemctl enable $value
	;;
	service-disable)
	    logger "1piboot Disabling service $value"
	    systemctl disable $value
	;;
	custom-scripts)
	    if [ "$value" == "True" ]
	    then
		for f in /boot/1piboot/0*-*.sh
		do
		    if [ -x $f ]
		    then
			logger "1piboot Executing custom 1piboot script $f"
			sh $f
		    else
			logger "1piboot custom 1piboot script $f does not have execute permission"
		    fi
		done
	    else
		logger "1piboot Skipping custom 1piboot scripts"
	    fi
	;;
	*)
	    [ "$rpifun" != "" ] && $logger "1piboot Unrecognized command line: $rpifun"
	;;
    esac
    
done < $cfgfile
logger "1piboot done"
