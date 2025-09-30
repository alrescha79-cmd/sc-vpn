#!/bin/bash

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

# Load Telegram configuration if available
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

echo -e "${blue}Mengkonfigurasi notifikasi Telegram...${neutral}"

# Encoded Telegram credentials (untuk keamanan dasar)
_bot_token="ODMyNjYwNTMxOTpBQUd1V2Q0aWwwTVY0VU1RNFpGWkZmRi1qaV9oSVcxVWZrRQo="
_chat_id="NjQ3MTQzMDI3Cg=="

# Decode credentials
TELEGRAM_BOT_TOKEN=$(echo "$_bot_token" | base64 -d 2>/dev/null || echo "")
TELEGRAM_CHAT_ID=$(echo "$_chat_id" | base64 -d 2>/dev/null || echo "")

# Set default notification settings
ENABLE_START_NOTIFICATION=true
ENABLE_SUCCESS_NOTIFICATION=true
ENABLE_UNAUTHORIZED_NOTIFICATION=true
ENABLE_EXPIRED_NOTIFICATION=true
TELEGRAM_PARSE_MODE="HTML"
TELEGRAM_TIMEOUT=10

if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    echo -e "${green}✓ Konfigurasi Telegram berhasil dimuat${neutral}"
    echo -e "${gray}Notifikasi akan dikirim ke admin script${neutral}" >/dev/stderr
else
    echo -e "${yellow}⚠ Konfigurasi Telegram tidak valid${neutral}"
    TELEGRAM_BOT_TOKEN=""
    TELEGRAM_CHAT_ID=""
fi

# Function to send Telegram notification
send_telegram_notification() {
    local message="$1"
    local parse_mode="${2:-$TELEGRAM_PARSE_MODE}"
    local notification_type="${3:-general}"
    
    # Check if the specific notification type is enabled
    case "$notification_type" in
        "start")
            [ "$ENABLE_START_NOTIFICATION" != "true" ] && return 0
            ;;
        "success")
            [ "$ENABLE_SUCCESS_NOTIFICATION" != "true" ] && return 0
            ;;
        "unauthorized")
            [ "$ENABLE_UNAUTHORIZED_NOTIFICATION" != "true" ] && return 0
            ;;
        "expired")
            [ "$ENABLE_EXPIRED_NOTIFICATION" != "true" ] && return 0
            ;;
    esac
    
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        local response=$(curl -s --connect-timeout "${TELEGRAM_TIMEOUT:-10}" \
            -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            -d "text=${message}" \
            -d "parse_mode=${parse_mode}" \
            -d "disable_web_page_preview=true" 2>/dev/null)
        
        # Optional: Log response for debugging
        if [[ "$response" =~ "\"ok\":true" ]]; then
            echo -e "${green}✓ Notifikasi Telegram berhasil dikirim${neutral}" >/dev/stderr
        else
            echo -e "${yellow}⚠ Gagal mengirim notifikasi Telegram${neutral}" >/dev/stderr
        fi
    else
        echo -e "${gray}ℹ Notifikasi Telegram dilewati (konfigurasi tidak lengkap)${neutral}" >/dev/stderr
    fi
}

# Function to get system information for notification
get_system_info() {
    local server_ip=$(curl -s --connect-timeout 5 ipinfo.io/ip || echo "Unknown")
    local server_city=$(curl -s --connect-timeout 5 ipinfo.io/city || echo "Unknown")
    local server_region=$(curl -s --connect-timeout 5 ipinfo.io/region || echo "Unknown")
    local server_country=$(curl -s --connect-timeout 5 ipinfo.io/country || echo "Unknown")
    local server_org=$(curl -s --connect-timeout 5 ipinfo.io/org || echo "Unknown")
    local server_timezone=$(curl -s --connect-timeout 5 ipinfo.io/timezone || echo "Unknown")
    local server_hostname=$(hostname || echo "Unknown")
    local server_os=$(cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f 2 || echo "Unknown")
    local server_kernel=$(uname -r || echo "Unknown")
    local server_arch=$(uname -m || echo "Unknown")
    local install_time=$(date '+%Y-%m-%d %H:%M:%S %Z')
    
    echo "${server_ip}|${server_city}|${server_region}|${server_country}|${server_org}|${server_timezone}|${server_hostname}|${server_os}|${server_kernel}|${server_arch}|${install_time}"
}

