#!/bin/bash

# ===============================
# MANAGER DATA IZIN VPS
# ===============================
# Script untuk mengelola data izin akses VPS
# Author: Alrescha79

# Colors
green="\e[38;5;87m"
red="\e[38;5;196m"
yellow="\e[38;5;226m"
neutral="\e[0m"
blue="\e[38;5;130m"

IZIN_FILE="/home/son/Projects/sclite/izin"

echo -e "${blue}════════════════════════════════════════════════════════════════${neutral}"
echo -e "${blue}║                     MANAGER DATA IZIN VPS                      ║${neutral}"
echo -e "${blue}════════════════════════════════════════════════════════════════${neutral}"

# ===============================
# FUNCTIONS
# ===============================

show_current_data() {
    echo -e "${yellow}📋 Data izin saat ini:${neutral}"
    echo ""
    if [ -f "$IZIN_FILE" ]; then
        echo "┌────────────────┬────────────┬─────────────────┐"
        echo "│ Username       │ Expired    │ IP Address      │"
        echo "├────────────────┼────────────┼─────────────────┤"
        
        while IFS= read -r line; do
            if [[ $line == ###* ]]; then
                username=$(echo "$line" | awk '{print $2}')
                expired=$(echo "$line" | awk '{print $3}')
                ip=$(echo "$line" | awk '{print $4}')
                
                # Calculate days left
                current_date=$(date +%Y-%m-%d)
                if [[ "$expired" > "$current_date" ]]; then
                    days_left=$(( ( $(date -d "$expired" +%s) - $(date -d "$current_date" +%s) ) / 86400 ))
                    status="${green}${days_left}d${neutral}"
                else
                    days_left=$(( ( $(date -d "$current_date" +%s) - $(date -d "$expired" +%s) ) / 86400 ))
                    status="${red}Exp ${days_left}d${neutral}"
                fi
                
                printf "│ %-14s │ %-10s │ %-15s │ %s\n" "$username" "$expired" "$ip" "$status"
            fi
        done < "$IZIN_FILE"
        
        echo "└────────────────┴────────────┴─────────────────┘"
    else
        echo -e "${red}File izin tidak ditemukan!${neutral}"
    fi
    echo ""
}

add_user() {
    echo -e "${yellow}➕ Tambah User Baru${neutral}"
    echo ""
    
    read -p "Username: " username
    read -p "IP Address: " ip
    read -p "Masa aktif (hari): " days
    
    # Validate input
    if [ -z "$username" ] || [ -z "$ip" ] || [ -z "$days" ]; then
        echo -e "${red}❌ Semua field harus diisi!${neutral}"
        return
    fi
    
    # Calculate expiry date
    expiry_date=$(date -d "+${days} days" +%Y-%m-%d)
    
    # Add to file
    echo "### $username $expiry_date $ip" >> "$IZIN_FILE"
    
    echo -e "${green}✅ User $username berhasil ditambahkan!${neutral}"
    echo -e "   IP: $ip"
    echo -e "   Expired: $expiry_date ($days hari dari sekarang)"
    echo ""
}

remove_user() {
    echo -e "${yellow}🗑️  Hapus User${neutral}"
    echo ""
    
    show_current_data
    
    read -p "Masukkan username yang akan dihapus: " username
    
    if [ -z "$username" ]; then
        echo -e "${red}❌ Username tidak boleh kosong!${neutral}"
        return
    fi
    
    # Check if user exists
    if grep -q "### $username " "$IZIN_FILE"; then
        # Remove user
        sed -i "/### $username /d" "$IZIN_FILE"
        echo -e "${green}✅ User $username berhasil dihapus!${neutral}"
    else
        echo -e "${red}❌ User $username tidak ditemukan!${neutral}"
    fi
    echo ""
}

extend_user() {
    echo -e "${yellow}📅 Perpanjang Masa Aktif${neutral}"
    echo ""
    
    show_current_data
    
    read -p "Masukkan username: " username
    read -p "Tambah masa aktif (hari): " add_days
    
    if [ -z "$username" ] || [ -z "$add_days" ]; then
        echo -e "${red}❌ Semua field harus diisi!${neutral}"
        return
    fi
    
    # Check if user exists
    if grep -q "### $username " "$IZIN_FILE"; then
        # Get current data
        user_line=$(grep "### $username " "$IZIN_FILE")
        current_ip=$(echo "$user_line" | awk '{print $4}')
        current_expiry=$(echo "$user_line" | awk '{print $3}')
        
        # Calculate new expiry
        new_expiry=$(date -d "$current_expiry + ${add_days} days" +%Y-%m-%d)
        
        # Update file
        sed -i "s/### $username $current_expiry $current_ip/### $username $new_expiry $current_ip/" "$IZIN_FILE"
        
        echo -e "${green}✅ Masa aktif $username berhasil diperpanjang!${neutral}"
        echo -e "   Expired lama: $current_expiry"
        echo -e "   Expired baru: $new_expiry"
    else
        echo -e "${red}❌ User $username tidak ditemukan!${neutral}"
    fi
    echo ""
}

# ===============================
# MAIN MENU
# ===============================
while true; do
    echo -e "${blue}🔧 Pilih Aksi:${neutral}"
    echo "1. Lihat Data Izin"
    echo "2. Tambah User"
    echo "3. Hapus User"
    echo "4. Perpanjang User"
    echo "5. Keluar"
    echo ""
    
    read -p "Pilih menu [1-5]: " choice
    
    case $choice in
        1) show_current_data ;;
        2) add_user ;;
        3) remove_user ;;
        4) extend_user ;;
        5) 
            echo -e "${green}👋 Terima kasih!${neutral}"
            exit 0
            ;;
        *)
            echo -e "${red}❌ Pilihan tidak valid!${neutral}"
            echo ""
            ;;
    esac
done