#!/bin/bash

# Valid Script
ipsaya=$(curl -sS ipv4.icanhazip.com)
data_server=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
date_list=$(date +"%Y-%m-%d" -d "$data_server")


   

# Variables
ip=$(wget -qO- ipv4.icanhazip.com)
srv_date=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
date=$(date +"%Y-%m-%d" -d "$srv_date")
ip_url="https://ip.yha.my.id/ip"
city=$(cat /etc/xray/city 2>/dev/null || echo "Unknown city")
pubkey=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "Pubkey not available")
domain=$(cat /etc/xray/domain 2>/dev/null || hostname -f)
# uuid=$(cat /proc/sys/kernel/random/uuid)

clear

# User data input


while true; do
    read -p "   Name: " user
    if [[ ${#user} -lt 3 || ! "$user" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        printf "\033[1A\033[0J"
        echo -e "${red}   Username cannot be empty${reset}"
        continue
    fi
    if grep -q "^### $user " /etc/xray/vmess/config.json; then
        random_number=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 5)
        user="${random_number}${user}"
        echo -e "${yellow}   Username already exists. New username used: $user${reset}"
        break
    else
        break
    fi
done


read -p "Password: " uuid


until [[ $duration =~ ^[0-9]+$ ]]; do
    read -p "   Active period (days): " duration
    if [[ -z "$duration" ]]; then
        echo -e "${red}   Active period cannot be empty${reset}"
    fi
done
until [[ $quota =~ ^[0-9]+$ ]]; do
    read -p "   User Quota (GB): " quota
    if [[ -z "$quota" ]]; then
        echo -e "${red}   User limit cannot be empty${reset}"
    fi
done
until [[ $ip_limit =~ ^[0-9]+$ ]]; do
    read -p "   Device Limit (IP): " ip_limit
    if [[ -z "$ip_limit" ]]; then
        echo -e "${red}   IP limit cannot be empty${reset}"
    fi
done

# Account creation process
exp=$(date -d "$duration days" +"%Y-%m-%d")
if [ ! -f "/etc/xray/vmess/config.json" ]; then
    echo "Configuration file not found. Creating new file..."
    echo '{"inbounds": []}' >/etc/xray/vmess/config.json
fi

if ! sed -i '/#vmess$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/vmess/config.json; then
    echo -e "${red}Failed to add user to config.json${reset}"
    exit 1
fi
if ! sed -i '/#vmessgrpc$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/vmess/config.json; then
    echo -e "${red}Failed to add user to config.json (GRPC)${reset}"
    exit 1
fi

# Create configuration files
cat >/etc/xray/vmess/$user-tls.json <<EOF
{
    "v": "2",
    "ps": "$user WS (CDN) TLS",
    "add": "${domain}",
    "port": "443",
    "id": "${uuid}",
    "aid": "0",
    "net": "ws",
    "path": "/whatever/vmess",
    "type": "none",
    "host": "${domain}",
    "tls": "tls"
}
EOF

cat >/etc/xray/vmess/$user-non.json <<EOF
{
    "v": "2",
    "ps": "$user WS (CDN) NTLS",
    "add": "${domain}",
    "port": "80",
    "id": "${uuid}",
    "aid": "0",
    "net": "ws",
    "path": "/whatever/vmess",
    "type": "none",
    "host": "${domain}",
    "tls": "none"
}
EOF

cat >/etc/xray/vmess/$user-grpc.json <<EOF
{
    "v": "2",
    "ps": "$user (SNI) GRPC",
    "add": "${domain}",
    "port": "443",
    "id": "${uuid}",
    "aid": "0",
    "net": "grpc",
    "path": "vmess-grpc",
    "type": "none",
    "host": "${domain}",
    "tls": "tls"
}
EOF

# Create configuration file for OpenClash
cat >/var/www/html/vmess-$user.txt <<-END
---------------------
# Format Vmess WS (CDN)
---------------------

- name: Vmess-$user-WS (CDN)
  type: vmess
  server: ${domain}
  port: 443
  uuid: ${uuid}
  alterId: 0
  cipher: auto
  udp: true
  tls: true
  skip-cert-verify: true
  servername: ${domain}
  network: ws
  ws-opts:
    path: /whatever/vmess
    headers:
      Host: ${domain}
---------------------
# Format Vmess WS (CDN) Non TLS
---------------------

- name: Vmess-$user-WS (CDN) Non TLS
  type: vmess
  server: ${domain}
  port: 80
  uuid: ${uuid}
  alterId: 0
  cipher: auto
  udp: true
  tls: false
  skip-cert-verify: false
  servername: ${domain}
  network: ws
  ws-opts:
    path: /whatever/vmess
    headers:
      Host: ${domain}
---------------------
# Format Vmess gRPC (SNI)
---------------------

- name: Vmess-$user-gRPC (SNI)
  server: ${domain}
  port: 443
  type: vmess
  uuid: ${uuid}
  alterId: 0
  cipher: auto
  network: grpc
  tls: true
  servername: ${domain}
  skip-cert-verify: true
  grpc-opts:
    grpc-service-name: vmess-grpc

---------------------
# Vmess Account Links
---------------------
TLS Link : vmess://$(base64 -w 0 /etc/xray/vmess/$user-tls.json)
---------------------
Non-TLS Link : vmess://$(base64 -w 0 /etc/xray/vmess/$user-non.json)
---------------------
GRPC Link : vmess://$(base64 -w 0 /etc/xray/vmess/$user-grpc.json)
---------------------

END

# Generate Vmess links
vmess_tls="vmess://$(base64 -w 0 /etc/xray/vmess/$user-tls.json)"
vmess_non="vmess://$(base64 -w 0 /etc/xray/vmess/$user-non.json)"
vmess_grpc="vmess://$(base64 -w 0 /etc/xray/vmess/$user-grpc.json)"

# Restart service
if ! systemctl restart vmess@config; then
    echo -e "${red}Failed to restart vmess service${reset}"
    exit 1
fi

# Exception if configuration file doesn't exist
if [ ! -f "/etc/xray/vmess/config.json" ]; then
    echo "Warning: Vmess configuration file not found. Creating new file..."
    mkdir -p /etc/xray/vmess
    echo '{"inbounds": []}' >/etc/xray/vmess/config.json
    systemctl restart vmess@config
fi

# Create directory if it doesn't exist
if [ ! -d "/etc/xray/vmess" ]; then
    echo "Directory /etc/xray/vmess not found. Creating directory..."
    mkdir -p /etc/xray/vmess
    if [ $? -ne 0 ]; then
        echo "Failed to create directory /etc/xray/vmess. Make sure you have sufficient permissions."
        exit 1
    fi
fi

# Exception if configuration file doesn't exist
if [ ! -f "/etc/xray/vmess/config.json" ]; then
    echo "Vmess configuration file not found. Creating new file..."
    echo '{"inbounds": []}' >/etc/xray/vmess/config.json
    if [ $? -ne 0 ]; then
        echo "Failed to create Vmess configuration file. Make sure you have sufficient permissions."
        exit 1
    fi
fi

# Set default values if empty
ip_limit=${ip_limit:-0}
quota=${quota:-0}

# Convert Quota to bytes
quota_bytes=$((${quota} * 1024 * 1024 * 1024))

# Save quota and IP limit data
if [[ ${quota} != "0" ]]; then
    echo "${quota_bytes}" >/etc/xray/vmess/${user}
    echo "${ip_limit}" >/etc/xray/vmess/${user}IP
fi

# Update database
db_file="/etc/xray/vmess/.vmess.db"
temp_file="/etc/xray/vmess/.vmess.db.tmp"

# Exception if database file doesn't exist
if [ ! -f "$db_file" ]; then
    echo "Warning: Vmess database file not found. Creating new file..."
    touch "$db_file"
fi

# Remove old entry if exists
grep -v "^### ${user} " "$db_file" >"$temp_file"
mv "$temp_file" "$db_file"

# Add new entry
echo "### ${user} ${exp} ${uuid}" >>"$db_file"



# Save original log
{
    echo "——————————————————————————"
    echo "    Xray/Vmess Account    "
    echo "───────────────────────────"
    echo "remarks      : ${user}"
    echo "host_server  : ${domain}"    
    echo "location     : $city"
    echo "location     : $kota"
    echo "port_tls     : 443"
    echo "port_nontls  : 80, 8080"
    echo "port_dns     : 443, 53"
    echo "port_grpc    : 443"
    echo "alterid      : 0"
    echo "security     : auto"
    echo "network      : WS or gRPC"
    echo "path         : /whatever/vmess"
    echo "servicename  : vmess-grpc"
    echo "user_id      : ${uuid}"
    echo "public_key   : ${pubkey}"
    echo "───────────────────────────"
    echo "tls_link     : ${vmess_tls}"
    echo "───────────────────────────"
    echo "ntls_link    : ${vmess_non}"
    echo "───────────────────────────"
    echo "grpc_link    : ${vmess_grpc}"
    echo "───────────────────────────"
    echo "openclash_format : https://${domain}:81/vmess-$user.txt"
    echo "───────────────────────────"
    echo "expires_on   : $exp"
    echo ""
} >> /etc/xray/vmess/log-create-${user}.log

# Display account information in JSON format
clear

cat <<EOF
{
  "username": "${user}",
  "password": "${uuid}",
  "ip": "${ip}",
  "host_server": "${domain}",
  "location": "$city",
  "port_tls": 443,
  "port_non_tls": "80, 8080",
  "port_dns": "443, 53",
  "port_grpc": 443,
  "alterid": 0,
  "security": "auto",
  "network": "WS or gRPC",
  "path": "/whatever/vmess",
  "servicename": "vmess-grpc",
  "public_key": "${pubkey}",
  "tls_link": "${vmess_tls}",
  "ntls_link": "${vmess_non}",
  "grpc_link": "${vmess_grpc}",
  "openclash_format": "https://${domain}:81/vmess-$user.txt",
  "expires_on": "$exp"
}
EOF
