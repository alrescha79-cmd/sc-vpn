#!/bin/bash

# Valid Script
ipsaya=$(curl -sS ipv4.icanhazip.com)
data_server=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
date_list=$(date +"%Y-%m-%d" -d "$data_server")


    
# colors
red="\e[91m"
green="\e[92m"
yellow="\e[93m"
blue="\e[94m"
purple="\e[95m"
cyan="\e[96m"
white="\e[97m"
reset="\e[0m"

# variables
domain=$(cat /etc/xray/domain 2>/dev/null || hostname -f)
clear
echo -e "${green}┌─────────────────────────────────────────┐${reset}"
echo -e "${green}│         UPDATE VMESS ACCOUNT            │${reset}"
echo -e "${green}└─────────────────────────────────────────┘${reset}"

account_count=$(grep -c -E "^### " "/etc/xray/vmess/.vmess.db")
if [[ ${account_count} == '0' ]]; then
    echo ""
    echo "  No customer names available"
    echo ""
    exit 0
fi

# Prompt for username and password directly
read -rp "Enter username: " user
# read -rp "Enter password: " uuid

# Check if user exists
if ! grep -qE "^### $user " "/etc/xray/vmess/.vmess.db"; then
    echo ""
    echo "Username not found"
    echo ""
    exit 1
fi
uuid=$(grep -E "^### $user " "/etc/xray/vmess/.vmess.db" | cut -d ' ' -f 4)
# Verify the UUID matches the stored one
stored_uuid=$(grep -E "^### $user " "/etc/xray/vmess/.vmess.db" | cut -d ' ' -f 4)
if [[ "$uuid" != "$stored_uuid" ]]; then
    echo ""
    echo "Password (UUID) does not match"
    echo ""
    exit 1
fi

# Get current expiration date
exp=$(grep -E "^### $user " "/etc/xray/vmess/.vmess.db" | cut -d ' ' -f 3)

clear
echo -e "${yellow}Updating premium account $user${reset}"
echo ""

# Read expiration date from database
old_exp=$(grep -E "^### $user " "/etc/xray/vmess/.vmess.db" | cut -d ' ' -f 3)

# Calculate remaining active days
days_left=$((($(date -d "$old_exp" +%s) - $(date +%s)) / 86400))

echo "Remaining active days: $days_left days"

while true; do
    read -p "Add active days: " active_days
    if [[ "$active_days" =~ ^[0-9]+$ ]]; then
        break
    else
        echo "Input must be a positive number."
    fi
done

while true; do
    read -p "Usage limit (GB, 0 for unlimited): " quota
    if [[ "$quota" =~ ^[0-9]+$ ]]; then
        break
    else
        echo "Input must be a positive number or 0."
    fi
done

while true; do
    read -p "Device limit (IP, 0 for unlimited): " ip_limit
    if [[ "$ip_limit" =~ ^[0-9]+$ ]]; then
        break
    else
        echo "Input must be a positive number or 0."
    fi
done

if [ ! -d /etc/xray/vmess ]; then
    mkdir -p /etc/xray/vmess
fi

if [[ $quota != "0" ]]; then
    quota_bytes=$((quota * 1024 * 1024 * 1024))
    echo "${quota_bytes}" >/etc/xray/vmess/${user}
    echo "${ip_limit}" >/etc/xray/vmess/${user}IP
else
    rm -f /etc/xray/vmess/${user} /etc/xray/vmess/${user}IP
fi

# Calculate new expiration date
new_exp=$(date -d "$old_exp +${active_days} days" +"%Y-%m-%d")

# Check if config file exists before making changes
if [ ! -f "/etc/xray/vmess/config.json" ]; then
    echo "Config file not found. Creating a new file..."
    echo '{"inbounds": []}' >/etc/xray/vmess/config.json
fi

# Remove old entries before updating to prevent duplicates
# Remove from database
sed -i "/^### $user /d" /etc/xray/vmess/.vmess.db

# Remove from config file (both WS and gRPC sections)
sed -i "/^### $user /d" /etc/xray/vmess/config.json
sed -i "/{\"id\": \"$stored_uuid\"/d" /etc/xray/vmess/config.json

# Add updated entries with the same UUID
sed -i '/#vmess$/a\### '"$user $new_exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/vmess/config.json

sed -i '/#vmessgrpc$/a\### '"$user $new_exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/vmess/config.json

echo "### ${user} ${new_exp} ${uuid}" >>/etc/xray/vmess/.vmess.db

# Restart service with error handling
if ! systemctl restart vmess@config >/dev/null 2>&1; then
    echo "Warning: Failed to restart vmess service. Please check system logs for more information."
    echo "However, the account has been successfully updated in the database."
fi

clear
echo -e "${green}┌─────────────────────────────────────────┐${reset}"
echo -e "${green}│    VMESS ACCOUNT UPDATED SUCCESSFULLY   │${reset}"
echo -e "${green}└─────────────────────────────────────────┘${reset}"
echo -e "Username     : ${green}$user${reset}"
echo -e "Quota limit  : ${yellow}$quota GB${reset}"
echo -e "IP limit     : ${yellow}$ip_limit devices${reset}"
echo -e "Expiration   : ${yellow}$new_exp${reset}"
echo ""