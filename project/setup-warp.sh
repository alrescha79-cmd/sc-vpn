#!/bin/bash

# Cloudflare WARP Setup Script
# Script untuk instalasi dan konfigurasi Cloudflare WARP pada VPS Ubuntu/Debian
# Script akan mengalihkan semua traffic ke WARP

# Color definitions
green="\e[38;5;87m"
red="\e[38;5;196m"
neutral="\e[0m"
blue="\e[38;5;130m"
orange="\e[38;5;99m"
yellow="\e[38;5;226m"
purple="\e[38;5;141m"
bold_white="\e[1;37m"
reset="\e[0m"

# Function to check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${red}Error: Script ini harus dijalankan sebagai root!${neutral}"
        exit 1
    fi
}

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        echo -e "${red}Error: Tidak dapat mendeteksi sistem operasi!${neutral}"
        exit 1
    fi
    
    if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
        echo -e "${red}Error: Script ini hanya mendukung Ubuntu dan Debian!${neutral}"
        exit 1
    fi
    
    echo -e "${green}Sistem operasi terdeteksi: $OS $VER${neutral}"
}

# Function to check if WARP is already installed
check_warp_installed() {
    if command -v warp-cli &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to show loading animation
show_loading() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " %s [%c]  " "$message" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r"
    done
    printf "    \n"
}

# Function to install dependencies
install_dependencies() {
    echo -e "${blue}Menginstall dependencies...${neutral}"
    {
        apt-get update -qq
        apt-get install -y curl gnupg lsb-release apt-transport-https ca-certificates
    } &> /dev/null &
    show_loading $! "Menginstall dependencies"
    
    if [ $? -eq 0 ]; then
        echo -e "${green}✓ Dependencies berhasil diinstall${neutral}"
    else
        echo -e "${red}✗ Gagal menginstall dependencies${neutral}"
        exit 1
    fi
}

# Function to add Cloudflare GPG key and repository
add_cloudflare_repo() {
    echo -e "${blue}Menambahkan repository Cloudflare WARP...${neutral}"
    
    {
        # Add Cloudflare GPG key
        curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
        
        # Add repository
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
        
        # Update package list
        apt-get update -qq
    } &> /dev/null &
    show_loading $! "Menambahkan repository Cloudflare"
    
    if [ $? -eq 0 ]; then
        echo -e "${green}✓ Repository Cloudflare berhasil ditambahkan${neutral}"
    else
        echo -e "${red}✗ Gagal menambahkan repository Cloudflare${neutral}"
        exit 1
    fi
}

# Function to install WARP
install_warp() {
    echo -e "${blue}Menginstall Cloudflare WARP...${neutral}"
    
    {
        apt-get install -y cloudflare-warp
    } &> /dev/null &
    show_loading $! "Menginstall WARP"
    
    if [ $? -eq 0 ]; then
        echo -e "${green}✓ Cloudflare WARP berhasil diinstall${neutral}"
    else
        echo -e "${red}✗ Gagal menginstall WARP${neutral}"
        exit 1
    fi
}

