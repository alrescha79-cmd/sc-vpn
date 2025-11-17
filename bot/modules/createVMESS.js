const { Client } = require('ssh2');
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./sellvpn.db');
const { v4: uuidv4 } = require('uuid');

// ✅ CREATE VMESS
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

      const conn = new Client();
      let sshOutput = '';
      let hasError = false;
      let commandTimeout;

      conn.on('ready', () => {
        console.log('✅ SSH Connection established for VMESS');
        
        const uuid = uuidv4();
        const expDate = new Date();
        expDate.setDate(expDate.getDate() + parseInt(exp));
        const expFormatted = expDate.toISOString().split('T')[0];
        
        const cmd = `
          # Get domain
          domain=\$(cat /etc/xray/domain 2>/dev/null || hostname -f)
          
          # Tambah user ke xray vmess
          cat <<EOF >> /etc/xray/config.json
{
  "email": "${username}@vmess",
  "id": "${uuid}",
  "alterId": 0
}
EOF
          
          # Restart xray
          systemctl restart xray
          
          # Simpan ke database
          mkdir -p /etc/vmess
          echo "### ${username} ${expFormatted} ${uuid} ${limitip} ${quota}" >> /etc/vmess/.vmess.db
          
          # Output
          echo "VMESS_CREATED_SUCCESS"
          echo "username:${username}"
          echo "uuid:${uuid}"
          echo "domain:\$domain"
          echo "expired:${expFormatted}"
          echo "quota:${quota}"
          echo "iplimit:${limitip}"
        `.trim();
        
        commandTimeout = setTimeout(() => {
          hasError = true;
          conn.end();
          console.error('❌ VMESS timeout after 30s');
          resolve('❌ Timeout saat membuat akun VMESS. Coba lagi.');
        }, 30000);
        
        conn.exec(cmd, (err, stream) => {
          if (err) {
            clearTimeout(commandTimeout);
            hasError = true;
            conn.end();
            return resolve('❌ Gagal eksekusi command VMESS.');
          }

          stream.on('close', (code, signal) => {
            clearTimeout(commandTimeout);
            conn.end();
            
            if (hasError) return;
            
            if (code !== 0) {
              console.error('VMESS Command exit code:', code);
              return resolve('❌ Gagal membuat akun VMESS di server.');
            }

            try {
              console.log('VMESS Output:', sshOutput);
              
              if (!sshOutput.includes('VMESS_CREATED_SUCCESS')) {
                return resolve('❌ Gagal membuat akun VMESS. Output tidak valid.');
              }
              
              const expDateDisplay = new Date();
              expDateDisplay.setDate(expDateDisplay.getDate() + parseInt(exp));
              
              const msg = `
🔥 *VMESS PREMIUM ACCOUNT*
         
🔹 *Informasi Akun*
┌─────────────────────
│👤 *Username:* \`${username}\`
│🌐 *Domain:* \`${server.domain}\`
│🆔 *UUID:* \`${uuid}\`
└─────────────────────
┌─────────────────────
│🔐 *Port TLS:* \`443\`
│📡 *Port HTTP:* \`80\`
│🔁 *Network:* WebSocket
│📦 *Quota:* ${quota === 0 ? 'Unlimited' : quota + ' GB'}
│🌍 *IP Limit:* ${limitip === 0 ? 'Unlimited' : limitip}
└─────────────────────

📅 *Expired:* \`${expDateDisplay.toLocaleDateString('id-ID')}\`
✨ By : *EXTRIMER TUNNEL*! ✨
              `.trim();

              resolve(msg);
            } catch (e) {
              console.error('Parse error:', e.message);
              resolve('❌ Gagal parsing response dari server.');
            }
          })
          .on('data', (data) => {
            sshOutput += data.toString();
          })
          .stderr.on('data', (data) => {
            console.error('SSH STDERR:', data.toString());
          });
        });
      })
      .on('error', (err) => {
        if (commandTimeout) clearTimeout(commandTimeout);
        console.error('SSH Error:', err.message);
        resolve('❌ Gagal koneksi SSH ke server. Cek password root VPS.');
      })
      .connect({
        host: server.domain,
        port: 22,
        username: 'root',
        password: server.auth,
        readyTimeout: 30000
      });
    });
  });
}

module.exports = { createvmess };
