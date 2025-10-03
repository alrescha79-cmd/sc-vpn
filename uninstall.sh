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
echo -e "${red}║                          UNINSTALLER VPN PANEL                           ║${neutral}"
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

# Stop all VPN services
show_progress "Menghentikan semua service VPN..."
services=(
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
    "dropbear.service"
    "openvpn.service"
    "xray.service"
)

for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        systemctl stop "$service" && echo -e "  ${green}✓${neutral} Stopped $service"
    fi
    if systemctl is-enabled --quiet "$service" 2>/dev/null; then
        systemctl disable "$service" && echo -e "  ${green}✓${neutral} Disabled $service"
    fi
done

# Remove systemd service files
show_progress "Menghapus file service systemd..."
service_files=(
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
)

for file in "${service_files[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        rm -rf "$file" && echo -e "  ${green}✓${neutral} Removed $file"
    fi
done

systemctl daemon-reload

# Remove cron jobs
show_progress "Menghapus cron jobs..."
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

# Remove configuration directories and files
show_progress "Menghapus direktori dan file konfigurasi..."
config_dirs=(
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

for dir in "${config_dirs[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir" && echo -e "  ${green}✓${neutral} Removed directory $dir"
    fi
done

# Remove configuration files
config_files=(
    "/etc/haproxy/haproxy.cfg"
    "/etc/nginx/conf.d/xray.conf"
    "/etc/nginx/nginx.conf"
    "/etc/ssh/sshd_config"
    "/etc/default/dropbear"
    "/etc/init.d/dropbear"
    "/etc/dropbear/dropbear_dss_host_key"
    "/etc/gerhanatunnel.txt"
    "/etc/pam.d/common-password"
    "/var/www/html/client-tcp.ovpn"
    "/var/www/html/client-udp.ovpn"
    "/var/www/html/client-ssl.ovpn"
    "/var/www/html/allovpn.zip"
    "/root/.profile"
    "/root/.bashrc"
    "/root/.key"
    "/etc/shells"
)

for file in "${config_files[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file" && echo -e "  ${green}✓${neutral} Removed $file"
    fi
done

# Remove binaries and executables
show_progress "Menghapus binary dan executable..."
binaries=(
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

# Add menu scripts from /usr/bin
menu_scripts=(
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
    "/usr/bin/check-license"
)

# Combine all binaries
all_binaries=("${binaries[@]}" "${menu_scripts[@]}")

for binary in "${all_binaries[@]}"; do
    if [ -f "$binary" ]; then
        rm -f "$binary" && echo -e "  ${green}✓${neutral} Removed $binary"
    fi
done

# Remove HAProxy certificate
if [ -f "/etc/haproxy/yha.pem" ]; then
    rm -f "/etc/haproxy/yha.pem" && echo -e "  ${green}✓${neutral} Removed HAProxy certificate"
fi

# Remove swap file if created by the script
show_progress "Menghapus swap file..."
if [ -f "/swapfile" ]; then
    swapoff /swapfile 2>/dev/null
    rm -f /swapfile
    # Remove from fstab
    sed -i '/\/swapfile/d' /etc/fstab
    echo -e "  ${green}✓${neutral} Removed swap file"
fi

# Clean iptables rules
show_progress "Membersihkan iptables rules..."
iptables -t nat -F PREROUTING 2>/dev/null
iptables -t nat -F POSTROUTING 2>/dev/null
iptables -F 2>/dev/null
iptables -X 2>/dev/null
iptables-save > /etc/iptables/rules.v4 2>/dev/null
echo -e "  ${green}✓${neutral} Cleaned iptables rules"

# Remove packages installed by the script
show_progress "Menghapus paket yang diinstal..."
packages_to_remove=(
    "haproxy"
    "nginx"
    "openvpn"
    "easy-rsa"
    "dropbear"
    "vnstat"
)

for package in "${packages_to_remove[@]}"; do
    if dpkg -s "$package" >/dev/null 2>&1; then
        apt-get remove --purge -y "$package" >/dev/null 2>&1 && echo -e "  ${green}✓${neutral} Removed package $package"
    fi
done

# Remove nginx repository
show_progress "Menghapus repository nginx..."
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
show_progress "Menghapus repository haproxy..."
if [ -f "/etc/apt/sources.list.d/haproxy.list" ]; then
    rm -f "/etc/apt/sources.list.d/haproxy.list"
fi
if [ -f "/usr/share/keyrings/haproxy.debian.net.gpg" ]; then
    rm -f "/usr/share/keyrings/haproxy.debian.net.gpg"
fi

# Remove Node.js if it was installed by the script
show_progress "Menghapus Node.js dan npm packages..."
if command -v npm >/dev/null 2>&1; then
    npm uninstall -g express express-fileupload 2>/dev/null
fi

# Clean temporary files
show_progress "Membersihkan file temporary..."
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

# Reset sysctl configurations that were added by the script
show_progress "Mereset konfigurasi sysctl..."
if [ -f "/etc/sysctl.conf.backup" ]; then
    mv /etc/sysctl.conf.backup /etc/sysctl.conf
    echo -e "  ${green}✓${neutral} Restored original sysctl.conf"
else
    # Remove specific lines added by the setup script
    sed -i '/net.core.default_qdisc = fq/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control = bbr/d' /etc/sysctl.conf
    sed -i '/net.ipv4.ip_forward=1/d' /etc/sysctl.conf
    sed -i '/net.ipv4.conf.all.route_localnet=1/d' /etc/sysctl.conf
    echo -e "  ${green}✓${neutral} Cleaned sysctl.conf"
fi

# Reset timezone
show_progress "Mereset timezone ke default..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Clean systemd configurations
show_progress "Membersihkan konfigurasi systemd..."
if [ -f "/etc/systemd/system.conf.backup" ]; then
    mv /etc/systemd/system.conf.backup /etc/systemd/system.conf
else
    sed -i '/DefaultTimeoutStopSec=30s/d' /etc/systemd/system.conf
    sed -i '/DefaultLimitCORE=infinity/d' /etc/systemd/system.conf
    sed -i '/DefaultLimitNOFILE=65535/d' /etc/systemd/system.conf
fi

# Reset security limits
show_progress "Mereset security limits..."
if [ -f "/etc/security/limits.conf.backup" ]; then
    mv /etc/security/limits.conf.backup /etc/security/limits.conf
else
    sed -i '/\* soft nofile 65535/d' /etc/security/limits.conf
    sed -i '/\* hard nofile 65535/d' /etc/security/limits.conf
    sed -i '/root soft nofile 51200/d' /etc/security/limits.conf
    sed -i '/root hard nofile 51200/d' /etc/security/limits.conf
fi

# Reload systemd and sysctl
systemctl daemon-reload
sysctl -p >/dev/null 2>&1

# Clean package cache
show_progress "Membersihkan cache paket..."
apt-get autoremove -y >/dev/null 2>&1
apt-get autoclean >/dev/null 2>&1

# Clean logs
show_progress "Membersihkan log files..."
> /var/log/auth.log
> /var/log/syslog
> /var/log/daemon.log
journalctl --vacuum-time=1d >/dev/null 2>&1

echo -e ""
echo -e "${green}╔═══════════════════════════════════════════════════════════════════════════╗${neutral}"
echo -e "${green}║                              UNINSTALL SELESAI                            ║${neutral}"
echo -e "${green}╚═══════════════════════════════════════════════════════════════════════════╝${neutral}"
echo -e ""
echo -e "${green}Proses uninstall telah selesai!${neutral}"
echo -e ""
echo -e "${blue}Yang telah dihapus:${neutral}"
echo -e "${gray}  ✓ Semua service VPN (Xray, OpenVPN, HAProxy, Nginx)${neutral}"
echo -e "${gray}  ✓ Database pengguna dan konfigurasi${neutral}"
echo -e "${gray}  ✓ Sertifikat SSL${neutral}"
echo -e "${gray}  ✓ Cron jobs dan scheduled tasks${neutral}"
echo -e "${gray}  ✓ Binary dan executable files${neutral}"
echo -e "${gray}  ✓ Repository dan preferences${neutral}"
echo -e "${gray}  ✓ Iptables rules${neutral}"
echo -e "${gray}  ✓ Swap file${neutral}"
echo -e "${gray}  ✓ Log files${neutral}"
echo -e ""
echo -e "${yellow}REKOMENDASI:${neutral}"
echo -e "${gray}  • Restart server untuk memastikan semua perubahan diterapkan${neutral}"
echo -e "${gray}  • Periksa kembali apakah ada file konfigurasi yang tertinggal${neutral}"
echo -e "${gray}  • Update sistem jika diperlukan${neutral}"
echo -e ""

read -p "Apakah Anda ingin restart server sekarang? (y/n): " restart_choice

if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
    echo -e "${blue}Server akan restart dalam 5 detik...${neutral}"
    sleep 5
    reboot
else
    echo -e "${yellow}Silakan restart server secara manual untuk menyelesaikan proses uninstall.${neutral}"
fi

echo -e ""
echo -e "${blue}Terima kasih telah menggunakan Alrescha79 VPN Panel!${neutral}"