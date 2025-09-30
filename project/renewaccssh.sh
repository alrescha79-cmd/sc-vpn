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
echo -e "${green}│     PEMBARUAN AKUN SSH / OPENVPN        │${reset}"
echo -e "${green}└─────────────────────────────────────────┘${reset}"

account_count=$(grep -c -E "^### " "/etc/ssh/.ssh.db")
if [[ ${account_count} == '0' ]]; then
    echo ""
    echo "  Tidak ada data pengguna yang tersedia"
    echo ""
    exit 0
fi

# Prompt for username directly
read -rp "Masukkan nama pengguna: " user

# Check if user exists
if ! grep -qE "^### $user " "/etc/ssh/.ssh.db"; then
    echo ""
    echo "Nama pengguna tidak ditemukan"
    echo ""
    exit 1
fi

# Get current expiration date
exp=$(grep -E "^### $user " "/etc/ssh/.ssh.db" | cut -d ' ' -f 3)

clear
echo -e "${yellow}Memperbarui akun SSH $user${reset}"
echo ""

# Read expiration date from database
old_exp=$(grep -E "^### $user " "/etc/ssh/.ssh.db" | cut -d ' ' -f 3)

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
    read -p "Batas perangkat (IP): " ip_limit
    if [[ "$ip_limit" =~ ^[1-9][0-9]*$ ]]; then
        break
    else
        echo "Input harus berupa angka positif lebih dari 0."
    fi
done

if [ ! -d /etc/ssh ]; then
    mkdir -p /etc/ssh
fi

# Remove old entries before updating to prevent duplicates
sed -i "/^### $user /d" /etc/ssh/.ssh.db

echo "${ip_limit}" >/etc/ssh/${user}

# Calculate new expiration date
new_exp=$(date -d "$old_exp +${active_days} days" +"%Y-%m-%d")

# Add updated entry
echo "### ${user} ${new_exp}" >>/etc/ssh/.ssh.db

# Update the user's expiration date
chage -E "$new_exp" "$user"

clear
echo -e "${green}┌─────────────────────────────────────────┐${reset}"
echo -e "${green}│    DATA AKUN SSH BERHASIL DIPERBARUI    │${reset}"
echo -e "${green}└─────────────────────────────────────────┘${reset}"
echo -e "Nama Pengguna : ${green}$user${reset}"
echo -e "Batas IP      : ${yellow}$ip_limit perangkat${reset}"
echo -e "Masa Berlaku  : ${yellow}$(date -d "$new_exp" "+%d %b %Y")${reset}"
echo ""