# Function to print rainbow text
print_rainbow() {
    local text="$1"
    local length=${#text}
    local start_color=(0 5 0)
    local mid_color=(0 200 0)
    local end_color=(0 5 0)
    for ((i = 0; i < length; i++)); do
        local progress=$((i * 100 / (length - 1)))
        if [ $progress -lt 50 ]; then
            local factor=$((progress * 2))
            r=$(((start_color[0] * (100 - factor) + mid_color[0] * factor) / 100))
            g=$(((start_color[1] * (100 - factor) + mid_color[1] * factor) / 100))
            b=$(((start_color[2] * (100 - factor) + mid_color[2] * factor) / 100))
        else
            local factor=$(((progress - 50) * 2))
            r=$(((mid_color[0] * (100 - factor) + end_color[0] * factor) / 100))
            g=$(((mid_color[1] * (100 - factor) + end_color[1] * factor) / 100))
            b=$(((mid_color[2] * (100 - factor) + end_color[2] * factor) / 100))
        fi
        printf "\e[38;2;%d;%d;%dm%s" "$r" "$g" "$b" "${text:$i:1}"
    done
    echo -e "$reset" # Reset color at the end
}

# Create required directories and set permissions
directories=(
    /etc/xray
    /etc/vmess
    /etc/vless
    /etc/trojan
    /etc/shadowsocks
    /usr/bin/xray
    /var/log/xray
    /var/www/html
    /etc/haproxy
    /etc/xray/vmess
    /etc/xray/vless
    /etc/xray/trojan
    /etc/xray/shadowsocks
    /etc/xray/ssh
)

for dir in "${directories[@]}"; do
    [ ! -d "$dir" ] && mkdir -p "$dir"
    chmod 777 "$dir"
done

clear

# Domain setup
if [ -z "$1" ]; then
    clear
    echo -e "${green}╔═════════════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${green}                            SELAMAT DATANG DI SCRIPT INSTALASI                          ${neutral}"
    echo -e "${green}                                  Alrescha79 Panel VPN                                  ${neutral}"
    echo -e "${green}                                      Script Premium                                    ${neutral}"
    echo -e "${green}╚═════════════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e ""
    echo -e "${yellow}                  Copyright${reset} (C)${gray} https://t.me/Alrescha79${reset}"
    echo -e ""
    echo -e "${green}═══════════════════════════════════════════════════════════════════════════${neutral}"
    echo -e "${yellow}                    Masukkan domain Anda untuk memulai instalasi:                        ${neutral}"
    echo -e "${green}═════════════════════════════════════════════════════════════ ══════════════${neutral}"
    echo -e ""
    read -p "  Masukkan domain Anda: " domain
else
    domain="$1"
fi
# Cek IP domain dan VPS
vps_ip=$(curl -s ipinfo.io/ip)
domain_ip=$(getent ahosts "$domain" | awk '{print $1}' | head -n 1)
if [ "$domain_ip" != "$vps_ip" ]; then
    echo -e "${red}Domain yang Anda masukkan tidak mengarah ke IP VPS Anda (${vps_ip}).${neutral}"
    echo -e "${yellow}Pastikan domain sudah di-pointing ke IP VPS: ${vps_ip}${neutral}"
    echo -e "${gray}Script akan tetap melanjutkan instalasi...${neutral}"
    sleep 3
fi

# Simpan domain ke file
echo "$domain" >/etc/xray/domain

# List file yang akan dibuat dan diatur permission-nya
files=(
    /etc/xray/domain
    /var/log/xray/access.log
    /var/log/xray/error.log
    /etc/xray/vmess/.vmess.db
    /etc/xray/vless/.vless.db
    /etc/xray/trojan/.trojan.db
    /etc/xray/shadowsocks/.shadowsocks.db
    /etc/xray/ssh/.ssh.db
    /etc/ssh/.ssh.db
)

for file in "${files[@]}"; do
    [ ! -f "$file" ] && touch "$file"
    chmod 777 "$file"
done

# Atur akses eksekusi ke beberapa direktori
chmod +x /var/log/xray /etc/xray /etc/haproxy /etc/xray/vmess /etc/xray/vless /etc/xray/trojan /etc/xray/shadowsocks /etc/xray/ssh

# Informasi sistem
timezone="Asia/Jakarta"
city=$(curl -s ipinfo.io/city)
isp=$(curl -s ipinfo.io/org | cut -d " " -f 2-10)
domain=$(cat /etc/xray/domain)
ip=$(wget -qO- ipinfo.io/ip)

# Mendapatkan data izin dan user info
echo -e "${blue}Mengunduh data otorisasi...${neutral}"
data=$(curl -s --connect-timeout 10 --max-time 30 https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/izin)

# Cek apakah data berhasil diunduh
if [ -z "$data" ]; then
    echo -e "${red}╔════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${red}║                          KONEKSI GAGAL                         ║${neutral}"
    echo -e "${red}╠════════════════════════════════════════════════════════════════╣${neutral}"
    echo -e "${red}║  Gagal mengunduh data otorisasi dari GitHub                    ${neutral}"
    echo -e "${red}║                                                                ${neutral}"
    echo -e "${red}║  Ada beberapa kemungkinan penyebab:                            ${neutral}"
    echo -e "${red}║    • Tidak ada koneksi internet                                ${neutral}"
    echo -e "${red}║    • Server GitHub tidak dapat dijangkau                       ${neutral}"
    echo -e "${red}║    • Firewall memblokir koneksi                                ${neutral}"
    echo -e "${red}║                                                                ${neutral}"
    echo -e "${red}║  Silahkan periksa koneksi Anda dan coba lagi                   ${neutral}"
    echo -e "${red}║  Jika masalah berlanjut, hubungi:                              ${neutral}"
    echo -e "${red}║  📱 Telegram: https://t.me/Alrescha79                          ${neutral}"
    echo -e "${red}║  📧 Email: anggun@cakson.my.id                                 ${neutral}"
    echo -e "${red}╚════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e ""
    echo -e "${yellow}Instalasi dibatalkan karena gagal mengunduh data.${neutral}"
    exit 1
fi

# Cek apakah format data valid (format: ### User Date IP)
if ! echo "$data" | grep -q "^###.*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.*[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+"; then
    echo -e "${red}╔════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${red}║                    KESALAHAN FORMAT DATA                       ║${neutral}"
    echo -e "${red}╠════════════════════════════════════════════════════════════════╣${neutral}"
    echo -e "${red}║  Format data otorisasi dari GitHub tidak valid                 ${neutral}"
    echo -e "${red}║                                                                ${neutral}"
    echo -e "${red}║  Jika masalah berlanjut, hubungi:                              ${neutral}"
    echo -e "${red}║  📱 Telegram: https://t.me/Alrescha79                          ${neutral}"
    echo -e "${red}║  📧 Email: anggun@cakson.my.id                                 ${neutral}"
    echo -e "${red}╚════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e ""
    echo -e "${yellow}Instalasi dibatalkan karena kesalahan format data.${neutral}"
    exit 1
fi

# Parsing data sesuai format baru: ### User Date IP
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

# Validasi IP dalam daftar izin
echo -e "${blue}Memeriksa otorisasi IP...${neutral}"
if [ -z "$user_id" ]; then
    # Log unauthorized access attempt
    mkdir -p /var/log/setup
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] UNAUTHORIZED ACCESS ATTEMPT - IP: $ip, ISP: $isp, City: $city" >> /var/log/setup/unauthorized.log
    
    # Send Telegram notification for unauthorized access
    system_info=$(get_system_info)
    IFS='|' read -r server_ip server_city server_region server_country server_org server_timezone server_hostname server_os server_kernel server_arch attempt_time <<< "$system_info"
    
    unauthorized_message="🚨 <b>AKSES TIDAK SAH TERDETEKSI!</b>

⚠️ <b>Detail Percobaan Akses:</b>
🆔 IP Address: <code>${server_ip}</code>
⏰ Waktu Percobaan: <code>${attempt_time}</code>

🌍 <b>Lokasi Penyerang:</b>
🏙️ Lokasi: <code>${server_city}, ${server_region}, ${server_country}</code>
🏢 ISP: <code>${server_org}</code>
🕐 Timezone: <code>${server_timezone}</code>

💻 <b>Sistem yang Digunakan:</b>
🖥️ Hostname: <code>${server_hostname}</code>
📦 OS: <code>${server_os}</code>
🔧 Kernel: <code>${server_kernel}</code>

❌ <b>Status:</b> Akses ditolak - IP tidak terdaftar
📝 <b>Tindakan:</b> Percobaan akses telah dicatat
🔒 <b>Keamanan:</b> Script telah dihentikan

📞 <b>Admin:</b> @Alrescha79"

    send_telegram_notification "$unauthorized_message" "HTML" "unauthorized"
    
    echo -e "${red}╔════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${red}║                           AKSES DITOLAK                        ║${neutral}"
    echo -e "${red}╠════════════════════════════════════════════════════════════════╣${neutral}"
    echo -e "${red}║  Alamat IP Anda (${ip}) tidak terdaftar dalam daftar izin      ${neutral}"
    echo -e "${red}║                                                                ${neutral}"
    echo -e "${red}║  Silakan hubungi pengembang untuk mendapatkan akses:           ${neutral}"
    echo -e "${red}║  📱 Telegram: https://t.me/Alrescha79                          ${neutral}"
    echo -e "${red}║  📧 Email: anggun@cakson.my.id                                 ${neutral}"
    echo -e "${red}║                                                                ${neutral}"
    echo -e "${red}║  Untuk meminta akses, harap berikan informasi:                 ${neutral}"
    echo -e "${red}║    • Alamat IP VPS: ${ip}                                      ${neutral}"
    echo -e "${red}║    • Tujuan penggunaan script                                  ${neutral}"
    echo -e "${red}║    • Lokasi server: ${city}                                    ${neutral}"
    echo -e "${red}║    • Provider: ${isp}                                          ${neutral}"
    echo -e "${red}╚════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e ""
    echo -e "${yellow}Instalasi dibatalkan karena IP tidak terdaftar.${neutral}"
    echo -e "${gray}Upaya akses ini telah dicatat untuk tujuan keamanan.${neutral}"
    echo -e "${gray}Script akan keluar dalam 5 detik...${neutral}"
    sleep 5
    exit 1
fi

# Validasi tanggal kadaluarsa
current_date=$(date +%Y-%m-%d)
if [[ "$exp_date" < "$current_date" ]]; then
    # Log expired access attempt
    mkdir -p /var/log/setup
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] EXPIRED ACCESS ATTEMPT - User: $user_id, IP: $ip, Expired: $exp_date" >> /var/log/setup/expired.log
    
    # Send Telegram notification for expired access
    system_info=$(get_system_info)
    IFS='|' read -r server_ip server_city server_region server_country server_org server_timezone server_hostname server_os server_kernel server_arch attempt_time <<< "$system_info"
    
    expired_message="⏰ <b>AKSES KADALUARSA TERDETEKSI!</b>

