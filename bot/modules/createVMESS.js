const { Client } = require('ssh2');
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./sellvpn.db');

async function createvmess(username, exp, quota, limitip, serverId) {
  console.log(`⚙️ Creating VMESS for ${username} | Exp: ${exp} | Quota: ${quota} GB | IP Limit: ${limitip}`);

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
          resolve('❌ Timeout koneksi ke server. Pastikan server online dan password benar.');
        }
      }, 35000);

      conn.on('ready', () => {
        console.log('✅ SSH Connection established');
        
        // Generate UUID
        const uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
          const r = Math.random() * 16 | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
          return v.toString(16);
        });
        
        // Hitung expired date
        const expDate = new Date();
        expDate.setDate(expDate.getDate() + parseInt(exp));
        const expFormatted = expDate.toISOString().split('T')[0]; // YYYY-MM-DD
        
        // Command untuk create VMESS (berdasarkan script addvmess)
        const cmd = `
user="${username}"
uuid="${uuid}"
exp_date="${expFormatted}"
duration=${exp}
quota=${quota}
ip_limit=${limitip}
domain=$(cat /etc/xray/domain 2>/dev/null || hostname -f)
city=$(cat /etc/xray/city 2>/dev/null || echo "Unknown")
pubkey=$(cat /etc/slowdns/server.pub 2>/dev/null || echo "")

# Create directory if not exists
mkdir -p /etc/xray/vmess

# Backup config if not exists
if [ ! -f "/etc/xray/vmess/config.json" ]; then
  echo '{"inbounds":[]}' > /etc/xray/vmess/config.json
fi

# Check if user already exists
if grep -q "^### \$user " /etc/xray/vmess/config.json 2>/dev/null; then
  echo "ERROR:User already exists"
  exit 1
fi

# Add user to config
sed -i '/#vmess$/a\\### '"\$user \$exp_date"'\\
},{"id": "'"\$uuid"'","email": "'"\$user"'"' /etc/xray/vmess/config.json

sed -i '/#vmessgrpc$/a\\### '"\$user \$exp_date"'\\
},{"id": "'"\$uuid"'","email": "'"\$user"'"' /etc/xray/vmess/config.json

# Create config file for web
cat > /var/www/html/vmess-\$user.txt <<EOF
══════════════════════════════════════════════════════════════════════
# Vmess Account Links
══════════════════════════════════════════════════════════════════════
TLS Link : vmess://\${uuid}@\${domain}:443?encryption=auto&security=tls&sni=\${domain}&type=ws&host=\${domain}&path=%2Fwhatever%2Fvmess#\${user}
══════════════════════════════════════════════════════════════════════
Non-TLS Link : vmess://\${uuid}@\${domain}:80?encryption=auto&security=none&type=ws&host=\${domain}&path=%2Fwhatever%2Fvmess#\${user}
══════════════════════════════════════════════════════════════════════
GRPC Link : vmess://\${uuid}@\${domain}:443?encryption=auto&security=tls&type=grpc&serviceName=vmess-grpc&sni=\${domain}#\${user}
══════════════════════════════════════════════════════════════════════
EOF

# Save quota and IP limit
if [ "\$quota" != "0" ]; then
  quota_bytes=\$((quota * 1024 * 1024 * 1024))
  echo "\$quota_bytes" > /etc/xray/vmess/\${user}
  echo "\$ip_limit" > /etc/xray/vmess/\${user}IP
fi

# Update database
db_file="/etc/xray/vmess/.vmess.db"
mkdir -p /etc/xray/vmess
touch \$db_file
grep -v "^### \${user} " "\$db_file" > "\$db_file.tmp" 2>/dev/null || true
mv "\$db_file.tmp" "\$db_file" 2>/dev/null || true
echo "### \${user} \${exp_date} \${uuid}" >> "\$db_file"

# Restart service
systemctl restart vmess@config 2>/dev/null || systemctl restart xray@vmess 2>/dev/null

# Generate links
vmess_tls="vmess://\${uuid}@\${domain}:443?encryption=auto&security=tls&sni=\${domain}&type=ws&host=\${domain}&path=%2Fwhatever%2Fvmess#\${user}"
vmess_non="vmess://\${uuid}@\${domain}:80?encryption=auto&security=none&type=ws&host=\${domain}&path=%2Fwhatever%2Fvmess#\${user}"
vmess_grpc="vmess://\${uuid}@\${domain}:443?encryption=auto&security=tls&type=grpc&serviceName=vmess-grpc&sni=\${domain}#\${user}"

# Output JSON
cat <<EOFDATA
{
  "status": "success",
  "username": "\$user",
  "uuid": "\$uuid",
  "domain": "\$domain",
  "city": "\$city",
  "pubkey": "\$pubkey",
  "expired": "\$exp_date",
  "quota": "\${quota} GB",
  "ip_limit": "\$ip_limit",
  "vmess_tls_link": "\$vmess_tls",
  "vmess_nontls_link": "\$vmess_non",
  "vmess_grpc_link": "\$vmess_grpc"
}
EOFDATA
`;
        
        console.log('🔨 Executing VMESS creation command...');
        
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
            console.log(`📄 Output: ${output.trim()}`);
            
            if (code !== 0) {
              console.error('❌ Command failed with exit code:', code);
              if (output.includes('ERROR:User already exists')) {
                return resolve('❌ Username sudah digunakan. Gunakan username lain.');
              }
              return resolve('❌ Gagal membuat akun VMESS di server (exit code ' + code + ').');
            }

            try {
              // Parse JSON output
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

              // Escape markdown special characters in links
              const escapedTlsLink = data.vmess_tls_link.replace(/#/g, '%23');
              const escapedNonTlsLink = data.vmess_nontls_link.replace(/#/g, '%23');
              const escapedGrpcLink = data.vmess_grpc_link.replace(/#/g, '%23');

              const msg = `
         🔥 *VMESS PREMIUM ACCOUNT*
         
🔹 *Informasi Akun*
┌─────────────────────
│👤 *Username:* \`${data.username}\`
│🌐 *Domain:* \`${data.domain}\`
└─────────────────────
┌─────────────────────
│🔐 *Port TLS:* \`443\`
│📡 *Port HTTP:* \`80\`
│🔁 *Network:* WebSocket
│📦 *Quota:* ${data.quota === '0 GB' ? 'Unlimited' : data.quota}
│🌍 *IP Limit:* ${data.ip_limit === '0' ? 'Unlimited' : data.ip_limit}
└─────────────────────

🔗 *VMESS TLS:*
\`\`\`
${data.vmess_tls_link}
\`\`\`
🔗 *VMESS NON-TLS:*
\`\`\`
${data.vmess_nontls_link}
\`\`\`
🔗 *VMESS GRPC:*
\`\`\`
${data.vmess_grpc_link}
\`\`\`

🧾 *UUID:* \`${data.uuid}\`
🔏 *PUBKEY:* \`${data.pubkey || 'N/A'}\`
┌─────────────────────
│🕒 *Expired:* \`${data.expired}\`
│
│📥 Save: https://${data.domain}:81/vmess-${data.username}.txt
└─────────────────────
✨ By : *EXTRIMER TUNNEL* ✨
`.trim();

              console.log('✅ VMESS created for', username);
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
            resolve('❌ Server tidak ditemukan. Cek domain/IP server.');
          } else if (err.level === 'client-authentication') {
            resolve('❌ Password root VPS salah. Update password di database.');
          } else if (err.code === 'ETIMEDOUT' || err.code === 'ECONNREFUSED') {
            resolve('❌ Tidak bisa koneksi ke server. Cek apakah server online dan port 22 terbuka.');
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

module.exports = { createvmess };
