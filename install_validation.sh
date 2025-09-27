#!/bin/bash

# ===============================
# INSTALLER VALIDASI AKSES VPS
# ===============================
# Script installer untuk setup validasi akses di VPS
# Author: Alrescha79
# Usage: bash install_validation.sh

# Colors
green="\e[38;5;87m"
red="\e[38;5;196m"
yellow="\e[38;5;226m"
neutral="\e[0m"
blue="\e[38;5;130m"
orange="\e[38;5;99m"

echo -e "${blue}════════════════════════════════════════════════════════════════${neutral}"
echo -e "${blue}║                    INSTALLER VALIDASI VPS                      ║${neutral}"
echo -e "${blue}║                      Author: Alrescha79                        ║${neutral}"
echo -e "${blue}════════════════════════════════════════════════════════════════${neutral}"
echo ""

# ===============================
# CEK REQUIREMENTS
# ===============================
check_requirements() {
    echo -e "${yellow}🔍 Memeriksa requirements...${neutral}"
    
    # Cek koneksi internet
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        echo -e "${red}✗ Tidak ada koneksi internet!${neutral}"
        exit 1
    fi
    echo -e "${green}✓ Koneksi internet: OK${neutral}"
    
    # Cek curl
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${yellow}⚠ curl tidak ditemukan, menginstall...${neutral}"
        apt update && apt install -y curl
    fi
    echo -e "${green}✓ curl: OK${neutral}"
    
    # Cek wget (fallback)
    if ! command -v wget >/dev/null 2>&1; then
        echo -e "${yellow}⚠ wget tidak ditemukan, menginstall...${neutral}"
        apt update && apt install -y wget
    fi
    echo -e "${green}✓ wget: OK${neutral}"
    
    echo ""
}

# ===============================
# INSTALL VALIDASI SCRIPT
# ===============================
install_validation() {
    echo -e "${yellow}📥 Menginstall script validasi...${neutral}"
    
    # URL script validasi dari GitHub
    VALIDATE_URL="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/validate_access.sh"
    
    # Download dan install ke /usr/bin/
    if curl -sS "$VALIDATE_URL" -o /usr/bin/validate_access.sh; then
        chmod +x /usr/bin/validate_access.sh
        echo -e "${green}✓ Script validasi berhasil diinstall di /usr/bin/validate_access.sh${neutral}"
    else
        echo -e "${red}✗ Gagal mendownload script validasi!${neutral}"
        exit 1
    fi
    
    echo ""
}

# ===============================
# TEST VALIDASI
# ===============================
test_validation() {
    echo -e "${yellow}🧪 Testing script validasi...${neutral}"
    
    # Test apakah script bisa dijalankan
    if source /usr/bin/validate_access.sh && type validate_user_access >/dev/null 2>&1; then
        echo -e "${green}✓ Script validasi dapat dimuat dengan baik${neutral}"
        
        # Dapatkan IP untuk testing
        source /usr/bin/validate_access.sh
        get_server_info
        
        if [ -n "$MYIP" ]; then
            echo -e "${green}✓ IP detection berhasil: ${MYIP}${neutral}"
        else
            echo -e "${yellow}⚠ IP detection gagal, tapi script tetap berfungsi${neutral}"
        fi
    else
        echo -e "${red}✗ Script validasi bermasalah!${neutral}"
        exit 1
    fi
    
    echo ""
}

# ===============================
# SETUP MENU SCRIPTS
# ===============================
setup_menu_scripts() {
    echo -e "${yellow}📋 Setup menu scripts...${neutral}"
    
    # Array script menu yang perlu diupdate
    MENU_SCRIPTS=(
        "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/menu"
        "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/menussh"
        "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/menuvmess"
        "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/menuvless"
        "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/menutrojan"
        "https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/project/menushadowsocks"
    )
    
    for script_url in "${MENU_SCRIPTS[@]}"; do
        script_name=$(basename "$script_url")
        
        if curl -sS "$script_url" -o "/usr/bin/$script_name"; then
            chmod +x "/usr/bin/$script_name"
            echo -e "${green}✓ $script_name berhasil diinstall${neutral}"
        else
            echo -e "${red}✗ Gagal mendownload $script_name${neutral}"
        fi
    done
    
    echo ""
}

# ===============================
# BUAT SYMLINK
# ===============================
create_symlinks() {
    echo -e "${yellow}🔗 Membuat symlink untuk kemudahan akses...${neutral}"
    
    # Symlink untuk menu utama
    ln -sf /usr/bin/menu /usr/local/bin/menu 2>/dev/null
    ln -sf /usr/bin/menu /root/menu 2>/dev/null
    
    echo -e "${green}✓ Symlink dibuat${neutral}"
    echo ""
}

# ===============================
# SHOW COMPLETION INFO
# ===============================
show_completion() {
    echo -e "${green}════════════════════════════════════════════════════════════════${neutral}"
    echo -e "${green}║                     INSTALASI SELESAI                         ║${neutral}"
    echo -e "${green}════════════════════════════════════════════════════════════════${neutral}"
    echo ""
    echo -e "${green}🎉 Script validasi akses VPS berhasil diinstall!${neutral}"
    echo ""
    echo -e "${blue}📁 File yang diinstall:${neutral}"
    echo -e "   • /usr/bin/validate_access.sh (script validasi utama)"
    echo -e "   • /usr/bin/menu* (menu-menu interface)"
    echo ""
    echo -e "${blue}🚀 Cara menggunakan:${neutral}"
    echo -e "   • Ketik: ${yellow}menu${neutral} untuk membuka menu utama"
    echo -e "   • Atau langsung: ${yellow}/usr/bin/menu${neutral}"
    echo ""
    echo -e "${yellow}⚠️  PENTING:${neutral}"
    echo -e "   • Pastikan IP VPS ini sudah terdaftar di sistem"
    echo -e "   • Hubungi admin jika ada masalah akses"
    echo -e "   • Telegram: https://t.me/Alrescha79"
    echo ""
    echo -e "${blue}════════════════════════════════════════════════════════════════${neutral}"
}

# ===============================
# MAIN EXECUTION
# ===============================
main() {
    # Cek apakah dijalankan sebagai root
    if [ "$EUID" -ne 0 ]; then
        echo -e "${red}❌ Script ini harus dijalankan sebagai root!${neutral}"
        echo -e "${yellow}Gunakan: sudo bash $0${neutral}"
        exit 1
    fi
    
    check_requirements
    install_validation
    test_validation
    setup_menu_scripts
    create_symlinks
    show_completion
}

# Jalankan main function
main "$@"