📊 <b>Detail Pengguna:</b>
👤 User ID: <code>${user_id}</code>
🆔 IP Address: <code>${server_ip}</code>
⏰ Waktu Percobaan: <code>${attempt_time}</code>
📅 Tanggal Kadaluarsa: <code>${exp_date}</code>
📅 Tanggal Sekarang: <code>${current_date}</code>

🌍 <b>Lokasi Server:</b>
🏙️ Lokasi: <code>${server_city}, ${server_region}, ${server_country}</code>
🏢 ISP: <code>${server_org}</code>

💻 <b>Sistem:</b>
🖥️ Hostname: <code>${server_hostname}</code>
📦 OS: <code>${server_os}</code>

❌ <b>Status:</b> Akses ditolak - Lisensi telah expired
📝 <b>Tindakan:</b> Percobaan akses telah dicatat
💰 <b>Solusi:</b> Perpanjang lisensi untuk melanjutkan

📞 <b>Perpanjangan:</b> @Alrescha79"

    send_telegram_notification "$expired_message" "HTML" "expired"
    
    echo -e "${red}╔════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${red}║                        AKSES KADALUARSA                        ║${neutral}"
    echo -e "${red}╠════════════════════════════════════════════════════════════════╣${neutral}"
    echo -e "${red}║  Akses untuk IP Anda telah kadaluarsa                          ${neutral}"
    echo -e "${red}║                                                                ${neutral}"
    echo -e "${red}║  Detail akses:                                                 ${neutral}"
    echo -e "${red}║    • User ID: ${user_id}                                       ${neutral}"
    echo -e "${red}║    • IP Address: ${ip}                                         ${neutral}"
    echo -e "${red}║    • Tanggal Kadaluarsa: ${exp_date}                           ${neutral}"
    echo -e "${red}║    • Tanggal Hari Ini: ${current_date}                         ${neutral}"
    echo -e "${red}║                                                                ${neutral}"
    echo -e "${red}║  Untuk memperpanjang akses, hubungi:                           ${neutral}"
    echo -e "${red}║  📱 Telegram: https://t.me/Alrescha79                          ${neutral}"
    echo -e "${red}║  📧 Email: anggun@cakson.my.id                                 ${neutral}"
    echo -e "${red}╚════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e ""
    echo -e "${yellow}Instalasi dibatalkan karena akses telah kadaluarsa.${neutral}"
    echo -e "${gray}Script akan keluar dalam 5 detik...${neutral}"
    sleep 5
    exit 1
fi

# Hitung sisa hari akses
days_left=$(( ( $(date -d "$exp_date" +%s) - $(date -d "$current_date" +%s) ) / 86400 ))

# Log authorized access
mkdir -p /var/log/setup
echo "[$(date '+%Y-%m-%d %H:%M:%S')] AUTHORIZED ACCESS - User: $user_id, IP: $ip, Expires: $exp_date, Days Left: $days_left" >> /var/log/setup/authorized.log

# Send Telegram notification for successful script usage
echo -e "${blue}Mengirim notifikasi Telegram...${neutral}"
system_info=$(get_system_info)
IFS='|' read -r server_ip server_city server_region server_country server_org server_timezone server_hostname server_os server_kernel server_arch install_time <<< "$system_info"

telegram_message="🚀 <b>Alrescha79 VPN Script - Instalasi Dimulai</b>

📊 <b>Detail Pengguna:</b>
👤 User ID: <code>${user_id}</code>
🆔 IP Address: <code>${server_ip}</code>
⏰ Waktu Instalasi: <code>${install_time}</code>
📅 Masa Berlaku: <code>${exp_date}</code>
⏳ Sisa Waktu: <code>${days_left} hari</code>

🌍 <b>Informasi Server:</b>
🏙️ Lokasi: <code>${server_city}, ${server_region}, ${server_country}</code>
🏢 ISP: <code>${server_org}</code>
🕐 Timezone: <code>${server_timezone}</code>
🖥️ Hostname: <code>${server_hostname}</code>

💻 <b>Sistem Operasi:</b>
📦 OS: <code>${server_os}</code>
🔧 Kernel: <code>${server_kernel}</code>
🏗️ Architecture: <code>${server_arch}</code>

🔧 <b>Status:</b> Instalasi sedang berlangsung...
📞 <b>Support:</b> @Alrescha79"

send_telegram_notification "$telegram_message" "HTML" "start"

echo -e "${green}╔════════════════════════════════════════════════════════════════╗${neutral}"
echo -e "${green}║                          AKSES DITERIMA                        ║${neutral}"
echo -e "${green}╠════════════════════════════════════════════════════════════════╣${neutral}"
echo -e "${green}║  ✓ Otorisasi IP berhasil diverifikasi                         ${neutral}"
echo -e "${green}║  ✓ User ID: ${user_id}                                        ${neutral}"
echo -e "${green}║  ✓ IP Address: ${ip}                                          ${neutral}"
echo -e "${green}║  ✓ Masa Berlaku: ${exp_date}                                  ${neutral}"
echo -e "${green}║  ✓ Sisa Waktu: ${days_left} hari                              ${neutral}"
echo -e "${green}║  ✓ Lokasi: ${city}                                            ${neutral}"
echo -e "${green}║  ✓ ISP: ${isp}                                                ${neutral}"
echo -e "${green}║  ✓ Notifikasi Telegram terkirim                               ${neutral}"
echo -e "${green}╚════════════════════════════════════════════════════════════════╝${neutral}"
echo -e ""

# Peringatan jika akses akan habis dalam 7 hari
if [ "$days_left" -le 7 ]; then
    echo -e "${yellow}╔════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${yellow}║                            PERINGATAN                          ║${neutral}"
    echo -e "${yellow}╠════════════════════════════════════════════════════════════════╣${neutral}"
    echo -e "${yellow}║  Akses Anda akan berakhir dalam ${days_left} hari!             ${neutral}"
    echo -e "${yellow}║  Segera hubungi developer untuk perpanjangan akses.            ${neutral}"
    echo -e "${yellow}║  📱 Telegram: https://t.me/Alrescha79                          ${neutral}"
    echo -e "${yellow}╚════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e ""
fi

echo -e "${blue}Melanjutkan dengan instalasi...${neutral}"
sleep 2

# URL sumber konfigurasi dan binary
nginx_key_url="https://nginx.org/keys/nginx_signing.key"
dropbear_init_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/fodder/dropbear/dropbear"
dropbear_conf_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/fodder/examples/dropbear"
dropbear_dss_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/fodder/dropbear/dropbear_dss_host_key"
sshd_conf_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/fodder/examples/sshd"
banner_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/fodder/examples/banner"
common_password_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/fodder/examples/common-password"
ws_py_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/fodder/websocket/ws.py"
haproxy_cfg_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/fodder/Haproxy/haproxy.cfg"
xray_conf_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/fodder/nginx/xray.conf"
udp_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/fodder/udp/udp-custom-linux-amd64"
nginx_conf_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/fodder/nginx/nginx.conf"
badvpn_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/main/BadVPN-UDPWG/badvpn"
openvpn_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/fodder/openvpn/openvpn.zip"
gotop_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/gotop"
vmess_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/main/VMess-VLESS-Trojan+Websocket+gRPC/vmess/config.json"
vless_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/main/VMess-VLESS-Trojan+Websocket+gRPC/vless/config.json"
trojan_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/main/VMess-VLESS-Trojan+Websocket+gRPC/trojan/config.json"



