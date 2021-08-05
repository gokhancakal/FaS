#!/bin/sh
# by Gökhan ÇAKAL
#FaS v0.9


#VARIABLES
#COLORS
normal=`echo "\033[m"`
bl=`echo "\033[36m"` 
yel=`echo "\033[33m"`
gr=`echo "\033[0;32m"`
rd=`echo "\033[01;31m"`
bgrd=`echo "\033[41m"`

#OTHERS
chk_nbr='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
hostname=$(cat /proc/sys/kernel/hostname)
hostname_f=$(hostname -f)
hostname_s=$(hostname -s)
ip=$(ip addr | grep -Po '(?!(inet 127.\d.\d.1))(inet \K(\d{1,3}\.){3}\d{1,3})')
gateway=$(ip route show default | awk '/default/ {print $3}')
ni=$(nmcli -t --fields NAME con show --active)
s_dns1=$(cat /etc/resolv.conf |grep -i '^nameserver'|cut -d ' ' -f2 | awk 'NR==1{print $1}')
s_dns2=$(cat /etc/resolv.conf |grep -i '^nameserver'|cut -d ' ' -f2 | awk 'NR==2{print $1}')
ip_prefix=$(ip addr show |grep -w inet |grep -v 127.0.0.1|awk '{ print $2}'| cut -d "/" -f 2)
hosts_ip1=$(grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" /etc/hosts | grep -v '127.0.0.1' | cut -d":" -f2)
hosts_ip2=$(grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" /etc/ansible/hosts | grep -v '127.0.0.1' | cut -d":" -f2)
all_hosts=$(grep all_hosts /etc/ansible/hosts) 
	
#CONTROL VALUES
c_value=false
c_value2=false
c_value3=false
c_value4=false
lv_value=false
yum_value=false
ansible_value1=false
ansible_value2=false
ansible_value3=false
ansible_value=x	

#MENU
ansible_m="ANSIBLE CONFIGURATION "
ansible_m1="INSTALL ANSIBLE        "
ansible_m2="ADD HOSTS TO ANSIBLE"
ansible_m3="REMOVE HOSTS FROM ANSIBLE"
ansible_m4="EXECUTE COMMAND "
ansible_m5="DISABLE SELX AND FW   "
ansible_m6="                 "
ansible_m7="                      "
m1="STATIC IP CONFIGURATION"
m2="ADD HOST            "
m3="DISABLE SELINUX          "
m4="DISABLE FIREWALL"
m5="INSTALL AND ENABLE NTP"
m6="INSTALL JAVA(1.8)"
m7="LOGICAL VOLUME MANAGER"
lv_m1="LVM EXTEND             "
lv_m2="LVM REDUCE          "
lv_m3="                         "
lv_m4="                "
lv_m5="                      "
lv_m6="                 "
lv_m7="                      "
back="BACK                  "

#FUNCTIONS#
#CONTROL
ip_control(){
	if [[ $1 == "\n" ]] || [[ $1 == "" ]]; then		
		c_value=false	
	else
		if [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			c_value=true
		else
			c_value=false
		fi
	fi
}

dns_control(){
	if [[ $1 == "\n" ]] || [[ $1 == "" ]]; then		
		c_value=false
	else
		if [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			c_value=true
		else
			c_value=false
			printf "${rd}\nDNS VALUE NOT GOING TO BE CHANGE${normal}\n";
		fi
	fi
}

lv_control(){
	if [ -d "$1" ] ;then
		lv_value=true
	else
		printf "${rd}\nDIRECTORY DOESN'T EXIST${normal}\n";
		printf "${rd}EXITING..${normal}\n";
		lv_value=false
	fi
}

yum_control(){
  if yum list installed "$@" >/dev/null 2>&1; then
    yum_value=true
  else
    yum_value=false
  fi
}


#ANSIBLE
ansible_control1(){
	if [[ $all_hosts ]]; then
		ansible_value1=true
	else
		ansible_value1=false	
	fi
}

ansible_control2(){
	if [[ $hosts_ip1 == $hosts_ip2 ]]; then
        ansible_value2=true
	else
        ansible_value2=false
	fi
}

ansible_control3(){
#	host_check=$(cat /etc/hosts |grep -i '$@'|cut -d ' ' -f1 | awk 'NR==1{print $1}')
#	if cat /etc/hosts |grep -i '$@'|cut -d ' ' -f1 | awk 'NR==1{print $1}' ; then
#	if cat /etc/ansible/hosts | grep -i '$@' ; then
	if  grep -q "$ansible_value" /etc/hosts ; then
		ansible_value3=true;
	else
		ansible_value3=false;
	fi
}

host_remove_ansible(){
	sed -i  /^$@.*$/d /etc/ansible/hosts
}

ansible_execute(){	
	while [[ $execute != "done" ]];
		do
		read -p "$(echo -e "${bl}CODE =  "${normal})" execute
		if [[ $execute == "done" ]]; then
			printf "${gr}\nSUCCESSFULLY COMPLETED${normal}\n";
			sleep 2; exit;
		else
			ansible all_hosts -m shell -a "$execute"				
		fi
		done
}


#ADD OR CHANGE
ip_change(){
	if [[ $2 == "gateway" ]]; then
		gw=$1
		sed -i  /^GATEWAY.*$/d /etc/sysconfig/network-scripts/ifcfg-$ni
		echo GATEWAY=$gw >> /etc/sysconfig/network-scripts/ifcfg-$ni	
	elif  [[ "$2" == "static_ip" ]]; then
		sip=$1
		sed -i  /^IPADDR.*$/d /etc/sysconfig/network-scripts/ifcfg-$ni
		echo IPADDR=$sip >> /etc/sysconfig/network-scripts/ifcfg-$ni				
	fi
	sed -i  s/^IPV6INIT=.*$/IPV6INIT="no"/ /etc/sysconfig/network-scripts/ifcfg-$ni
    sed -i  s/^BOOTPROTO=.*$/BOOTPROTO="none"/ /etc/sysconfig/network-scripts/ifcfg-$ni
	sed -i  s/^ONBOOT=.*$/ONBOOT="yes"/ /etc/sysconfig/network-scripts/ifcfg-$ni
	if [[ "$ip_prefix" == 24 ]]; then
		sed -i  /^NETMASK.*$/d /etc/sysconfig/network-scripts/ifcfg-$ni
		echo NETMASK=255.255.255.0 >> /etc/sysconfig/network-scripts/ifcfg-$ni
	elif [[ "$ip_prefix" == 16 ]]; then
		sed -i  /^NETMASK.*$/d /etc/sysconfig/network-scripts/ifcfg-$ni
		echo NETMASK=255.255.0.0  >> /etc/sysconfig/network-scripts/ifcfg-$ni
	elif [[ "$ip_prefix" == 8 ]]; then
		sed -i  /^NETMASK.*$/d /etc/sysconfig/network-scripts/ifcfg-$ni
		echo NETMASK=255.0.0.0  >> /etc/sysconfig/network-scripts/ifcfg-$ni	
	fi
}

dns_change(){
	if [[ $2 == "dns1" ]]; then
		dns1=$1
		sed -i  /^DNS1.*$/d /etc/sysconfig/network-scripts/ifcfg-$ni
		echo DNS1=$dns1 >> /etc/sysconfig/network-scripts/ifcfg-$ni		
	elif  [[ $2 == "dns2" ]]; then
		dns2=$1	
		sed -i  /^DNS2.*$/d /etc/sysconfig/network-scripts/ifcfg-$ni
		echo DNS2=$dns2 >> /etc/sysconfig/network-scripts/ifcfg-$ni
	fi
}

host_add(){	
	while [[ $h_ip != "done" ]];
		do
		read -p "$(echo -e "${bl}add ($ip $hostname $hostname_s ) =  "${normal})" h_ip h_fq h_sq
		ip_control "$h_ip"
		if [[ "$c_value" = true ]]; then
			if grep -oP "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?=.*$h_fq)" /etc/hosts ; then
				printf "${rd}HOSTNAME ALREADY EXISTS${normal}\n";
			else
				echo $h_ip $h_fq $h_sq >> /etc/hosts
				printf "${gr}\nHOSTNAME WAS ADDED SUCCESSFULLY\n${normal}";
			fi
		else
			if [[ $h_ip == "done" ]]; then
				printf "${gr}\nSUCCESSFULLY COMPLETED${normal}\n";
				sleep 2; exit;
			else 
				printf "${rd}\nIP VALUES MUST BE LIKE 0.0.0.0${normal}\n";
			fi			
		fi
		done
}

nw_restart_text(){
	read -p "$(echo -e ${bl}"DO YOU WANT TO RESTART NETWORK? (yes/no)"${normal})" s2
	if [[ "$s2" == "y" ]] || [[ "$s2" == "yes" ]]; then
		systemctl restart network
	else
		printf "${rd}\nYOU NEED TO RESTART NETWORK FOR ASSIGN $1${normal}\n";
		printf "${bl}YOU CAN COMPLETE THE PROCCES LATER WITH USING ${rd}'systemctl restart network'${bl} COMMAND${normal}\n";
	fi
	sleep 5;
	exit;
}
lvm_extend(){
	umount $lve1
	lvextend -L $$lve3 $lve2
	xfs_growfs $lve2
	sed -i  s/^$lve2.*$/#^$lve2.*$/ /etc/fstab
}

lvm_reduce(){
	umount $lvr1
	lvreduce -L $$lvr3 $lvr2
	xfs_growfs $lvr2
	sed -i  s/^$lvr2.*$/#^$lve2.*$/ /etc/fstab
}

#VISUALIZATION
menu(){ 
	printf "\n${yel}##################################################${normal}";
	printf "\n${yel}###################${normal} [FaS v0.9] ${yel}###################${normal}";
    printf "\n${yel}##################################################${normal}\n";
	printf "${yel}#####                  :                  -  #####${normal}\n";
	printf "${yel}#####                ++:               -+::  #####${normal}\n";
	printf "${yel}#####              :+++:             -+++:   #####${normal}\n";
	printf "${yel}#####      --:++++++++++++-::-:    --+++:    #####${normal}\n";
	printf "${yel}#####  +++*+++***+++++++++++++++++++:+++:    #####${normal}\n";
	printf "${yel}#####   :--::::::++++:::::::::-::+:   -+++   #####${normal}\n";
	printf "${yel}#####       -:::::+++::::::-:--          -:: #####${normal}\n";
	printf "${yel}#####             :++                        #####${normal}\n";
	printf "${yel}#####              -:-                       #####${normal}";
	printf "\n${yel}##################################################${normal}\n";
	printf "${yel}##########${rd} 0)${normal} $1    ${yel}##########${normal}";
	printf "\n${yel}##################################################${normal}";
	printf "\n${yel}######################${rd} MENU ${yel}######################${normal}\n";
	printf "${yel}##########${normal}                              ${yel}##########${normal}\n";
    printf "${yel}##########${rd} 1)${normal} $2   ${yel}##########${normal}\n";
    printf "${yel}##########${rd} 2)${normal} $3      ${yel}##########${normal}\n";
	printf "${yel}##########${rd} 3)${normal} $4 ${yel}##########${normal}\n";
    printf "${yel}##########${rd} 4)${normal} $5          ${yel}##########${normal}\n";
    printf "${yel}##########${rd} 5)${normal} $6    ${yel}##########${normal}\n";
    printf "${yel}##########${rd} 6)${normal} $7         ${yel}##########${normal}\n";
    printf "${yel}##########${rd} 7)${normal} $8    ${yel}##########${normal}\n";
    printf "${yel}##########${normal}                              ${yel}##########${normal}\n";
	printf "${yel}###################${rd} R) REBOOT ${yel}####################${normal}\n";
	printf "${yel}####################${rd} X) EXIT ${yel}#####################${normal}\n";
	printf "${yel}##################################################${normal}\n";
	read -p "$(echo -e "${bl}SELECT = "${normal})" opt
}

progress_bar(){
	printf "\n";
	echo -ne ${bl}'[============                             ] (33%)\r'${normal};
	sleep 1
	echo -ne ${bl}'[=======================                  ] (66%)\r'${normal};
	sleep 1
	echo -ne ${bl}'[=========================================] (100%)\r'${normal};
	echo -ne '\n';
}

host_info_text(){
	printf "${gr}\n$1 HAS BEEN SUCCESSFULLY IDENTIFIED\n\n${yel}HOSTNAME  : ${bl}$hostname\n${yel}STATIC IP : ${bl}$sip\n${yel}GATEWAY   : ${bl}$gw\n${yel}DNS1      : ${bl}$s_dns1\n${yel}DNS2      : ${bl}$s_dns2\n${normal}\n";
}

brack(){
	echo -e ${bl}"--------------------------------------------------"${normal};
}

brack2(){
	echo -e ${bl}"##################################################"${normal};
}


#EXECUTION
clear
menu "$ansible_m" "$m1" "$m2" "$m3" "$m4" "$m5" "$m6" "$m7";
while [[ $opt != "\n" ]];
   do
   if [[ $opt == "\n" ]]; then
     clear;
     printf "         ${rd}CHOOSE  AN OPTION FROM THE MENU!${normal}         ";
     menu "$ansible_m" "$m1" "$m2" "$m3" "$m4" "$m5" "$m6" "$m7";
   else
     case $opt in
			
		0)  clear
			menu "$back" "$ansible_m1" "$ansible_m2" "$ansible_m3" "$ansible_m4" "$ansible_m5" "$ansible_m6" "$ansible_m7";
			while [[ $opt != "\n" ]];
				do
				if [[ $opt == "\n" ]]; then
					clear;
					printf "         ${rd}CHOOSE  AN OPTION FROM THE MENU!${normal}         ";
					menu "$back" "$ansible_m1" "$ansible_m2" "$ansible_m3" "$ansible_m4" "$ansible_m5" "$ansible_m6" "$ansible_m7";
				else
					case $opt in			
						
						0)  clear ;menu "$ansible_m" "$m1" "$m2" "$m3" "$m4" "$m5" "$m6" "$m7";
						;;
						1)  printf "${gr}                *INSTALL ANSIBLE*                 ${normal}\n"; 
							brack
							read -p "$(echo -e ${bl}"DO YOU WANT TO INSTALL ANSIBLE ?(yes/no)"${normal})" s9
							if [[ "$s9" == "y" ]] || [[ "$s9" == "yes" ]]; then
								echo -e ${yel}"\n$(yum install epel-release -y)";
								echo -e ${yel}"\n$(yum install ansible -y)";
								yum_control "ansible"
								if [[ "$yum_value" == true ]]; then
									printf "${gr}\nANSIBLE SUCCESSFULLY INSTALLED\n${normal}";
								else
									printf "${rd}\nSOMETHING WENT WRONG\n${normal}";
								fi
							else
								printf "${rd}\nINSTALLATION CANCELED\n${normal}";
							fi; sleep 3; exit
						;;
						2)  printf "${gr}              *ADD HOSTS TO ANSIBLE*              ${normal}\n"; 
							brack
							read -p "$(echo -e ${bl}"ALL HOSTS WILL BE ADDED UNDER THE ALL GROUP DO YOU CONFIRM THAT ?(yes/no)"${normal})" s10
							if [[ "$s10" == "y" ]] || [[ "$s10" == "yes" ]]; then
