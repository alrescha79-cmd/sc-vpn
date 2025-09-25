#!/bin/bash

# === Konfigurasi Awal ===
user="trial$(openssl rand -hex 2 | head -c 4)"
uuid=$(cat /proc/sys/kernel/random/uuid)
domain=$(cat /etc/xray/domain 2>/dev/null || hostname -f)
ns_domain=$(cat /etc/xray/dns 2>/dev/null || echo "NS domain not set")
city=$(cat /etc/xray/city 2>/dev/null || echo "Unknown")
pubkey=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "Not Available")
ip=$(curl -s ipv4.icanhazip.com)
duration=60 # in minutes
exp=$(date -d "+$duration minutes" +"%Y-%m-%d %H:%M:%S")

# === Inject user ke config
mkdir -p /etc/xray/vless
if [ ! -f "/etc/xray/vless/config.json" ]; then
  echo '{"clients":[]}' > /etc/xray/vless/config.json
fi

tmpfile=$(mktemp)
jq --arg uuid "$uuid" --arg email "$user" '.clients += [{"id": $uuid, "flow": "", "email": $email}]' /etc/xray/vless/config.json > "$tmpfile" && mv "$tmpfile" /etc/xray/vless/config.json

# Auto remove after expiry
tmux new-session -d -s "trial_vless_$user" "sleep $((duration * 60)); sed -i '/$user/d' /etc/xray/vless/config.json; systemctl restart vless@config"

# Restart xray vless service
systemctl restart vless@config

# === Generate VLESS links
vless_tls="vless://${uuid}@${domain}:443?path=/whatever/vless&security=tls&encryption=none&host=${domain}&type=ws#${user}-WS-TLS"
vless_non="vless://${uuid}@${domain}:80?path=/whatever/vless&encryption=none&host=${domain}&type=ws#${user}-WS-NTLS"
vless_grpc="vless://${uuid}@${domain}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=${domain}#${user}-gRPC"

# === Output JSON Satu Baris Aman ke Bot
jq -n \
  --arg status "success" \
  --arg username "$user" \
  --arg uuid "$uuid" \
  --arg ip "$ip" \
  --arg domain "$domain" \
  --arg ns_domain "$ns_domain" \
  --arg city "$city" \
  --arg public_key "$pubkey" \
  --arg expiration "$exp" \
  --arg protocol "vless" \
  --arg link_tls "$vless_tls" \
  --arg link_ntls "$vless_non" \
  --arg link_grpc "$vless_grpc" \
  --arg port_tls "443" \
  --arg port_http "80, 8080" \
  --arg dns_port "443, 53" \
  --arg grpc_port "443" \
  --arg path "/whatever/vless" \
  --arg service_name "vless-grpc" \
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
    link_ntls: $link_ntls,
    link_grpc: $link_grpc,
    port_tls: $port_tls,
    port_http: $port_http,
    dns_port: $dns_port,
    grpc_port: $grpc_port,
    path: $path,
    service_name: $service_name
  }'