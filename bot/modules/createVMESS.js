const { Client } = require('ssh2');
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./sellvpn.db');

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

      conn.on('ready', () => {
        console.log('✅ SSH Connection established for VMESS');
        
        const cmd = `addvmess ${username} ${exp} ${quota} ${limitip}`;
        
        conn.exec(cmd, (err, stream) => {
          if (err) {
            hasError = true;
            conn.end();
            return resolve('❌ Gagal eksekusi command VMESS.');
          }

          stream.on('close', (code, signal) => {
            conn.end();
            
            if (hasError || code !== 0) {
              return resolve('❌ Gagal membuat akun VMESS di server.');
            }

            try {
              const expDate = new Date();
              expDate.setDate(expDate.getDate() + parseInt(exp));
              
              const msg = `
🔥 *VMESS PREMIUM ACCOUNT*
         
🔹 *Informasi Akun*
┌─────────────────────
│👤 *Username:* \`${username}\`
│🌐 *Domain:* \`${server.domain}\`
└─────────────────────
┌─────────────────────
│🔐 *Port TLS:* \`443\`
│📡 *Port HTTP:* \`80\`
│🔁 *Network:* WebSocket
│📦 *Quota:* ${quota === 0 ? 'Unlimited' : quota + ' GB'}
│🌍 *IP Limit:* ${limitip === 0 ? 'Unlimited' : limitip}
└─────────────────────

📅 *Expired:* \`${expDate.toLocaleDateString('id-ID')}\`
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
        password: server.auth,
        readyTimeout: 30000
      });
    });
  });
}

module.exports = { createvmess };
