#######################################################################
#       Script de déploiement service DHCP made by K-lfa               #
#######################################################################
#!/bin/bash

if [ $(id | awk -F" " '{print$1}') != "uid=0(root)" ];then
	echo -e "\033[31;1mMust Be Root !\033[0m"       #Si non loggué root afficher must be root
else
	FILE=/etc/dhcp/dhcp.conf #Variable du fichier de configuration
	echo -e "\033[1mInstallation des paquets Bind9 ...\033[0m\n"                    #Installation des paquets necessaires
	apt-get update > /dev/null && apt-get install isc-dhcp-server -y > /dev/null
	mv /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.old
	read -p "Quel est le nom de domaine a diffuser ? : " DOMAINAME
	read -p "Quel est l'IP du serveur DNS ? : " DNSSERVER
	read -p "Quel est la plage d'IP ? : " SUBNET
	read -p "Quel est le masque ? : " MASK
	read -p "Quel est la plage d'IP d'exception ? (Ex : 192.168.1.20 192.168.1.30) : " LEASERANGE
	read -p "Quel est l'adresse de broadcast ? : " BCASTADD
	read -p  "Quel l'adresse de la passerelle ? : " GATEWAY

	cat <<EOF>> $FILE
		#Nom de domaine
		option domain-name	"$DOMAINAME";

		#Serveur DNS
		option domain-name-servers	$DNSSERVER;

		#Bail par défaut
		default-lease-time 1200;

		#Bail maximum
		max-lease-time 7200;

		#Serveur déclaré
		authoritative;

		#Subnet & Subnet Mask
		subnet $SUBNET netmask $MASK {
		#Range Subnet lease
		range dynamic-bootp $LEASERANGE;
		#Broadcast Address
		option broadcast-address $BCASTADD;
		#Gateway
		option routers $GATEWAY
		}
EOF

fi