#									read -p "$(echo -e "${bl}HOST IP = "${normal})" hosts_group
									ansible_control1
									if [[ "$ansible_value1" == false ]]; then
										echo [all_hosts] >> /etc/ansible/hosts
									fi
									ansible_control2
									if [[ "$ansible_value2" == false ]]; then
										echo $hosts_ip1 >> /etc/ansible/hosts																
										printf "${gr}\nSUCCESS!\n${normal}";
									else
										printf "${rd}HOSTS ALREADY EXISTS${normal}\n";										
									fi
							else		
									printf "${rd}\nCANCELED\n${normal}";
							fi; sleep 3;exit; 
						;;
						3)  printf "${gr}           *REMOVE HOSTS FROM ANSIBLE*            ${normal}\n"; 
							brack
							read -p "$(echo -e ${bl}"DO YOU WANT TO REMOVE HOSTS FROM ANSIBLE ?(yes/no)"${normal})" s11
							if [[ "$s11" == "y" ]] || [[ "$s11" == "yes" ]]; then
								read -p "$(echo -e "${bl}HOST IP ADDRESS = "${normal})" hrmva
								ansible_value=$hrmva
								ansible_control3 "$ansible_value"
								if [[ "$ansible_value3" == true ]]; then
									host_remove_ansible "$hrmva"
									printf "${gr}\nHOST SUCCESSFULLY REMOVED\n${normal}";			
								else
									printf "${rd}\nIP ADDRESS IS NOT ALREADY HERE\n${normal}";
								fi
							else		
								printf "${rd}\nCANCELED\n${normal}";
							fi; sleep 3;exit; 
						;;
						4)  printf "${gr}          *EXECUTE COMMAND WITH ANSIBLE*          ${normal}\n"; 
							brack
							read -p "$(echo -e ${bl}"DO YOU WANT TO EXECUTE COMMAND WITH ANSIBLE ?(yes/no)"${normal})" s12
							if [[ "$s12" == "y" ]] || [[ "$s12" == "yes" ]]; then
							brack
							echo -e ${bgrd}"          WHEN YOU FINISH EXECUTING CODE          \n             JUST TYPE 'done' TO FINISH.          "${normal};
							brack	
								printf "${bl}\nPLEASE ENTER THE CODE TO EXECUTE\n${normal}";
								ansible_execute						
							else		
									printf "${rd}\nCANCELED\n${normal}";
							fi; sleep 3;exit; 						
						;;
						m|M)clear;menu "$ansible_m" "$m1" "$m2" "$m3" "$m4" "$m5" "$m6" "$m7";
						;;						
						x|X)printf "${rd}BYE\n${normal}";
							exit;
						;;
						\n) clear;
							printf "         ${rd}CHOOSE  AN OPTION FROM THE MENU!${normal}         ";		
							menu "$ansible_m" "$m1" "$m2" "$m3" "$m4" "$m5" "$m6" "$m7";	
						;;
						*)	clear;
							printf "         ${rd}CHOOSE  AN OPTION FROM THE MENU!${normal}         ";		
							menu "$ansible_m" "$m1" "$m2" "$m3" "$m4" "$m5" "$m6" "$m7";			
						;;
					esac
				fi
				done		
				
		;;							
        1)	printf "            ${gr}*STATIC IP CONFIGURATION*${normal}            \n"; 
		    brack
	        read -p "$(echo -e ${bl}"DO YOU WANT TO CHANGE STATIC IP ?(yes/no)"${normal})" s1
		    if [[ "$s1" == "y" ]] || [[ "$s1" == "yes" ]]; then
				brack
				echo -e ${bgrd}"    YOU DON'T NEED THE SET OTHER PARAMETERS FOR   \n         CHANGING DNS ADDRESS OR HOSTNAME.        \n BUT IF YOU WANT THE CHANGE IP ADDRESS YOU NEED TO\n           SET NETMASK AND GATEWAY TOO.           "${normal};
				brack
				read -p "$(echo -e ${yel}"STATIC IP ${bl}($ip)${yel} : "${normal})" sip
				read -p "$(echo -e ${yel}"GATEWAY ${bl}($gateway)${yel} : "${normal})" gw
				read -p "$(echo -e ${yel}"DNS1 ${bl}($s_dns1)${yel} : "${normal})" dns1
				read -p "$(echo -e ${yel}"DNS2 ${bl}($s_dns2)${yel} : "${normal})" dns2
				read -p "$(echo -e ${yel}"HOSTNAME ${bl}($hostname)${yel} : "${normal})" hn
				ip_control "$sip"
				if [[ "$c_value" = true ]]; then
					ip_change "$sip" "static_ip"
					c_value2=true
				else
					printf "${rd}\nIP VALUE NOT GOING TO BE CHANGE${normal}\n";
					ip_change "$ip" "static_ip"
				fi
				ip_control "$gw"
				if [[ "$c_value" = true ]]; then				
					ip_change "$gw" "gateway"
					c_value3=true
				else
					printf "${rd}\nGATEWAY VALUE NOT GOING TO BE CHANGE${normal}\n";			
					ip_change "$gateway" "gateway"
				fi	
				if [[ "$hn" != "" ]];then
					hostnamectl set-hostname $hn
					printf "${gr}\nHOSTNAME SUCCESSFULLY CHANGE${normal}\n";
				else
					printf "${rd}\nHOSTNAME NOT GOING TO BE CHANGE${normal}\n";	
				fi				
				dns_control "$dns1"
				if [[ "$c_value" = true ]]; then
					dns_change "$dns1" "dns1"
					c_value4=true
				else
					printf "${bl}\nYOU CAN DEFINE DNS LATER USING ${rd}/etc/resolv.conf${normal}\n";
					dns_change "$s_dns1" "dns1"
				fi
				dns_control "$dns2"
				if [[ "$c_value" = true ]]; then
					dns_change "$dns2" "dns2"
					c_value4=true
				else
					dns_change "$s_dns2" "dns2"
				fi
				if	[[ "$c_value2" = true ]] && [[ "$c_value3" = true ]] ; then
					progress_bar
					host_info_text "STATIC IP AND GATEWAY"
					nw_restart_text "STATIC IP AND GATEWAY"
				elif [[ "$c_value2" = true ]]; then
					progress_bar
					host_info_text "STATIC IP"
		            nw_restart_text "STATIC IP"
				elif [[ "$c_value2" = true ]]; then
					progress_bar
					host_info_text "STATIC IP"
		            nw_restart_text "STATIC IP"
				elif [[ "$c_value3" = true ]]; then
					progress_bar
					host_info_text "GATEWAY"
					nw_restart_text "GATEWAY"		
				elif [[ "$c_value4" = true ]]; then
					progress_bar
					host_info_text "DNS"
					nw_restart_text "DNS"
				fi
			else
				printf "${rd}\nCANCELED${normal}";
			fi; sleep 3; exit;  
        ;;
		
        2)	printf "                    ${gr}*ADD HOST*${normal}                    \n"; 
		    brack
		    read -p "$(echo -e ${bl}"DO YOU WANT TO ADD HOST ?(yes/no)"${normal})" s8
			brack
			echo -e ${bgrd}"            WHEN YOU FINISH ADDING HOSTS          \n             JUST TYPE 'done' TO FINISH.          "${normal};
			brack
			if [[ "$s8" == "y" ]] || [[ "$s8" == "yes" ]]; then
				host_add				
			else 
				printf "${rd}\nCANCELED${normal}\n";
			fi; sleep 3; exit			
        ;;		
        3)  printf "            ${gr}*DISABLE SELINUX*${normal}            \n"; 
		    brack
		    read -p "$(echo -e ${bl}"DO YOU WANT TO DISABLE SELINUX ?(yes/no)"${normal})" s3
			if [[ "$s3" == "y" ]] || [[ "$s3" == "yes" ]]; then
				sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
				progress_bar
				printf "${gr}\nSELINUX DISABLED${normal}\n";				
            else
				printf "${rd}\nSELINUX STATUS NOT CHANGED${normal}\n";
            fi; sleep 3; exit;     
        ;;
        4)  printf "            ${gr}*DISABLE FIREWALL*${normal}            \n"; 
		    brack
		    read -p "$(echo -e ${bl}"DO YOU WANT TO DISABLE FIREWALL?(yes/no)"${normal})" s4
				if [[ "$s4" == "y" ]] || [[ "$s4" == "yes" ]]; then
				echo -e ${yel}"\n$(systemctl stop firewalld)";
				echo -e ${yel}"$(systemctl disable firewalld)";
				printf "${gr}\nFIREWALL DISABLED${normal}\n";
            else
				printf "${rd}\nFIREWALL STATUS NOT CHANGED\n${normal}";
            fi; sleep 3; exit;     
        ;;
		5)  printf "            ${gr}*INSTALL AND ENABLE NTP*${normal}            \n"; 
		    brack
		    read -p "$(echo -e ${bl}"DO YOU WANT TO INSTALL NTP?(yes/no)"${normal})" s5
			if [[ "$s5" == "y" ]] || [[ "$s5" == "yes" ]]; then
				echo -e ${yel}"\n$(yum install ntp -y)";		
				sed -i  s/centos/tr/ /etc/ntp.conf
				systemctl start ntpd
				echo -e ${yel}"$(systemctl enable ntpd)";	
				yum_control	"ntpdate"
				if [[ "$yum_value" == true ]]; then				
					printf "${gr}\nNTP SUCCESSFULLY INSTALLED\n${normal}";
				else
					printf "${rd}\nSOMETHING WENT WRONG\n${normal}";
				fi
            else
				printf "${rd}\nINSTALLATION CANCELED\n${normal}";
            fi; sleep 3;exit;  
        ;;
		6)  printf "               ${gr}*INSTALL JAVA(1.8)*${normal}              \n"; 
		    brack
		    read -p "$(echo -e ${bl}"DO YOU WANT TO INSTALL JAVA(1.8)?(yes/no)"${normal})" s5
			if [[ "$s5" == "y" ]] || [[ "$s5" == "yes" ]]; then
				echo -e ${yel}"\n$(yum install java-1.8.0-openjdk -y)";
