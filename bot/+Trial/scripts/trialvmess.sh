#!/bin/bash

# === Konfigurasi Awal ===
user="trial$(openssl rand -hex 2 | head -c 4)"
uuid=$(cat /proc/sys/kernel/random/uuid)
domain=$(cat /etc/xray/domain 2>/dev/null || hostname -f)
ns_domain=$(cat /etc/xray/dns 2>/dev/null || echo "NS domain not set")
city=$(cat /etc/xray/city 2>/dev/null || echo "Unknown")
pubkey=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "Not Available")
ip=$(curl -s ipv4.icanhazip.com)
duration=60 # minutes
exp=$(date -d "+$duration minutes" +"%Y-%m-%d %H:%M:%S")

# === Inject ke config JSON (pastikan ada #vmess dan #vmessgrpc)
if [ ! -f "/etc/xray/vmess/config.json" ]; then
  echo '{"clients":[]}' > /etc/xray/vmess/config.json
fi

sed -i '/#vmess$/a\### '"$user $exp"'\
},{"id": "'"$uuid"'","alterId": 0,"email": "'"$user"'"' /etc/xray/vmess/config.json
sed -i '/#vmessgrpc$/a\### '"$user $exp"'\
},{"id": "'"$uuid"'","alterId": 0,"email": "'"$user"'"' /etc/xray/vmess/config.json

# === Buat file config sementara untuk encoded link
mkdir -p /etc/xray
cat >/etc/xray/$user-tls.json <<EOF
{
  "v": "2",
  "ps": "$user WS (CDN) TLS",
  "add": "${domain}",
  "port": "443",
  "id": "${uuid}",
  "aid": "0",
  "net": "ws",
  "path": "/whatever/vmess",
  "type": "none",
  "host": "${domain}",
  "tls": "tls"
}
EOF

cat >/etc/xray/$user-non.json <<EOF
{
  "v": "2",
  "ps": "$user WS (CDN) NTLS",
  "add": "${domain}",
  "port": "80",
  "id": "${uuid}",
  "aid": "0",
  "net": "ws",
  "path": "/whatever/vmess",
  "type": "none",
  "host": "${domain}",
  "tls": "none"
}
EOF

cat >/etc/xray/$user-grpc.json <<EOF
{
  "v": "2",
  "ps": "$user (SNI) GRPC",
  "add": "${domain}",
  "port": "443",
  "id": "${uuid}",
  "aid": "0",
  "net": "grpc",
  "path": "vmess-grpc",
  "type": "none",
  "host": "${domain}",
  "tls": "tls"
}
EOF

# === Encode ke base64 VMESS
vmess_tls="vmess://$(base64 -w 0 /etc/xray/$user-tls.json)"
vmess_non="vmess://$(base64 -w 0 /etc/xray/$user-non.json)"
vmess_grpc="vmess://$(base64 -w 0 /etc/xray/$user-grpc.json)"

# === Auto remove akun
tmux new-session -d -s "trial_vmess_$user" "sleep $((duration * 60)); sed -i '/$user/d' /etc/xray/vmess/config.json; systemctl restart vmess@config"

# === Restart service
systemctl restart vmess@config

# === Output JSON ke bot
jq -n \
  --arg user "$user" \
  --arg uuid "$uuid" \
  --arg ip "$ip" \
  --arg domain "$domain" \
  --arg city "$city" \
  --arg ns "$ns_domain" \
  --arg pub "$pubkey" \
  --arg exp "$exp" \
  --arg link_tls "$vmess_tls" \
  --arg link_ntls "$vmess_non" \
  --arg link_grpc "$vmess_grpc" \
  '{
    status: "success",
    username: $user,
    uuid: $uuid,
    ip: $ip,
    domain: $domain,
    city: $city,
    ns_domain: $ns,
    public_key: $pub,
    expiration: $exp,
    protocol: "vmess",
    link_tls: $link_tls,
    link_ntls: $link_ntls,
    link_grpc: $link_grpc,
    port_tls: "443",
    port_http: "80, 8080",
    dns_port: "443, 53",
    grpc_port: "443",
    alter_id: "0",
    path: "/whatever/vmess",
    service_name: "vmess-grpc"
  }'
