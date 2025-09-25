#!/bin/bash
red='\e[1;31m'
green='\e[0;32m'
purple='\e[0;35m'
orange='\e[0;33m'
NC='\e[0m'
clear

echo -e "${blue}─────────────────────────────────────────${neutral}"
echo -e "${green}   INSTALLASI rest-go HIdeSSH       ${neutral}"
echo -e "${blue}─────────────────────────────────────────${neutral}"
cd


echo -e "${blue}─────────────────────────────────────────${neutral}"
echo -e "${green}   INSTALLASI golang restapi HIdeSSH       ${neutral}"
echo -e "${blue}─────────────────────────────────────────${neutral}"

cd
wget -q -O /usr/local/bin/vpn-api "https://github.com/alrescha79-cmd/sc-vpn/raw/refs/heads/main/golang/vpn-rest" && chmod +x /usr/local/bin/vpn-api

clear
read -p "Port example 3005 : " port
uuid=$(cat /proc/sys/kernel/random/uuid)


cat >/etc/systemd/system/vpn-api.service <<EOF
[Unit]
Description=VPN Account Management API
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/vpn-api
Restart=always
RestartSec=10
Environment=PORT=${port}
Environment=API_KEY=${uuid}
Environment=AllowOrigins=*

[Install]
WantedBy=multi-user.target
EOF



cd
chmod 644 /etc/systemd/system/vpn-api.service

sudo systemctl daemon-reload
sudo systemctl start vpn-api
sudo systemctl enable vpn-api

echo "Installation completed"
echo "You can access key header Bearer: ${uuid}"
echo "Port Rest Api: ${port}"