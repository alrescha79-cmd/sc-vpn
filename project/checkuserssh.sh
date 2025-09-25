#!/bin/bash

# Valid Script
ipsaya=$(curl -sS ipv4.icanhazip.com)
data_server=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
date_list=$(date +"%Y-%m-%d" -d "$data_server")


        # color configuration
        dark_purple="\e[38;5;54m"
        green="\e[38;5;82m"
        red="\e[38;5;196m"
        neutral="\e[0m"
        blue="\e[38;5;130m"
        orange="\e[38;5;99m"
        yellow="\e[38;5;226m"
        purple="\e[38;5;141m"
        bold_white="\e[1;37m"
        normal="\e[0m"
        pink="\e[38;5;205m"

        # Menentukan file log
        if [ -e "/var/log/auth.log" ]; then
            LOG_FILE="/var/log/auth.log"
        elif [ -e "/var/log/secure" ]; then
            LOG_FILE="/var/log/secure"
        else
            echo "File not exist"
            exit 1
        fi

        # Prompt for username
        read -p "User: " -e user

        # Check if user exists
        if ! grep -q "^### $user " "/etc/ssh/.ssh.db"; then
          echo -e "${red}User '$user' not found!${neutral}"
          exit 1
        fi

        # Membuat file temporary
        touch /tmp/ssh_login_user

        clear

        # Fungsi untuk menampilkan informasi login SSH dan Dropbear untuk user tertentu
        tampilkan_info_ssh_dropbear_user() {

            echo -e "${orange}─────────────────────────────────────────${neutral}"
            echo -e "${green}         SSH USER STATUS ${neutral}"
            echo -e "${orange}─────────────────────────────────────────${neutral}"

            cat $LOG_FILE | grep -i sshd | grep -i "Accepted password for" >/tmp/login-db-ssh.txt
            cat $LOG_FILE | grep -i dropbear | grep -i "Password auth succeeded" >/tmp/login-db-dropbear.txt

            ssh_pids=($(pgrep sshd))
            dropbear_pids=($(pgrep dropbear))

            for ssh_pid in "${ssh_pids[@]}"; do
                if grep -q "sshd\[$ssh_pid\]" /tmp/login-db-ssh.txt; then
                    grep "sshd\[$ssh_pid\]" /tmp/login-db-ssh.txt >/tmp/login-db-pid-ssh.txt
                    ssh_user=$(grep -oP '(?<=for )\w+' /tmp/login-db-pid-ssh.txt)
                    ssh_ip=$(grep -oP '(?<=from )\d+\.\d+\.\d+\.\d+' /tmp/login-db-pid-ssh.txt)
                    # Only add to file if it matches the requested user
                    if [[ "$ssh_user" == "$user" ]]; then
                        echo "$ssh_pid $ssh_user $ssh_ip" >>/tmp/ssh_login_user
                    fi
                fi
            done

            for dropbear_pid in "${dropbear_pids[@]}"; do
                if grep -q "dropbear\[$dropbear_pid\]" /tmp/login-db-dropbear.txt; then
                    grep "dropbear\[$dropbear_pid\]" /tmp/login-db-dropbear.txt >/tmp/login-db-pid-dropbear.txt
                    dropbear_user=$(grep -oP "(?<=for ')\w+(?=' from)" /tmp/login-db-pid-dropbear.txt | sed "s/'//g")
                    dropbear_ip=$(grep -oP '(?<=from )\d+\.\d+\.\d+\.\d+' /tmp/login-db-pid-dropbear.txt | cut -d ':' -f 1)
                    # Only add to file if it matches the requested user
                    if [[ "$dropbear_user" == "$user" ]]; then
                        echo "$dropbear_pid $dropbear_user $dropbear_ip" >>/tmp/ssh_login_user
                    fi
                fi
            done

            tampilkan_info_pengguna_user "/tmp/ssh_login_user"
        }

        tampilkan_info_pengguna_user() {
    local file=$1

    echo -e "${dark_purple}─────────────────────────────────────────${neutral}"
    printf " %-12s | %-7s | %-7s\n" "Username" "LoginIP" "LimitIP"
    echo -e "${dark_purple}─────────────────────────────────────────${neutral}"

    login_ip=$(grep -w "$user" "$file" | awk '{print $3}' | sort -u | wc -l)
    [[ -e /etc/ssh/$user ]] && limit_ip=$(cat /etc/ssh/$user) || limit_ip="0"

    # kalau limit_ip=0 artinya unlimited
    if [[ "$limit_ip" -eq 0 ]]; then
        limit_ip="∞"
    fi

    # tampilkan informasi user
    if [[ $login_ip -gt 0 ]]; then
        printf " %-12s | %-7s | %-7s\n" "$user" "$login_ip" "$limit_ip"
        echo -e "${orange}─────────────────────────────────────────${neutral}"
        echo -e "${green}User is currently online${neutral}"
    else
        echo -e "${orange}─────────────────────────────────────────${neutral}"
        echo -e "${yellow}User is currently offline${neutral}"
    fi
}

        # Menampilkan informasi
        tampilkan_info_ssh_dropbear_user

        # Membersihkan file temporary
        rm -rf /tmp/ssh_login_user /tmp/login-db-ssh.txt /tmp/login-db-dropbear.txt /tmp/login-db-pid-ssh.txt /tmp/login-db-pid-dropbear.txt
clear 
echo -e "——————————————————————————————————————"
echo -e  "    Check SSH Account    "
echo -e "——————————————————————————————————————"
echo -e "User       : ${user}"
echo -e "Status     : OK"
echo -e "IP Connect : ${login_ip}"
echo -e "Usage      : Unlimited"