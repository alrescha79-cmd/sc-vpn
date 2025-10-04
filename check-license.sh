#!/bin/bash

# Color definitions
red="\e[38;5;196m"
green="\e[38;5;82m"
yellow="\e[38;5;226m"
blue="\e[38;5;39m"
white="\e[1;37m"
neutral="\e[0m"
gray="\e[38;5;245m"

# Constants
LICENSE_LOG_FILE="/var/log/setup/license-monitor.log"
LICENSE_CACHE_FILE="/tmp/license_status"
TELEGRAM_CONFIG_FILE="/root/.vars"

# VPN Services yang dapat dikelola (tidak termasuk SSH untuk keamanan)
VPN_SERVICES=(
    "nginx" "haproxy" "openvpn"
    "vmess@config" "vless@config" "trojan@config" "shadowsocks@config"
    "ws" "dropbear"
)

# Logging function
log_message() {
    mkdir -p "$(dirname "$LICENSE_LOG_FILE")" 2>/dev/null || true
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LICENSE_LOG_FILE"
}

# Date calculation function
datediff() {
    local exp_date="$1"
    local current_date="$2"
    local exp_epoch=$(date -d "$exp_date" +%s 2>/dev/null || echo "0")
    local current_epoch=$(date -d "$current_date" +%s 2>/dev/null || echo "0")
    local diff_days=$(( (exp_epoch - current_epoch) / 86400 ))
    
    if [ "$diff_days" -gt 0 ]; then
        echo "$diff_days Hari Lagi"
    elif [ "$diff_days" -eq 0 ]; then
        echo "Expires Hari Ini"
    else
        echo "Expired $((-diff_days)) Hari yang Lalu"
    fi
}

# Display license status function
display_license_status() {
    local user_id="$1"
    local status="$2"
    local exp_date="$3"
    local current_date="$4"
    local current_time="$5"
    local hostname=$(hostname 2>/dev/null || echo "Unknown")
    local ip_address=$(curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null || echo "Unknown")
    
    local status_text status_color box_color
    if [ "$status" = "VALID" ]; then
        status_text="ACTIVE"
        status_color="${green}"
        box_color="${green}"
    elif [ "$status" = "EXPIRED" ]; then
        status_text="EXPIRED"
        status_color="${red}"
        box_color="${red}"
    else
        status_text="UNKNOWN"
        status_color="${yellow}"
        box_color="${yellow}"
    fi
    
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

# Get system info function
get_system_info() {
    local server_ip=$(curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null || echo "Unknown")
    local server_city=$(curl -s --connect-timeout 5 ipinfo.io/city 2>/dev/null || echo "Unknown")
    local server_region=$(curl -s --connect-timeout 5 ipinfo.io/region 2>/dev/null || echo "Unknown")
    local server_country=$(curl -s --connect-timeout 5 ipinfo.io/country 2>/dev/null || echo "Unknown")
    local server_org=$(curl -s --connect-timeout 5 ipinfo.io/org 2>/dev/null || echo "Unknown")
    local server_timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "Unknown")
    local server_hostname=$(hostname 2>/dev/null || echo "Unknown")
    local server_os=$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f2 2>/dev/null || echo "Unknown")
    local server_kernel=$(uname -r 2>/dev/null || echo "Unknown")
    local server_arch=$(uname -m 2>/dev/null || echo "Unknown")
    local current_time=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "Unknown")
    
    echo "${server_ip}|${server_city}|${server_region}|${server_country}|${server_org}|${server_timezone}|${server_hostname}|${server_os}|${server_kernel}|${server_arch}|${current_time}"
}