shadowsocks_url="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/main/VMess-VLESS-Trojan+Websocket+gRPC/shadowsocks/config.json"

# Info OS
os_id=$(grep -w ID /etc/os-release | head -n1 | sed 's/ID=//g' | sed 's/"//g')
os_version=$(grep -w VERSION_ID /etc/os-release | head -n1 | sed 's/VERSION_ID=//g' | sed 's/"//g')
echo "Sistem Operasi: $os_id, Versi: $os_version"

# Cek jika bukan root
if [ "$EUID" -ne 0 ]; then
    echo -e "${red}Script ini harus dijalankan sebagai root${neutral}"
    exit 1
fi
# Update package list
if ! apt update -y; then
    echo -e "${red}Failed to update${neutral}"
fi

# Install sudo if not installed
if ! dpkg -s sudo >/dev/null 2>&1; then
    if ! apt install sudo -y; then
        echo -e "${red}Failed to install sudo${neutral}"
    fi
else
    echo -e "${green}sudo is already installed, skipping...${neutral}"
fi

# Install software-properties-common and debconf-utils
if ! dpkg -s software-properties-common debconf-utils >/dev/null 2>&1; then
    if ! apt install -y --no-install-recommends software-properties-common debconf-utils; then
        echo -e "${red}Failed to install basic packages${neutral}"
    fi
else
    echo -e "${green}software-properties-common and debconf-utils are already installed, skipping...${neutral}"
fi

# Remove exim4 if installed
if dpkg -s exim4 >/dev/null 2>&1; then
    if ! apt remove --purge -y exim4; then
        echo -e "${red}Failed to remove exim4${neutral}"
    else
        echo -e "${green}exim4 removed successfully${neutral}"
    fi
else
    echo -e "${green}exim4 is not installed, skipping...${neutral}"
fi

# Remove ufw if installed
if dpkg -s ufw >/dev/null 2>&1; then
    if ! apt remove --purge -y ufw; then
        echo -e "${red}Failed to remove ufw${neutral}"
    else
        echo -e "${green}ufw removed successfully${neutral}"
    fi
else
    echo -e "${green}ufw is not installed, skipping...${neutral}"
fi

# Remove firewalld if installed
if dpkg -s firewalld >/dev/null 2>&1; then
    if ! apt remove --purge -y firewalld; then
        echo -e "${red}Failed to remove firewalld${neutral}"
    else
        echo -e "${green}firewalld removed successfully${neutral}"
    fi
else
    echo -e "${green}firewalld is not installed, skipping...${neutral}"
fi

# Configure iptables-persistent
if ! echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections; then
    echo -e "${red}Failed to configure iptables-persistent v4${neutral}"
fi
if ! echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections; then
    echo -e "${red}Failed to configure iptables-persistent v6${neutral}"
fi

# Configure keyboard
if ! debconf-set-selections <<<"keyboard-configuration keyboard-configuration/layout select English"; then
    echo -e "${red}Failed to configure keyboard layout${neutral}"
fi
if ! debconf-set-selections <<<"keyboard-configuration keyboard-configuration/variant select English"; then
    echo -e "${red}Failed to configure keyboard variant${neutral}"
fi

export DEBIAN_FRONTEND=noninteractive

# Update & upgrade system
if ! apt update -y; then
    echo -e "${red}Failed to update${neutral}"
fi
if ! apt-get upgrade -y; then
    echo -e "${red}Failed to upgrade${neutral}"
else
    echo -e "${green}System upgraded successfully${neutral}"
fi
if ! apt dist-upgrade -y; then
    echo -e "${red}Failed to dist-upgrade${neutral}"
else
    echo -e "${green}System dist-upgraded successfully${neutral}"
fi

# Install all needed packages
packages=(
    libnss3-dev liblzo2-dev libnspr4-dev pkg-config libpam0g-dev libcap-ng-dev
    libcap-ng-utils libselinux1-dev flex bison make libnss3-tools libevent-dev bc
    rsyslog dos2unix zlib1g-dev libssl-dev libsqlite3-dev sed dirmngr libxml-parser-perl build-essential
    gcc g++ htop lsof tar wget curl ruby zip unzip p7zip-full libc6 util-linux
    ca-certificates iptables iptables-persistent netfilter-persistent
    net-tools openssl gnupg gnupg2 lsb-release shc cmake git whois
    screen socat xz-utils apt-transport-https gnupg1 dnsutils cron bash-completion ntpdate chrony jq
    tmux python3 python3-pip lsb-release gawk
    libncursesw5-dev libgdbm-dev tk-dev libffi-dev libbz2-dev checkinstall
    openvpn easy-rsa dropbear
)
for package in "${packages[@]}"; do
    if ! dpkg -s "$package" >/dev/null 2>&1; then
        if ! apt-get update -y; then
            echo -e "${red}Failed to update${neutral}"
        fi
        if ! apt-get install -y "$package"; then
            echo -e "${red}Failed to install $package${neutral}"
        fi
    else
        echo -e "${green}$package is already installed, skipping...${neutral}"
    fi
done

# Simpan city info
if [ -n "$city" ]; then
    [ -f /etc/xray/city ] && rm /etc/xray/city
    echo "$city" >>/etc/xray/city
else
    [ -f /etc/xray/city ] && rm /etc/xray/city
    echo "City information not available" >>/etc/xray/city
fi

# Simpan ISP info
if [ -n "$isp" ]; then
    [ -f /etc/xray/isp ] && rm /etc/xray/isp
    echo "$isp" >>/etc/xray/isp
else
    [ -f /etc/xray/isp ] && rm /etc/xray/isp
    echo "ISP information not available" >>/etc/xray/isp
fi

# Install Node.js jika belum ada
if ! dpkg -s nodejs >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || echo -e "${red}Failed to download Node.js setup${neutral}"
    apt-get install -y nodejs || echo -e "${red}Failed to install Node.js${neutral}"
    npm install -g npm@latest
else
    echo -e "${green}Node.js is already installed, skipping...${neutral}"
fi

# Install vnstat jika belum ada
if ! dpkg -s vnstat >/dev/null 2>&1; then
    apt-get install -y vnstat || echo -e "${red}Failed to install vnstat${neutral}"
    wget -q https://humdi.net/vnstat/vnstat-2.9.tar.gz
    tar zxvf vnstat-2.9.tar.gz || echo -e "${red}Failed to extract vnstat${neutral}"
    cd vnstat-2.9 || echo -e "${red}Failed to enter vnstat-2.9 directory${neutral}"
    ./configure --prefix=/usr --sysconfdir=/etc >/dev/null 2>&1 && make >/dev/null 2>&1 && make install >/dev/null 2>&1
    cd || echo -e "${red}Failed to return to home directory${neutral}"
    net=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    vnstat -i $net
    if grep -q 'Interface "eth0"' /etc/vnstat.conf; then
        sed -i 's/Interface "'""eth0""'"/Interface "'""$net""'"/g' /etc/vnstat.conf
    else
        echo -e "Interface eth0 not found in /etc/vnstat.conf"
    fi
    chown vnstat:vnstat /var/lib/vnstat -R || echo -e "${red}Failed to change ownership of vnstat directory${neutral}"
    systemctl enable vnstat
    /etc/init.d/vnstat restart
else
    echo -e "${green}vnstat is already installed, skipping...${neutral}"
fi

rm -f /root/vnstat-2.9.tar.gz >/dev/null 2>&1 || echo -e "${red}Failed to delete vnstat-2.6.tar.gz file${neutral}"
rm -rf /root/vnstat-2.9 >/dev/null 2>&1 || echo -e "${red}Failed to delete vnstat-2.6 directory${neutral}"

