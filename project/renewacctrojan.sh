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
echo -e "${green}│        PEMBARUAN AKUN TROJAN            │${reset}"
echo -e "${green}└─────────────────────────────────────────┘${reset}"

account_count=$(grep -c -E "^### " "/etc/xray/trojan/.trojan.db")
if [[ ${account_count} == '0' ]]; then
    echo ""
    echo "  Tidak ada data pengguna yang tersedia"
    echo ""
    exit 0
fi

# Prompt for username directly
read -rp "Masukkan nama pengguna: " user

# Check if user exists
if ! grep -qE "^### $user " "/etc/xray/trojan/.trojan.db"; then
    echo ""
    echo "Nama pengguna tidak ditemukan"
    echo ""
    exit 1
fi

# Get current expiration date
exp=$(grep -E "^### $user " "/etc/xray/trojan/.trojan.db" | cut -d ' ' -f 3)

clear
echo -e "${yellow}Memperbarui akun Trojan $user${reset}"
echo ""

# Read expiration date from database
old_exp=$(grep -E "^### $user " "/etc/xray/trojan/.trojan.db" | cut -d ' ' -f 3)

# Calculate remaining active days
remaining_days=$((($(date -d "$old_exp" +%s) - $(date +%s)) / 86400))

echo "Sisa masa aktif: $remaining_days hari"

while true; do
    read -p "Tambahkan masa aktif (hari): " active_period
    if [[ "$active_period" =~ ^[0-9]+$ ]]; then
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

if [ ! -d /etc/xray/trojan ]; then
    mkdir -p /etc/xray/trojan
fi

if [[ $quota != "0" ]]; then
    quota_bytes=$((quota * 1024 * 1024 * 1024))
    echo "${quota_bytes}" >/etc/xray/trojan/${user}
    echo "${ip_limit}" >/etc/xray/trojan/${user}IP
else
    rm -f /etc/xray/trojan/${user} /etc/xray/trojan/${user}IP
fi

# Calculate new expiration date
new_exp=$(date -d "$old_exp +${active_period} days" +"%Y-%m-%d")
uuid=$(grep -E "^### $user " "/etc/xray/trojan/.trojan.db" | cut -d ' ' -f 4)
# Check if config file exists before making changes
if [ ! -f "/etc/xray/trojan/config.json" ]; then
    echo "File konfigurasi tidak ditemukan. Membuat file baru..."
    echo '{"inbounds": []}' >/etc/xray/trojan/config.json
fi

# Remove old entries before updating to prevent duplicates
# Remove from database
sed -i "/^### $user /d" /etc/xray/trojan/.trojan.db

# Remove from config file
sed -i "/^### $user /d" /etc/xray/trojan/config.json
sed -i "/{\"id\": \"$uuid\"/d" /etc/xray/trojan/config.json

# Add updated entries with the same UUID
sed -i '/#trojan$/a\### '"$user $new_exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/trojan/config.json

sed -i '/#trojangrpc$/a\### '"$user $new_exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/trojan/config.json

echo "### ${user} ${new_exp} ${uuid}" >>/etc/xray/trojan/.trojan.db

# Restart service with error handling
if ! systemctl restart trojan@config >/dev/null 2>&1; then
    echo "Peringatan: Gagal memulai ulang layanan Trojan. Periksa log sistem untuk informasi lebih lanjut."
    echo "Namun, data akun sudah berhasil diperbarui di basis data."
fi

clear
echo -e "${green}┌─────────────────────────────────────────┐${reset}"
echo -e "${green}│   DATA AKUN TROJAN BERHASIL DIPERBARUI  │${reset}"
echo -e "${green}└─────────────────────────────────────────┘${reset}"
echo -e "Nama Pengguna : ${green}$user${reset}"
echo -e "Batas Kuota   : ${yellow}$quota GB${reset}"
echo -e "Batas IP      : ${yellow}$ip_limit perangkat${reset}"
echo -e "Masa Berlaku  : ${yellow}$new_exp${reset}"
echo ""