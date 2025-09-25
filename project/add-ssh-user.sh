#!/bin/bash
red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'

IP=$(wget -qO- ifconfig.me/ip);
domain=$(cat /etc/xray/domain 2>/dev/null || hostname -f)

read -p "Username : " Login
read -p "Password : " Pass
read -p "Expired (days) : " Expired

useradd -e `date -d "$Expired days" +"%Y-%m-%d"` -s /bin/false -M $Login
expi="$(chage -l $Login | grep "Account expires" | awk -F": " '{print $2}')"
echo -e "$Pass\n$Pass\n"|passwd $Login &> /dev/null
hariini=`date -d "0 days" +"%Y-%m-%d"`
expi=`date -d "$masaaktif days" +"%Y-%m-%d"`
clear
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" 
echo -e "         SSH Account Account      " 
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" 
echo -e "Username       : $Login "
echo -e "Password       : $Pass"
echo -e "Remarks : $Login" 
echo -e "Domain : $domain" 
echo -e "==============================="
echo -e "Domain         : $domain"
echo -e "Host           : $IP"
echo -e "OpenSSH        : 22"
echo -e "Dropbear       : 109, 143, 69"
echo -e "SSL/TLS        : 222, 444, 777, 443"
echo -e "Port Suid      : 3128, 8080"
echo -e "Websocket HTTP: 2082, 8880"
echo -e "Websocket HTTPS: 443"
echo -e "badvpn         : 7100-7300"
echo -e "Masa Aktif     : $Expired days"
echo -e "==============================="
echo -e "PAYLOAD"                                                          
echo -e "GET / HTTP/1.1[crlf]Host: $domain[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]Upgrade: websocket[crlf][crlf]"
echo -e "==============================="
echo -e "SETING HOST SSH"               
echo -e "bugisisendiri:2082@$Login:$Pass"
echo -e "==============================="
