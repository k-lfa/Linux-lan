############################################################################
#     Script d'installation de routeur simple Linux make by K-lfa	   #
############################################################################
#!/bin/bash

if [ $(id | awk -F" " '{print $1}') == "uid=0(root)" ];then

ip -4 -o addr show | awk -F" " '{print $2}' 

read -p "Quel est l'interface WAN ? :   " WAN
read -p "Quel est l'interface LAN a router ? :  " LAN

	if [ $(cat /etc/sysctl.conf | grep -co '^net.ipv4.ip_forward=1') -eq 0 ];then
	sed -ne 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
	sysctl -p
	else
	echo "NAT déja activé"
	fi

iptables -t nat -A POSTROUTING -o $WAN -j MASQUERADE
iptables -t nat -L POSTROUTING

else

echo -e "\033[31;1mMust Be Root !\033[0m"
fi
