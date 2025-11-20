const { Client } = require('ssh2');
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./sellvpn.db');

async function trialtrojan(serverId) {
  console.log(`⚙️ Creating Trojan Trial for server ${serverId}`);

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
          console.error('❌ Global timeout after 35 seconds');
          conn.end();
          resolve({ status: 'error', message: 'Timeout koneksi ke server.' });
        }
      }, 35000);

      conn.on('ready', () => {
        console.log('✅ SSH Connection established');
        
        // Command untuk create trial Trojan
        const cmd = `
user="trial$(openssl rand -hex 2 | head -c 4)"
uuid=$(cat /proc/sys/kernel/random/uuid)
domain=$(cat /etc/xray/domain 2>/dev/null || hostname -f)
ns_domain=$(cat /etc/xray/dns 2>/dev/null || echo "")
city=$(cat /etc/xray/city 2>/dev/null || echo "Unknown")
pubkey=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "")
ip=$(curl -s ipv4.icanhazip.com)
duration=60
exp=$(date -d "+$duration minutes" +"%Y-%m-%d %H:%M:%S")

# Validasi config
mkdir -p /etc/xray/trojan
if [ ! -f "/etc/xray/trojan/config.json" ]; then
  echo '{"inbounds":[]}' > /etc/xray/trojan/config.json
fi

# Inject user ke config
sed -i '/#trojan$/a\\### '"$user $exp"'\\
},{"password": "'"$uuid"'","email": "'"$user"'"' /etc/xray/trojan/config.json

sed -i '/#trojangrpc$/a\\### '"$user $exp"'\\
},{"password": "'"$uuid"'","email": "'"$user"'"' /etc/xray/trojan/config.json

# Auto Remove
echo "sleep $((duration * 60)); sed -i '/$user/d' /etc/xray/trojan/config.json; systemctl restart trojan@config 2>/dev/null" | at now 2>/dev/null || (nohup bash -c "sleep $((duration * 60)); sed -i '/$user/d' /etc/xray/trojan/config.json; systemctl restart trojan@config 2>/dev/null" &)

# Restart service
systemctl restart trojan@config 2>/dev/null

# Generate Trojan Links
trojan_tls="trojan://${uuid}@${domain}:443?path=/trojan-ws&security=tls&host=${domain}&type=ws&sni=${domain}#${user}-WS-TLS"
trojan_grpc="trojan://${uuid}@${domain}:443?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=${domain}#${user}-gRPC"

# Output JSON
cat <<EOF
{
  "status": "success",
  "username": "$user",
  "uuid": "$uuid",
  "ip": "$ip",
  "domain": "$domain",
  "ns_domain": "$ns_domain",
  "city": "$city",
  "public_key": "$pubkey",
  "expiration": "$exp",
  "protocol": "trojan",
  "link_tls": "$trojan_tls",
  "link_grpc": "$trojan_grpc",
  "port_tls": "443"
}
EOF
`;
        
        console.log('🔨 Executing trial Trojan command...');
        
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
            console.log(`📄 Output: ${output.trim()}`);
            
            if (code !== 0) {
              console.error('❌ Command failed with exit code:', code);
              return resolve({ status: 'error', message: `Gagal membuat trial Trojan (exit code ${code}).` });
            }

            try {
              // Parse JSON output
              const jsonStart = output.indexOf('{');
              const jsonEnd = output.lastIndexOf('}');
              if (jsonStart === -1 || jsonEnd === -1) {
                throw new Error('No JSON found in output');
              }
              const jsonStr = output.substring(jsonStart, jsonEnd + 1);
              const result = JSON.parse(jsonStr);
              
              console.log('✅ Trojan Trial created:', result.username);
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
            const stderr = data.toString();
            console.warn('⚠️ STDERR:', stderr);
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

module.exports = { trialtrojan };
