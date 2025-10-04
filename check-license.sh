#!/bin/bash

# Color definitions
red="\e[38;5;196m"
green="\e[38;5;82m"
yellow="\e[38;5;226m"
blue="\e[38;5;39m"
white="\e[1;37m"
neutral="\e[0m"
gray="\e[38;5;245m"

# Configuration
LICENSE_CHECK_FILE="/var/log/setup/license_status"
LICENSE_LOG_FILE="/var/log/setup/license.log"
SERVICES_STATUS_FILE="/var/log/setup/services_status"

# Load configuration from /root/.vars if available
if [ -f "/root/.vars" ]; then
    source /root/.vars 2>/dev/null
fi

# Create directories if not exist
mkdir -p /var/log/setup

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LICENSE_LOG_FILE"
}

# Function to calculate date difference
datediff() {
    local exp_date="$1"
    local current_date="$2"
    local exp_epoch=$(date -d "$exp_date" +%s 2>/dev/null || echo "0")
    local current_epoch=$(date -d "$current_date" +%s 2>/dev/null || echo "0")
    local diff_days=$(( (exp_epoch - current_epoch) / 86400 ))
    
    if [ $diff_days -gt 0 ]; then
        echo "$diff_days Hari Lagi"
    elif [ $diff_days -eq 0 ]; then
        echo "Expires Hari Ini"
    else
        echo "Expired $((-diff_days)) Hari yang Lalu"
    fi
}

