const axios = require('axios');
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./sellvpn.db');

async function createshadowsocks(username, exp, quota, limitip, serverId) {
  console.log(`⚙️ Creating Shadowsocks for ${username} | Exp: ${exp} | Quota: ${quota} GB | IP Limit: ${limitip}`);

  if (/\s/.test(username) || /[^a-zA-Z0-9]/.test(username)) {
    return '❌ Username tidak valid.';
  }

  return new Promise((resolve) => {
    db.get('SELECT * FROM Server WHERE id = ?', [serverId], async (err, server) => {
      if (err || !server) return resolve('❌ Server tidak ditemukan.');

      const url = `http://${server.domain}:5888/createshadowsocks?user=${username}&exp=${exp}&quota=${quota}&iplimit=${limitip}&auth=${server.auth}`;

      try {
        const { data } = await axios.get(url);

        if (data.status !== 'success') return resolve(`❌ Gagal: ${data.message}`);

        const d = data.data;

        const msg = `
         🔥 *SHADOWSOCKS PREMIUM*

🔹 *Informasi Akun*
┌─────────────────────
│👤 *Username:* \`${d.username}\`
│🌐 *Domain:* \`${d.domain}\`
└─────────────────────
┌─────────────────────
│📦 *Quota:* ${d.quota}
│🌍 *IP Limit:* ${d.ip_limit}
└─────────────────────

🔗 *SS WS LINK:*
${d.ss_link_ws}
\`\`\`
🔗 *SS GRPC LINK:*
${d.ss_link_grpc}
\`\`\`

🔏 *PUBKEY:* \`${d.pubkey}\`
┌─────────────────────
│🕒 *Expired:* \`${d.expired}\`
│
│📥 [Save Account](https://${d.domain}:81/shadowsocks-${d.username}.txt)
└─────────────────────
✨ By : *EXTRIMER TUNNEL*! ✨
`.trim();

        resolve(msg);
      } catch (e) {
        resolve('❌ Error Shadowsocks API');
      }
    });
  });
}
module.exports = { createshadowsocks };