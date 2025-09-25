const axios = require('axios');
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./sellvpn.db');

async function renewssh(username, exp, limitip, serverId) {
  console.log(`Renewing SSH account for ${username} with expiry ${exp} days, limit IP ${limitip} on server ${serverId}`);
  
  // Validasi username
  if (/\s/.test(username) || /[^a-zA-Z0-9]/.test(username)) {
    return '❌ Username tidak valid. Mohon gunakan hanya huruf dan angka tanpa spasi.';
  }

  // Ambil domain dari database
  return new Promise((resolve, reject) => {
    db.get('SELECT * FROM Server WHERE id = ?', [serverId], (err, server) => {
      if (err) {
        console.error('Error fetching server:', err.message);
        return resolve('❌ Server tidak ditemukan. Silakan coba lagi.');
      }

      if (!server) return resolve('❌ Server tidak ditemukan. Silakan coba lagi.');

      const domain = server.domain;
      const auth = server.auth;
      const param = `:5888/renewssh?user=${username}&exp=${exp}&iplimit=${limitip}&auth=${auth}`;
      const url = `http://${domain}${param}`;
      axios.get(url)
        .then(response => {
          if (response.data.status === "success") {
            const sshData = response.data.data;
            const msg = `
   ♻️ *RENEW SSH PREMIUM* ♻️

🔹 *Informasi Akun*
┌─────────────────────────────
│ Username: \`${username}\`
│ Kadaluarsa: \`${sshData.exp}\`
│ Batas IP: \`${sshData.limitip} IP\`
└─────────────────────────────
✅ Akun ${username} berhasil diperbarui
✨ Selamat menggunakan layanan kami! ✨
`;
         
              console.log('SSH account renewed successfully');
              return resolve(msg);
            } else {
              console.log('Error renewing SSH account');
              return resolve(`❌ Terjadi kesalahan: ${response.data.message}`);
            }
          })
        .catch(error => {
          console.error('Error saat memperbarui SSH:', error);
          return resolve('❌ Terjadi kesalahan saat memperbarui SSH. Silakan coba lagi nanti.');
        });
    });
  });
}
async function renewvmess(username, exp, quota, limitip, serverId) {
    console.log(`Renewing VMess account for ${username} with expiry ${exp} days, quota ${quota} GB, limit IP ${limitip} on server ${serverId}`);
    
    // Validasi username
    if (/\s/.test(username) || /[^a-zA-Z0-9]/.test(username)) {
      return '❌ Username tidak valid. Mohon gunakan hanya huruf dan angka tanpa spasi.';
    }
  
    // Ambil domain dari database
    return new Promise((resolve, reject) => {
      db.get('SELECT * FROM Server WHERE id = ?', [serverId], (err, server) => {
        if (err) {
          console.error('Error fetching server:', err.message);
          return resolve('❌ Server tidak ditemukan. Silakan coba lagi.');
        }
  
        if (!server) return resolve('❌ Server tidak ditemukan. Silakan coba lagi.');
  
        const domain = server.domain;
        const auth = server.auth;
        const param = `:5888/renewvmess?user=${username}&exp=${exp}&quota=${quota}&iplimit=${limitip}&auth=${auth}`;
        const url = `http://${domain}${param}`;
        axios.get(url)
          .then(response => {
            if (response.data.status === "success") {
              const vmessData = response.data.data;
              const msg = `
     ♻️ *RENEW VMESS PREMIUM* ♻️
  
  🔹 *Informasi Akun*
  ┌─────────────────────────────
  │ Username: \`${username}\`
  │ Kadaluarsa: \`${vmessData.exp}\`
  │ Kuota: \`${vmessData.quota}\`
  │ Batas IP: \`${vmessData.limitip} IP\`
  └─────────────────────────────
  ✅ Akun ${username} berhasil diperbarui
  ✨ Selamat menggunakan layanan kami! ✨
  `;
                console.log('VMess account renewed successfully');
                return resolve(msg);
              } else {
                console.log('Error renewing VMess account');
                return resolve(`❌ Terjadi kesalahan: ${response.data.message}`);
              }
            })
          .catch(error => {
            console.error('Error saat memperbarui VMess:', error);
            return resolve('❌ Terjadi kesalahan saat memperbarui VMess. Silakan coba lagi nanti.');
          });
      });
    });
  }
  async function renewvless(username, exp, quota, limitip, serverId) {
    console.log(`Renewing VLess account for ${username} with expiry ${exp} days, quota ${quota} GB, limit IP ${limitip} on server ${serverId}`);
    
    // Validasi username
    if (/\s/.test(username) || /[^a-zA-Z0-9]/.test(username)) {
      return '❌ Username tidak valid. Mohon gunakan hanya huruf dan angka tanpa spasi.';
    }
  
    // Ambil domain dari database
    return new Promise((resolve, reject) => {
      db.get('SELECT * FROM Server WHERE id = ?', [serverId], (err, server) => {
        if (err) {
          console.error('Error fetching server:', err.message);
          return resolve('❌ Server tidak ditemukan. Silakan coba lagi.');
        }
  
        if (!server) return resolve('❌ Server tidak ditemukan. Silakan coba lagi.');
  
        const domain = server.domain;
        const auth = server.auth;
        const param = `:5888/renewvless?user=${username}&exp=${exp}&quota=${quota}&iplimit=${limitip}&auth=${auth}`;
        const url = `http://${domain}${param}`;
        axios.get(url)
          .then(response => {
            if (response.data.status === "success") {
              const vlessData = response.data.data;
              const msg = `
     ♻️ *RENEW VLESS PREMIUM* ♻️
  
  🔹 *Informasi Akun*
  ┌─────────────────────────────
  │ Username: \`${username}\`
  │ Kadaluarsa: \`${vlessData.exp}\`
  │ Kuota: \`${vlessData.quota}\`
  │ Batas IP: \`${vlessData.limitip} IP\`
  └─────────────────────────────
  ✅ Akun ${username} berhasil diperbarui
  ✨ Selamat menggunakan layanan kami! ✨
  `;
           
                console.log('VLess account renewed successfully');
                return resolve(msg);
              } else {
                console.log('Error renewing VLess account');
                return resolve(`❌ Terjadi kesalahan: ${response.data.message}`);
              }
            })
          .catch(error => {
            console.error('Error saat memperbarui VLess:', error);
            return resolve('❌ Terjadi kesalahan saat memperbarui VLess. Silakan coba lagi nanti.');
          });
      });
    });
  }
  async function renewtrojan(username, exp, quota, limitip, serverId) {
    console.log(`Renewing Trojan account for ${username} with expiry ${exp} days, quota ${quota} GB, limit IP ${limitip} on server ${serverId}`);
    
    // Validasi username
    if (/\s/.test(username) || /[^a-zA-Z0-9]/.test(username)) {
      return '❌ Username tidak valid. Mohon gunakan hanya huruf dan angka tanpa spasi.';
    }
  
    // Ambil domain dari database
    return new Promise((resolve, reject) => {
      db.get('SELECT * FROM Server WHERE id = ?', [serverId], (err, server) => {
        if (err) {
          console.error('Error fetching server:', err.message);
          return resolve('❌ Server tidak ditemukan. Silakan coba lagi.');
        }
  
        if (!server) return resolve('❌ Server tidak ditemukan. Silakan coba lagi.');
  
        const domain = server.domain;
        const auth = server.auth;
        const param = `:5888/renewtrojan?user=${username}&exp=${exp}&quota=${quota}&iplimit=${limitip}&auth=${auth}`;
        const url = `http://${domain}${param}`;
        axios.get(url)
          .then(response => {
            if (response.data.status === "success") {
              const trojanData = response.data.data;
              const msg = `
    ♻️ *RENEW TROJAN PREMIUM* ♻️
  
  🔹 *Informasi Akun*
  ┌─────────────────────────────
  │ Username: \`${username}\`
  │ Kadaluarsa: \`${trojanData.exp}\`
  │ Kuota: \`${trojanData.quota}\`
  │ Batas IP: \`${trojanData.limitip} IP\`
  └─────────────────────────────
  ✅ Akun ${username} berhasil diperbarui
  ✨ Selamat menggunakan layanan kami! ✨
  `;
           
                console.log('Trojan account renewed successfully');
                return resolve(msg);
              } else {
                console.log('Error renewing Trojan account');
                return resolve(`❌ Terjadi kesalahan: ${response.data.message}`);
              }
            })
          .catch(error => {
            console.error('Error saat memperbarui Trojan:', error);
            return resolve('❌ Terjadi kesalahan saat memperbarui Trojan. Silakan coba lagi nanti.');
          });
      });
    });
  }
  async function renewshadowsocks(username, exp, quota, limitip, serverId) {
    console.log(`Renewing Shadowsocks account for ${username} with expiry ${exp} days, quota ${quota} GB, limit IP ${limitip} on server ${serverId}`);
    
    // Validasi username
    if (/\s/.test(username) || /[^a-zA-Z0-9]/.test(username)) {
      return '❌ Username tidak valid. Mohon gunakan hanya huruf dan angka tanpa spasi.';
    }
  
    // Ambil domain dari database
    return new Promise((resolve, reject) => {
      db.get('SELECT * FROM Server WHERE id = ?', [serverId], (err, server) => {
        if (err) {
          console.error('Error fetching server:', err.message);
          return resolve('❌ Server tidak ditemukan. Silakan coba lagi.');
        }
  
        if (!server) return resolve('❌ Server tidak ditemukan. Silakan coba lagi.');
  
        const domain = server.domain;
        const auth = server.auth;
        const param = `:5888/renewshadowsocks?user=${username}&exp=${exp}&quota=${quota}&iplimit=${limitip}&auth=${auth}`;
        const url = `http://${domain}${param}`;
        axios.get(url)
          .then(response => {
            if (response.data.status === "success") {
              const shadowsocksData = response.data.data;
              const msg = `
     ♻️ *RENEW SHADOWSOCKS PREMIUM* ♻️
  
  🔹 *Informasi Akun*
  ┌─────────────────────────────
  │ Username: \`${username}\`
  │ Kadaluarsa: \`${vmessData.exp}\`
  │ Kuota: \`${vmessData.quota}\`
  │ Batas IP: \`${shadowsocksData.limitip} IP\`
  └─────────────────────────────
  ✅ Akun ${username} berhasil diperbarui
  ✨ Selamat menggunakan layanan kami! ✨
  `;
           
                console.log('Shadowsocks account renewed successfully');
                return resolve(msg);
              } else {
                console.log('Error renewing Shadowsocks account');
                return resolve(`❌ Terjadi kesalahan: ${response.data.message}`);
              }
            })
          .catch(error => {
            console.error('Error saat memperbarui Shadowsocks:', error);
            return resolve('❌ Terjadi kesalahan saat memperbarui Shadowsocks. Silakan coba lagi nanti.');
          });
      });
    });
  }
  
  module.exports = { renewshadowsocks, renewtrojan, renewvless, renewvmess, renewssh };
