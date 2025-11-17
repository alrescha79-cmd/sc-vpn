const axios = require('axios');
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./sellvpn.db');

async function createtrojan(username, exp, quota, limitip, serverId) {
  console.log(`⚙️ Creating TROJAN for ${username} | Exp: ${exp} | Quota: ${quota} GB | IP Limit: ${limitip}`);

  if (/\s/.test(username) || /[^a-zA-Z0-9]/.test(username)) {
    return '❌ Username tidak valid.';
  }

  return new Promise((resolve) => {
    db.get('SELECT * FROM Server WHERE id = ?', [serverId], async (err, server) => {
      if (err || !server) return resolve('❌ Server tidak ditemukan.');

      const url = `http://${server.domain}:5888/createtrojan?user=${username}&exp=${exp}&quota=${quota}&iplimit=${limitip}`;

      try {
        const { data } = await axios.get(url);

        if (data.status !== 'success') return resolve(`❌ Gagal: ${data.message}`);

        const d = data.data;

        const msg = `
         🔥 *TROJAN PREMIUM ACCOUNT*

🔹 *Informasi Akun*
┌─────────────────────
│👤 *Username:* \`${d.username}\`
│🌐 *Domain:* \`${d.domain}\`
└─────────────────────
┌─────────────────────
│🔐 *Port TLS:* \`443\`
│📡 *Port HTTP:* \`80\`
│🔁 *Network:* WebSocket / gRPC
│📦 *Quota:* ${d.quota}
│🌍 *IP Limit:* ${d.ip_limit}
└─────────────────────

🔗 *TROJAN TLS:*
\`\`\`
${d.trojan_tls_link}
\`\`\`
🔗 *TROJAN GRPC:*
\`\`\`
${d.trojan_grpc_link}
\`\`\`

🔏 *PUBKEY:* \`${d.pubkey}\`
┌─────────────────────
│🕒 *Expired:* \`${d.expired}\`
│
│📥 [Save Account](https://${d.domain}:81/trojan-${d.username}.txt)
└─────────────────────
✨ By : *EXTRIMER TUNNEL*! ✨
`.trim();

        resolve(msg);
      } catch (e) {
        resolve('❌ Tidak bisa request trojan.');
      }
    });
  });
}

module.exports = { createtrojan };