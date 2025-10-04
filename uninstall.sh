#!/bin/bash

# VPN Panel Uninstaller Script
# This script removes all components installed by the setup.sh script
# Author: Alrescha79 Panel VPN

# Color definitions
green="\e[38;5;82m"
red="\e[38;5;196m"
neutral="\e[0m"
orange="\e[38;5;130m"
blue="\e[38;5;39m"
yellow="\e[38;5;226m"
purple="\e[38;5;141m"
bold_white="\e[1;37m"
pink="\e[38;5;205m"
reset="\e[0m"
gray="\e[38;5;245m"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${red}Script ini harus dijalankan sebagai root${neutral}"
    exit 1
fi

clear

echo -e "${red}╔═══════════════════════════════════════════════════════════════════════════╗${neutral}"
echo -e "${red}║                            UNINSTALLER VPN PANEL                          ║${neutral}"
echo -e "${red}║                              Alrescha79 Script                            ║${neutral}"
echo -e "${red}╚═══════════════════════════════════════════════════════════════════════════╝${neutral}"
echo -e ""
echo -e "${yellow}PERINGATAN: Script ini akan menghapus SEMUA komponen VPN Panel!${neutral}"
echo -e "${yellow}Termasuk:${neutral}"
echo -e "${gray}  • Semua konfigurasi VPN (OpenVPN, Xray, HAProxy, Nginx)${neutral}"
echo -e "${gray}  • Database pengguna dan log${neutral}"
echo -e "${gray}  • Sertifikat SSL${neutral}"
echo -e "${gray}  • Service dan cron jobs${neutral}"
echo -e "${gray}  • Paket yang diinstal${neutral}"
echo -e ""
echo -e "${green}YANG TIDAK AKAN DIHAPUS:${neutral}"
echo -e "${green}  ✓ SSH service dan konfigurasi (untuk akses remote)${neutral}"
echo -e "${green}  ✓ Sistem operasi dasar${neutral}"
echo -e "${green}  ✓ Paket sistem penting${neutral}"
echo -e ""
echo -e "${red}Tindakan ini TIDAK DAPAT DIBATALKAN!${neutral}"
echo -e ""

read -p "Apakah Anda yakin ingin melanjutkan? (ketik 'yes' untuk konfirmasi): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${yellow}Uninstall dibatalkan.${neutral}"
    exit 0
fi

echo -e ""
echo -e "${blue}Memulai proses uninstall...${neutral}"
echo -e ""

# Function to show progress
show_progress() {
    echo -e "${blue}[INFO]${neutral} $1"
}

show_error() {
    echo -e "${red}[ERROR]${neutral} $1"
}

show_success() {
    echo -e "${green}[SUCCESS]${neutral} $1"
}

# Backup SSH configuration before proceeding
show_progress "Backup konfigurasi SSH untuk keamanan..."
if [ -f "/etc/ssh/sshd_config" ]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.uninstall
    echo -e "  ${green}✓${neutral} SSH config backed up"
fi

# Stop VPN services ONLY (exclude SSH and system services)
show_progress "Menghentikan service VPN saja (SSH tetap aktif)..."
vpn_services=(
    "vmess@config.service"
    "vless@config.service"
    "trojan@config.service"
    "shadowsocks@config.service"
    "haproxy.service"
    "ws.service"
    "udp.service"
    "limitip.service"
    "limitquota.service"
    "badvpn.service"
    "nginx.service"
    "dropbear.service"  # Dropbear bukan SSH utama
    "openvpn.service"
    "xray.service"
    "license-monitor.timer"      # License monitor
    "license-monitor.service"    # License monitor
)

for service in "${vpn_services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        systemctl stop "$service" && echo -e "  ${green}✓${neutral} Stopped $service"
    fi
    if systemctl is-enabled --quiet "$service" 2>/dev/null; then
        systemctl disable "$service" && echo -e "  ${green}✓${neutral} Disabled $service"
    fi
done

# Remove systemd service files (VPN related only)
show_progress "Menghapus file service VPN..."
vpn_service_files=(
    "/etc/systemd/system/vmess@config.service"
    "/etc/systemd/system/vless@config.service"
    "/etc/systemd/system/trojan@config.service"
    "/etc/systemd/system/shadowsocks@config.service"
    "/etc/systemd/system/ws.service"
    "/etc/systemd/system/udp.service"
    "/etc/systemd/system/limitip.service"
    "/etc/systemd/system/limitquota.service"
    "/etc/systemd/system/badvpn.service"
    "/etc/systemd/system/xray@.service.d/10-donot_touch_single_conf.conf"
    "/etc/systemd/system/xray@.service.d"
    "/lib/systemd/system/dropbear.service"
    "/etc/systemd/system/license-monitor.service"
    "/etc/systemd/system/license-monitor.timer"
)

