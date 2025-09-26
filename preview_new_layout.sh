#!/bin/bash

# Color definitions
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
purple='\033[0;35m'
cyan='\033[0;36m'
white='\033[0;37m'
magenta='\033[0;35m'
gray='\033[0;90m'
neutral='\033[0m'

# Preview Menu Utama dengan tampilan baru
preview_main_menu() {
    clear
    
    echo -e ""
    echo -e "${cyan}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${cyan}║                        ${yellow}ALRESCHA79 VPN PANEL${cyan}                         ║${neutral}"
    echo -e "${cyan}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e ""
    
    echo -e "${green}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${green}║                            INFORMASI SISTEM                            ║${neutral}"
    echo -e "${green}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e "    ${white}• SISTEM    : Ubuntu 22.04.3 LTS${neutral}"
    echo -e "    ${white}• RAM       : 2048 / 4096 MB${neutral}"
    echo -e "    ${white}• UPTIME    : up 5 days, 12 hours${neutral}"
    echo -e "    ${white}• CPU CORE  : 4 Core${neutral}"
    echo -e "    ${white}• ISP       : Digital Ocean${neutral}"
    echo -e "    ${white}• IP PUBLIK : 192.168.1.100${neutral}"
    echo -e "    ${white}• DOMAIN    : vpn.alrescha79.com${neutral}"
    echo -e ""
    
    echo -e "${blue}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${blue}║                            STATUS LAYANAN                              ║${neutral}"
    echo -e "${blue}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e "    ${white}XRAY: ${green}ACTIVE${white}  │  HAPROXY: ${green}ACTIVE${white}  │  SSH/OVPN: ${green}ACTIVE${neutral}"
    echo -e ""
    
    echo -e "${blue}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${blue}║                             JUMLAH AKUN                                ║${neutral}"
    echo -e "${blue}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e "    SSH/OPENVPN : ${yellow}12${neutral} Account    │    SHADOWSOCKS : ${yellow} 7${neutral} Account"
    echo -e "    VMESS XRAY  : ${yellow} 8${neutral} Account    │    TROJAN XRAY : ${yellow} 3${neutral} Account"
    echo -e "    VLESS XRAY  : ${yellow} 5${neutral} Account"
    echo -e ""
    
    echo -e "${purple}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${purple}║                            INFORMASI AKSES                             ║${neutral}"
    echo -e "${purple}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e "    ${white}• USER ID   : PREVIEW_USER ${green}[ACTIVE]${neutral}"
    echo -e "    ${white}• MASA AKTIF : 96 hari | 31-12-2025${neutral}"
    echo -e ""
    
    echo -e "${magenta}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${magenta}║                              MENU UTAMA                                ║${neutral}"
    echo -e "${magenta}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e "    ${green}[1]${neutral} Kelola SSH/OpenVPN       │  ${green}[5]${neutral} Kelola Shadowsocks"
    echo -e "    ${green}[2]${neutral} Kelola VMess             │  ${green}[6]${neutral} Setup Bot Notifikasi"
    echo -e "    ${green}[3]${neutral} Kelola VLess             │  ${green}[7]${neutral} Menu Bot Telegram"
    echo -e "    ${green}[4]${neutral} Kelola Trojan            │  ${green}[8]${neutral} Menu Features"
    echo -e ""
    echo -e "    ${red}[x]${neutral} Keluar dari Panel"
    echo -e ""
    
    echo -e "${gray}╔═══════════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${gray}║                            INFORMASI SCRIPT                            ║${neutral}"
    echo -e "${gray}╚═══════════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e "    ${green}SCRIPT VERSION:${neutral} 4.0.1    │    ${green}AUTHOR:${neutral} Alrescha79"
    echo -e ""
    
    echo -e "${yellow}Pilih menu [1-8 atau x]: ${neutral}[PREVIEW ONLY]"
    echo -e ""
}

# Main navigation
while true; do
    clear
    echo -e "${cyan}╔══════════════════════════════════════════════════════════════════════╗${neutral}"
    echo -e "${cyan}║                          PREVIEW MODE                               ║${neutral}"
    echo -e "${cyan}║                   ALRESCHA79 VPN PANEL                              ║${neutral}"
    echo -e "${cyan}║                    (TAMPILAN BARU)                                  ║${neutral}"
    echo -e "${cyan}╚══════════════════════════════════════════════════════════════════════╝${neutral}"
    echo -e ""
    echo -e "${green}Tampilan Baru:${neutral}"
    echo -e "  ✅ Hanya title yang memiliki pinggiran (║)"
    echo -e "  ✅ Isi konten tanpa pinggiran, lebih clean"
    echo -e "  ✅ Layout lebih sederhana dan mudah dibaca"
    echo -e ""
    echo -e "${yellow}[1]${neutral} Preview Menu Utama (Tampilan Baru)"
    echo -e "${red}[x]${neutral} Keluar Preview"
    echo -e ""
    echo -ne "${yellow}Pilih opsi [1 atau x]: ${neutral}"
    read choice
    
    case $choice in
        1) preview_main_menu; read -p "Tekan Enter untuk kembali..." ;;
        x|X) echo -e "${green}Keluar dari preview mode...${neutral}"; break ;;
        *) echo -e "${red}Pilihan tidak valid!${neutral}"; sleep 2 ;;
    esac
done