# Function to configure WARP
configure_warp() {
    echo -e "${blue}Mengkonfigurasi Cloudflare WARP...${neutral}"
    
    # Start warp-svc service first
    echo -e "${yellow}Memulai WARP service...${neutral}"
    systemctl start warp-svc
    systemctl enable warp-svc
    sleep 2
    
    # Delete any existing registration to start fresh
    echo -e "${yellow}Membersihkan registrasi lama (jika ada)...${neutral}"
    warp-cli delete &> /dev/null || true
    sleep 1
    
    # Register WARP
    echo -e "${yellow}Mendaftarkan WARP...${neutral}"
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo -e "${yellow}Percobaan registrasi ke-${attempt}...${neutral}"
        if warp-cli register 2>&1 | tee /tmp/warp-register.log | grep -q "Success"; then
            echo -e "${green}✓ Registrasi berhasil${neutral}"
            break
        else
            if [ $attempt -eq $max_attempts ]; then
                echo -e "${red}✗ Registrasi gagal setelah $max_attempts percobaan${neutral}"
                echo -e "${yellow}Log error:${neutral}"
                cat /tmp/warp-register.log
                return 1
            fi
            echo -e "${yellow}Registrasi gagal, mencoba lagi dalam 3 detik...${neutral}"
            sleep 3
            attempt=$((attempt + 1))
        fi
    done
    
    sleep 2
    
    # Set mode to warp (full VPN mode)
    echo -e "${yellow}Mengatur mode WARP...${neutral}"
    warp-cli set-mode warp
    sleep 2
    
    # Enable DNS fallback
    echo -e "${yellow}Mengatur DNS fallback...${neutral}"
    warp-cli set-families-mode off &> /dev/null || true
    sleep 1
    
    # Connect to WARP
    echo -e "${yellow}Menghubungkan ke WARP...${neutral}"
    warp-cli connect
    sleep 5
    
    # Check connection status with retry
    local connected=false
    for i in {1..10}; do
        local status=$(warp-cli status 2>/dev/null)
        if echo "$status" | grep -q "Status update: Connected"; then
            echo -e "${green}✓ WARP berhasil terhubung${neutral}"
            connected=true
            break
        fi
        echo -e "${yellow}Menunggu koneksi... ($i/10)${neutral}"
        sleep 2
    done
    
    if [ "$connected" = false ]; then
        echo -e "${red}⚠ WARP gagal terhubung setelah 10 percobaan${neutral}"
        echo -e "${yellow}Status saat ini:${neutral}"
        warp-cli status
        return 1
    fi
}

# Function to setup routing
setup_routing() {
    echo -e "${blue}Mengkonfigurasi routing untuk mengalihkan semua traffic ke WARP...${neutral}"
    
    # Enable always-on mode
    echo -e "${yellow}Mengaktifkan mode always-on...${neutral}"
    warp-cli enable-always-on
    
    # Set custom DNS (optional, using Cloudflare DNS)
    echo -e "${yellow}Mengatur DNS...${neutral}"
    warp-cli set-custom-endpoint "" &> /dev/null || true
    
    echo -e "${green}✓ Routing berhasil dikonfigurasi${neutral}"
}

# Function to create systemd service for auto-start
create_autostart_service() {
    echo -e "${blue}Membuat service untuk auto-start WARP...${neutral}"
    
    # Ensure warp-svc is enabled
    systemctl enable warp-svc &> /dev/null
    
    cat > /etc/systemd/system/warp-autoconnect.service <<EOF
[Unit]
Description=Cloudflare WARP Auto-Connect
After=network-online.target warp-svc.service
Wants=network-online.target
Requires=warp-svc.service

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 5
ExecStart=/usr/bin/warp-cli connect
ExecStartPost=/bin/sleep 2
RemainAfterExit=yes
Restart=on-failure
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable warp-autoconnect.service &> /dev/null
    
    echo -e "${green}✓ Auto-start service berhasil dibuat${neutral}"
}