for file in "${vpn_service_files[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        rm -rf "$file" && echo -e "  ${green}✓${neutral} Removed $file"
    fi
done

systemctl daemon-reload

# Remove cron jobs
show_progress "Menghapus cron jobs VPN..."
cron_files=(
    "/etc/cron.d/xp_all"
    "/etc/cron.d/daily_reboot"
    "/etc/cron.d/logclear"
)

for cron_file in "${cron_files[@]}"; do
    if [ -f "$cron_file" ]; then
        rm -f "$cron_file" && echo -e "  ${green}✓${neutral} Removed $cron_file"
    fi
done

# Remove VPN configuration directories and files
show_progress "Menghapus direktori konfigurasi VPN..."
vpn_config_dirs=(
    "/etc/xray"
    "/etc/vmess"
    "/etc/vless"
    "/etc/trojan"
    "/etc/shadowsocks"
    "/var/log/xray"
    "/etc/openvpn"
    "/root/.acme.sh"
    "/var/log/setup"
    "/home/daily_reboot"
)

for dir in "${vpn_config_dirs[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir" && echo -e "  ${green}✓${neutral} Removed directory $dir"
    fi
done

# Remove VPN configuration files (EXCLUDE SSH!)
show_progress "Menghapus file konfigurasi VPN..."
vpn_config_files=(
    "/etc/haproxy/haproxy.cfg"
    "/etc/nginx/conf.d/xray.conf"
    "/etc/nginx/nginx.conf"
    # "/etc/ssh/sshd_config"  # ← DIHAPUS! SSH tidak boleh dihapus
    "/etc/default/dropbear"
    "/etc/init.d/dropbear"
    "/etc/dropbear/dropbear_dss_host_key"
    "/etc/gerhanatunnel.txt"
    # "/etc/pam.d/common-password"  # ← DIHAPUS! Sistem penting
    "/var/www/html/client-tcp.ovpn"
    "/var/www/html/client-udp.ovpn"
    "/var/www/html/client-ssl.ovpn"
    "/var/www/html/allovpn.zip"
    # "/root/.profile"  # ← DIHAPUS! Bisa ada konfigurasi penting
    # "/root/.bashrc"   # ← DIHAPUS! Bisa ada konfigurasi penting
    "/root/.key"
    # "/etc/shells"     # ← DIHAPUS! Sistem penting
)

for file in "${vpn_config_files[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file" && echo -e "  ${green}✓${neutral} Removed $file"
    fi
done

# Remove VPN binaries and executables
show_progress "Menghapus binary dan executable VPN..."
vpn_binaries=(
    "/usr/bin/gotop"
    "/usr/bin/ws.py"
    "/usr/bin/udp"
    "/usr/bin/badvpn"
    "/usr/bin/config.json"
    "/usr/local/bin/xray"
    "/usr/local/bin/add-vmess"
    "/usr/local/bin/add-vless"
    "/usr/local/bin/add-trojan"
    "/usr/local/bin/add-shadowsocks"
    "/usr/local/bin/add-ssh"
    "/usr/local/bin/del-vmess"
    "/usr/local/bin/del-vless"
    "/usr/local/bin/del-trojan"
    "/usr/local/bin/del-shadowsocks"
    "/usr/local/bin/del-ssh"
    "/usr/local/bin/check-vmess"
    "/usr/local/bin/check-vless"
    "/usr/local/bin/check-trojan"
    "/usr/local/bin/check-shadowsocks"
    "/usr/local/bin/check-ssh"
    "/usr/local/bin/renew-vmess"
    "/usr/local/bin/renew-vless"
    "/usr/local/bin/renew-trojan"
    "/usr/local/bin/renew-shadowsocks"
    "/usr/local/bin/renew-ssh"
)

# VPN menu scripts from /usr/bin
vpn_menu_scripts=(
    "/usr/bin/addshadowsocks"
    "/usr/bin/addssh"
    "/usr/bin/addtrojan"
    "/usr/bin/addvless"
    "/usr/bin/addvmess"
    "/usr/bin/autokill"
    "/usr/bin/backuprestore"
    "/usr/bin/backuprestore.js"
    "/usr/bin/checkshadowsocks"
    "/usr/bin/chechssh"
    "/usr/bin/checktrojan"
    "/usr/bin/checkvless"
    "/usr/bin/checkvmess"
    "/usr/bin/dellshadowsocks"
    "/usr/bin/dellssh"
    "/usr/bin/delltrojan"
    "/usr/bin/dellvless"
    "/usr/bin/dellvmess"
    "/usr/bin/exp"
    "/usr/bin/features"
    "/usr/bin/limitip"
    "/usr/bin/limitssh"
    "/usr/bin/logclear"
    "/usr/bin/menu"
    "/usr/bin/menushadowsocks"
    "/usr/bin/menussh"
    "/usr/bin/menutrojan"
    "/usr/bin/menuvless"
    "/usr/bin/menuvmess"
    "/usr/bin/quota"
    "/usr/bin/renewssh"
    "/usr/bin/renewtrojan"
    "/usr/bin/renewvmess"
    "/usr/bin/renewvless"
    "/usr/bin/trial"
    "/usr/bin/trialvmess"
    "/usr/bin/trialvless"
    "/usr/bin/trialssh"
    "/usr/bin/trialshadowsoks"
    "/usr/bin/check-license"           # License monitor
    "/usr/bin/install-license-monitor" # License monitor installer
    "/usr/bin/uninstall-license-monitor" # License monitor uninstaller
)