#				echo JAVA_HOME="/usr/lib/jvm/jre-1.8.0-openjdk.x86_64" >> ~/.bashrc
#				echo JRE_HOME="${JAVA_HOME}" >> ~/.bashrc
#				echo JDK_HOME="${JAVA_HOME}" >> ~/.bashrc
#				echo PATH="/usr/local/firefox:/sbin:$JAVA_HOME/bin:$ANT_HOME/bin:$M2_HOME/bin:$PATH" >> ~/.bashrc
#				source ~/.bashrc
				printf "${bl}\nCHECKING JAVA STATUS \n${normal}";
				echo -e ${yel}"\n$(java -version)";
#				echo -e ${yel}"\n$(which java)"
				yum_control	"java*"
				if [[ "$yum_value" == true ]]; then				
					printf "${gr}\nJAVA SUCCESSFULLY INSTALLED\n${normal}";
				else
					printf "${rd}\nSOMETHING WENT WRONG\n${normal}";
				fi
            else
				printf "${rd}\nJAVA INSTALLATION CANCELED\n${normal}";
            fi; sleep 3; exit;  
        ;;
		7)  clear
			menu "$ansible_m" "$lv_m1" "$lv_m2" "$lv_m3" "$lv_m4" "$lv_m5" "$lv_m6" "$lv_m7";
			while [[ $opt != "\n" ]];
				do
				if [[ $opt == "\n" ]]; then
					clear;
					printf "         ${rd}CHOOSE  AN OPTION FROM THE MENU!${normal}         ";
					menu "$lv_m1" "$lv_m2";
				else
					case $opt in			
						
						0)  clear ;menu "$ansible_m" "$ansible_m1" "$ansible_m2" "$ansible_m3" "$ansible_m4" "$ansible_m5" "$ansible_m6" "$ansible_m7";
						;;
						1)  printf "${gr}                   *LVM EXTEND*                   ${normal}\n"; 
							brack
							read -p "$(echo -e ${bl}"DO YOU WANT USE LVM?(yes/no)"${normal})" s6		   
							if [[ "$s6" == "y" ]] || [[ "$s6" == "yes" ]]; then
								printf "\n";
								echo -e ${yel}"$(df -h)";
								printf "${bl}\nPLEASE ENTER THE DIRECTORY FOR THE UMOUNT ${bl}(/home)\n${normal}";
								read -p "$(echo -e "${bl}DIR(UMOUNT) = "${normal})" lve1
								lv_control "$lve1"
								if [[ "$lv_value" = true ]]; then
									printf "${bl}\nCHECKING LVDISPLAY \n${normal}";
									echo -e ${yel}"\n$(lvdisplay)";
								else
									sleep 2; exit;
								fi
								printf "${bl}PLEASE ENTER THE DIRECTORY FOR REMOVE (/dev/mapper/centos-home)\n${normal}";
								read -p "$(echo -e "${bl}DIR(LVREMOVE) = "${normal})" lve2
								lv_control "$lve2"	
								if [[ "$lv_value" = true ]]; then
									printf "${bl}\nPLEASE ENTER THE VALUE TO BE EXTENDED (50G)\n${normal}";
									read -p "$(echo -e "${bl}VALUE(ONLY G TYPE) = "${normal})" lve3
									lv_control "$lve3"		
									if [[ "$lv_value" = true ]]; then
										lvm_extend "$lve1" "$lve2" "$lve3"
									else
										sleep 2; exit;
									fi
								else
									sleep 2; exit;
								fi												
							else
								printf "${rd}\nCANCELED${normal}";
							fi; sleep 2; exit;			       
						;;
						2)  printf "${gr}                   *LVM REDUCE*                   ${normal}\n"; 
							brack
							read -p "$(echo -e ${bl}"DO YOU WANT USE LVM?(yes/no)"${normal})" s6		   
							if [[ "$s6" == "y" ]] || [[ "$s6" == "yes" ]]; then
								printf "\n";
								echo -e ${yel}"$(df -h)";
								printf "${bl}\nPLEASE ENTER THE DIRECTORY FOR THE UMOUNT ${bl}(/home)\n${normal}";
								read -p "$(echo -e "${bl}DIR(UMOUNT) = "${normal})" lvr1
								lv_control "$lvr1"
								if [[ "$lv_value" = true ]]; then
									printf "${bl}\nCHECKING LVDISPLAY \n${normal}";
									echo -e ${yel}"\n$(lvdisplay)"
								else
									sleep 2; exit;
								fi								
								printf "${bl}PLEASE ENTER THE DIRECTORY FOR LVREMOVE (/dev/mapper/centos-home)\n${normal}";
								read -p "$(echo -e "${bl}DIR(LVREMOVE) = "${normal})" lvr2
								lv_control "$lvr2"	
								if [[ "$lv_value" = true ]]; then
									printf "${bl}\nPLEASE ENTER THE VALUE TO BE EXTENDED (50G)\n${normal}";
									read -p "$(echo -e "${bl}VALUE(ONLY G TYPE) = "${normal})" lvr3
									lv_control "$lvr3"		
									if [[ "$lv_value" = true ]]; then
										lvm_extend "$lvr1" "$lvr2" "$lvr3"
									else
										sleep 2; exit;
									fi
								else
									sleep 2; exit;
								fi												
							else
								printf "${rd}\nCANCELED${normal}";
							fi; sleep 2; exit;			       		       
						;;
						m|M)clear;menu "$ansible_m" "$m1" "$m2" "$m3" "$m4" "$m5" "$m6" "$m7";
						;;						
						x|X)printf "${rd}BYE\n${normal}";
							exit;
						;;
						\n) clear;
							printf "         ${rd}CHOOSE  AN OPTION FROM THE MENU!${normal}         ";		
							menu "$ansible_m" "$m1" "$m2" "$m3" "$m4" "$m5" "$m6" "$m7";	
						;;
						*)	clear;
							printf "         ${rd}CHOOSE  AN OPTION FROM THE MENU!${normal}         ";		
							menu "$ansible_m" "$m1" "$m2" "$m3" "$m4" "$m5" "$m6" "$m7";			
						;;
					esac
				fi
				done		
				;;
        r|R) printf "                     ${gr}*REBOOT*${normal}                     \n"; 
		    brack
		    read -p "$(echo -e ${bl}"DO YOU WANT REBOOT THE MACHINE?(yes/no)"${normal})" s7
			if [[ "$s7" == "y" ]] || [[ "$s7" == "yes" ]]; then
				printf "${gr}\nREBOOTING${normal}";
				progress_bar
				reboot
            else
				printf "${rd}\nCANCELED${normal}";
            fi; sleep 3; clear; menu "$ansible_m" "$m1" "$m2" "$m3" "$m4" "$m5" "$m6" "$m7"; 
        ;;
        x|X)printf "${rd}BYE\n${normal}";
			exit;
        ;;
		\n) clear;
		    printf "         ${rd}CHOOSE  AN OPTION FROM THE MENU!${normal}         ";		
            menu "$ansible_m" "$m1" "$m2" "$m3" "$m4" "$m5" "$m6" "$m7";	
        ;;
        *)	clear;
			printf "         ${rd}CHOOSE  AN OPTION FROM THE MENU!${normal}         ";		
			menu "$ansible_m" "$m1" "$m2" "$m3" "$m4" "$m5" "$m6" "$m7";			
        ;;
      esac
    fi
done
