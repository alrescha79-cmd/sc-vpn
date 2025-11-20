const { Client } = require('ssh2');
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./sellvpn.db');

async function trialvless(serverId) {
  console.log(`⚙️ Creating VLESS Trial for server ${serverId}`);

  return new Promise((resolve) => {
    db.get('SELECT * FROM Server WHERE id = ?', [serverId], async (err, server) => {
      if (err || !server) {
        console.error('❌ DB Error:', err?.message || 'Server not found');
        return resolve({ status: 'error', message: 'Server tidak ditemukan.' });
      }

      console.log(`📡 Connecting to ${server.domain} with user root...`);

      const conn = new Client();
      let resolved = false;
      
      const globalTimeout = setTimeout(() => {
        if (!resolved) {
          resolved = true;
          console.error('❌ Global timeout after 45 seconds');
          conn.end();
          resolve({ status: 'error', message: 'Timeout - Server terlalu lama merespon.' });
        }
      }, 45000);

      conn.on('ready', () => {
        console.log('✅ SSH Connection established');
        
        const cmd = `
set -e
user="trial$(date +%s | tail -c 5)"
uuid=$(cat /proc/sys/kernel/random/uuid)
domain=$(cat /etc/xray/domain 2>/dev/null || echo "unknown")
ns_domain=$(cat /etc/xray/dns 2>/dev/null || echo "")
city=$(cat /etc/xray/city 2>/dev/null || echo "Unknown")
pubkey=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "")
ip=$(hostname -I | awk '{print $1}')
duration=60
exp=$(date -d "+$duration minutes" +"%Y-%m-%d %H:%M:%S")

# Check if config file exists and has markers
if [ ! -f "/etc/xray/vless/config.json" ]; then
  echo "ERROR: /etc/xray/vless/config.json not found" >&2
  exit 1
fi

if ! grep -q '#vless$' /etc/xray/vless/config.json; then
  echo "ERROR: Marker #vless not found in config.json" >&2
  exit 1
fi

# Add user to config
sed -i '/#vless$/a\\### '"$user $exp"'\\
},{"id": "'"$uuid"'","email": "'"$user"'"' /etc/xray/vless/config.json

sed -i '/#vlessgrpc$/a\\### '"$user $exp"'\\
},{"id": "'"$uuid"'","email": "'"$user"'"' /etc/xray/vless/config.json

# Schedule auto-delete
(nohup bash -c "sleep 3600; sed -i '/$user/d' /etc/xray/vless/config.json; systemctl restart vless@config 2>/dev/null" >/dev/null 2>&1 &)

# Restart service
systemctl restart vless@config 2>/dev/null || true

systemctl restart vless@config 2>/dev/null || true

vless_tls="vless://\${uuid}@\${domain}:443?encryption=none&security=tls&sni=\${domain}&type=ws&host=\${domain}&path=%2Fwhatever%2Fvless#\${user}"
vless_ntls="vless://\${uuid}@\${domain}:80?encryption=none&security=none&type=ws&host=\${domain}&path=%2Fwhatever%2Fvless#\${user}"
vless_grpc="vless://\${uuid}@\${domain}:443?encryption=none&security=tls&type=grpc&serviceName=vless-grpc&sni=\${domain}#\${user}"

cat <<EOFDATA
{
  "status": "success",
  "username": "\$user",
  "uuid": "\$uuid",
  "ip": "\$ip",
  "domain": "\$domain",
  "ns_domain": "\$ns_domain",
  "city": "\$city",
  "public_key": "\$pubkey",
  "expiration": "\$exp",
  "link_tls": "\$vless_tls",
  "link_ntls": "\$vless_ntls",
  "link_grpc": "\$vless_grpc"
}
EOFDATA
`;
        
        console.log('🔨 Executing trial VLESS command...');
        
        let output = '';
        
        conn.exec(cmd, (err, stream) => {
          if (err) {
            clearTimeout(globalTimeout);
            if (!resolved) {
              resolved = true;
              console.error('❌ Exec error:', err.message);
              conn.end();
              return resolve({ status: 'error', message: 'Gagal eksekusi command SSH.' });
            }
            return;
          }

          stream.on('close', (code, signal) => {
            clearTimeout(globalTimeout);
            conn.end();
            
            if (resolved) return;
            resolved = true;
            
            console.log(`📝 Command finished with code: ${code}`);
            
            if (code !== 0) {
              console.error('❌ Command failed with exit code:', code);
              return resolve({ status: 'error', message: `Gagal membuat trial VLESS (exit code ${code}).` });
            }

            try {
              const jsonStart = output.indexOf('{');
              const jsonEnd = output.lastIndexOf('}');
              if (jsonStart === -1 || jsonEnd === -1) {
                throw new Error('No JSON found in output');
              }
              const jsonStr = output.substring(jsonStart, jsonEnd + 1);
              const result = JSON.parse(jsonStr);
              
              console.log('✅ VLESS Trial created:', result.username);
              resolve(result);
            } catch (e) {
              console.error('❌ Failed to parse JSON:', e.message);
              resolve({ status: 'error', message: 'Gagal parsing output dari server.' });
            }
          })
          .on('data', (data) => {
            output += data.toString();
          })
          .stderr.on('data', (data) => {
            console.warn('⚠️ STDERR:', data.toString());
          });
        });
      })
      .on('error', (err) => {
        clearTimeout(globalTimeout);
        if (!resolved) {
          resolved = true;
          console.error('❌ SSH Connection Error:', err.message);
          
          if (err.code === 'ENOTFOUND') {
            resolve({ status: 'error', message: 'Server tidak ditemukan. Cek domain/IP server.' });
          } else if (err.level === 'client-authentication') {
            resolve({ status: 'error', message: 'Password root VPS salah. Update di database.' });
          } else if (err.code === 'ETIMEDOUT' || err.code === 'ECONNREFUSED') {
            resolve({ status: 'error', message: 'Tidak bisa koneksi ke server. Cek apakah server online.' });
          } else {
            resolve({ status: 'error', message: `Gagal koneksi SSH: ${err.message}` });
          }
        }
      })
      .connect({
        host: server.domain,
        port: 22,
        username: 'root',
        password: server.auth,
        readyTimeout: 30000,
        keepaliveInterval: 10000
      });
    });
  });
}

module.exports = { trialvless };
