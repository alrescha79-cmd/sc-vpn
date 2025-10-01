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

# Function to print rainbow text

# variables
domain=$(cat /etc/xray/domain 2>/dev/null || hostname -f)
clear
echo -e "${green}┌─────────────────────────────────────────┐${reset}"
echo -e "${green}│           HAPUS AKUN VLESS              │${reset}"
echo -e "${green}└─────────────────────────────────────────┘${reset}"

account_count=$(grep -c -E "^### " "/etc/xray/vless/.vless.db")
if [[ ${account_count} == '0' ]]; then
    echo ""
    echo "  Tidak ada akun yang tersedia untuk dihapus!"
    echo ""
    exit 0
fi

echo -e "${yellow}Pilih akun yang akan dihapus:${reset}"
echo -e "${green}1) Berdasarkan nomor${reset}"
echo -e "${green}2) Ketik username secara manual${reset}"
delete_choice="2"
echo "Auto-selected: 2) Ketik username secara manual"
if [[ $delete_choice == "1" ]]; then
clear
        echo -e "${green}┌─────────────────────────────────────────┐${reset}"
        echo -e "${green}│          HAPUS AKUN VLESS              │${reset}"
        echo -e "${green}└─────────────────────────────────────────┘${reset}"
    echo " ┌────┬────────────────────┬─────────────┐"
    echo " │ no │ username           │     exp     │"
    echo " ├────┼────────────────────┼─────────────┤"
    grep -E "^### " "/etc/xray/vless/.vless.db" | awk '{
        cmd = "date -d \"" $3 "\" +%s"
        cmd | getline exp_timestamp
        close(cmd)
        current_timestamp = systime()
        days_left = int((exp_timestamp - current_timestamp) / 86400)
        if (days_left < 0) days_left = 0
        printf " │ %-2d │ %-18s │ %-11s │\n", NR, $2, days_left " days"
    }'
    echo " └────┴────────────────────┴─────────────┘"
    
fi

case $delete_choice in
    1)
        until [[ ${account_number} -ge 1 && ${account_number} -le ${account_count} ]]; do
            read -rp "Pilih nomor akun [1-${account_count}]: " account_number
        done
        user=$(grep -E "^### " "/etc/xray/vless/.vless.db" | cut -d ' ' -f 2 | sed -n "${account_number}p")
        exp=$(grep -E "^### " "/etc/xray/vless/.vless.db" | cut -d ' ' -f 3 | sed -n "${account_number}p")
        echo ""
        echo -e "${green}┌─────────────────────────────────────────┐${reset}"
        echo -e "${green}│           AKUN YANG DIPILIH             │${reset}"
        echo -e "${green}└─────────────────────────────────────────┘${reset}"
        echo -e "Username     : ${green}$user${reset}"
        echo -e "Expired      : ${yellow}$exp${reset}"
        echo ""
        sleep 2
        ;;
    2)
        read -rp "Masukkan username: " user
        if ! grep -qE "^### $user " "/etc/xray/vless/.vless.db"; then
            echo "Username tidak ditemukan"
            exit 1
        fi
        exp=$(grep -E "^### $user " "/etc/xray/vless/.vless.db" | cut -d ' ' -f 3)
        echo "Anda memilih: $user (Expired: $exp)"
        ;;
    *)
        echo "Pilihan tidak valid"
        exit 1
        ;;
esac

sed -i "/^### $user $exp/,/^},{/d" /etc/xray/vless/config.json
sed -i "/^### $user $exp/d" /etc/xray/vless/.vless.db
if [ -f "/etc/xray/vless/log-create-${user}.log" ]; then
    rm -f "/etc/xray/vless/log-create-${user}.log"
    rm -f "/etc/xray/vless/${user}-non.json"
    rm -f "/etc/xray/vless/${user}-tls.json"
    rm -f "/etc/xray/vless/${user}-grpc.json"
fi

if ! systemctl restart vless@config >/dev/null 2>&1; then
    echo "Warning: Failed to restart vless service. Please check system logs for more information."
    echo "However, the account has been successfully removed from the database."
fi

clear
echo -e "${green}┌─────────────────────────────────────────┐${reset}"
echo -e "${green}│           HAPUS AKUN VLESS              │${reset}"
echo -e "${green}└─────────────────────────────────────────┘${reset}"
echo -e "username     : ${green}$user${reset}"
echo -e "Akun telah dihapus secara permanen"

echo -e ""
echo -e "${green}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
echo -e "${green}║                    Terima kasih telah menggunakan                     ║${neutral}"
echo -e "${green}║                       ALRESCHA79 VPN PANEL                            ║${neutral}"
echo -e "${green}║                                                                       ║${neutral}"
echo -e "${green}║                 📱 Telegram: https://t.me/Alrescha79                  ║${neutral}"
echo -e "${green}║                                                                       ║${neutral}"
echo -e "${green}║            Ketik perintah ${yellow}menu${green} untuk membuka panel kembali            ║${neutral}"
echo -e "${green}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
echo -e ""

