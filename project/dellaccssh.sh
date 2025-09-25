#!/bin/bash

# Valid Script
ipsaya=$(curl -sS ipv4.icanhazip.com)
data_server=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
date_list=$(date +"%Y-%m-%d" -d "$data_server")


    

# colors
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


# variable
domain=$(cat /etc/xray/domain 2>/dev/null || hostname -f)
clear



account_count=$(grep -c -E "^### " "/etc/ssh/.ssh.db")
if [[ ${account_count} == '0' ]]; then
    echo ""
    echo "         No accounts available"
    echo ""
    exit 0
fi

echo -e "${yellow}choose how to delete the account:${reset}"
echo -e "${green}1) select by number${reset}"
echo -e "${green}2) enter username manually${reset}"
# Auto-select option 2: enter username manually
delete_choice="2"
echo "Auto-selected: 2) enter username manually"

case $delete_choice in
    1)
        clear
        echo -e "${green}┌─────────────────────────────────────────┐${reset}"
        echo -e "${green}│        DELETE SSH OVPN ACCOUNT          │${reset}"
        echo -e "${green}└─────────────────────────────────────────┘${reset}"
        echo " ┌────┬────────────────────┬─────────────┐"
        echo " │ No │ Username           │  Days Left  │"
        echo " ├────┼────────────────────┼─────────────┤"
        grep -E "^### " "/etc/ssh/.ssh.db" | awk '{
            cmd = "date -d \"" $3 "\" +%s"
            cmd | getline exp_timestamp
            close(cmd)
            current_timestamp = systime()
            days_left = int((exp_timestamp - current_timestamp) / 86400)
            if (days_left < 0) days_left = 0
            printf " │ %-2d │ %-18s │ %-11s │\n", NR, $2, days_left " days"
        }'
        echo " └────┴────────────────────┴─────────────┘"
        echo ""
        
        until [[ $client_number =~ ^[0-9]+$ && $client_number -ge 1 && $client_number -le $account_count ]]; do
            read -rp "select account number [1-${account_count}]: " client_number
        done
        
        user=$(grep -E "^### " "/etc/ssh/.ssh.db" | cut -d ' ' -f 2 | sed -n "${client_number}"p)
        exp=$(grep -E "^### " "/etc/ssh/.ssh.db" | cut -d ' ' -f 3 | sed -n "${client_number}"p)
        ;;
    2)
        read -rp "Enter username: " user
        if ! grep -qE "^### $user " "/etc/ssh/.ssh.db"; then
            echo "Username not found"
            exit 1
        fi
        exp=$(grep -E "^### $user " "/etc/ssh/.ssh.db" | cut -d ' ' -f 3)
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac



# Deletion process
if userdel -f $user 2>/dev/null; then
    sed -i "/^### $user/d" /etc/ssh/.ssh.db
    rm -f /etc/xray/log-createssh-$user.log
    
    clear
    echo -e "${green}┌─────────────────────────────────────────┐${reset}"
    echo -e "${green}│  SSH/OVPN ACCOUNT DELETED SUCCESSFULLY  │${reset}"
    echo -e "${green}└─────────────────────────────────────────┘${reset}"
    echo -e "  Username : $user"
    echo -e "  Expiration Date : $exp"
else
    echo "Failed to delete account. Please check if the username is correct."
fi


clear
echo ""
echo -e "—————————————————————————————————————"
echo -e "     SSH/OVPN ACCOUNT DELETED SUCCESSFULLY      "
echo -e "───────────────────────────"