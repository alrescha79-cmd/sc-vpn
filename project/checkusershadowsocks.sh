#!/bin/bash

# Valid Script
ipsaya=$(curl -sS ipv4.icanhazip.com)
data_server=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
date_list=$(date +"%Y-%m-%d" -d "$data_server")

    
# color configuration
green="\e[38;5;87m"
red="\e[38;5;196m"
neutral="\e[0m"
blue="\e[38;5;130m"
orange="\e[38;5;99m"
yellow="\e[38;5;226m"
purple="\e[38;5;141m"
bold_white="\e[1;37m"
normal="\e[0m"
pink="\e[38;5;205m"

# function to convert bytes to a more readable format
convert_size() {
    local -i bytes=$1
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$(((bytes + 1023) / 1024))KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$(((bytes + 1048575) / 1048576))MB"
    else
        echo "$(((bytes + 1073741823) / 1073741824))GB"
    fi
}

# Prompt for username
read -p "User: " -e user

# Check if user exists
if ! grep -q "^### $user " "/etc/xray/shadowsocks/.shadowsocks.db"; then
  echo -e "${red}User '$user' not found!${reset}"
  exit 1
fi

# get data
my_ip=$(curl -s ipv4.icanhazip.com)
server_data=$(curl -s -I https://google.com | grep -i ^date | cut -d' ' -f2-)
current_date=$(date +"%Y-%m-%d" -d "$server_data")
current_time=$(date +%T)

# loading animation
check_shadowsocks_user() {
    echo ""
    echo -ne "\e[33mChecking Shadowsocks Account\e[0m"
    for i in {1..2}; do
        for j in ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏; do
            echo -ne "\r\e[33mChecking Shadowsocks Account $j\e[0m"
            sleep 0.1
        done
    done
    echo -ne "\r\e[33mShadowsocks Account Check Successful!    \e[0m\n"
    sleep 1
    clear

    # display header
    echo -e "${orange}──────────────────────────────────────────${neutral}"
    echo -e "${green}      SHADOWSOCKS USER STATUS      ${neutral}"
    echo -e "${orange}──────────────────────────────────────────${neutral}"
    
    # process log for the specific user
    declare -A user_ips
    declare -A last_access_time
    declare -A log_count

    log_file=$(tail -n 150 /var/log/xray/access.log | grep -w "email: ${user}" | grep -v "127.0.0.1")
    current_time_seconds=$(date +%s.%N)
    log_count[$user]=$(grep -w "email: ${user}" /var/log/xray/access.log | grep -v "127.0.0.1" | wc -l)

    while read -r line; do
        if [[ -n ${line} ]]; then
            ((log_count[$user]++))
            read -r _ access_time ip_address _ <<<"$line"

            if [[ $ip_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(:([0-9]+))?$ ]]; then
                ip_address=${ip_address%%:*}
                access_time_seconds=$(date -d "${access_time}" +%s.%N)
                time_difference=$(echo "$current_time_seconds - $access_time_seconds" | bc)

                if (($(echo "$time_difference < 10" | bc -l))); then
                    if [[ -n "${user_ips[$ip_address]}" && "${user_ips[$ip_address]}" != "$user" ]]; then
                        continue
                    fi
                    user_ips[$ip_address]=$user
                    last_access_time["${user}:${ip_address}"]=$access_time
                fi
            fi
        fi
    done <<<"${log_file}"

    # display results for the specific user
    if [[ -n "${user_ips[*]}" ]]; then
        echo -e "${red} CONNECTION DETAILS:${normal}"
        echo -e "${orange}┌───────────────────────────────────────┐${normal}"
        echo -e "${orange}│${normal} USER: ${user}"
        
        if [[ -e /etc/xray/shadowsocks/${user} ]]; then
            usage=$(</etc/xray/shadowsocks/usage/${user})
            readable_usage=$(convert_size ${usage})
            limit=$(</etc/xray/shadowsocks/${user})
            readable_limit=$(convert_size ${limit})
            connection_count=$(echo "${user_ips[*]}" | grep -cw "${user}")
            echo -e "${orange}│${normal} USAGE: ${readable_usage}"
            echo -e "${orange}│${normal} QUOTA: ${readable_limit}"
            ip_limit=$(cat /etc/xray/shadowsocks/${user}IP 2>/dev/null || echo "0")
            if [[ "$ip_limit" -eq 0 ]]; then
                echo -e "${orange}│${normal} IP LIMIT: Unlimited"
            else
                echo -e "${orange}│${normal} IP LIMIT: $ip_limit"
            fi
            echo -e "${orange}│${normal} LOG COUNT: ${log_count[$user]}"
            echo -e "${orange}├───────────────────────────────────────┤${normal}"
            echo -e "${orange}│ ${bright_green}IP LIST:${normal}"
            
            for ip_address in "${!user_ips[@]}"; do
                if [[ "${user_ips[$ip_address]}" == "$user" ]]; then
                    if [[ "$ip_address" == "127.0.0.1" ]]; then
                        asn="Localhost"
                    else
                        asn=$(whois ${ip_address} | grep -i "descr" | awk -F: '{print $2}' | grep -v '^$' | head -n 1 | xargs || \
                              echo "Unable to retrieve ASN information")

                        if [[ -z $asn ]]; then
                            asn="ISP is not identified"
                        fi
                    fi
                    echo -e "${orange}│   ${normal}${ip_address} » ${asn}"
                fi
            done
        fi
        echo -e "${orange}└───────────────────────────────────────┘${normal}"
        echo ""
        echo -e "${green}User is currently online${normal}"
    else
        echo -e "   ${orange}No active connections for user ${user} at the moment.${normal}"
        echo ""
        echo -e "${yellow}User is currently offline${normal}"
    fi

    echo ""
}
check_shadowsocks_user
# Display account information
clear 
echo -e "——————————————————————————————————————"
echo -e  "    Check Xray/SHADOWSOCKS Account    "
echo -e "——————————————————————————————————————"
echo -e "User       : ${user}"
echo -e "Status     : OK"
echo -e "IP Connect : ${connection_count}"
echo -e "Usage      : ${readable_usage}"