ln -fs /usr/share/zoneinfo/$timezone /etc/localtime

os_id=$(grep -w ID /etc/os-release | head -n1 | sed 's/ID=//g' | sed 's/"//g')
if [[ $os_id == "ubuntu" ]]; then
    sudo apt update -y || echo -e "${red}Failed to update package list${neutral}"
    if ! dpkg -s software-properties-common >/dev/null 2>&1; then
        apt-get install --no-install-recommends software-properties-common || echo -e "${red}Failed to install software-properties-common${neutral}"
    else
        echo -e "${green}software-properties-common is already installed, skipping...${neutral}"
    fi
    rm -f /etc/apt/sources.list.d/nginx.list || echo -e "${red}Failed to delete nginx.list${neutral}"
    if ! dpkg -s ubuntu-keyring >/dev/null 2>&1; then
        apt install -y ubuntu-keyring || echo -e "${red}Failed to install ubuntu-keyring${neutral}"
    else
        echo -e "${green}ubuntu-keyring is already installed, skipping...${neutral}"
    fi
    curl $nginx_key_url | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" | tee /etc/apt/sources.list.d/nginx.list
    echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | tee /etc/apt/preferences.d/99nginx
    if ! dpkg -s nginx >/dev/null 2>&1; then
        if ! apt install -y nginx; then
            echo -e "${red}Failed to install nginx${neutral}"
        fi
    else
        echo -e "${green}nginx is already installed, skipping...${neutral}"
    fi
    if [ -f /etc/nginx/conf.d/default.conf ]; then
        rm /etc/nginx/conf.d/default.conf || echo -e "${red}Failed to delete /etc/nginx/conf.d/default.conf${neutral}"
    else
        echo -e "${yellow}/etc/nginx/conf.d/default.conf does not exist, skipping deletion${neutral}"
    fi
elif [[ $os_id == "debian" ]]; then
    sudo apt update -y || echo -e "${red}Failed to update package list${neutral}"
    rm -f /etc/apt/sources.list.d/nginx.list || echo -e "${red}Failed to delete nginx.list${neutral}"
    if ! dpkg -s debian-archive-keyring >/dev/null 2>&1; then
        apt install -y debian-archive-keyring || echo -e "${red}Failed to install debian-archive-keyring${neutral}"
    else
        echo -e "${green}debian-archive-keyring is already installed, skipping...${neutral}"
    fi
    curl $nginx_key_url | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian $(lsb_release -cs) nginx" | tee /etc/apt/sources.list.d/nginx.list
    echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | tee /etc/apt/preferences.d/99nginx
    if ! dpkg -s nginx >/dev/null 2>&1; then
        apt install -y nginx || echo -e "${red}Failed to install nginx${neutral}"
    else
        echo -e "${green}nginx is already installed, skipping...${neutral}"
    fi
else
    echo -e "${red}Unsupported OS. Exiting.${neutral}"
    exit 1
fi
# Install haproxy sesuai OS dan versi
if [[ $os_id == "ubuntu" && $os_version == "18.04" ]]; then
    add-apt-repository -y ppa:vbernat/haproxy-2.6 || echo -e "${red}Failed to add haproxy repository${neutral}"
    sudo apt update -y || echo -e "${red}Failed to update package list${neutral}"
    apt-get install -y haproxy=2.6.* || echo -e "${red}Failed to install haproxy${neutral}"

elif [[ $os_id == "ubuntu" && $os_version == "20.04" ]]; then
    add-apt-repository -y ppa:vbernat/haproxy-2.9 || echo -e "${red}Failed to add haproxy repository${neutral}"
    sudo apt update -y || echo -e "${red}Failed to update package list${neutral}"
    apt-get install -y haproxy=2.9.* || echo -e "${red}Failed to install haproxy${neutral}"

elif [[ $os_id == "ubuntu" && $os_version == "22.04" ]]; then
    add-apt-repository -y ppa:vbernat/haproxy-3.0 || echo -e "${red}Failed to add haproxy repository${neutral}"
    sudo apt update -y || echo -e "${red}Failed to update package list${neutral}"
    apt-get install -y haproxy=3.0.* || echo -e "${red}Failed to install haproxy${neutral}"

elif [[ $os_id == "ubuntu" && $os_version == "24.04" ]]; then
    add-apt-repository -y ppa:vbernat/haproxy-3.0 || echo -e "${red}Failed to add haproxy repository${neutral}"
    sudo apt update -y || echo -e "${red}Failed to update package list${neutral}"
    apt-get install -y haproxy=3.0.* || echo -e "${red}Failed to install haproxy${neutral}"

elif [[ $os_id == "debian" && $os_version == "10" ]]; then
    curl https://haproxy.debian.net/bernat.debian.org.gpg | gpg --dearmor >/usr/share/keyrings/haproxy.debian.net.gpg || echo -e "${red}Failed to add haproxy repository${neutral}"
    echo "deb [signed-by=/usr/share/keyrings/haproxy.debian.net.gpg] http://haproxy.debian.net buster-backports-2.6 main" >/etc/apt/sources.list.d/haproxy.list || echo -e "${red}Failed to add haproxy repository${neutral}"
    sudo apt update -y || echo -e "${red}Failed to update package list${neutral}"
    apt-get install -y haproxy=2.6.* || echo -e "${red}Failed to install haproxy${neutral}"

elif [[ $os_id == "debian" && $os_version == "11" ]]; then
    curl https://haproxy.debian.net/bernat.debian.org.gpg | gpg --dearmor >/usr/share/keyrings/haproxy.debian.net.gpg || echo -e "${red}Failed to add haproxy repository${neutral}"
    echo "deb [signed-by=/usr/share/keyrings/haproxy.debian.net.gpg] http://haproxy.debian.net bullseye-backports-3.0 main" >/etc/apt/sources.list.d/haproxy.list || echo -e "${red}Failed to add haproxy repository${neutral}"
    sudo apt update -y || echo -e "${red}Failed to update package list${neutral}"
    apt-get install -y haproxy=3.0.* || echo -e "${red}Failed to install haproxy${neutral}"

elif [[ $os_id == "debian" && $os_version == "12" ]]; then
    curl https://haproxy.debian.net/bernat.debian.org.gpg | gpg --dearmor >/usr/share/keyrings/haproxy.debian.net.gpg || echo -e "${red}Failed to add haproxy repository${neutral}"
    echo "deb [signed-by=/usr/share/keyrings/haproxy.debian.net.gpg] http://haproxy.debian.net bookworm-backports-3.0 main" >/etc/apt/sources.list.d/haproxy.list || echo -e "${red}Failed to add haproxy repository${neutral}"
    sudo apt update -y || echo -e "${red}Failed to update package list${neutral}"
    apt-get install -y haproxy=3.0.* || echo -e "${red}Failed to install haproxy${neutral}"

else
    echo -e "${red}Unsupported OS. Exiting.${neutral}"
    exit 1
fi
loading_bar() {
    local total=$1
    local current=0
    local width=50
    local filled
    local empty

    filled="▰"
    empty="▱"

    while [ "$current" -le "$total" ]; do
        # Menghitung berapa banyak simbol terisi
        local filled_count=$((current * width / total))
        local empty_count=$((width - filled_count))

        # Membuat bar loading
        local bar=$(printf "%${filled_count}s" | tr ' ' "$filled")
        bar+=$(printf "%${empty_count}s" | tr ' ' "$empty")

        # Menampilkan bar
        printf "\r[${bar}] %d%%" $((current * 100 / total))
        sleep 0.1
        ((current++))
    done
    printf "\n"
}

