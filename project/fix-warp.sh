#!/bin/bash

# Cloudflare WARP Fix Registration Script
# Script untuk memperbaiki masalah registrasi WARP

# Color definitions
green="\e[38;5;87m"
red="\e[38;5;196m"
neutral="\e[0m"
blue="\e[38;5;130m"
yellow="\e[38;5;226m"

echo -e "${blue}════════════════════════════════════════════════════${neutral}"
echo -e "${blue}    Cloudflare WARP - Fix Registration Script${neutral}"
echo -e "${blue}════════════════════════════════════════════════════${neutral}"
echo -e ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${red}Error: Script ini harus dijalankan sebagai root!${neutral}"
   echo -e "Gunakan: sudo $0"
   exit 1
fi

# Check if WARP is installed
if ! command -v warp-cli &> /dev/null; then
    echo -e "${red}Error: WARP tidak terinstall!${neutral}"
    echo -e "${yellow}Silakan install WARP terlebih dahulu.${neutral}"
    exit 1
fi

echo -e "${yellow}[1/7]${neutral} Checking current status..."
warp-cli status
echo -e ""

echo -e "${yellow}[2/7]${neutral} Disconnecting WARP..."
warp-cli disconnect &> /dev/null
sleep 2

echo -e "${yellow}[3/7]${neutral} Deleting existing registration..."
warp-cli delete &> /dev/null
sleep 2

echo -e "${yellow}[4/7]${neutral} Restarting WARP service..."
systemctl restart warp-svc
sleep 3

echo -e "${yellow}[5/7]${neutral} Checking service status..."
if systemctl is-active --quiet warp-svc; then
    echo -e "${green}✓ WARP service is running${neutral}"
else
    echo -e "${red}✗ WARP service is not running${neutral}"
    echo -e "${yellow}Trying to start service...${neutral}"
    systemctl start warp-svc
    sleep 2
fi

echo -e "${yellow}[6/7]${neutral} Registering WARP (this may take a moment)..."
max_attempts=3
attempt=1
success=false

while [ $attempt -le $max_attempts ]; do
    echo -e "${blue}Attempt $attempt of $max_attempts...${neutral}"
    
    if warp-cli register 2>&1 | tee /tmp/warp-register-fix.log; then
        # Check if registration was successful
        sleep 2
        if ! warp-cli status 2>&1 | grep -q "Registration Missing"; then
            echo -e "${green}✓ Registration successful!${neutral}"
            success=true
            break
        fi
    fi
    
    if [ $attempt -lt $max_attempts ]; then
        echo -e "${yellow}Registration failed, waiting 5 seconds before retry...${neutral}"
        sleep 5
    fi
    
    attempt=$((attempt + 1))
done

if [ "$success" = false ]; then
    echo -e "${red}✗ Registration failed after $max_attempts attempts${neutral}"
    echo -e ""
    echo -e "${yellow}Error log:${neutral}"
    cat /tmp/warp-register-fix.log 2>/dev/null || echo "No log available"
    echo -e ""
    echo -e "${yellow}Troubleshooting steps:${neutral}"
    echo -e "1. Check internet connectivity: ping -c 3 1.1.1.1"
    echo -e "2. Check DNS resolution: nslookup cloudflareclient.com"
    echo -e "3. Restart VPS and try again"
    echo -e "4. Check firewall rules: iptables -L"
    echo -e "5. Reinstall WARP completely"
    exit 1
fi

echo -e "${yellow}[7/7]${neutral} Configuring and connecting WARP..."
warp-cli set-mode warp
sleep 2

warp-cli connect
sleep 5

# Verify connection
echo -e ""
echo -e "${blue}════════════════════════════════════════════════════${neutral}"
echo -e "${blue}             Final Status Check${neutral}"
echo -e "${blue}════════════════════════════════════════════════════${neutral}"
warp-cli status

if warp-cli status | grep -q "Status update: Connected"; then
    echo -e ""
    echo -e "${green}✓✓✓ WARP berhasil diperbaiki dan terhubung! ✓✓✓${neutral}"
    echo -e ""
    echo -e "${yellow}Testing connection...${neutral}"
    echo -e "Your IP: $(curl -s https://api.ipify.org)"
    echo -e ""
    echo -e "${green}WARP is now routing all your traffic through Cloudflare network.${neutral}"
else
    echo -e ""
    echo -e "${yellow}⚠ WARP terdaftar tapi belum connected${neutral}"
    echo -e "${yellow}Coba jalankan: warp-cli connect${neutral}"
fi

echo -e ""
echo -e "${blue}════════════════════════════════════════════════════${neutral}"
echo -e ""

# Clean up
rm -f /tmp/warp-register-fix.log
