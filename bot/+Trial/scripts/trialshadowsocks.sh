#!/bin/bash

# === Konfigurasi Awal ===
user="trial$(openssl rand -hex 2 | head -c 4)"
uuid=$(cat /proc/sys/kernel/random/uuid)
domain=$(cat /etc/xray/domain 2>/dev/null || hostname -f)
ns_domain=$(cat /etc/xray/dns 2>/dev/null || echo "NS domain not set")
city=$(cat /etc/xray/city 2>/dev/null || echo "Unknown")
pubkey=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "Not Available")
ip=$(curl -s ipv4.icanhazip.com)
duration=60
exp=$(date -d "+$duration minutes" +"%Y-%m-%d %H:%M:%S")
method="aes-256-gcm"
password="$uuid"

# === Inject user ke config
sed -i '/#ssws$/a\### '"$user $exp"'\
},{"password": "'"$password"'","method": "'"$method"'","email": "'"$user"'"' /etc/xray/shadowsocks/config.json
sed -i '/#ssgrpc$/a\### '"$user $exp"'\
},{"password": "'"$password"'","method": "'"$method"'","email": "'"$user"'"' /etc/xray/shadowsocks/config.json

# === Encode SS link
ss_base64=$(echo -n "${method}:${password}" | base64 -w 0)
ss_link_ws="ss://${ss_base64}@${domain}:443?plugin=xray-plugin;mux=0;path=/shadowsocks;host=${domain};tls;network=ws#${user}-WS"
ss_link_grpc="ss://${ss_base64}@${domain}:443?plugin=xray-plugin;mux=0;serviceName=ss-grpc;host=${domain};tls#${user}-gRPC"

# === Restart Service dan Auto Remove
tmux new-session -d -s "trial_shadowsocks_$user" "sleep $((duration * 60)); sed -i '/$user/d' /etc/xray/shadowsocks/config.json; systemctl restart shadowsocks@config"
systemctl restart shadowsocks@config

# === Output JSON pakai jq
jq -n --arg user "$user" \
      --arg uuid "$uuid" \
      --arg password "$password" \
      --arg ip "$ip" \
      --arg domain "$domain" \
      --arg ns_domain "$ns_domain" \
      --arg city "$city" \
      --arg pubkey "$pubkey" \
      --arg exp "$exp" \
      --arg method "$method" \
      --arg link_ws "$ss_link_ws" \
      --arg link_grpc "$ss_link_grpc" \
      '{
        status: "success",
        username: $user,
        uuid: $uuid,
        password: $password,
        ip: $ip,
        domain: $domain,
        ns_domain: $ns_domain,
        city: $city,
        public_key: $pubkey,
        expiration: $exp,
        protocol: "shadowsocks",
        method: $method,
        link_ws: $link_ws,
        link_grpc: $link_grpc,
        port_tls: "443",
        path: "/shadowsocks",
        service_name: "ss-grpc"
      }'