echo "Memulai proses instalasi, mohon tunggu..."


echo "Proses instalasi selesai."

# Download Dropbear configs
if [ -n "$dropbear_conf_url" ]; then
    [ -f /etc/default/dropbear ] && rm /etc/default/dropbear
    wget -q -O /etc/default/dropbear "$dropbear_conf_url" >/dev/null 2>&1 || echo -e "${red}Failed to download dropbear.conf${neutral}"

    [ -f /etc/init.d/dropbear ] && rm /etc/init.d/dropbear
    wget -q -O /etc/init.d/dropbear "$dropbear_init_url" && chmod +x /etc/init.d/dropbear >/dev/null 2>&1 || echo -e "${red}Failed to download dropbear.init${neutral}"

    [ -f /etc/dropbear/dropbear_dss_host_key ] && rm /etc/dropbear/dropbear_dss_host_key
    wget -q -O /etc/dropbear/dropbear_dss_host_key "$dropbear_dss_url" && chmod +x /etc/dropbear/dropbear_dss_host_key >/dev/null 2>&1 || echo -e "${red}Failed to download dropbear_dss_host_key${neutral}"
else
    echo -e "${yellow}dropbear_conf_url is not set, skipping download of dropbear_dss_host_key${neutral}"
fi

# Download SSHD config
if [ -n "$sshd_conf_url" ]; then
    [ -f /etc/ssh/sshd_config ] && rm /etc/ssh/sshd_config
    wget -q -O /etc/ssh/sshd_config "$sshd_conf_url" >/dev/null 2>&1 || echo -e "${red}Failed to download sshd_config${neutral}"
else
    echo -e "${yellow}sshd_conf_url is not set, skipping download of sshd_config${neutral}"
fi

# Download Banner
if [ -n "$banner_url" ]; then
    wget -q -O /etc/gerhanatunnel.txt "$banner_url" && chmod +x /etc/gerhanatunnel.txt >/dev/null 2>&1 || echo -e "${red}Failed to download gerhanatunnel.txt${neutral}"
else
    echo -e "${yellow}banner_url is not set, skipping download of gerhanatunnel.txt${neutral}"
fi

# Download Common Password
if [ -n "$common_password_url" ]; then
    [ -f /etc/pam.d/common-password ] && rm /etc/pam.d/common-password
    wget -O /etc/pam.d/common-password "$common_password_url" >/dev/null 2>&1 || echo -e "${red}Failed to download common-password${neutral}"
else
    echo -e "${yellow}common_password_url is not set, skipping download of common-password${neutral}"
fi

# Download ws.py
if [ -n "$ws_py_url" ]; then
    wget -O /usr/bin/ws.py "$ws_py_url" >/dev/null 2>&1 && chmod +x /usr/bin/ws.py || echo -e "${red}Failed to download ws.py${neutral}"
else
    echo -e "${yellow}ws_py_url is not set, skipping download of ws.py${neutral}"
fi

# Permission for common-password
if [ -f /etc/pam.d/common-password ]; then
    chmod +x /etc/pam.d/common-password || echo -e "${red}Failed to give execute permission to common-password${neutral}"
else
    echo -e "${yellow}/etc/pam.d/common-password not found, skipping permission change${neutral}"
fi

# Download and prepare Gotop
if wget -O /usr/bin/gotop "$gotop_url" >/dev/null 2>&1; then    
    if command -v dos2unix >/dev/null 2>&1; then
        dos2unix /usr/bin/gotop >/dev/null 2>&1
    else
        sed -i 's/\r$//' /usr/bin/gotop
    fi
    chmod +x /usr/bin/gotop
    echo -e "${green}Successfully downloaded Gotop${neutral}"
else
    echo -e "${red}Failed to download Gotop${neutral}"
fi

# Remove existing haproxy.cfg
if [ -f /etc/haproxy/haproxy.cfg ]; then
    rm /etc/haproxy/haproxy.cfg
    echo -e "${yellow}Existing haproxy.cfg removed${neutral}"
fi

# Remove Apache if installed
if dpkg -s apache2 >/dev/null 2>&1; then
    apt-get remove --purge apache2 -y
    echo -e "${yellow}Apache has been removed${neutral}"
else
    echo -e "${green}Apache is not installed, skipping removal${neutral}"
fi

# Download haproxy.cfg
if wget -O /etc/haproxy/haproxy.cfg "$haproxy_cfg_url" >/dev/null 2>&1; then
    echo -e "${green}Successfully downloaded haproxy.cfg${neutral}"
else
    echo -e "${red}Failed to download haproxy.cfg${neutral}"
fi

# Download xray.conf
if wget -O /etc/nginx/conf.d/xray.conf "$xray_conf_url" >/dev/null 2>&1; then
    echo -e "${green}Successfully downloaded xray.conf${neutral}"
else
    echo -e "${red}Failed to download xray.conf${neutral}"
fi

# Download Xray configs
if wget -O /etc/xray/vmess/config.json "$vmess_url" >/dev/null 2>&1; then
    echo -e "${green}Successfully downloaded vmess${neutral}"
else
    echo -e "${red}Failed to download vmess${neutral}"
fi

if wget -O /etc/xray/vless/config.json "$vless_url" >/dev/null 2>&1; then
    echo -e "${green}Successfully downloaded vless${neutral}"
else
    echo -e "${red}Failed to download vless${neutral}"
fi

if wget -O /etc/xray/trojan/config.json "$trojan_url" >/dev/null 2>&1; then
    echo -e "${green}Successfully downloaded trojan${neutral}"
else
    echo -e "${red}Failed to download trojan${neutral}"
fi

if wget -O /etc/xray/shadowsocks/config.json "$shadowsocks_url" >/dev/null 2>&1; then
    echo -e "${green}Successfully downloaded shadowsocks${neutral}"
else
    echo -e "${red}Failed to download shadowsocks${neutral}"
fi

# Download UDP custom binary
if wget -O /usr/bin/udp "$udp_url" >/dev/null 2>&1 && chmod +x /usr/bin/udp >/dev/null 2>&1; then
    echo -e "${green}Successfully downloaded udp-custom-linux-amd64${neutral}"
else
    echo -e "${red}Failed to download udp-custom-linux-amd64${neutral}"
fi

# Download nginx.conf
if wget -O /etc/nginx/nginx.conf "$nginx_conf_url" >/dev/null 2>&1 && chmod +x /etc/nginx/nginx.conf >/dev/null 2>&1; then
    echo -e "${green}Successfully downloaded nginx.conf${neutral}"
else
    echo -e "${red}Failed to download nginx.conf${neutral}"
fi

# Download badvpn binary
if wget -O /usr/bin/badvpn "$badvpn_url" >/dev/null 2>&1 && chmod +x /usr/bin/badvpn >/dev/null 2>&1; then
    echo -e "${green}Successfully downloaded badvpn${neutral}"
else
    echo -e "${red}Failed to download badvpn${neutral}"
fi

wget --no-check-certificate -O /opt/bbr.sh https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/bbr.sh
chmod 755 /opt/bbr.sh
/opt/bbr.sh

# Get network interface
interface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

# IPTABLES Rules
if iptables -t nat -A PREROUTING -i $interface -p udp -m udp --dport 53 -j REDIRECT --to-ports 5300; then
    iptables-save >/etc/iptables/rules.v4
else
    echo -e "${red}Failed to add PREROUTING iptables rule${neutral}"
fi

if iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $interface -j MASQUERADE; then
    iptables-save >/etc/iptables/rules.v4
else
    echo -e "${red}Failed to add POSTROUTING iptables rule untuk 10.8.0.0/24${neutral}"
