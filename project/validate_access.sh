#!/bin/bash

# ===============================
# FUNGSI VALIDASI MASA AKTIF UNIVERSAL
# ===============================

# Warna
green="\e[38;5;87m"
red="\e[38;5;196m"
neutral="\e[0m"
yellow="\e[38;5;226m"
blue="\e[38;5;130m"

# Fungsi untuk memvalidasi masa aktif sebelum mengakses menu
validate_user_access() {
    # Ambil IP server
    MYIP=$(curl -sS ipv4.icanhazip.com 2>/dev/null)
    
    # URL data izin
    url_izin="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/izin"
    
    # Ambil data dari GitHub dengan format baru: ### User Date IP
    data_izin=$(curl -sS "$url_izin" 2>/dev/null)
    user_line=$(echo "$data_izin" | grep "$MYIP")
    
    if [ -n "$user_line" ]; then
        username=$(echo "$user_line" | awk '{print $2}')
        valid=$(echo "$user_line" | awk '{print $3}')
    else
        username=""
        valid=""
    fi
    
    # Cek jika data user tidak ditemukan
    if [ -z "$username" ] || [ -z "$valid" ]; then
        clear
        echo -e "${red}╔════════════════════════════════════════════════════════════════╗${neutral}"
        echo -e "${red}║                           AKSES DITOLAK                        ║${neutral}"
        echo -e "${red}╠════════════════════════════════════════════════════════════════╣${neutral}"
        echo -e "${red}║  IP Anda (${MYIP}) tidak terdaftar dalam sistem                ║${neutral}"
        echo -e "${red}║                                                                ║${neutral}"
        echo -e "${red}║  Silakan hubungi administrator untuk mendapatkan akses:        ║${neutral}"
        echo -e "${red}║  📱 Telegram: https://t.me/Alrescha79                          ║${neutral}"
        echo -e "${red}║  📧 Email: anggun@cakson.my.id                                 ║${neutral}"
        echo -e "${red}╚════════════════════════════════════════════════════════════════╝${neutral}"
        echo -e ""
        echo -e "${yellow}Tekan Enter untuk kembali ke menu utama...${neutral}"
        read
        menu
        exit 1
    fi
    
    # Cek masa aktif
    current_date=$(date +%Y-%m-%d)
    if [[ "$valid" < "$current_date" ]]; then
        # Hitung berapa hari sudah expired
        expired_days=$(( ( $(date -d "$current_date" +%s) - $(date -d "$valid" +%s) ) / 86400 ))
        
        clear
        echo -e "${red}╔════════════════════════════════════════════════════════════════╗${neutral}"
        echo -e "${red}║                        AKSES KADALUARSA                        ║${neutral}"
        echo -e "${red}╠════════════════════════════════════════════════════════════════╣${neutral}"
        echo -e "${red}║  Masa aktif script Anda telah berakhir!                        ║${neutral}"
        echo -e "${red}║                                                                ║${neutral}"
        echo -e "${red}║  Detail Akses:                                                 ║${neutral}"
        echo -e "${red}║    • User ID: ${username}                                      ║${neutral}"
        echo -e "${red}║    • IP Address: ${MYIP}                                       ║${neutral}"
        echo -e "${red}║    • Tanggal Kadaluarsa: ${valid}                              ║${neutral}"
        echo -e "${red}║    • Sudah Expired: ${expired_days} hari                       ║${neutral}"
        echo -e "${red}║                                                                ║${neutral}"
        echo -e "${red}║  Untuk memperpanjang masa aktif, hubungi:                      ║${neutral}"
        echo -e "${red}║  📱 Telegram: https://t.me/Alrescha79                          ║${neutral}"
        echo -e "${red}║  📧 Email: anggun@cakson.my.id                                 ║${neutral}"
        echo -e "${red}║                                                                ║${neutral}"
        echo -e "${red}║  💰 Informasi Harga & Paket Tersedia                           ║${neutral}"
        echo -e "${red}╚════════════════════════════════════════════════════════════════╝${neutral}"
        echo -e ""
        echo -e "${yellow}Tekan Enter untuk kembali ke menu utama...${neutral}"
        read
        menu
        exit 1
    fi
    
    # Tampilkan peringatan jika akan expired dalam 7 hari
    days_left=$(( ( $(date -d "$valid" +%s) - $(date -d "$current_date" +%s) ) / 86400 ))
    if [ "$days_left" -le 7 ] && [ "$days_left" -gt 0 ]; then
        echo -e "${yellow}╔════════════════════════════════════════════════════════════════╗${neutral}"
        echo -e "${yellow}║                            PERINGATAN                          ║${neutral}"
        echo -e "${yellow}╠════════════════════════════════════════════════════════════════╣${neutral}"
        echo -e "${yellow}║  ⚠️  Masa aktif script akan berakhir dalam ${days_left} hari!  ║${neutral}"
        echo -e "${yellow}║  Segera hubungi developer untuk perpanjangan akses.            ║${neutral}"
        echo -e "${yellow}║  📱 Telegram: https://t.me/Alrescha79                          ║${neutral}"
        echo -e "${yellow}╚════════════════════════════════════════════════════════════════╝${neutral}"
        echo -e ""
        sleep 2
    fi
}

# Export fungsi agar bisa digunakan oleh script lain
export -f validate_user_access