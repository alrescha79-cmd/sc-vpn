#!/bin/bash

# Test script untuk validasi IP
# Simulasi IP dan data izin

# Mock functions
curl() {
    if [[ "$*" == *"ipinfo.io/ip"* ]]; then
        echo "34.139.24.37"  # IP yang ada dalam daftar trial
    elif [[ "$*" == *"ipinfo.io/city"* ]]; then
        echo "Jakarta"
    elif [[ "$*" == *"ipinfo.io/org"* ]]; then
        echo "AS15169 Google LLC"
    elif [[ "$*" == *"izin"* ]]; then
        cat /home/son/Projects/sclite/izin
    fi
}

wget() {
    if [[ "$*" == *"ipinfo.io/ip"* ]]; then
        echo "34.139.24.37"
    fi
}

# Source colors dari script asli
green="\e[38;5;82m"
red="\e[38;5;196m"
neutral="\e[0m"
blue="\e[38;5;39m"
yellow="\e[38;5;226m"
gray="\e[38;5;245m"

# Test validasi
echo "Testing IP validation..."

# Informasi sistem
city=$(curl -s ipinfo.io/city)
isp=$(curl -s ipinfo.io/org | cut -d " " -f 2-10)
ip=$(wget -qO- ipinfo.io/ip)

# Mendapatkan data izin dan user info
echo -e "${blue}Mengunduh data otorisasi...${neutral}"
data=$(curl -s --connect-timeout 10 --max-time 30 https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/izin)

# Cek apakah data berhasil diunduh
if [ -z "$data" ]; then
    echo -e "${red}Data kosong!${neutral}"
    exit 1
fi

# Cek apakah format data valid
if ! echo "$data" | grep -q "^###.*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.*[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+"; then
    echo -e "${red}Format data tidak valid${neutral}"
    exit 1
fi

# Parsing data sesuai format baru
user_line=$(echo "$data" | grep "$ip")
if [ -n "$user_line" ]; then
    user_id=$(echo "$user_line" | awk '{print $2}')
    exp_date=$(echo "$user_line" | awk '{print $3}')
    user_ip=$(echo "$user_line" | awk '{print $4}')
else
    user_id=""
    exp_date=""
    user_ip=""
fi

echo "IP: $ip"
echo "User Line: $user_line"
echo "User ID: $user_id"
echo "Exp Date: $exp_date"
echo "User IP: $user_ip"

# Validasi IP dalam daftar izin
if [ -z "$user_id" ]; then
    echo -e "${red}IP tidak terdaftar${neutral}"
    exit 1
fi

# Validasi tanggal kadaluarsa
current_date=$(date +%Y-%m-%d)
if [[ "$exp_date" < "$current_date" ]]; then
    echo -e "${red}Akses kadaluarsa${neutral}"
    exit 1
fi

# Hitung sisa hari akses
days_left=$(( ( $(date -d "$exp_date" +%s) - $(date -d "$current_date" +%s) ) / 86400 ))

echo -e "${green}✓ Validasi berhasil!${neutral}"
echo -e "${green}✓ User ID: ${user_id}${neutral}"
echo -e "${green}✓ Sisa hari: ${days_left}${neutral}"