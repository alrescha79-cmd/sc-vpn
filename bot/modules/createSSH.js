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

      conn.on('ready', () => {
        console.log('✅ SSH Connection established');
        
        // Jalankan script addsh di server
        const cmd = `addsh ${username} ${password} ${exp} ${iplimit}`;
        
        conn.exec(cmd, (err, stream) => {
          if (err) {
            hasError = true;
            conn.end();
            return resolve('❌ Gagal eksekusi command SSH.');
          }

          stream.on('close', (code, signal) => {
            conn.end();
            
            if (hasError || code !== 0) {
              return resolve('❌ Gagal membuat akun SSH di server.');
            }

            // Parse output dari script
            try {
              const lines = sshOutput.split('\n');
              const expDate = new Date();
              expDate.setDate(expDate.getDate() + parseInt(exp));
              
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
│📅 *Expired:* \`${expDate.toLocaleDateString('id-ID')}\`
│🌐 *IP Limit:* \`${iplimit} IP\`
└─────────────────────
✨ By : *EXTRIMER TUNNEL*! ✨
              `.trim();

              resolve(msg);
            } catch (e) {
              resolve('❌ Gagal parsing response dari server.');
            }
          })
          .on('data', (data) => {
            sshOutput += data.toString();
          })
          .stderr.on('data', (data) => {
            console.error('SSH STDERR:', data.toString());
            hasError = true;
          });
        });
      })
      .on('error', (err) => {
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