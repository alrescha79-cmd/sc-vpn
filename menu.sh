#!/bin/bash

red='\e[1;31m'
green='\e[0;32m'
purple='\e[0;35m'
orange='\e[0;33m'
NC='\e[0m'
clear

echo -e "${blue}══════════════════════════════════════════════════════════════════════${neutral}"
echo -e "${green}                               Install package            ${neutral}"
echo -e "${blue}══════════════════════════════════════════════════════════════════════${neutral}"

cd /usr/bin
wget -q -O addshadowsocks "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/addshadowsocks"
wget -q -O addssh "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/addssh"
wget -q -O addtrojan "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/addtrojan"
wget -q -O addvless "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/addvless"
wget -q -O addvmess "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/addvmess"
wget -q -O autokill "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/autokill"
wget -q -O backuprestore "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/backuprestore"
wget -q -O backuprestore.js "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/backuprestore.js"

wget -q -O checkshadowsocks "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/checkshadowsocks"
wget -q -O chechssh "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/chechssh"
wget -q -O checktrojan "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/checktrojan"
wget -q -O checkvless "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/checkvless"
wget -q -O checkvmess "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/checkvmess"

wget -q -O dellshadowsocks  "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/dellshadowsocks"
wget -q -O dellssh "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/dellssh"
wget -q -O delltrojan "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/delltrojan"
wget -q -O dellvless "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/dellvless"
wget -q -O dellvmess "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/dellvmess"

wget -q -O exp "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/exp"
wget -q -O features "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/features"
wget -q -O limitip "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/limitip"
wget -q -O limitssh "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/limitssh"
wget -q -O logclear "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/logclear"

wget -q -O menu "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/menu"
wget -q -O menushadowsocks "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/menushadowsocks"
wget -q -O menussh "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/menussh"
wget -q -O menutrojan "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/menutrojan"
wget -q -O menuvless "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/menuvless"
wget -q -O menuvmess "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/menuvmess"

wget -q -O quota "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/quota"

wget -q -O renewssh  "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/renewssh"
wget -q -O renewtrojan  "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/renewtrojan"
wget -q -O renewvmess  "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/renewvmess"
wget -q -O renewvless  "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/renewvless"

wget -q -O trial "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/trial"
wget -q -O trialvmess "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/trialvmess"
wget -q -O trialvless "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/trialvless"
wget -q -O trialssh "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/trialssh"
wget -q -O trialshadowsoks "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/trialshadowsoks"


chmod +x addshadowsocks
chmod +x addssh
chmod +x addtrojan
chmod +x addvless
chmod +x addvmess

chmod +x autokill
chmod +x backuprestore
chmod +x backuprestore.js

chmod +x checkssh
chmod +x checktrojan
chmod +x checkvless
chmod +x checkvmess
chmod +x checkshadowsocks

chmod +x dellshadowsocks
chmod +x dellssh
chmod +x delltrojan
chmod +x dellvless
chmod +x dellvmess

chmod +x exp
chmod +x features
chmod +x limitip
chmod +x limitssh
chmod +x clearlog

chmod +x menu
chmod +x menussh
chmod +x menuvless
chmod +x menuvmess
chmod +x menutrojan
chmod +x menushadowsocks

chmod +x quota
chmod +x renewssh
chmod +x renewvless
chmod +x renewtrojan
chmod +x renewvmess

chmod +x trial
chmod +x trialvmess
chmod +x trialvless
chmod +x trialssh
chmod +x trialshadowsoks


echo -e "${blue}══════════════════════════════════════════════════════════════════════${neutral}"
echo -e "${green}                               Install package            ${neutral}"
echo -e "${blue}══════════════════════════════════════════════════════════════════════${neutral}"
cd 