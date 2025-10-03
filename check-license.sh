#!/bin/bash

# Color definitions
red="\e[38;5;196m"
green="\e[38;5;82m"
yellow="\e[38;5;226m"
blue="\e[38;5;39m"
neutral="\e[0m"
gray="\e[38;5;245m"

# Configuration
LICENSE_CHECK_FILE="/var/log/setup/license_status"
LICENSE_LOG_FILE="/var/log/setup/license.log"
SERVICES_STATUS_FILE="/var/log/setup/services_status"

# Create directories if not exist
mkdir -p /var/log/setup

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LICENSE_LOG_FILE"
}

# Function to get system information
get_system_info() {
    local server_ip=$(curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null || echo "Unknown")
    local server_city=$(curl -s --connect-timeout 5 ipinfo.io/city 2>/dev/null || echo "Unknown")
    local server_region=$(curl -s --connect-timeout 5 ipinfo.io/region 2>/dev/null || echo "Unknown")
    local server_country=$(curl -s --connect-timeout 5 ipinfo.io/country 2>/dev/null || echo "Unknown")
    local server_org=$(curl -s --connect-timeout 5 ipinfo.io/org 2>/dev/null | cut -d " " -f 2-10 || echo "Unknown")
    local server_timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "Unknown")
    local server_hostname=$(hostname 2>/dev/null || echo "Unknown")
    local server_os=$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f2 2>/dev/null || echo "Unknown")
    local server_kernel=$(uname -r 2>/dev/null || echo "Unknown")
    local server_arch=$(uname -m 2>/dev/null || echo "Unknown")
    local current_time=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "Unknown")
    
    echo "${server_ip}|${server_city}|${server_region}|${server_country}|${server_org}|${server_timezone}|${server_hostname}|${server_os}|${server_kernel}|${server_arch}|${current_time}"
}

# Function to send Telegram notification
send_telegram_notification() {
    local message="$1"
    local parse_mode="${2:-HTML}"
    local notification_type="${3:-general}"
    
    # Load Telegram settings from setup.sh variables if available
    local bot_token=""
    local chat_id=""
    
    # Try to get from environment or decode base64
    if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
        bot_token="$TELEGRAM_BOT_TOKEN"
    else
        local _bot_token="ODMyNjYwNTMxOTpBQUd1V2Q0aWwwTVY0VU1RNFpGWkZmRi1qaV9oSVcxVWZrRQo="
        bot_token=$(echo "$_bot_token" | base64 -d 2>/dev/null || echo "")
    fi
    
    if [ -n "$TELEGRAM_CHAT_ID" ]; then
        chat_id="$TELEGRAM_CHAT_ID"
    else
        local _chat_id="NjQ3MTQzMDI3Cg=="
        chat_id=$(echo "$_chat_id" | base64 -d 2>/dev/null || echo "")
    fi
    
    # Send notification if token and chat_id are available
    if [ -n "$bot_token" ] && [ -n "$chat_id" ]; then
        curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
            -H "Content-Type: application/json" \
            -d "{
                \"chat_id\": \"${chat_id}\",
                \"text\": \"${message}\",
                \"parse_mode\": \"${parse_mode}\",
                \"disable_web_page_preview\": true
            }" >/dev/null 2>&1
    fi
}

# Function to stop all services
stop_all_services() {
    echo -e "${yellow}Menghentikan semua layanan karena lisensi kadaluarsa...${neutral}"
    log_message "STOPPING ALL SERVICES - License expired"
    
    # Stop main services
    local services=(
        "xray"
        "nginx" 
        "haproxy"
        "dropbear"
        "ssh"
        "sshd"
        "openvpn"
        "openvpn@server"
        "stunnel4"
        "squid"
        "privoxy"
        "cron"
        "fail2ban"
    )
    
    local stopped_services=""
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            systemctl stop "$service" 2>/dev/null
            if [ $? -eq 0 ]; then
                stopped_services+="✓ $service\n"
                log_message "Stopped service: $service"
            fi
        fi
    done
    
    # Save services status
    echo "SERVICES_STOPPED" > "$SERVICES_STATUS_FILE"
    echo -e "${red}Semua layanan telah dihentikan karena lisensi kadaluarsa${neutral}"
    
    # Send Telegram notification
    local system_info=$(get_system_info)
    IFS='|' read -r server_ip server_city server_region server_country server_org server_timezone server_hostname server_os server_kernel server_arch current_time <<< "$system_info"
    
    local telegram_message="🚨 <b>LAYANAN DIHENTIKAN - LISENSI KADALUARSA</b>

⚠️ <b>Peringatan:</b> Semua layanan VPN telah dihentikan otomatis

🌍 <b>Informasi Server:</b>
🆔 IP Address: <code>${server_ip}</code>
🏙️ Lokasi: <code>${server_city}, ${server_region}, ${server_country}</code>
🏢 ISP: <code>${server_org}</code>
🖥️ Hostname: <code>${server_hostname}</code>
⏰ Waktu: <code>${current_time}</code>

🛑 <b>Layanan yang Dihentikan:</b>
$(echo -e "$stopped_services")

💡 <b>Solusi:</b>
1. Perpanjang lisensi script
2. Jalankan ulang script setup
3. Atau hubungi admin untuk perpanjangan

📞 <b>Admin:</b> @Alrescha79"

    send_telegram_notification "$telegram_message" "HTML" "service_stopped"
}

