#!/bin/bash
# 1. apt-get install udhcpd hostapd
#
# 2. Create a file /etc/network/interfaces:
#
#auto lo
#iface lo inet loopback
#auto eth0
#allow-hotplug eth0
#iface eth0 inet manual
#auto wlan0
#allow-hotplug wlan0
#iface wlan0 inet manual
#wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf

# 3. Create a file /etc/udhcpd.conf
# 
#start 192.168.3.2 # This is the range of IPs that the hostspot will give to client devices.
#end 192.168.3.10
#interface wlan0 # The device uDHCP listens on.
#remaining yes
#opt dns 8.8.8.8 4.2.2.2 # The DNS servers client devices will use.
#opt subnet 255.255.255.0
#opt router 192.168.3.1 # The Pi's IP address on wlan0 which we will set up shortly.
#opt lease 864000 # 10 day DHCP lease time in seconds

# 4. Create file /etc/hostapd/hostapd.conf 
#
#interface=wlan0
#driver=nl80211
#ssid=qwerty
#hw_mode=g
#channel=6
#macaddr_acl=0
#auth_algs=1
#wpa=2
#wpa_passphrase=12345678
#wpa_key_mgmt=WPA-PSK
#wpa_pairwise=TKIP
#rsn_pairwise=CCMP

SSID="$2"
PASSWORD="$3"

case "$1" in
	start)
		if [[ -z $2 ]] || [[ -z $3 ]]; then
			echo "Set SSID and Password"
			exit 1
		fi
		echo "Create WiFi AP with SSID=$2 and PASSWORD=$3"
		# Add ssid to hostapd.conf
		sed -i "/ssid=/c\ssid=$2" /etc/hostapd/hostapd.conf
		# Add password to hostapd.conf
		sed -i "/wpa_passphrase=/c\wpa_passphrase=$3" /etc/hostapd/hostapd.conf
		# Remove wlan0 from /etc/network/interfaces
		sed -i "/allow-hotplug wlan0/d" /etc/network/interfaces
		sed -i "/iface wlan0 inet manual/d" /etc/network/interfaces
		sed -i "/wpa-conf \/etc\/wpa_supplicant\/wpa_supplicant.conf/d" /etc/network/interfaces
		
		# Configure NAT
		echo 1 > /proc/sys/net/ipv4/ip_forward
		iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
		iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

		# Start hostapd and dhcp server
		hostapd -B /etc/hostapd/hostapd.conf

		# Set wlan0 IP address
		ip addr add 192.168.3.1/24 dev wlan0
		udhcpd /etc/udhcpd.conf
		;;
	stop)
		INTERFACES=`cat /etc/network/interfaces`
		# Add wlan0 to /etc/network/interfaces
		if [[ $INTERFACES != *"allow-hotplug wlan0"* ]]; then
			echo -e "allow-hotplug wlan0\niface wlan0 inet manual\nwpa-conf /etc/wpa_supplicant/wpa_supplicant.conf" >> /etc/network/interfaces
		fi
		killall hostapd udhcpd
		# Remove wlan0 IP address
		ip addr del 192.168.3.1/24 dev wlan0

		# Disable NAT
		echo 0 > /proc/sys/net/ipv4/ip_forward
		;;
	*)
		echo "Usage: accessPoint.sh {start|stop}"
		exit 1
		;;
esac