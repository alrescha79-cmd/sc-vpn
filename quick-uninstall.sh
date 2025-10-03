#!/bin/bash

# Quick Uninstaller for Alrescha79 VPN Panel
# This script downloads and runs the uninstaller

# Color definitions
green="\e[38;5;82m"
red="\e[38;5;196m"
neutral="\e[0m"
blue="\e[38;5;39m"
yellow="\e[38;5;226m"
gray="\e[38;5;245m"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${red}Script ini harus dijalankan sebagai root${neutral}"
    exit 1
fi

clear

echo -e "${blue}╔═══════════════════════════════════════════════════════════════════════════╗${neutral}"
echo -e "${blue}║                          QUICK UNINSTALLER                               ║${neutral}"
echo -e "${blue}║                        Alrescha79 VPN Panel                               ║${neutral}"
echo -e "${blue}╚═══════════════════════════════════════════════════════════════════════════╝${neutral}"
echo -e ""

echo -e "${yellow}Pilih opsi uninstall:${neutral}"
echo -e ""
echo -e "${blue}1.${neutral} Uninstall langsung (tanpa backup)"
echo -e "${blue}2.${neutral} Backup dulu, lalu uninstall"
echo -e "${blue}3.${neutral} Batal"
echo -e ""

read -p "Masukkan pilihan (1-3): " choice

case $choice in
    1)
        echo -e "${blue}Mengunduh uninstaller...${neutral}"
        if wget -q -O /tmp/uninstall.sh https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/dev/uninstall.sh; then
            chmod +x /tmp/uninstall.sh
            echo -e "${green}✓ Uninstaller berhasil diunduh${neutral}"
            echo -e "${blue}Menjalankan uninstaller...${neutral}"
            /tmp/uninstall.sh
        else
            echo -e "${red}✗ Gagal mengunduh uninstaller${neutral}"
            exit 1
        fi
        ;;
    2)
        echo -e "${blue}Mengunduh backup script...${neutral}"
        if wget -q -O /tmp/backup-before-uninstall.sh https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/dev/backup-before-uninstall.sh; then
            chmod +x /tmp/backup-before-uninstall.sh
            echo -e "${green}✓ Backup script berhasil diunduh${neutral}"
            echo -e "${blue}Menjalankan backup + uninstall...${neutral}"
            /tmp/backup-before-uninstall.sh
        else
            echo -e "${red}✗ Gagal mengunduh backup script${neutral}"
            exit 1
        fi
        ;;
    3)
        echo -e "${yellow}Dibatalkan oleh pengguna.${neutral}"
        exit 0
        ;;
    *)
        echo -e "${red}Pilihan tidak valid!${neutral}"
        exit 1
        ;;
esac

# Cleanup
rm -f /tmp/backup-before-uninstall.sh /tmp/uninstall.sh 2>/dev/null