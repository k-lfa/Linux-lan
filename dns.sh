#######################################################################
#	Script de déploiement service DNS made by K-lfa		      #
#######################################################################
#!/bin/bash

SERVER=$(hostname)

if [ $(id | awk -F" " '{print $1}') == "uid=0(root)" ];then		#Veriication si connecté en root

	echo -e "\033[1mInstallation des paquets Bind9 ...\033[0m\n"			#Installation des paquets necessaires
	apt-get update > /dev/null && apt-get install bind9 -y > /dev/null
	mkdir /etc/bind/old
	mv /etc/bind/db.* /etc/bind/old/

	echo -e "\033[1mCréation de la zone principale\033[0m"
	read -p "Quel est le nom de domaine ? :  " DOMAINAME		#Saisi du nom de domaine
	echo -e "\nCréation du fichier db.$DOMAINAME"
	mv /etc/bind/old/db.empty /etc/bind/db.$DOMAINAME		#Création de la db nom de domaine
	read -p "Quelle est l'adresse IP du serveur DNS maitre ? : " IP #Saisi de l'IP du serveur
	FIRSTBYTE=`echo $IP | awk -F"." '{print$1}'`
	SECONDBYTE=`echo $IP | awk -F"." '{print$2}'`
	THIRTYBYTE=`echo $IP | awk -F"." '{print$3}'`
	LASTBYTE=`echo $IP | awk -F"." '{print $4}'`
	sed -i -e '/^@/,/@/d' /etc/bind/db.$DOMAINAME							#Suppression des données de la zone
	cat << EOF >> /etc/bind/db.$DOMAINAME							#Ajout des données de la zone dans le fichier de configuration
@	IN	SOA	$SERVER.$DOMAINAME. root.$DOMAINAME. (
	1	;serial
	604800		; Refresh
	86400		; Retry
	2419200		; Expire
	86400 )	; Negative Cache TTL
;
@	IN	NS 	$SERVER.$DOMAINAME.
$SERVER IN	A	$IP
EOF

	echo -e "\n\033[1mCréation de la zone reverse\033[0m"
	cp /etc/bind/db.$DOMAINAME /etc/bind/db.$DOMAINAME.rev
	sed -i 's/^'"$SERVER"'.*/'"$LASTBYTE"'	IN	PTR	'"$SERVER"'.'"$DOMAINAME"'./' /etc/bind/db.$DOMAINAME.rev

	echo -e "\n\033[1mConfiguration de la zone principale $DOMAINAME\033[0m"
	cat << EOF >> /etc/bind/named.conf.local 
	 	zone "$DOMAINAME" {
	 	type master;
	 	file "/etc/bind/db.$DOMAINAME";
	 	allow-query { any; };
	 	};
	 	zone "$THIRTYBYTE.$SECONDBYTE.$FIRSTBYTE.in-addr.arpa" {
	 	type master;
	 	file "/etc/bind/db.$DOMAINAME.rev";
	 	};
EOF

	while [ "$REDIR" != "n" ]
	do
		read -p "Ajouter des redirecteurs inconditionels ? y/n : " REDIR
		if [ "$REDIR" = "y" ];then
			read -p "Ajouter l'IP du serveur DNS forwarder exemple: 8.8.8.8   : " IPFORW
			sed -i 's/^.*forwarders {/      forwarders {/' /etc/bind/named.conf.options
                        sed -i 's/^.*0.0.0.0;/  '"$IPFORW"';/' /etc/bind/named.conf.options
		elif [ "$REDIR" = "n" ];then
		#Verifier si IP dans fichier
		sed -i 's/*^.\/\/ };/};/g' /etc/bind/named.conf.options
		else
		echo -e "\033[1mEntrez y ou n\033[0m"
		fi
	done

	while [ -z "$ENRCH" ] || [ "$ENRCH" != "n" ]
	do
		read -p "Ajouter des enregistrements A ? y/n : " ENRCH

		if [ "$ENRCH" = "y" ];then
			read -p "Entrez le nom court de l'hôte : " NAMEA
                        read -p "Entrez l'adresse IP de l'hôte : " IPA
                        LASTBYTE=`echo $IPA | awk -F"." '{print $4}'`
                        echo "$NAMEA    IN      A       $IPA" >> /etc/bind/db.$DOMAINAME
                        echo "$LASTBYTE IN      PTR     $NAMEA." >> /etc/bind/db.$DOMAINAME.rev
		elif [ "$ENRCH" = "n" ];then
			echo -e "\n\033Test de la zone DNS\033[0m\n"
                        named-checkzone $DOMAINAME /etc/bind/db.$DOMAINAME
                        echo -e "\n\033[1mRedémarrage du service BIND\033[0m"
                        service bind9 restart
			service bind9 status
                        exit
		else
			echo -e "\033[1mEntrez y ou n\033[0m"
                fi
        done

else
	echo -e "\033[31;1mMust Be Root !\033[0m"	#Si non loggué root afficher must be root
fi
