const { Client } = require('ssh2');
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./sellvpn.db');

async function createssh(username, password, exp, iplimit, serverId) {
  console.log(`⚙️ Creating SSH for ${username} | Exp: ${exp} | IP Limit: ${iplimit}`);

  if (/\s/.test(username) || /[^a-zA-Z0-9]/.test(username)) {
    return '❌ Username tidak valid.';
  }

  return new Promise((resolve) => {
    db.get('SELECT * FROM Server WHERE id = ?', [serverId], async (err, server) => {
      if (err || !server) return resolve('❌ Server tidak ditemukan.');

      const conn = new Client();
      let sshOutput = '';
      let hasError = false;
      let commandTimeout;

      conn.on('ready', () => {
        console.log('✅ SSH Connection established');
        
        // Command untuk membuat user SSH langsung tanpa script interaktif
        const expDate = new Date();
        expDate.setDate(expDate.getDate() + parseInt(exp));
        const expFormatted = expDate.toISOString().split('T')[0]; // YYYY-MM-DD
        
        const cmd = `
          # Buat user SSH
          useradd -M -N -s /bin/false -e ${expFormatted} ${username} 2>/dev/null || usermod -e ${expFormatted} ${username}
          echo "${username}:${password}" | chpasswd
          
          # Tambah ke database SSH
          echo "### ${username} ${expFormatted} ${iplimit}" >> /etc/ssh/.ssh.db
          
          # Get domain
          domain=\$(cat /etc/xray/domain 2>/dev/null || hostname -f)
          
          # Output JSON
          echo "SSH_CREATED_SUCCESS"
          echo "username:${username}"
          echo "password:${password}"
          echo "domain:\$domain"
          echo "expired:${expFormatted}"
          echo "iplimit:${iplimit}"
        `.trim();
        
        // Set timeout untuk command
        commandTimeout = setTimeout(() => {
          hasError = true;
          conn.end();
          console.error('❌ Error parsing response: timeout of 30000ms exceeded');
          resolve('❌ Timeout saat membuat akun SSH. Coba lagi atau hubungi admin.');
        }, 30000);
        
        conn.exec(cmd, (err, stream) => {
          if (err) {
            clearTimeout(commandTimeout);
            hasError = true;
            conn.end();
            return resolve('❌ Gagal eksekusi command SSH.');
          }

          stream.on('close', (code, signal) => {
            clearTimeout(commandTimeout);
            conn.end();
            
            if (hasError) {
              return; // Sudah di-resolve oleh timeout atau error
            }
            
            if (code !== 0) {
              console.error('Command exit code:', code);
              return resolve('❌ Gagal membuat akun SSH di server.');
            }

            // Parse output dari script
            try {
              console.log('SSH Output:', sshOutput);
              
              if (!sshOutput.includes('SSH_CREATED_SUCCESS')) {
                return resolve('❌ Gagal membuat akun SSH. Output tidak valid.');
              }
              
              const expDateDisplay = new Date();
              expDateDisplay.setDate(expDateDisplay.getDate() + parseInt(exp));
              
              const msg = `
🔥 *AKUN SSH PREMIUM* 

🔹 *Informasi Akun*
┌─────────────────────
│👤 Username   : \`${username}\`
│🔑 Password   : \`${password}\`
│🌐 Domain     : \`${server.domain}\`
└─────────────────────
┌─────────────────────
│🔒 TLS        : 443
│🌍 HTTP       : 80
│🛡️ SSH        : 22
│🌐 SSH WS     : 80
│🔐 SSL WS     : 443
│🧱 Dropbear   : 109, 443
│🧭 DNS        : 53, 443, 22
│📥 OVPN       : 1194, 2200, 443
└─────────────────────

📁 *Link Simpan Akun:*
\`https://${server.domain}:81/ssh-${username}.txt\`

📦 *Download OVPN:*
\`https://${server.domain}:81/allovpn.zip\`

┌─────────────────────
│📅 *Expired:* \`${expDateDisplay.toLocaleDateString('id-ID')}\`
│🌐 *IP Limit:* \`${iplimit} IP\`
└─────────────────────
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
            // Jangan set hasError=true untuk stderr, karena beberapa command normal output ke stderr
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
        password: server.auth, // auth = password root VPS
        readyTimeout: 30000
      });
    });
  });
}

module.exports = { createssh };