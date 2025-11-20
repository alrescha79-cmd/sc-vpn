const { Client } = require('ssh2');
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./sellvpn.db');

async function trialssh(serverId) {
  console.log(`⚙️ Creating SSH Trial for server ${serverId}`);

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
        
        // Generate random username
        const randomHex = Math.random().toString(16).substring(2, 6);
        const username = `trial${randomHex}`;
        const password = username;
        const duration = 60; // minutes
        
        // Command untuk create trial SSH
        const cmd = `
user="${username}"
password="${password}"
duration=${duration}
expiration=$(date -d "+$duration minutes" +"%Y-%m-%d %H:%M:%S")
domain=$(cat /etc/xray/domain 2>/dev/null || hostname -f)
ip=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ipv4.icanhazip.com)
ns_domain=$(cat /etc/xray/dns 2>/dev/null || echo "")
public_key=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "")
city=$(cat /etc/xray/city 2>/dev/null || echo "Unknown")

# Buat akun
useradd -e $(date -d "+$duration minutes" +"%Y-%m-%d") -s /bin/false -M "$user" 2>/dev/null
echo "$user:$password" | chpasswd

# Auto delete after duration
echo "sleep $((duration * 60)); userdel $user 2>/dev/null" | at now 2>/dev/null || (nohup bash -c "sleep $((duration * 60)); userdel $user 2>/dev/null" &)

# Output JSON
cat <<EOF
{
  "status": "success",
  "username": "$user",
  "password": "$password",
  "ip": "$ip",
  "domain": "$domain",
  "city": "$city",
  "ns_domain": "$ns_domain",
  "public_key": "$public_key",
  "expiration": "$expiration",
  "ports": {
    "openssh": "22, 80, 443",
    "udp_ssh": "1-65535",
    "dns": "443, 53, 22",
    "dropbear": "443, 109",
    "ssh_ws": "80, 8080",
    "ssh_ssl_ws": "443",
    "ssl_tls": "443",
    "ovpn_ssl": "443",
    "ovpn_tcp": "1194",
    "ovpn_udp": "2200"
  },
  "openvpn_link": "https://$domain:81/allovpn.zip",
  "save_link": "https://$domain:81/ssh-$user.txt",
  "wss_payload": "GET wss://bugmu.com/ HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf][crlf]"
}
EOF
`;
        
        console.log('🔨 Executing trial SSH command...');
        
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
              return resolve({ status: 'error', message: `Gagal membuat trial SSH (exit code ${code}).` });
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
              
              console.log('✅ SSH Trial created:', result.username);
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

module.exports = { trialssh };
