#!/bin/bash

SSID="$2"
PASSWORD="$3"

case "$1" in
	connect)
		if [[ -z $2 ]] || [[ -z $3 ]]; then
			echo "Set SSID and Password"
			exit 1
		fi
		# Add "network{}" section to "wpa_supplicant.conf"
		echo "Enable WiFi and connect to SSID=$2 and PASSWORD=$3"
		WPA_SUPPLICANT=`cat /etc/wpa_supplicant/wpa_supplicant.conf`
		if [[ $WPA_SUPPLICANT != *"network={"* ]]; then
			echo -e "network={\n\tssid=\"$2\"\n\tpsk=\"$3\"\n}" >> /etc/wpa_supplicant/wpa_supplicant.conf
			ifup wlan0
		fi
		;;
	disconnect)
		# Remove "network{}" section from "wpa_supplicant.conf"
		echo "Disable WiFi client mode and disconnect"
		ifdown wlan0
		sed -i '/network={/,/}/d' /etc/wpa_supplicant/wpa_supplicant.conf
		;;
	status)
		# Check wifi connection status
		if ifconfig wlan0 | grep -q "inet addr:"; then
			echo "connected"
		else
			echo "disconnected"
		fi
		;;
	ip)
		# Get IP WiFi address
		ifconfig wlan0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'
		;;
	*)
		echo "Usage: client.sh {connect|disconnect|status|ip}"
		exit 1
		;;
esac