# Function to start all services
start_all_services() {
    echo -e "${green}Memulai kembali semua layanan...${neutral}"
    log_message "STARTING ALL SERVICES - License renewed"
    
    # Start main services
    local services=(
        "nginx" 
        "haproxy"
        "xray"
        "dropbear"
        "ssh"
        "sshd"
        "openvpn"
        "openvpn@server"
        "stunnel4"
        "squid"
        "privoxy"
        "cron"
        "fail2ban"
    )
    
    local started_services=""
    for service in "${services[@]}"; do
        if systemctl is-enabled --quiet "$service" 2>/dev/null; then
            systemctl start "$service" 2>/dev/null
            if [ $? -eq 0 ]; then
                started_services+="✓ $service\n"
                log_message "Started service: $service"
            fi
        fi
    done
    
    # Update services status
    echo "SERVICES_RUNNING" > "$SERVICES_STATUS_FILE"
    echo -e "${green}Semua layanan telah dimulai kembali${neutral}"
    
    # Send Telegram notification
    local system_info=$(get_system_info)
    IFS='|' read -r server_ip server_city server_region server_country server_org server_timezone server_hostname server_os server_kernel server_arch current_time <<< "$system_info"
    
    local telegram_message="✅ <b>LAYANAN DIMULAI KEMBALI - LISENSI VALID</b>

🎉 <b>Informasi:</b> Semua layanan VPN telah dimulai kembali

🌍 <b>Informasi Server:</b>
🆔 IP Address: <code>${server_ip}</code>
🏙️ Lokasi: <code>${server_city}, ${server_region}, ${server_country}</code>
🏢 ISP: <code>${server_org}</code>
🖥️ Hostname: <code>${server_hostname}</code>
⏰ Waktu: <code>${current_time}</code>

🚀 <b>Layanan yang Dimulai:</b>
$(echo -e "$started_services")

✅ <b>Status:</b> Semua layanan beroperasi normal
🔧 <b>Script:</b> Alrescha79 VPN Script

📞 <b>Support:</b> @Alrescha79"

    send_telegram_notification "$telegram_message" "HTML" "service_started"
}

# Function to check license validity
check_license() {
    echo -e "${blue}Memeriksa validitas lisensi...${neutral}"
    log_message "Checking license validity"
    
    # Get current IP
    local vps_ip=$(curl -s --connect-timeout 10 ipinfo.io/ip 2>/dev/null)
    if [ -z "$vps_ip" ]; then
        log_message "ERROR: Cannot get VPS IP address"
        return 1
    fi
    
    # Download license data
    local data=$(curl -s --connect-timeout 10 --max-time 30 https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/izin 2>/dev/null)
    if [ -z "$data" ]; then
        log_message "ERROR: Cannot download license data"
        return 1
    fi
    
    # Validate data format
    if ! echo "$data" | grep -q "^###.*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.*[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+"; then
        log_message "ERROR: Invalid license data format"
        return 1
    fi
    
    # Parse license data
    local user_line=$(echo "$data" | grep "$vps_ip")
    if [ -z "$user_line" ]; then
        log_message "ERROR: IP $vps_ip not found in license data"
        return 1
    fi
    
    local user_id=$(echo "$user_line" | awk '{print $2}')
    local exp_date=$(echo "$user_line" | awk '{print $3}')
    local user_ip=$(echo "$user_line" | awk '{print $4}')
    
    # Validate expiration date
    local current_date=$(date +%Y-%m-%d)
    if [[ "$exp_date" < "$current_date" ]]; then
        log_message "LICENSE EXPIRED: User $user_id, IP $vps_ip, Expired $exp_date"
        return 1
    fi
    
    # Calculate days left
    local days_left=$(( ( $(date -d "$exp_date" +%s) - $(date -d "$current_date" +%s) ) / 86400 ))
    
    log_message "LICENSE VALID: User $user_id, IP $vps_ip, Expires $exp_date, Days left $days_left"
    
    # Save license status
    echo "VALID|$user_id|$exp_date|$days_left" > "$LICENSE_CHECK_FILE"
    
    return 0
}

