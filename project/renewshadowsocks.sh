#!/bin/bash

# Valid Script
ipsaya=$(curl -sS ipv4.icanhazip.com)
data_server=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
date_list=$(date +"%Y-%m-%d" -d "$data_server")


    
# colors
red="\e[91m"
green="\e[92m"
yellow="\e[93m"
blue="\e[94m"
purple="\e[95m"
cyan="\e[96m"
white="\e[97m"
reset="\e[0m"

# variables
domain=$(cat /etc/xray/domain 2>/dev/null || hostname -f)
clear
echo -e "${green}┌─────────────────────────────────────────┐${reset}"
echo -e "${green}│     PEMBARUAN AKUN SHADOWSOCKS          │${reset}"
echo -e "${green}└─────────────────────────────────────────┘${reset}"

account_count=$(grep -c -E "^### " "/etc/xray/shadowsocks/.shadowsocks.db")
if [[ ${account_count} == '0' ]]; then
    echo ""
    echo "  Tidak ada data pengguna yang tersedia"
    echo ""
    exit 0
fi

# Prompt for username directly
read -rp "Masukkan nama pengguna: " user

# Check if user exists
if ! grep -qE "^### $user " "/etc/xray/shadowsocks/.shadowsocks.db"; then
    echo ""
    echo "Nama pengguna tidak ditemukan"
    echo ""
    exit 1
fi

# Get current expiration date and password
exp=$(grep -E "^### $user " "/etc/xray/shadowsocks/.shadowsocks.db" | cut -d ' ' -f 3)
password=$(grep -E "^### $user " "/etc/xray/shadowsocks/.shadowsocks.db" | cut -d ' ' -f 4)

clear
echo -e "${yellow}Memperbarui akun Shadowsocks $user${reset}"
echo ""

# Read expiration date from database
old_exp=$(grep -E "^### $user " "/etc/xray/shadowsocks/.shadowsocks.db" | cut -d ' ' -f 3)

# Calculate remaining active days
days_left=$((($(date -d "$old_exp" +%s) - $(date +%s)) / 86400))

echo "Sisa masa aktif: $days_left hari"

while true; do
    read -p "Tambahkan masa aktif (hari): " active_days
    if [[ "$active_days" =~ ^[0-9]+$ ]]; then
        break
    else
    echo "Input harus berupa angka positif."
    fi
done

while true; do
    read -p "Batas kuota (GB, 0 untuk tanpa batas): " quota
    if [[ "$quota" =~ ^[0-9]+$ ]]; then
        break
    else
    echo "Input harus berupa angka positif atau 0."
    fi
done

while true; do
    read -p "Batas perangkat (IP, 0 untuk tanpa batas): " ip_limit
    if [[ "$ip_limit" =~ ^[0-9]+$ ]]; then
        break
    else
    echo "Input harus berupa angka positif atau 0."
    fi
done

if [ ! -d /etc/xray/shadowsocks ]; then
    mkdir -p /etc/xray/shadowsocks
fi

if [[ $quota != "0" ]]; then
    quota_bytes=$((quota * 1024 * 1024 * 1024))
    echo "${quota_bytes}" >/etc/xray/shadowsocks/${user}
    echo "${ip_limit}" >/etc/xray/shadowsocks/${user}IP
else
    rm -f /etc/xray/shadowsocks/${user} /etc/xray/shadowsocks/${user}IP
fi

# Calculate new expiration date
new_exp=$(date -d "$old_exp +${active_days} days" +"%Y-%m-%d")

# Check if config file exists before making changes
if [ ! -f "/etc/xray/shadowsocks/config.json" ]; then
    echo "File konfigurasi tidak ditemukan. Membuat file baru..."
    echo '{"inbounds": []}' >/etc/xray/shadowsocks/config.json
fi

# Remove old entries before updating to prevent duplicates
# Remove from database
sed -i "/^### $user /d" /etc/xray/shadowsocks/.shadowsocks.db

# Remove from config file (both WS and gRPC sections)
sed -i "/^### $user /d" /etc/xray/shadowsocks/config.json
sed -i "/\"password\": \"$password\"/d" /etc/xray/shadowsocks/config.json

# Add updated entries with the same password
sed -i '/#ssws$/a\### '"$user $new_exp $password"'\
},{"password": "'""$password""'","method": "aes-256-gcm","email": "'""$user""'"' /etc/xray/shadowsocks/config.json

sed -i '/#ssgrpc$/a\### '"$user $new_exp $password"'\
},{"password": "'""$password""'","method": "aes-256-gcm","email": "'""$user""'"' /etc/xray/shadowsocks/config.json

echo "### ${user} ${new_exp} ${password}" >>/etc/xray/shadowsocks/.shadowsocks.db

# Restart service with error handling
if ! systemctl restart shadowsocks@config >/dev/null 2>&1; then
    echo "Peringatan: Gagal memulai ulang layanan Shadowsocks. Periksa log sistem untuk informasi lebih lanjut."
    echo "Namun, data akun sudah berhasil diperbarui di basis data."
fi

clear
echo -e "${green}┌─────────────────────────────────────────┐${reset}"
echo -e "${green}│ AKUN SHADOWSOCKS BERHASIL DIPERBARUI    │${reset}"
echo -e "${green}└─────────────────────────────────────────┘${reset}"
echo -e "Nama Pengguna : ${green}$user${reset}"
echo -e "Batas Kuota   : ${yellow}$quota GB${reset}"
echo -e "Batas IP      : ${yellow}$ip_limit perangkat${reset}"
echo -e "Masa Berlaku  : ${yellow}$new_exp${reset}"
echo ""