fi

if iptables -t nat -A POSTROUTING -s 20.8.0.0/24 -o $interface -j MASQUERADE; then
    iptables-save >/etc/iptables/rules.v4
else
    echo -e "${red}Failed to add POSTROUTING iptables rule untuk 20.8.0.0/24${neutral}"
fi

if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf
    fi
else
    echo -e "${green}net.ipv4.ip_forward=1 is already in /etc/sysctl.conf, skipping...${neutral}"
fi
sysctl -p

if iptables-save >/etc/iptables/rules.v4; then
    echo -e "${green}Successfully saved iptables rules${neutral}"
else
    echo -e "${red}Failed to save iptables rules${neutral}"
fi

# Install Xray
if ! command -v xray >/dev/null 2>&1; then
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version 1.8.7
else
    echo -e "${green}Xray is already installed, skipping installation${neutral}"
fi

if [ ! -d "/root/.acme.sh" ]; then
    mkdir /root/.acme.sh
fi

systemctl daemon-reload
systemctl stop haproxy
systemctl stop nginx

if [ ! -f "/root/.acme.sh/acme.sh" ]; then
    curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
    chmod +x /root/.acme.sh/acme.sh
fi

domain=$(cat /etc/xray/domain)
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
/root/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
cat /etc/xray/xray.crt /etc/xray/xray.key | tee /etc/haproxy/yha.pem
chown www-data:www-data /etc/xray/xray.key
chown www-data:www-data /etc/xray/xray.crt

mkdir -p /usr/lib/openvpn/ || echo -e "${red}Failed to create directory /usr/lib/openvpn/${neutral}"
if [ -d "/etc/openvpn/" ]; then
    echo -e "${green}Directory /etc/openvpn/ already exists, continuing...${neutral}"
else
    mkdir -p /etc/openvpn/ || echo -e "${red}Failed to create directory /etc/openvpn/${neutral}"
fi

if wget -O /etc/openvpn/openvpn.zip "$openvpn_url" >/dev/null 2>&1; then
    if unzip -o -d /etc/openvpn/ /etc/openvpn/openvpn.zip >/dev/null 2>&1; then
        echo -e "${green}Successfully downloaded and extracted openvpn.zip${neutral}"
        rm -f /etc/openvpn/openvpn.zip
    else
        echo -e "${red}Failed to extract openvpn.zip${neutral}"
    fi
else
    echo -e "${red}Failed to download openvpn.zip${neutral}"
fi

# Generate OpenVPN client configs
cat >/etc/openvpn/client-tcp.ovpn <<-EOF
auth-user-pass
client
dev tun
proto tcp
remote $ip 1194
persist-key
persist-tun
pull
resolv-retry infinite
nobind
user nobody
comp-lzo
remote-cert-tls server
verb 3
mute 2
connect-retry 5 5
connect-retry-max 8080
mute-replay-warnings
redirect-gateway def1
script-security 2
cipher none
auth none
EOF

cat >/etc/openvpn/client-udp.ovpn <<-EOF
auth-user-pass
client
dev tun
proto udp
remote $ip 2200
persist-key
persist-tun
pull
resolv-retry infinite
nobind
user nobody
comp-lzo
remote-cert-tls server
verb 3
mute 2
connect-retry 5 5
connect-retry-max 8080
mute-replay-warnings
redirect-gateway def1
script-security 2
cipher none
auth none
EOF

cat >/etc/openvpn/client-ssl.ovpn <<-EOF
auth-user-pass
client
dev tun
proto tcp
remote $ip 443
persist-key
persist-tun
pull
resolv-retry infinite
nobind
user nobody
comp-lzo
remote-cert-tls server
verb 3
mute 2
connect-retry 5 5
connect-retry-max 8080
mute-replay-warnings
redirect-gateway def1
script-security 2
cipher none
auth none
EOF

# Function to append cert to ovpn files and zip them
input_cert_ovpn() {
    for config in client-tcp client-udp client-ssl; do
        echo '<ca>' >>/etc/openvpn/${config}.ovpn
        cat /etc/openvpn/ca.crt >>/etc/openvpn/${config}.ovpn
        echo '</ca>' >>/etc/openvpn/${config}.ovpn
        cp /etc/openvpn/${config}.ovpn /var/www/html/${config}.ovpn
    done
    cd /var/www/html/
    zip allovpn.zip client-tcp.ovpn client-udp.ovpn client-ssl.ovpn >/dev/null 2>&1
    sed -i 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn
    cd
}
input_cert_ovpn

if ! zip -j /var/www/html/allovpn.zip /var/www/html/*.ovpn; then
    echo "Failed to create zip file for all client configurations."
fi
if ! sed -i 's/#AUTOSTART="all"/AUTOSTART="all"/g' /etc/default/openvpn; then
    echo "Failed to enable autostart for OpenVPN."
fi

# Config JSON for UDP
cat >/usr/bin/config.json <<EOF
{
    "listen": ":2100",
    "stream_buffer": 33554432,
    "receive_buffer": 83886080,
    "auth": {
        "mode": "passwords"
    }
}
EOF

# Cron jobs & shell configs
cat >/etc/cron.d/xp_all <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
2 0 * * * root /usr/bin/exp
EOF

cat >/root/.profile <<EOF
if [ "\$BASH" ]; then
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi
fi
mesg n || true
menu
EOF
chmod 644 /root/.profile

cat >/root/.bashrc <<EOF
cat /dev/null > ~/.bash_history && history -c
EOF
chmod 644 /root/.bashrc

cat >/etc/shells <<EOF
/bin/sh
/bin/bash
/usr/bin/bash
/bin/rbash
/usr/bin/rbash
/bin/dash
/usr/bin/dash
/usr/bin/screen
/usr/bin/tmux
/bin/false
/usr/sbin/nologin
EOF
chmod +x /etc/shells

cat /dev/null >~/.bash_history && history -c

cat >/etc/cron.d/daily_reboot <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 5 * * * root /sbin/reboot
EOF

cat >/etc/cron.d/logclear <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 */6 * * * root /usr/bin/logclear
EOF

service cron restart

cat >/home/daily_reboot <<EOF
5
EOF

# Systemd service templates
capabilities="CAP_NET_ADMIN CAP_NET_BIND_SERVICE"
limits="LimitNPROC=10000
LimitNOFILE=1000000"
restart="Restart=on-failure
RestartPreventExitStatus=23"
wanted_by="WantedBy=multi-user.target"
after="After=network.target nss-lookup.target"
documentation="Documentation=https://t.me/gerhanatunnell"

create_service() {
    local name=$1
    local description=$2
    local exec_start=$3
    cat >/etc/systemd/system/${name}@config.service <<EOF
[Unit]
Description=${description} %i
${documentation}
${after}
[Service]
User=www-data
CapabilityBoundingSet=${capabilities}
AmbientCapabilities=${capabilities}
NoNewPrivileges=yes
ExecStart=${exec_start}
${restart}
${limits}
[Install]
${wanted_by}
EOF
}
create_service "vmess" "GerhanaTunnel Server Xray Instance" "/usr/local/bin/xray run -config /etc/xray/vmess/%i.json"
create_service "vless" "GerhanaTunnel Server Xray Instance" "/usr/local/bin/xray run -config /etc/xray/vless/%i.json"
create_service "trojan" "GerhanaTunnel Server Xray Instance" "/usr/local/bin/xray run -config /etc/xray/trojan/%i.json"
create_service "shadowsocks" "GerhanaTunnel Server Shadowsocks Instance" "/usr/local/bin/xray run -config /etc/xray/shadowsocks/%i.json"

