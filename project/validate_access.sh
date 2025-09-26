#!/bin/bash

# ===============================
# SCRIPT VALIDASI AKSES VPS
# ===============================
# Script ini memvalidasi IP dan masa aktif VPS
# Digunakan oleh semua menu dalam sistem
# Author: Alrescha79

# Colors
red="\e[38;5;196m"
green="\e[38;5;87m"
yellow="\e[38;5;226m"
neutral="\e[0m"
blue="\e[38;5;130m"
orange="\e[38;5;99m"

# ===============================
# DAPATKAN IP PUBLIK VPS
# ===============================
get_server_info() {
    # Coba beberapa service untuk mendapatkan IP publik dengan fallback
    local ip_services=(
        "https://ipv4.icanhazip.com"
        "https://api.ipify.org"
        "https://ifconfig.me/ip"
        "https://ipecho.net/plain"
    )
    
    for service in "${ip_services[@]}"; do
        ipsaya=$(curl -s --connect-timeout 10 --max-time 15 "$service" 2>/dev/null | tr -d '\n\r' | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')
        if [ -n "$ipsaya" ]; then
            break
        fi
    done
    
    # Jika masih tidak mendapat IP, coba dengan method lain
    if [ -z "$ipsaya" ]; then
        ipsaya=$(wget -qO- --timeout=10 ipv4.icanhazip.com 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')
    fi
    
    # Fallback ke IP dari hostname jika semua gagal
    if [ -z "$ipsaya" ]; then
        ipsaya=$(hostname -I | awk '{print $1}')
    fi
    
    MYIP=$ipsaya
    
    # Dapatkan tanggal server
    data_server=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
    if [ -z "$data_server" ]; then
        date_list=$(date +"%Y-%m-%d")
    else
        date_list=$(date +"%Y-%m-%d" -d "$data_server")
    fi
}

# ===============================
# AMBIL DATA CLIENT DARI GITHUB
# ===============================
get_client_data() {
    # URL data izin
    local url_izin="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/izin"
    
    # Coba ambil data dengan retry mechanism
    local max_retries=3
    local retry_count=0
    local data_izin=""
    
    while [ $retry_count -lt $max_retries ] && [ -z "$data_izin" ]; do
        data_izin=$(curl -sS --connect-timeout 10 --max-time 20 "$url_izin" 2>/dev/null)
        if [ -z "$data_izin" ]; then
            retry_count=$((retry_count + 1))
            sleep 2
        fi
    done
    
    # Jika masih gagal, coba dengan wget
    if [ -z "$data_izin" ]; then
        data_izin=$(wget -qO- --timeout=15 "$url_izin" 2>/dev/null)
    fi
    
    if [ -n "$data_izin" ]; then
        # Cari data berdasarkan IP dengan format: ### User Date IP
        user_line=$(echo "$data_izin" | grep -F "$MYIP")
        
        if [ -n "$user_line" ]; then
            username=$(echo "$user_line" | awk '{print $2}')
            valid=$(echo "$user_line" | awk '{print $3}')
        else
            username=""
            valid=""
        fi
    else
        username=""
        valid=""
    fi

    # Simpan data untuk penggunaan oleh script lain
    # Gunakan /tmp sebagai fallback jika /usr/bin tidak writable
    if [ -w /usr/bin ]; then
        echo "$username" > /usr/bin/user 2>/dev/null
        echo "$valid" > /usr/bin/e 2>/dev/null
    else
        mkdir -p /tmp/sc-vpn 2>/dev/null
        echo "$username" > /tmp/sc-vpn/user 2>/dev/null
        echo "$valid" > /tmp/sc-vpn/e 2>/dev/null
        # Buat symlink untuk kompatibilitas
        ln -sf /tmp/sc-vpn/user /usr/bin/user 2>/dev/null
        ln -sf /tmp/sc-vpn/e /usr/bin/e 2>/dev/null
    fi
}

# ===============================
# FUNGSI VALIDASI MASA AKTIF
# ===============================
validate_user_access() {
    # Dapatkan informasi server dan client
    get_server_info
    get_client_data
    
    # Debug info (bisa dihilangkan di production)
    # echo "DEBUG: IP detected = $MYIP"
    # echo "DEBUG: Username = $username"
    # echo "DEBUG: Valid until = $valid"
    
    # Cek jika IP tidak terdeteksi
    if [ -z "$MYIP" ] || [ "$MYIP" = "127.0.0.1" ] || [ "$MYIP" = "localhost" ]; then
        clear
        echo -e "${red}╔════════════════════════════════════════════════════════════════╗${neutral}"
        echo -e "${red}║                        ERROR JARINGAN                          ║${neutral}"
        echo -e "${red}╠════════════════════════════════════════════════════════════════╣${neutral}"
        echo -e "${red}║  Tidak dapat mendeteksi IP publik server ini.                  ║${neutral}"
        echo -e "${red}║  Pastikan koneksi internet tersedia dan coba lagi.             ║${neutral}"
        echo -e "${red}║                                                                ║${neutral}"
        echo -e "${red}║  Jika masalah berlanjut, hubungi administrator:                ║${neutral}"
        echo -e "${red}║  📱 Telegram: https://t.me/Alrescha79                          ║${neutral}"
        echo -e "${red}╚════════════════════════════════════════════════════════════════╝${neutral}"
        echo -e ""
        echo -e "${yellow}Tekan Enter untuk keluar...${neutral}"
        read
        exit 1
    fi
    
    # Cek jika data user tidak ditemukan
    if [ -z "$username" ] || [ -z "$valid" ]; then
        clear
        echo -e "${red}╔════════════════════════════════════════════════════════════════╗${neutral}"
        echo -e "${red}║                           AKSES DITOLAK                        ║${neutral}"
        echo -e "${red}╠════════════════════════════════════════════════════════════════╣${neutral}"
        echo -e "${red}║  IP Server: ${orange}${MYIP}${red}                                    ║${neutral}"
        echo -e "${red}║  Status: ${orange}TIDAK TERDAFTAR${red}                                ║${neutral}"
        echo -e "${red}║                                                                ║${neutral}"
        echo -e "${red}║  IP server ini belum terdaftar dalam sistem kami.              ║${neutral}"
        echo -e "${red}║  Silakan hubungi administrator untuk registrasi:               ║${neutral}"
        echo -e "${red}║                                                                ║${neutral}"
        echo -e "${red}║  📱 Telegram: https://t.me/Alrescha79                          ║${neutral}"
        echo -e "${red}║  📧 Email: anggun@cakson.my.id                                 ║${neutral}"
        echo -e "${red}║  💬 WhatsApp: +62-xxx-xxxx-xxxx                                ║${neutral}"
        echo -e "${red}║                                                                ║${neutral}"
        echo -e "${red}║  💡 Sertakan IP server ini saat menghubungi admin              ║${neutral}"
        echo -e "${red}╚════════════════════════════════════════════════════════════════╝${neutral}"
        echo -e ""
        echo -e "${yellow}Tekan Enter untuk keluar...${neutral}"
        read
        exit 1
    fi
    
    # Validasi format tanggal
    if ! date -d "$valid" >/dev/null 2>&1; then
        clear
        echo -e "${red}╔════════════════════════════════════════════════════════════════╗${neutral}"
        echo -e "${red}║                       ERROR KONFIGURASI                        ║${neutral}"
        echo -e "${red}╠════════════════════════════════════════════════════════════════╣${neutral}"
        echo -e "${red}║  Format tanggal expiry tidak valid: ${valid}                   ║${neutral}"
        echo -e "${red}║  Hubungi administrator untuk perbaikan.                        ║${neutral}"
        echo -e "${red}╚════════════════════════════════════════════════════════════════╝${neutral}"
        echo -e ""
        echo -e "${yellow}Tekan Enter untuk keluar...${neutral}"
        read
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
        echo -e "${red}║  📋 Detail Akses:                                              ║${neutral}"
        echo -e "${red}║    👤 User ID: ${orange}${username}${red}                               ║${neutral}"
        echo -e "${red}║    🌐 IP Address: ${orange}${MYIP}${red}                               ║${neutral}"
        echo -e "${red}║    📅 Expired Date: ${orange}${valid}${red}                            ║${neutral}"
        echo -e "${red}║    ⏰ Sudah Expired: ${orange}${expired_days} hari${red}                   ║${neutral}"
        echo -e "${red}║                                                                ║${neutral}"
        echo -e "${red}║  🔄 Untuk memperpanjang masa aktif, hubungi:                   ║${neutral}"
        echo -e "${red}║    📱 Telegram: https://t.me/Alrescha79                        ║${neutral}"
        echo -e "${red}║    📧 Email: anggun@cakson.my.id                               ║${neutral}"
        echo -e "${red}║    💬 WhatsApp: +62-xxx-xxxx-xxxx                              ║${neutral}"
        echo -e "${red}║                                                                ║${neutral}"
        echo -e "${red}║  💰 Informasi Harga & Paket Tersedia                           ║${neutral}"
        echo -e "${red}║  🎯 Perpanjangan Otomatis Tersedia                             ║${neutral}"
        echo -e "${red}╚════════════════════════════════════════════════════════════════╝${neutral}"
        echo -e ""
        echo -e "${yellow}Tekan Enter untuk keluar...${neutral}"
        read
        exit 1
    fi
    
    # Tampilkan info sukses jika diperlukan (bisa di-comment untuk production)
    local days_left=$(( ( $(date -d "$valid" +%s) - $(date -d "$current_date" +%s) ) / 86400 ))
    if [ "$1" = "--show-success" ]; then
        echo -e "${green}✅ Akses Valid - User: ${username} | IP: ${MYIP} | Sisa: ${days_left} hari${neutral}"
        sleep 1
    fi
    
    # Jika sampai di sini, berarti akses valid
    return 0
}

# ===============================
# EXPORT FUNGSI UNTUK DIGUNAKAN SCRIPT LAIN
# ===============================
export -f validate_user_access
export -f get_server_info
export -f get_client_data