# Function to verify installation
verify_installation() {
    echo -e "${blue}Memverifikasi instalasi...${neutral}"
    echo ""
    
    # Check WARP status
    echo -e "${yellow}Status WARP:${neutral}"
    warp-cli status
    echo ""
    
    # Check IP address
    echo -e "${yellow}IP Address sebelum WARP:${neutral}"
    echo -e "$(curl -s https://api.ipify.org)"
    echo ""
    
    echo -e "${yellow}IP Address dengan WARP:${neutral}"
    sleep 2
    local warp_ip=$(curl -s --interface CloudflareWARP https://api.ipify.org 2>/dev/null || curl -s https://api.ipify.org)
    echo -e "$warp_ip"
    echo ""
}

# Function to show WARP management menu
show_management_menu() {
    while true; do
        clear
        echo -e "${orange}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
        echo -e "${orange}║                    ${green}CLOUDFLARE WARP MANAGEMENT${orange}                        ║${neutral}"
        echo -e "${orange}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
        echo -e "${neutral}${green} [1]${neutral} Status WARP"
        echo -e "${neutral}${green} [2]${neutral} Connect WARP"
        echo -e "${neutral}${green} [3]${neutral} Disconnect WARP"
        echo -e "${neutral}${green} [4]${neutral} Restart WARP"
        echo -e "${neutral}${green} [5]${neutral} Enable Always-On"
        echo -e "${neutral}${green} [6]${neutral} Disable Always-On"
        echo -e "${neutral}${green} [7]${neutral} Check IP Address"
        echo -e "${neutral}${green} [8]${neutral} Fix Registration (Reset & Register)"
        echo -e "${neutral}${green} [9]${neutral} Uninstall WARP"
        echo -e "${neutral}${red} [x]${neutral} Kembali ke Menu Utama"
        echo -e "${orange}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
        echo -e ""
        read -p " Pilih menu: " choice
        
        case $choice in
            1)
                echo -e ""
                warp-cli status
                echo -e ""
                read -n 1 -s -r -p "Tekan tombol untuk kembali"
                ;;
            2)
                echo -e "${blue}Menghubungkan ke WARP...${neutral}"
                # Check if registered first
                if warp-cli status 2>&1 | grep -q "Registration Missing"; then
                    echo -e "${yellow}WARP belum terdaftar, melakukan registrasi...${neutral}"
                    warp-cli register
                    sleep 2
                fi
                warp-cli connect
                sleep 2
                echo -e "${green}✓ WARP terhubung${neutral}"
                sleep 2
                ;;
            3)
                echo -e "${blue}Memutuskan koneksi WARP...${neutral}"
                warp-cli disconnect
                echo -e "${yellow}✓ WARP terputus${neutral}"
                sleep 2
                ;;
            4)
                echo -e "${blue}Merestart WARP...${neutral}"
                warp-cli disconnect
                sleep 1
                warp-cli connect
                echo -e "${green}✓ WARP direstart${neutral}"
                sleep 2
                ;;
            5)
                echo -e "${blue}Mengaktifkan Always-On...${neutral}"
                warp-cli enable-always-on
                echo -e "${green}✓ Always-On diaktifkan${neutral}"
                sleep 2
                ;;
            6)
                echo -e "${blue}Menonaktifkan Always-On...${neutral}"
                warp-cli disable-always-on
                echo -e "${yellow}✓ Always-On dinonaktifkan${neutral}"
                sleep 2
                ;;
            7)
                echo -e ""
                echo -e "${yellow}IP Address Asli:${neutral}"
                warp-cli disconnect &> /dev/null
                sleep 1
                curl -s https://api.ipify.org
                echo -e ""
                echo ""
                echo -e "${yellow}IP Address dengan WARP:${neutral}"
                warp-cli connect &> /dev/null
                sleep 2
                curl -s https://api.ipify.org
                echo -e ""
                echo ""
                read -n 1 -s -r -p "Tekan tombol untuk kembali"
                ;;
            8)
                echo -e ""
                echo -e "${blue}Memperbaiki registrasi WARP...${neutral}"
                echo -e "${yellow}Membersihkan registrasi lama...${neutral}"
                warp-cli disconnect &> /dev/null
                warp-cli delete &> /dev/null
                sleep 2
                
                echo -e "${yellow}Memulai ulang WARP service...${neutral}"
                systemctl restart warp-svc
                sleep 3
                
                echo -e "${yellow}Mendaftarkan ulang WARP...${neutral}"
                if warp-cli register; then
                    echo -e "${green}✓ Registrasi berhasil${neutral}"
                    sleep 2
                    
                    echo -e "${yellow}Mengatur mode WARP...${neutral}"
                    warp-cli set-mode warp
                    sleep 1
                    
                    echo -e "${yellow}Menghubungkan ke WARP...${neutral}"
                    warp-cli connect
                    sleep 3
                    
                    echo -e "${green}✓ WARP berhasil diperbaiki dan terhubung${neutral}"
                else
                    echo -e "${red}✗ Gagal mendaftarkan ulang WARP${neutral}"
                    echo -e "${yellow}Coba restart VPS atau hubungi support${neutral}"
                fi
                echo -e ""
                read -n 1 -s -r -p "Tekan tombol untuk kembali"
                ;;
            9)
                echo -e ""
                read -p " Apakah Anda yakin ingin uninstall WARP? (y/n): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    echo -e "${blue}Menguninstall WARP...${neutral}"
                    warp-cli disconnect &> /dev/null
                    systemctl stop warp-svc &> /dev/null
                    systemctl disable warp-svc &> /dev/null
                    systemctl disable warp-autoconnect.service &> /dev/null
                    rm -f /etc/systemd/system/warp-autoconnect.service
                    systemctl daemon-reload
                    apt-get remove --purge -y cloudflare-warp &> /dev/null
                    rm -f /etc/apt/sources.list.d/cloudflare-client.list
                    rm -f /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
                    echo -e "${green}✓ WARP berhasil diuninstall${neutral}"
                    sleep 2
                    return
                else
                    echo -e "${yellow}Uninstall dibatalkan${neutral}"
                    sleep 1
                fi
                ;;
            x|X)
                return
                ;;
            *)
                echo -e "${red}Pilihan tidak valid!${neutral}"
                sleep 1
                ;;
        esac
    done
}