cat >/etc/systemd/system/xray@.service.d/10-donot_touch_single_conf.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/local/bin/xray run -config /etc/xray/%i.json
EOF

sudo systemctl daemon-reload
sudo systemctl stop xray
sudo systemctl disable xray
sudo systemctl disable dropbear
sudo systemctl stop dropbear
rm -rf /lib/systemd/system/dropbear.service
sudo systemctl daemon-reload
/etc/init.d/dropbear start
/etc/init.d/dropbear restart

cat >/etc/systemd/system/ws.service <<EOF
[Unit]
Description=Python Proxy FATKAY
Documentation=https://t.me/fatkay
${after}
[Service]
Type=simple
User=root
CapabilityBoundingSet=${capabilities}
AmbientCapabilities=${capabilities}
NoNewPrivileges=true
ExecStart=/usr/bin/python3 -O /usr/bin/ws.py
${restart}
[Install]
${wanted_by}
EOF

cat >/etc/systemd/system/udp.service <<EOF
[Unit]
Description=ePro Udp-Custom VPN Server By HC
After=network.target
[Service]
User=root
WorkingDirectory=/usr/bin
ExecStart=/usr/bin/udp server -exclude 2200,7300,7200,7100,323,10008,10004 /usr/bin/config.json
Environment=HYSTERIA_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true
${limits}
${restart}
[Install]
${wanted_by}
EOF

cat >/etc/systemd/system/limitip.service <<EOF
[Unit]
Description=Limit IP Usage Xray Service
Documentation=https://t.me/gerhanatunnel
After=syslog.target network-online.target
[Service]
User=root
NoNewPrivileges=true
ExecStart=/bin/bash -c '/usr/bin/limitipssh 15 & /usr/bin/limitip 15 & wait'
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

cat >/etc/systemd/system/limitquota.service <<EOF
[Unit]
Description=Limit Quota Usage Xray Service
Documentation=https://t.me/gerhanatunnel
After=syslog.target network-online.target
[Service]
User=root
NoNewPrivileges=true
ExecStart=/usr/bin/quota
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

cat >/etc/systemd/system/badvpn.service <<EOF
[Unit]
Description=BadVPN UDP Service
Documentation=https://t.me/gerhanatunnel
After=syslog.target network-online.target
[Service]
User=root
NoNewPrivileges=true
ExecStart=/usr/bin/badvpn --listen-addr 127.0.0.1:7100 --listen-addr 127.0.0.1:7200 --listen-addr 127.0.0.1:7300 --max-clients 500
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000
[Install]
WantedBy=multi-user.target
EOF

if [ -f /root/.key ]; then
    rm -f /root/.key
fi
echo "$key" >>/root/.key

uuid_baru=$(cat /proc/sys/kernel/random/uuid)
for config in vmess vless trojan shadowsocks; do
    sudo sed -i "s/1d1c1d94-6987-4658-a4dc-8821a30fe7e0/$uuid_baru/g" /etc/xray/$config/config.json
done

npm i --prefix /usr/bin express express-fileupload

# Swap RAM
swap_file="/swapfile"
swap_size="5G"
if [ ! -f "$swap_file" ]; then
    fallocate -l $swap_size $swap_file
    chmod 600 $swap_file
    mkswap $swap_file
    swapon $swap_file
    echo "$swap_file swap swap defaults 0 0" >> /etc/fstab
    echo -e "${green}Swap RAM successfully added with size $swap_size${neutral}"
else
    echo -e "${yellow}Swap file already exists, skipping swap RAM addition${neutral}"
fi

sudo systemctl daemon-reload
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
    "ssh.service"
    "dropbear.service"
)
for service in "${services[@]}"; do
    sudo systemctl enable $service
    sudo systemctl start $service
    sudo systemctl restart $service
    echo -ne "Restarting $service...\r"
    sleep 1
    echo -ne "Restarting $service...$green Done! $neutral\n"
done

sudo systemctl restart netfilter-persistent


cd

clear
echo -e "${blue}══════════════════════════════════════════════════════════════════════${neutral}"
echo -e "${green}                                  Install Menu              ${neutral}"
echo -e "${blue}══════════════════════════════════════════════════════════════════════${neutral}"


wget https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/menu.sh && chmod +x menu.sh && ./menu.sh

cd


clear
echo -e "${blue}══════════════════════════════════════════════════════════════════════${neutral}"
echo -e "${green}                               plugin Alrescha79        ${neutral}"
echo -e "${blue}══════════════════════════════════════════════════════════════════════${neutral}"


wget https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/package-gohide.sh && chmod +x package-gohide.sh && ./package-gohide.sh
cd 
rm -rf package-gohide.sh

# cd
# echo -e "${blue}══════════════════════════════════════════════════════════════════════${neutral}"
# echo -e "${green}   Install golang bye Alrescha79       ${neutral}"
# echo -e "${blue}══════════════════════════════════════════════════════════════════════${neutral}"


# cd
# wget https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/backend/install-go.sh && chmod +x install-go.sh && ./install-go.sh
# rm -rf install-go.sh
# cd

if [ -d "/root/rmck" ]; then
    rm -rf /root/rmck
fi


clear

# Send completion notification to Telegram
echo -e "${blue}Mengirim notifikasi penyelesaian instalasi...${neutral}"
completion_time=$(date '+%Y-%m-%d %H:%M:%S %Z')
domain=$(cat /etc/xray/domain 2>/dev/null || echo "Not configured")

completion_message="✅ <b>Alrescha79 VPN Script - Instalasi Selesai</b>

📊 <b>Detail Pengguna:</b>
👤 User ID: <code>${user_id}</code>
🆔 IP Address: <code>${server_ip}</code>
🌐 Domain: <code>${domain}</code>
⏰ Waktu Selesai: <code>${completion_time}</code>

🌍 <b>Informasi Server:</b>
🏙️ Lokasi: <code>${server_city}, ${server_region}, ${server_country}</code>
🏢 ISP: <code>${server_org}</code>
🖥️ Hostname: <code>${server_hostname}</code>

💻 <b>Sistem:</b>
📦 OS: <code>${server_os}</code>
🔧 Kernel: <code>${server_kernel}</code>

🎉 <b>Status:</b> Instalasi berhasil diselesaikan!
🔄 <b>Selanjutnya:</b> Server akan restart dalam beberapa saat
📞 <b>Support:</b> @Alrescha79

🚀 Server VPN siap digunakan setelah restart!"

send_telegram_notification "$completion_message" "HTML" "success"

echo -e "${blue}══════════════════════════════════════════════════════════════════════${neutral}"
echo -e "${green}           Install SELESAI            ${neutral}"
echo -e "${blue}══════════════════════════════════════════════════════════════════════${neutral}"
echo -e "${green}  Selamat! Proses instalasi selesai.${neutral}"
echo -e "${green}  ✓ Notifikasi Telegram telah dikirim.${neutral}"
echo -e "${gray}Server akan otomatis reboot dalam 10 detik...${neutral}"
echo -e "${blue}══════════════════════════════════════════════════════════════════════${neutral}"

# Countdown with animation
for i in {10..1}; do
    printf "\r${yellow}Reboot dalam: ${red}%2d${yellow} detik ${blue}[" $i
    
    # Progress bar animation
    filled=$((10 - i + 1))
    for ((j=1; j<=10; j++)); do
        if [ $j -le $filled ]; then
            printf "▰"
        else
            printf "▱"
        fi
    done
    printf "]${neutral}"
    
    sleep 1
done

printf "\n"
echo -e "${green}🔄 Melakukan reboot sekarang...${neutral}"
sleep 1
reboot