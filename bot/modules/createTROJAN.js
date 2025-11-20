const { Client } = require('ssh2');
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./sellvpn.db');

async function createtrojan(username, exp, quota, limitip, serverId) {
  console.log(`⚙️ Creating TROJAN for ${username} | Exp: ${exp} | Quota: ${quota} GB | IP Limit: ${limitip}`);

  if (/\s/.test(username) || /[^a-zA-Z0-9]/.test(username)) {
    return '❌ Username tidak valid. Gunakan hanya huruf dan angka tanpa spasi.';
  }

  return new Promise((resolve) => {
    db.get('SELECT * FROM Server WHERE id = ?', [serverId], async (err, server) => {
      if (err || !server) {
        console.error('❌ DB Error:', err?.message || 'Server tidak ditemukan');
        return resolve('❌ Server tidak ditemukan.');
      }

      console.log(`📡 Connecting to ${server.domain} with user root...`);

      const conn = new Client();
      let resolved = false;
      
      const globalTimeout = setTimeout(() => {
        if (!resolved) {
          resolved = true;
          console.error('❌ Global timeout after 35 seconds');
          conn.end();
          resolve('❌ Timeout koneksi ke server.');
        }
      }, 35000);

      conn.on('ready', () => {
        console.log('✅ SSH Connection established');
        
        // Generate UUID for password
        const uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
          const r = Math.random() * 16 | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
          return v.toString(16);
        });
        
        const expDate = new Date();
        expDate.setDate(expDate.getDate() + parseInt(exp));
        const expFormatted = expDate.toISOString().split('T')[0];
        
        const cmd = `
user="${username}"
uuid="${uuid}"
exp_date="${expFormatted}"
quota=${quota}
ip_limit=${limitip}
domain=$(cat /etc/xray/domain 2>/dev/null || hostname -f)
city=$(cat /etc/xray/city 2>/dev/null || echo "Unknown")
pubkey=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "")

mkdir -p /etc/xray/trojan

if [ ! -f "/etc/xray/trojan/config.json" ]; then
  echo '{"inbounds":[]}' > /etc/xray/trojan/config.json
fi

if grep -q "^### \$user " /etc/xray/trojan/config.json 2>/dev/null; then
  echo "ERROR:User already exists"
  exit 1
fi

sed -i '/#trojan$/a\\### '"\$user \$exp_date"'\\
},{"password": "'"\$uuid"'","email": "'"\$user"'"' /etc/xray/trojan/config.json

sed -i '/#trojangrpc$/a\\### '"\$user \$exp_date"'\\
},{"password": "'"\$uuid"'","email": "'"\$user"'"' /etc/xray/trojan/config.json

cat > /var/www/html/trojan-\$user.txt <<EOF
TLS Link : trojan://\${uuid}@\${domain}:443?path=/trojan-ws&security=tls&host=\${domain}&type=ws&sni=\${domain}#\${user}
GRPC Link : trojan://\${uuid}@\${domain}:443?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=\${domain}#\${user}
EOF

if [ "\$quota" != "0" ]; then
  quota_bytes=\$((quota * 1024 * 1024 * 1024))
  echo "\$quota_bytes" > /etc/xray/trojan/\${user}
  echo "\$ip_limit" > /etc/xray/trojan/\${user}IP
fi

db_file="/etc/xray/trojan/.trojan.db"
mkdir -p /etc/xray/trojan
touch \$db_file
grep -v "^### \${user} " "\$db_file" > "\$db_file.tmp" 2>/dev/null || true
mv "\$db_file.tmp" "\$db_file" 2>/dev/null || true
echo "### \${user} \${exp_date} \${uuid}" >> "\$db_file"

systemctl restart trojan@config 2>/dev/null || systemctl restart xray@trojan 2>/dev/null

trojan_tls="trojan://\${uuid}@\${domain}:443?path=/trojan-ws&security=tls&host=\${domain}&type=ws&sni=\${domain}#\${user}"
trojan_grpc="trojan://\${uuid}@\${domain}:443?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=\${domain}#\${user}"

cat <<EOFDATA
{
  "status": "success",
  "username": "\$user",
  "password": "\$uuid",
  "domain": "\$domain",
  "city": "\$city",
  "pubkey": "\$pubkey",
  "expired": "\$exp_date",
  "quota": "\${quota} GB",
  "ip_limit": "\$ip_limit",
  "trojan_tls_link": "\$trojan_tls",
  "trojan_grpc_link": "\$trojan_grpc"
}
EOFDATA
`;
        
        console.log('🔨 Executing TROJAN creation command...');
        
        let output = '';
        
        conn.exec(cmd, (err, stream) => {
          if (err) {
            clearTimeout(globalTimeout);
            if (!resolved) {
              resolved = true;
              console.error('❌ Exec error:', err.message);
              conn.end();
              return resolve('❌ Gagal eksekusi command SSH.');
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
              if (output.includes('ERROR:User already exists')) {
                return resolve('❌ Username sudah digunakan. Gunakan username lain.');
              }
              return resolve('❌ Gagal membuat akun TROJAN di server.');
            }

            try {
              const jsonStart = output.indexOf('{');
              const jsonEnd = output.lastIndexOf('}');
              if (jsonStart === -1 || jsonEnd === -1) {
                throw new Error('No JSON found in output');
              }
              const jsonStr = output.substring(jsonStart, jsonEnd + 1);
              const data = JSON.parse(jsonStr);
              
              if (data.status !== 'success') {
                throw new Error('Status not success');
              }

              const msg = `
         🔥 *TROJAN PREMIUM ACCOUNT*
         
🔹 *Informasi Akun*
┌─────────────────────
│👤 *Username:* \`${data.username}\`
│🔑 *Password:* \`${data.password}\`
│🌐 *Domain:* \`${data.domain}\`
└─────────────────────
┌─────────────────────
│🔐 *Port TLS:* \`443\`
│🔁 *Network:* WebSocket / gRPC
│📦 *Quota:* ${data.quota === '0 GB' ? 'Unlimited' : data.quota}
│🌍 *IP Limit:* ${data.ip_limit === '0' ? 'Unlimited' : data.ip_limit}
└─────────────────────

🔗 *TROJAN TLS:*
\`\`\`
${data.trojan_tls_link}
\`\`\`
🔗 *TROJAN GRPC:*
\`\`\`
${data.trojan_grpc_link}
\`\`\`

🔏 *PUBKEY:* \`${data.pubkey || 'N/A'}\`
┌─────────────────────
│🕒 *Expired:* \`${data.expired}\`
│
│📥 Save: https://${data.domain}:81/trojan-${data.username}.txt
└─────────────────────
✨ By : *EXTRIMER TUNNEL* ✨
`.trim();

              console.log('✅ TROJAN created for', username);
              resolve(msg);
            } catch (e) {
              console.error('❌ Failed to parse JSON:', e.message);
              resolve('❌ Gagal parsing output dari server.');
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
            resolve('❌ Server tidak ditemukan. Cek domain/IP server.');
          } else if (err.level === 'client-authentication') {
            resolve('❌ Password root VPS salah. Update password di database.');
          } else if (err.code === 'ETIMEDOUT' || err.code === 'ECONNREFUSED') {
            resolve('❌ Tidak bisa koneksi ke server. Cek apakah server online.');
          } else {
            resolve(`❌ Gagal koneksi SSH: ${err.message}`);
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

module.exports = { createtrojan };
