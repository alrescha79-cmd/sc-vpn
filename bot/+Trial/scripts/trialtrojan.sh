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

# === Validasi config
mkdir -p /etc/xray/trojan
if [ ! -f "/etc/xray/trojan/config.json" ]; then
  echo '{"inbounds":[]}' > /etc/xray/trojan/config.json
fi

# === Inject user ke config
sed -i '/#trojan$/a\### '"$user $exp"'\
},{"password": "'"$uuid"'","email": "'"$user"'"' /etc/xray/trojan/config.json

sed -i '/#trojangrpc$/a\### '"$user $exp"'\
},{"password": "'"$uuid"'","email": "'"$user"'"' /etc/xray/trojan/config.json

# === Auto Remove
tmux new-session -d -s "trial_trojan_$user" "sleep $((duration * 60)); sed -i '/$user/d' /etc/xray/trojan/config.json; systemctl restart trojan@config"

# === Restart service
systemctl restart trojan@config

# === Generate Trojan Links
trojan_tls="trojan://${uuid}@${domain}:443?path=/trojan-ws&security=tls&host=${domain}&type=ws&sni=${domain}#${user}-WS-TLS"
trojan_grpc="trojan://${uuid}@${domain}:443?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=${domain}#${user}-gRPC"

# === Output JSON
jq -n --arg status "success" \
      --arg username "$user" \
      --arg uuid "$uuid" \
      --arg ip "$ip" \
      --arg domain "$domain" \
      --arg ns_domain "$ns_domain" \
      --arg city "$city" \
      --arg public_key "$pubkey" \
      --arg expiration "$exp" \
      --arg protocol "trojan" \
      --arg link_tls "$trojan_tls" \
      --arg link_grpc "$trojan_grpc" \
      --arg port_tls "443" \
      --arg port_http "80, 8080" \
      --arg dns_port "443, 53" \
      --arg grpc_port "443" \
      --arg path "/trojan-ws" \
      --arg service_name "trojan-grpc" \
      '{
        status: $status,
        username: $username,
        uuid: $uuid,
        ip: $ip,
        domain: $domain,
        ns_domain: $ns_domain,
        city: $city,
        public_key: $public_key,
        expiration: $expiration,
        protocol: $protocol,
        link_tls: $link_tls,
        link_grpc: $link_grpc,
        port_tls: $port_tls,
        port_http: $port_http,
        dns_port: $dns_port,
        grpc_port: $grpc_port,
        path: $path,
        service_name: $service_name
      }'