# Main function
main() {
    echo -e "${blue}=== Alrescha79 VPN License Checker ===${neutral}"
    echo -e "${gray}Waktu: $(date '+%Y-%m-%d %H:%M:%S')${neutral}"
    echo ""
    
    # Check if this is manual run or cron job
    if [ "$1" = "--silent" ]; then
        # Silent mode for cron
        exec > /dev/null 2>&1
    fi
    
    # Check current services status
    local current_services_status=""
    if [ -f "$SERVICES_STATUS_FILE" ]; then
        current_services_status=$(cat "$SERVICES_STATUS_FILE")
    fi
    
    # Check license
    if check_license; then
        echo -e "${green}✓ Lisensi valid${neutral}"
        
        # If services were stopped due to expired license, start them
        if [ "$current_services_status" = "SERVICES_STOPPED" ]; then
            echo -e "${yellow}Mendeteksi layanan yang dihentikan, memulai kembali...${neutral}"
            start_all_services
        else
            echo -e "${green}✓ Semua layanan berjalan normal${neutral}"
        fi
        
    else
        echo -e "${red}✗ Lisensi tidak valid atau kadaluarsa${neutral}"
        
        # If services are running, stop them
        if [ "$current_services_status" != "SERVICES_STOPPED" ]; then
            stop_all_services
        else
            echo -e "${red}✓ Layanan sudah dihentikan sebelumnya${neutral}"
        fi
    fi
    
    echo ""
    echo -e "${gray}Log tersimpan di: $LICENSE_LOG_FILE${neutral}"
}

# Handle command line arguments
case "$1" in
    --check)
        main
        ;;
    --silent)
        main --silent
        ;;
    --start-services)
        start_all_services
        ;;
    --stop-services)
        stop_all_services
        ;;
    --status)
        if [ -f "$LICENSE_CHECK_FILE" ]; then
            IFS='|' read -r status user_id exp_date days_left < "$LICENSE_CHECK_FILE"
            echo -e "${blue}Status Lisensi:${neutral}"
            echo -e "  User ID: $user_id"
            echo -e "  Kadaluarsa: $exp_date"
            echo -e "  Sisa hari: $days_left"
            echo -e "  Status: $status"
        else
            echo -e "${red}Belum ada data lisensi${neutral}"
        fi
        
        if [ -f "$SERVICES_STATUS_FILE" ]; then
            services_status=$(cat "$SERVICES_STATUS_FILE")
            echo -e "${blue}Status Layanan:${neutral} $services_status"
        else
            echo -e "${yellow}Status layanan tidak diketahui${neutral}"
        fi
        ;;
    --install-cron)
        # Install cron job to check license every hour
        echo "0 * * * * /bin/bash $(readlink -f "$0") --silent" | crontab -
        echo -e "${green}✓ Cron job telah diinstall untuk pengecekan otomatis setiap jam${neutral}"
        ;;
    --remove-cron)
        # Remove cron job
        crontab -l | grep -v "$(readlink -f "$0")" | crontab -
        echo -e "${green}✓ Cron job telah dihapus${neutral}"
        ;;
    *)
        echo -e "${blue}Penggunaan:${neutral}"
        echo -e "  $0 --check          : Cek lisensi dan kelola layanan"
        echo -e "  $0 --silent         : Cek lisensi tanpa output (untuk cron)"
        echo -e "  $0 --status         : Tampilkan status lisensi dan layanan"
        echo -e "  $0 --start-services : Paksa mulai semua layanan"
        echo -e "  $0 --stop-services  : Paksa hentikan semua layanan"
        echo -e "  $0 --install-cron   : Install pengecekan otomatis setiap jam"
        echo -e "  $0 --remove-cron    : Hapus pengecekan otomatis"
        echo ""
        echo -e "${yellow}Contoh penggunaan:${neutral}"
        echo -e "  bash $0 --check"
        echo -e "  bash $0 --install-cron"
        ;;
esac