const { Client } = require('ssh2');
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./sellvpn.db');

async function trialshadowsocks(serverId) {
  console.log(`⚙️ Creating SHADOWSOCKS Trial for server ${serverId}`);

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
if [ ! -f "/etc/xray/shadowsocks/config.json" ]; then
  echo "ERROR: /etc/xray/shadowsocks/config.json not found" >&2
  exit 1
fi

if ! grep -q '#shadowsocks$' /etc/xray/shadowsocks/config.json; then
  echo "ERROR: Marker #shadowsocks not found in config.json" >&2
  exit 1
fi

# Add user to config
sed -i '/#shadowsocks$/a\\### '"$user $exp"'\\
},{"password": "'"$uuid"'","email": "'"$user"'","method": "aes-128-gcm"' /etc/xray/shadowsocks/config.json

sed -i '/#shadowsocksgrpc$/a\\### '"$user $exp"'\\
},{"password": "'"$uuid"'","email": "'"$user"'","method": "aes-128-gcm"' /etc/xray/shadowsocks/config.json

# Schedule auto-delete
(nohup bash -c "sleep 3600; sed -i '/$user/d' /etc/xray/shadowsocks/config.json; systemctl restart shadowsocks@config 2>/dev/null" >/dev/null 2>&1 &)

# Restart service
systemctl restart shadowsocks@config 2>/dev/null || true

systemctl restart shadowsocks@config

ss_base64=\$(echo -n "aes-128-gcm:\${uuid}" | base64 -w0)
ss_tls="ss://\${ss_base64}@\${domain}:443#\${user}"
ss_grpc="ss://\${ss_base64}@\${domain}:443?plugin=grpc#\${user}"

cat <<EOFDATA
{
  "status": "success",
  "username": "\$user",
  "password": "\$uuid",
  "ip": "\$ip",
  "domain": "\$domain",
  "ns_domain": "\$ns_domain",
  "city": "\$city",
  "public_key": "\$pubkey",
  "expiration": "\$exp",
  "method": "aes-128-gcm",
  "link_tls": "\$ss_tls",
  "link_grpc": "\$ss_grpc"
}
EOFDATA
`;
        
        console.log('🔨 Executing trial SHADOWSOCKS command...');
        
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
              return resolve({ status: 'error', message: `Gagal membuat trial SHADOWSOCKS (exit code ${code}).` });
            }

            try {
              const jsonStart = output.indexOf('{');
              const jsonEnd = output.lastIndexOf('}');
              if (jsonStart === -1 || jsonEnd === -1) {
                throw new Error('No JSON found in output');
              }
              const jsonStr = output.substring(jsonStart, jsonEnd + 1);
              const result = JSON.parse(jsonStr);
              
              console.log('✅ SHADOWSOCKS Trial created:', result.username);
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

module.exports = { trialshadowsocks };
