#!/bin/bash

# Color definitions
red="\e[38;5;196m"
green="\e[38;5;82m"
yellow="\e[38;5;226m"
blue="\e[38;5;39m"
neutral="\e[0m"

echo -e "${blue}=== Installer Alrescha79 VPN License Monitor ===${neutral}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${red}Error: Script ini harus dijalankan sebagai root${neutral}"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

echo -e "${yellow}Menginstall License Monitor...${neutral}"

# Copy main script to /usr/bin
if cp "$SCRIPT_DIR/check-license.sh" /usr/bin/check-license; then
    chmod +x /usr/bin/check-license
    echo -e "${green}✓ Script utama telah diinstall ke /usr/bin/check-license${neutral}"
else
    echo -e "${red}✗ Gagal menginstall script utama${neutral}"
    exit 1
fi

# Copy systemd service and timer files
if cp "$SCRIPT_DIR/license-monitor.service" /etc/systemd/system/; then
    echo -e "${green}✓ Service file telah diinstall${neutral}"
else
    echo -e "${red}✗ Gagal menginstall service file${neutral}"
    exit 1
fi

if cp "$SCRIPT_DIR/license-monitor.timer" /etc/systemd/system/; then
    echo -e "${green}✓ Timer file telah diinstall${neutral}"
else
    echo -e "${red}✗ Gagal menginstall timer file${neutral}"
    exit 1
fi

# Reload systemd daemon
echo -e "${yellow}Memuat ulang systemd daemon...${neutral}"
if systemctl daemon-reload; then
    echo -e "${green}✓ Systemd daemon berhasil dimuat ulang${neutral}"
else
    echo -e "${red}✗ Gagal memuat ulang systemd daemon${neutral}"
    exit 1
fi

# Enable and start timer
echo -e "${yellow}Mengaktifkan timer untuk pengecekan otomatis...${neutral}"
if systemctl enable license-monitor.timer; then
    echo -e "${green}✓ Timer berhasil diaktifkan${neutral}"
else
    echo -e "${red}✗ Gagal mengaktifkan timer${neutral}"
fi

if systemctl start license-monitor.timer; then
    echo -e "${green}✓ Timer berhasil dimulai${neutral}"
else
    echo -e "${red}✗ Gagal memulai timer${neutral}"
fi

# Create log directory
mkdir -p /var/log/setup
echo -e "${green}✓ Direktori log telah dibuat${neutral}"

echo ""
echo -e "${green}=== Instalasi Selesai ===${neutral}"
echo -e "${blue}Perintah yang tersedia:${neutral}"
echo -e "  check-license --check          : Cek lisensi dan kelola layanan"
echo -e "  check-license --status         : Tampilkan status lisensi dan layanan"
echo -e "  check-license --start-services : Paksa mulai semua layanan"
echo -e "  check-license --stop-services  : Paksa hentikan semua layanan"
echo ""
echo -e "${blue}Systemd commands:${neutral}"
echo -e "  systemctl status license-monitor.timer  : Status timer"
echo -e "  systemctl stop license-monitor.timer    : Hentikan timer"
echo -e "  systemctl start license-monitor.timer   : Mulai timer"
echo ""
echo -e "${yellow}Timer akan menjalankan pengecekan lisensi setiap jam secara otomatis${neutral}"
echo -e "${yellow}Log tersimpan di: /var/log/setup/license.log${neutral}"

# Run initial check
echo ""
echo -e "${blue}Menjalankan pengecekan lisensi pertama kali...${neutral}"
/usr/bin/check-license --check