# Combine VPN binaries
all_vpn_binaries=("${vpn_binaries[@]}" "${vpn_menu_scripts[@]}")

for binary in "${all_vpn_binaries[@]}"; do
    if [ -f "$binary" ]; then
        rm -f "$binary" && echo -e "  ${green}✓${neutral} Removed $binary"
    fi
done

# Remove HAProxy certificate
if [ -f "/etc/haproxy/yha.pem" ]; then
    rm -f "/etc/haproxy/yha.pem" && echo -e "  ${green}✓${neutral} Removed HAProxy certificate"
fi

# Remove swap file if created by the script (but ask first)
show_progress "Menangani swap file..."
if [ -f "/swapfile" ]; then
    echo -e "${yellow}Ditemukan swap file. Apakah ingin menghapusnya?${neutral}"
    read -p "Hapus swap file? (y/n): " remove_swap
    if [[ "$remove_swap" =~ ^[Yy]$ ]]; then
        swapoff /swapfile 2>/dev/null
        rm -f /swapfile
        sed -i '/\/swapfile/d' /etc/fstab
        echo -e "  ${green}✓${neutral} Removed swap file"
    else
        echo -e "  ${yellow}↪${neutral} Swap file dipertahankan"
    fi
fi

# Clean VPN-related iptables rules (preserve SSH rules!)
show_progress "Membersihkan iptables rules VPN (SSH rules dipertahankan)..."
# Only remove specific VPN-related rules, not all rules
# This is safer than flushing all tables
echo -e "  ${yellow}↪${neutral} Manual cleanup required for iptables VPN rules"
echo -e "  ${gray}  Gunakan: iptables -L untuk melihat rules aktif${neutral}"

# Remove VPN packages (keep system packages!)
show_progress "Menghapus paket VPN..."
vpn_packages_to_remove=(
    "haproxy"
    "nginx"
    "openvpn"
    "easy-rsa"
    "dropbear"  # Dropbear bukan SSH utama
    "vnstat"
)

for package in "${vpn_packages_to_remove[@]}"; do
    if dpkg -s "$package" >/dev/null 2>&1; then
        echo -e "${yellow}Hapus package $package? (y/n):${neutral}"
        read -p "> " remove_pkg
        if [[ "$remove_pkg" =~ ^[Yy]$ ]]; then
            apt-get remove --purge -y "$package" >/dev/null 2>&1 && echo -e "  ${green}✓${neutral} Removed package $package"
        else
            echo -e "  ${yellow}↪${neutral} Package $package dipertahankan"
        fi
    fi
done

# Remove nginx repository
show_progress "Menghapus repository VPN..."
if [ -f "/etc/apt/sources.list.d/nginx.list" ]; then
    rm -f "/etc/apt/sources.list.d/nginx.list"
fi
if [ -f "/usr/share/keyrings/nginx-archive-keyring.gpg" ]; then
    rm -f "/usr/share/keyrings/nginx-archive-keyring.gpg"
fi
if [ -f "/etc/apt/preferences.d/99nginx" ]; then
    rm -f "/etc/apt/preferences.d/99nginx"
fi

# Remove haproxy repository
if [ -f "/etc/apt/sources.list.d/haproxy.list" ]; then
    rm -f "/etc/apt/sources.list.d/haproxy.list"
fi
if [ -f "/usr/share/keyrings/haproxy.debian.net.gpg" ]; then
    rm -f "/usr/share/keyrings/haproxy.debian.net.gpg"
fi

# Clean temporary files
show_progress "Membersihkan file temporary VPN..."
temp_files=(
    "/tmp/gotop*"
    "/tmp/vnstat*"
    "/root/vnstat*"
    "/root/menu.sh"
    "/root/package-gohide.sh"
    "/opt/bbr.sh"
)

for pattern in "${temp_files[@]}"; do
    rm -rf $pattern 2>/dev/null
done

