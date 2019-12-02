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

cfgfile="/boot/1piboot/1piboot.conf"
[ ! -f $cfgfile ] && logger "1piboot Config file $cfgfile not found...skipping" && exit
logger "1piboot Starting Configuration..."
IFS=":="
while read rpifun value
do
    if [[ ! $rpifun =~ ^\ *# && -n $rpifun ]] # skip comment and malformed lines
    then
	value="${value%%\#*}"    # Del EOL comments
	value="${value%"${value##*[^[:blank:]]}"}"  # Del trailing spaces/tabs
	value="${value%\"}"     # Del opening double-quotes 
	value="${value#\"}"     # Del closing double-quotes 
	value="${value%\'}"     # Del opening single-quotes 
	value="${value#\'}"     # Del closing single-quotes 
	case "$rpifun" in
	    locale)
		logger "1piboot Setting locale to $value..."
		raspi-config do_change_locale "$value" nonint
		declare -x LANG="$LOCALE"
		;;
	    hostname)
		logger "1piboot Setting hostname to $value..."
		raspi-config do_hostname "$value" nonint
		hostnamectl set-hostname $value
		;;
	    keymap)
		logger "1piboot Setting keyboard to $value..."
		raspi-config do_configure_keyboard "$value" nonint
		;;
	    timezone)
		logger "1piboot Setting timezone to $value..."
		raspi-config do_change_timezone "$value" nonint
		;;
	    wifi-country)
		logger "1piboot Setting WiFi country to $value..."
		raspi-config do_wifi_country "$value" nonint
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
    fi
done < $cfgfile
logger "1piboot done"