# Main installation function
main_install() {
    clear
    echo -e "${orange}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${orange}║                    ${green}CLOUDFLARE WARP SETUP SCRIPT${orange}                      ║${neutral}"
    echo -e "${orange}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
    echo -e "${neutral} Script ini akan menginstall dan mengkonfigurasi Cloudflare WARP"
    echo -e "${neutral} pada VPS Anda untuk mengalihkan semua traffic melalui WARP."
    echo -e "${orange}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e ""
    
    check_root
    detect_os
    
    echo -e ""
    read -p " Lanjutkan instalasi? (y/n): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${yellow}Instalasi dibatalkan${neutral}"
        exit 0
    fi
    
    echo -e ""
    echo -e "${green}Memulai instalasi...${neutral}"
    echo -e ""
    
    install_dependencies
    add_cloudflare_repo
    install_warp
    configure_warp
    setup_routing
    create_autostart_service
    
    echo -e ""
    echo -e "${orange}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${orange}║                    ${green}INSTALASI SELESAI${orange}                                 ║${neutral}"
    echo -e "${orange}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
    echo -e "${neutral} Cloudflare WARP telah berhasil diinstall dan dikonfigurasi!"
    echo -e "${neutral} Semua traffic dari VPS Anda sekarang dialihkan melalui WARP."
    echo -e "${orange}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e ""
    
    verify_installation
    
    echo -e "${yellow}Catatan:${neutral}"
    echo -e " - Gunakan ${green}'warp-cli status'${neutral} untuk melihat status koneksi"
    echo -e " - Gunakan ${green}'warp-cli connect'${neutral} untuk menghubungkan"
    echo -e " - Gunakan ${green}'warp-cli disconnect'${neutral} untuk memutuskan koneksi"
    echo -e " - WARP akan otomatis start saat VPS reboot"
    echo -e ""
    
    read -p " Buka menu management WARP? (y/n): " open_menu
    if [[ $open_menu =~ ^[Yy]$ ]]; then
        show_management_menu
    fi
}

# Main script execution
main() {
    if check_warp_installed; then
        clear
        echo -e "${orange}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
        echo -e "${orange}║                    ${green}CLOUDFLARE WARP${orange}                                   ║${neutral}"
        echo -e "${orange}╠═══════════════════════════════════════════════════════════════════════╣${neutral}"
        echo -e "${neutral} WARP sudah terinstall di sistem ini."
        echo -e "${orange}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
        echo -e ""
        read -p " Buka menu management? (y/n): " choice
        if [[ $choice =~ ^[Yy]$ ]]; then
            show_management_menu
        fi
    else
        main_install
    fi
}

# Run main function
main