# Function to display license status with beautiful formatting
display_license_status() {
    local status="$1"
    local user_id="$2"
    local exp_date="$3"
    local days_left="$4"
    local current_date=$(date +%Y-%m-%d)
    local current_time=$(date '+%H:%M:%S')
    local hostname=$(hostname)
    local ip_address=$(curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null || echo "Unknown")
    
    # Determine status color and text
    local status_color="$green"
    local status_text="AKTIF"
    local box_color="$green"
    
    if [ "$status" != "VALID" ] || [ $days_left -le 0 ]; then
        status_color="$red"
        status_text="EXPIRED"
        box_color="$red"
    elif [ $days_left -le 7 ]; then
        status_color="$yellow"
        status_text="SEGERA EXPIRED"
        box_color="$yellow"
    fi
    
    # Display beautiful license information
    echo -e "${box_color}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${box_color}║                            INFORMASI LISENSI                          ║${neutral}"
    echo -e "${box_color}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
    echo -e "${box_color}║${neutral}                   ${white}USER ID     : ${user_id}${neutral}                             ${box_color}║${neutral}"
    echo -e "${box_color}║${neutral}                   ${white}STATUS      : ${status_color}${status_text}${neutral}                           ${box_color}║${neutral}"
    echo -e "${box_color}║${neutral}                   ${white}EXPIRED     : ${exp_date}${neutral}                    ${box_color}║${neutral}"
    echo -e "${box_color}║${neutral}                   ${white}MASA AKTIF  : $(datediff "$exp_date" "$current_date")${neutral}                      ${box_color}║${neutral}"
    echo -e "${box_color}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
    echo -e "${box_color}║${neutral}                   ${white}SERVER IP   : ${ip_address}${neutral}                        ${box_color}║${neutral}"
    echo -e "${box_color}║${neutral}                   ${white}HOSTNAME    : ${hostname}${neutral}                           ${box_color}║${neutral}"
    echo -e "${box_color}║${neutral}                   ${white}WAKTU CEK   : ${current_date} ${current_time}${neutral}           ${box_color}║${neutral}"
    echo -e "${box_color}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
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
    
    # Load Telegram settings with priority order
    local bot_token=""
    local chat_id=""
    
    # 1. First priority: Check /root/.vars file
    if [ -f "/root/.vars" ]; then
        source /root/.vars 2>/dev/null
        if [ -n "$bot_token" ]; then
            # Use from .vars file
            bot_token="$bot_token"
        fi
        if [ -n "$telegram_id" ]; then
            # Use from .vars file
            chat_id="$telegram_id"
        fi
    fi
    
    # 2. Second priority: Check environment variables
    if [ -z "$bot_token" ] && [ -n "$TELEGRAM_BOT_TOKEN" ]; then
        bot_token="$TELEGRAM_BOT_TOKEN"
    fi
    
    if [ -z "$chat_id" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        chat_id="$TELEGRAM_CHAT_ID"
    fi
    
    # 3. Third priority: Use base64 encoded defaults (fallback)
    if [ -z "$bot_token" ]; then
        local _bot_token="ODMyNjYwNTMxOTpBQUd1V2Q0aWwwTVY0VU1RNFpGWkZmRi1qaV9oSVcxVWZrRQo="
        bot_token=$(echo "$_bot_token" | base64 -d 2>/dev/null || echo "")
    fi
    
    if [ -z "$chat_id" ]; then
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
    echo -e "${yellow}Menghentikan layanan VPN karena lisensi kadaluarsa (SSH tetap aktif)...${neutral}"
    log_message "STOPPING ALL SERVICES - License expired"
    
    # Stop VPN services only (SSH excluded for remote access)
    local services=(
        "xray"
        "nginx" 
        "haproxy"
        "dropbear"  # Dropbear is alternative SSH, can be stopped
        # "ssh"     # EXCLUDED - needed for remote access
        # "sshd"    # EXCLUDED - needed for remote access
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
    echo -e "${red}Layanan VPN telah dihentikan karena lisensi kadaluarsa (SSH tetap aktif)${neutral}"
    
    # Send Telegram notification
    local system_info=$(get_system_info)
    IFS='|' read -r server_ip server_city server_region server_country server_org server_timezone server_hostname server_os server_kernel server_arch current_time <<< "$system_info"
    
    local telegram_message="🚨 <b>LAYANAN VPN DIHENTIKAN - LISENSI KADALUARSA</b>

⚠️ <b>Peringatan:</b> Layanan VPN telah dihentikan otomatis karena lisensi kadaluarsa

🌍 <b>Informasi Server:</b>
🆔 IP Address: <code>${server_ip}</code>
🏙️ Lokasi: <code>${server_city}, ${server_region}, ${server_country}</code>
🏢 ISP: <code>${server_org}</code>
🖥️ Hostname: <code>${server_hostname}</code>
⏰ Waktu: <code>${current_time}</code>

🛑 <b>Layanan VPN yang Dihentikan:</b>
$(echo -e "$stopped_services")

✅ <b>Layanan yang Tetap Aktif:</b>
🔒 SSH - Akses remote tetap aman
🔧 System services - Server tetap operasional

💡 <b>Solusi:</b>
1. Perpanjang lisensi script
2. Atau hubungi admin untuk informasi lebih lanjut

📞 <b>Admin:</b> @Alrescha79"

    send_telegram_notification "$telegram_message" "HTML" "service_stopped"
}

# Function to start all services
start_all_services() {
    echo -e "${green}Memulai kembali layanan VPN...${neutral}"
    log_message "STARTING ALL SERVICES - License renewed"
    
    # Start VPN services only (SSH excluded - always running)
    local services=(
        "nginx" 
        "haproxy"
        "xray"
        "dropbear"  # Dropbear is alternative SSH, can be started
        # "ssh"     # EXCLUDED - should always run for remote access
        # "sshd"    # EXCLUDED - should always run for remote access
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
    echo -e "${green}Layanan VPN telah dimulai kembali${neutral}"
    
    # Send Telegram notification
    local system_info=$(get_system_info)
    IFS='|' read -r server_ip server_city server_region server_country server_org server_timezone server_hostname server_os server_kernel server_arch current_time <<< "$system_info"
    
    local telegram_message="✅ <b>LAYANAN VPN DIMULAI KEMBALI - LISENSI VALID</b>

🎉 <b>Informasi:</b> Layanan VPN telah dimulai kembali setelah lisensi diperpanjang

🌍 <b>Informasi Server:</b>
🆔 IP Address: <code>${server_ip}</code>
🏙️ Lokasi: <code>${server_city}, ${server_region}, ${server_country}</code>
🏢 ISP: <code>${server_org}</code>
🖥️ Hostname: <code>${server_hostname}</code>
⏰ Waktu: <code>${current_time}</code>

🚀 <b>Layanan VPN yang Dimulai:</b>
$(echo -e "$started_services")

🔒 <b>Layanan yang Selalu Aktif:</b>
✅ SSH - Akses remote selalu tersedia
✅ System services - Server operasional

✅ <b>Status:</b> Semua layanan VPN beroperasi normal
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
    # Check if this is manual run or cron job
    if [ "$1" = "--silent" ]; then
        # Silent mode for cron
        exec > /dev/null 2>&1
    fi
    
    # Display header for manual runs
    if [ "$1" != "--silent" ]; then
        echo ""
        echo -e "${blue}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
        echo -e "${blue}║                      ALRESCHA79 VPN LICENSE CHECKER                   ║${neutral}"
        echo -e "${blue}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
        echo -e "${neutral}  ${gray}Waktu: $(date '+%Y-%m-%d %H:%M:%S')${neutral}             "
        echo -e "${neutral}  ${gray}Proses: Memeriksa validitas lisensi...${neutral}"
        echo -e "${blue}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
        echo ""
    fi
    
    # Check current services status
    local current_services_status=""
    if [ -f "$SERVICES_STATUS_FILE" ]; then
        current_services_status=$(cat "$SERVICES_STATUS_FILE")
    fi
    
    # Check license
    if check_license; then
        # Get license info for display
        if [ -f "$LICENSE_CHECK_FILE" ]; then
            IFS='|' read -r status user_id exp_date days_left < "$LICENSE_CHECK_FILE"
            if [ "$1" != "--silent" ]; then
                display_license_status "$status" "$user_id" "$exp_date" "$days_left"
                echo ""
            fi
        fi
        
        # If services were stopped due to expired license, start them
        if [ "$current_services_status" = "SERVICES_STOPPED" ]; then
            if [ "$1" != "--silent" ]; then
                echo -e "${yellow}Mendeteksi layanan yang dihentikan, memulai kembali...${neutral}"
            fi
            start_all_services
        else
            if [ "$1" != "--silent" ]; then
                echo -e "${green}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
                echo -e "${green}║                            STATUS LAYANAN                             ║${neutral}"
                echo -e "${green}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
                echo -e "${neutral}                   ${white}VPN SERVICES : ${green}RUNNING${neutral}             "
                echo -e "${neutral}                   ${white}SSH ACCESS   : ${green}ALWAYS ACTIVE${neutral}       "
                echo -e "${neutral}                   ${white}MONITORING   : ${green}ACTIVE${neutral}              "
                echo -e "${green}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
            fi
        fi
        
    else
        if [ "$1" != "--silent" ]; then
            echo -e "${red}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
            echo -e "${red}║                             LISENSI INVALID                           ║${neutral}"
            echo -e "${red}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
            echo -e "${neutral}                   ${white}STATUS      : ${red}EXPIRED/INVALID${neutral}     "
            echo -e "${neutral}                   ${white}AKSI        : Menghentikan layanan VPN${neutral}"
            echo -e "${neutral}                   ${white}SSH ACCESS  : ${green}TETAP AKTIF${neutral}         "
            echo -e "${red}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
            echo ""
        fi
        
        # If services are running, stop them
        if [ "$current_services_status" != "SERVICES_STOPPED" ]; then
            stop_all_services
        else
            if [ "$1" != "--silent" ]; then
                echo -e "${red}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
                echo -e "${red}║                             STATUS LAYANAN                            ║${neutral}"
                echo -e "${red}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
                echo -e "${neutral}                   ${white}VPN SERVICES : ${red}ALREADY STOPPED${neutral} "
                echo -e "${neutral}                   ${white}SSH ACCESS   : ${green}ALWAYS ACTIVE${neutral}       "
                echo -e "${neutral}                   ${white}REASON       : ${red}LICENSE EXPIRED${neutral}     "
                echo -e "${red}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
            fi
        fi
    fi
    
    if [ "$1" != "--silent" ]; then
        echo ""
        echo -e "${gray}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
        echo -e "${gray}║${neutral}  ${gray}Log tersimpan di: $LICENSE_LOG_FILE${neutral}  ${gray}║${neutral}"
        echo -e "${gray}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
    fi
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
        echo ""
        if [ -f "$LICENSE_CHECK_FILE" ]; then
            IFS='|' read -r status user_id exp_date days_left < "$LICENSE_CHECK_FILE"
            display_license_status "$status" "$user_id" "$exp_date" "$days_left"
        else
            echo -e "${red}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
            echo -e "${red}║                            INFORMASI LISENSI                          ║${neutral}"
            echo -e "${red}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
            echo -e "${neutral}                   ${white}STATUS      : ${red}BELUM ADA DATA${neutral}         "
            echo -e "${neutral}                   ${white}KETERANGAN  : Jalankan setup terlebih dahulu${ne"
            echo -e "${red}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
        fi
        
        echo ""
        # Display services status with beautiful formatting
        if [ -f "$SERVICES_STATUS_FILE" ]; then
            services_status=$(cat "$SERVICES_STATUS_FILE")
            if [ "$services_status" = "SERVICES_RUNNING" ]; then
                echo -e "${green}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
                echo -e "${green}║                            STATUS LAYANAN                             ║${neutral}"
                echo -e "${green}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
                echo -e "${neutral}                   ${white}VPN SERVICES : ${green}RUNNING${neutral}             "
                echo -e "${neutral}                   ${white}SSH ACCESS   : ${green}ALWAYS ACTIVE${neutral}       "
                echo -e "${neutral}                   ${white}MONITORING   : ${green}ACTIVE${neutral}              "
                echo -e "${green}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
            else
                echo -e "${red}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
                echo -e "${red}║                            STATUS LAYANAN                             ║${neutral}"
                echo -e "${red}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
                echo -e "${neutral}                   ${white}VPN SERVICES : ${red}STOPPED${neutral}              "
                echo -e "${neutral}                   ${white}SSH ACCESS   : ${green}ALWAYS ACTIVE${neutral}        "
                echo -e "${neutral}                   ${white}REASON       : ${red}LICENSE EXPIRED${neutral}      "
                echo -e "${red}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
            fi
        else
            echo -e "${yellow}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
            echo -e "${yellow}║                            STATUS LAYANAN                             ║${neutral}"
            echo -e "${yellow}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
            echo -e "${neutral}                   ${white}STATUS       : ${yellow}TIDAK DIKETAHUI${neutral}      "
            echo -e "${neutral}                   ${white}KETERANGAN   : Jalankan cek lisensi dulu${neutral}"
            echo -e "${yellow}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
        fi
        echo ""
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
        echo -e "  $0 --stop-services  : Paksa hentikan semua layanan"
        echo -e "  $0 --install-cron   : Install pengecekan otomatis setiap jam"
        echo ""
        echo -e "${yellow}Contoh penggunaan:${neutral}"
        echo -e "  bash $0 --check"
        echo -e "  bash $0 --install-cron"
        ;;
esac