# SAFELY reset sysctl configurations (only VPN-related)
show_progress "Mereset konfigurasi sysctl VPN..."
if [ -f "/etc/sysctl.conf.backup" ]; then
    echo -e "${yellow}Ditemukan backup sysctl. Restore? (y/n):${neutral}"
    read -p "> " restore_sysctl
    if [[ "$restore_sysctl" =~ ^[Yy]$ ]]; then
        mv /etc/sysctl.conf.backup /etc/sysctl.conf
        echo -e "  ${green}✓${neutral} Restored original sysctl.conf"
    fi
else
    # Remove only specific VPN-related lines
    sed -i '/net.core.default_qdisc = fq/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control = bbr/d' /etc/sysctl.conf
    # Keep these as they might be needed: net.ipv4.ip_forward, route_localnet
    echo -e "  ${green}✓${neutral} Cleaned VPN-specific sysctl.conf entries"
fi

# Don't reset timezone - user might have set it intentionally
show_progress "Timezone dipertahankan..."
echo -e "  ${yellow}↪${neutral} Timezone tidak direset ($(cat /etc/timezone 2>/dev/null || echo 'Unknown'))"

# Clean systemd configurations (VPN-related only)
show_progress "Membersihkan konfigurasi systemd VPN..."
if [ -f "/etc/systemd/system.conf.backup" ]; then
    echo -e "${yellow}Restore backup systemd config? (y/n):${neutral}"
    read -p "> " restore_systemd
    if [[ "$restore_systemd" =~ ^[Yy]$ ]]; then
        mv /etc/systemd/system.conf.backup /etc/systemd/system.conf
    fi
else
    # Remove only VPN-related systemd configs
    sed -i '/DefaultTimeoutStopSec=30s/d' /etc/systemd/system.conf
fi

# Don't reset security limits - they might be needed for system
show_progress "Security limits dipertahankan untuk stabilitas sistem..."

# Reload systemd and sysctl
systemctl daemon-reload
sysctl -p >/dev/null 2>&1

# Clean package cache
show_progress "Membersihkan cache paket..."
apt-get autoremove -y >/dev/null 2>&1
apt-get autoclean >/dev/null 2>&1

# Clean VPN logs only (keep system logs!)
show_progress "Membersihkan log VPN saja..."
if [ -d "/var/log/xray" ]; then
    rm -rf /var/log/xray
fi
# Don't clean system logs as they're important for troubleshooting

echo -e ""
echo -e "${green}╔═══════════════════════════════════════════════════════════════════════════╗${neutral}"
echo -e "${green}║                              UNINSTALL SELESAI                            ║${neutral}"
echo -e "${green}╚═══════════════════════════════════════════════════════════════════════════╝${neutral}"
echo -e ""
echo -e "${green}Proses uninstall VPN Panel telah selesai dengan aman!${neutral}"
echo -e ""
echo -e "${blue}Yang telah dihapus:${neutral}"
echo -e "${gray}  ✓ Semua service VPN (Xray, OpenVPN, HAProxy, Nginx)${neutral}"
echo -e "${gray}  ✓ Database pengguna VPN dan konfigurasi${neutral}"
echo -e "${gray}  ✓ Sertifikat SSL VPN${neutral}"
echo -e "${gray}  ✓ Cron jobs VPN${neutral}"
echo -e "${gray}  ✓ Binary dan executable VPN${neutral}"
echo -e "${gray}  ✓ Repository VPN${neutral}"
echo -e "${gray}  ✓ Log VPN${neutral}"
echo -e "${gray}  ✓ License Monitor System${neutral}"
echo -e ""
echo -e "${green}Yang DIPERTAHANKAN untuk keamanan:${neutral}"
echo -e "${green}  ✓ SSH service dan konfigurasi${neutral}"
echo -e "${green}  ✓ Sistem operasi dasar${neutral}"
echo -e "${green}  ✓ Log sistem${neutral}"
echo -e "${green}  ✓ Konfigurasi jaringan dasar${neutral}"
echo -e "${green}  ✓ User accounts dan permissions${neutral}"
echo -e ""
echo -e "${blue}Status SSH: ${green}AMAN - Akses remote tetap berfungsi${neutral}"
echo -e ""
echo -e "${yellow}REKOMENDASI:${neutral}"
echo -e "${gray}  • SSH tetap aktif dan aman untuk akses remote${neutral}"
echo -e "${gray}  • Restart server tidak diperlukan (opsional)${neutral}"
echo -e "${gray}  • Periksa service yang masih berjalan: systemctl list-units${neutral}"
echo -e ""

echo -e "${blue}Terima kasih telah menggunakan Alrescha79 VPN Panel!${neutral}"
echo -e "${gray}Akses SSH Anda tetap aman dan berfungsi normal.${neutral}"