# Send telegram notification function
send_telegram_notification() {
    local message="$1"
    local parse_mode="${2:-HTML}"
    local notification_type="$3"
    
    # Load Telegram configuration with priority: .vars file > environment variables
    local bot_token chat_id
    if [ -f "$TELEGRAM_CONFIG_FILE" ]; then
        bot_token=$(grep "^TELEGRAM_BOT_TOKEN=" "$TELEGRAM_CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        chat_id=$(grep "^TELEGRAM_CHAT_ID=" "$TELEGRAM_CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    fi
    
    # Fallback to environment variables if not found in .vars
    [ -z "$bot_token" ] && bot_token="$TELEGRAM_BOT_TOKEN"
    [ -z "$chat_id" ] && chat_id="$TELEGRAM_CHAT_ID"
    
    # Check if configuration is available
    if [ -n "$bot_token" ] && [ -n "$chat_id" ]; then
        # Send message with proper JSON escaping
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

# Function to stop all VPN services
stop_all_services() {
    local stopped_services=""
    echo -e "${red}Menghentikan layanan VPN...${neutral}"
    
    for service in "${VPN_SERVICES[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "  ${yellow}Menghentikan: ${service}${neutral}"
            systemctl stop "$service" >/dev/null 2>&1
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                stopped_services="${stopped_services}❌ $service - Gagal dihentikan\n"
            else
                stopped_services="${stopped_services}✅ $service - Berhasil dihentikan\n"
            fi
        else
            stopped_services="${stopped_services}⚪ $service - Sudah tidak aktif\n"
        fi
    done
    
    log_message "STOPPING ALL SERVICES - License expired"
    
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
$(echo -e \"$stopped_services\")

✅ <b>Layanan yang Tetap Aktif:</b>
🔒 SSH - Akses remote tetap aman
🔧 System services - Server tetap operasional

❌ <b>Status:</b> Layanan VPN dihentikan karena lisensi kadaluarsa
🔧 <b>Script:</b> Alrescha79 VPN Script

💡 <b>Solusi:</b>
1. Perpanjang lisensi script
2. Atau hubungi admin untuk informasi lebih lanjut

📞 <b>Admin:</b> @Alrescha79"

    send_telegram_notification "$telegram_message" "HTML" "service_stopped"
}

# Function to start all services
start_all_services() {
    local started_services=""
    echo -e "${green}Memulai layanan VPN...${neutral}"
    
    for service in "${VPN_SERVICES[@]}"; do
        if ! systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "  ${green}Memulai: ${service}${neutral}"
            systemctl start "$service" >/dev/null 2>&1
            sleep 1
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                started_services="${started_services}✅ $service - Berhasil dimulai\n"
            else
                started_services="${started_services}❌ $service - Gagal dimulai\n"
            fi
        else
            started_services="${started_services}⚪ $service - Sudah aktif\n"
        fi
    done
    
    log_message "STARTING ALL SERVICES - License valid"
    
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
$(echo -e \"$started_services\")

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
    
    # Validate extracted data
    if [ -z "$user_id" ] || [ -z "$exp_date" ] || [ -z "$user_ip" ]; then
        log_message "ERROR: Invalid license format for IP $vps_ip"
        return 1
    fi
    
    # Check if IP matches
    if [ "$user_ip" != "$vps_ip" ]; then
        log_message "ERROR: IP mismatch - Expected: $user_ip, Got: $vps_ip"
        return 1
    fi
    
    # Check expiration
    local current_date=$(date '+%Y-%m-%d')
    local exp_epoch=$(date -d "$exp_date" +%s 2>/dev/null)
    local current_epoch=$(date -d "$current_date" +%s 2>/dev/null)
    
    if [ -z "$exp_epoch" ] || [ -z "$current_epoch" ]; then
        log_message "ERROR: Cannot parse dates"
        return 1
    fi
    
    # Cache license status
    local current_time=$(date '+%H:%M:%S')
    echo "USER_ID=$user_id|STATUS=VALID|EXP_DATE=$exp_date|CURRENT_DATE=$current_date|CURRENT_TIME=$current_time" > "$LICENSE_CACHE_FILE" 2>/dev/null || true
    
    if [ "$current_epoch" -gt "$exp_epoch" ]; then
        log_message "LICENSE EXPIRED: User $user_id, IP $vps_ip, Expired $exp_date"
        echo "USER_ID=$user_id|STATUS=EXPIRED|EXP_DATE=$exp_date|CURRENT_DATE=$current_date|CURRENT_TIME=$current_time" > "$LICENSE_CACHE_FILE" 2>/dev/null || true
        return 2  # License expired
    else
        log_message "LICENSE VALID: User $user_id, IP $vps_ip, Expires $exp_date"
        return 0  # License valid
    fi
}

# Main license check and service management
main_check() {
    local silent_mode="$1"
    
    check_license
    local license_status=$?
    
    case $license_status in
        0)  # Valid license
            [ "$silent_mode" != "--silent" ] && echo -e "${green}✓ Lisensi valid - Layanan VPN akan dimulai${neutral}"
            start_all_services
            return 0
            ;;
        2)  # Expired license
            [ "$silent_mode" != "--silent" ] && echo -e "${red}✗ Lisensi telah kadaluarsa - Layanan VPN akan dihentikan${neutral}"
            stop_all_services
            return 2
            ;;
        *)  # Error
            [ "$silent_mode" != "--silent" ] && echo -e "${yellow}⚠ Error saat memeriksa lisensi - Layanan tidak diubah${neutral}"
            return 1
            ;;
    esac
}

# Function to display license and service status
display_status() {
    echo -e "${blue}Menampilkan status lisensi dan layanan...${neutral}"
    
    # Try to get cached license info first
    local user_id status exp_date current_date current_time
    if [ -f "$LICENSE_CACHE_FILE" ]; then
        local cache_data=$(cat "$LICENSE_CACHE_FILE" 2>/dev/null)
        if [ -n "$cache_data" ]; then
            user_id=$(echo "$cache_data" | grep -o "USER_ID=[^|]*" | cut -d'=' -f2)
            status=$(echo "$cache_data" | grep -o "STATUS=[^|]*" | cut -d'=' -f2)
            exp_date=$(echo "$cache_data" | grep -o "EXP_DATE=[^|]*" | cut -d'=' -f2)
            current_date=$(echo "$cache_data" | grep -o "CURRENT_DATE=[^|]*" | cut -d'=' -f2)
            current_time=$(echo "$cache_data" | grep -o "CURRENT_TIME=[^|]*" | cut -d'=' -f2)
        fi
    fi
    
    # If no cached data or incomplete, run fresh check
    if [ -z "$user_id" ] || [ -z "$status" ] || [ -z "$exp_date" ]; then
        echo -e "${yellow}Cache tidak tersedia, melakukan pengecekan lisensi...${neutral}"
        check_license >/dev/null 2>&1
        local license_status=$?
        
        if [ -f "$LICENSE_CACHE_FILE" ]; then
            local cache_data=$(cat "$LICENSE_CACHE_FILE" 2>/dev/null)
            user_id=$(echo "$cache_data" | grep -o "USER_ID=[^|]*" | cut -d'=' -f2)
            status=$(echo "$cache_data" | grep -o "STATUS=[^|]*" | cut -d'=' -f2)
            exp_date=$(echo "$cache_data" | grep -o "EXP_DATE=[^|]*" | cut -d'=' -f2)
            current_date=$(echo "$cache_data" | grep -o "CURRENT_DATE=[^|]*" | cut -d'=' -f2)
            current_time=$(echo "$cache_data" | grep -o "CURRENT_TIME=[^|]*" | cut -d'=' -f2)
        fi
    fi
    
    # Display license information
    if [ -n "$user_id" ] && [ -n "$status" ] && [ -n "$exp_date" ]; then
        display_license_status "$user_id" "$status" "$exp_date" "$current_date" "$current_time"
        echo ""
        
        # Display service status
        if [ "$status" = "VALID" ]; then
            echo -e "${green}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
            echo -e "${green}║                            STATUS LAYANAN                             ║${neutral}"
            echo -e "${green}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
            echo -e "${neutral}                   ${white}VPN SERVICES : ${green}RUNNING${neutral}                "
            echo -e "${neutral}                   ${white}SSH ACCESS   : ${green}ALWAYS ACTIVE${neutral}        "
            echo -e "${neutral}                   ${white}STATUS       : ${green}ALL SERVICES OK${neutral}       "
            echo -e "${green}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
        elif [ "$status" = "EXPIRED" ]; then
            echo -e "${red}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
            echo -e "${red}║                            STATUS LAYANAN                             ║${neutral}"
            echo -e "${red}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
            echo -e "${neutral}                   ${white}VPN SERVICES : ${red}STOPPED${neutral}              "
            echo -e "${neutral}                   ${white}SSH ACCESS   : ${green}ALWAYS ACTIVE${neutral}        "
            echo -e "${neutral}                   ${white}REASON       : ${red}LICENSE EXPIRED${neutral}      "
            echo -e "${red}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
        else
            echo -e "${yellow}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
            echo -e "${yellow}║                            STATUS LAYANAN                             ║${neutral}"
            echo -e "${yellow}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
            echo -e "${neutral}                   ${white}STATUS       : ${yellow}TIDAK DIKETAHUI${neutral}      "
            echo -e "${neutral}                   ${white}KETERANGAN   : Jalankan cek lisensi dulu${neutral}"
            echo -e "${yellow}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
        fi
        echo ""
        
        # Display service details
        if [ "$status" = "VALID" ]; then
            echo -e "${green}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
            echo -e "${green}║                            STATUS LAYANAN                             ║${neutral}"
            echo -e "${green}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
            echo -e "${neutral}                   ${white}VPN SERVICES : ${green}RUNNING${neutral}                "
            echo -e "${neutral}                   ${white}SSH ACCESS   : ${green}ALWAYS ACTIVE${neutral}        "
            echo -e "${neutral}                   ${white}STATUS       : ${green}ALL SERVICES OK${neutral}       "
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
}

# Main script logic
case "${1:-}" in
    --check)
        main_check
        ;;
    --silent)
        main_check --silent
        ;;
    --status)
        display_status
        ;;
    --stop-services)
        echo -e "${red}Menghentikan semua layanan VPN secara paksa...${neutral}"
        stop_all_services
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