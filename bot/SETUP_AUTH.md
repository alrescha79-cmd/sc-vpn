# 🔐 Setup Auth sebagai Password Root VPS

## ✅ Perubahan yang Dilakukan

Bot sekarang menggunakan **SSH connection** langsung ke server VPN untuk menjalankan script, tanpa memerlukan API HTTP (port 5888).

### 📝 Apa itu "auth"?

**`auth`** = **Password root VPS** tempat VPN server diinstall.

Bot akan:
1. SSH ke server dengan `root@domain` menggunakan password dari kolom `auth`
2. Menjalankan command seperti: `addsh`, `addvmess`, `addvless`, `addtrojan`, `addshadowsocks`
3. Mendapatkan output dari script tersebut
4. Format dan kirim ke user via Telegram

---

## 🚀 Cara Menggunakan

### 1. Install Dependencies

```bash
cd /home/son/Projects/sc-vpn/bot
npm install ssh2
```

### 2. Restart Bot

```bash
pm2 restart sellvpn
pm2 logs sellvpn
```

### 3. Tambah Server

Di bot Telegram:
```
/addserver

Domain/IP: vpn1.example.com
Password Root VPS: YourRootPassword123
Nama Server: SG Premium
Quota: 50
IP Limit: 2
Batas Create: 100
Harga: 1000
```

### 4. Test Create Akun

```
/create
→ Pilih SSH/VMESS/VLESS/Trojan
→ Pilih Server
→ Isi username, password, exp, dll
```

---

## 🔧 Requirement Server VPN

Server VPN **HARUS** sudah punya script berikut terinstall:

- `/usr/bin/addsh` - Create SSH account
- `/usr/bin/addvmess` - Create VMESS account  
- `/usr/bin/addvless` - Create VLESS account
- `/usr/bin/addtrojan` - Create Trojan account
- `/usr/bin/addshadowsocks` - Create Shadowsocks account

Script ini biasanya sudah terinstall otomatis jika Anda menggunakan [`setup.sh`](/home/son/Projects/sc-vpn/setup.sh).

---

## 🔐 Security Notes

⚠️ **PENTING:**

1. **Password root disimpan di database** - Pastikan file `sellvpn.db` aman
2. **Gunakan password yang kuat** untuk root VPS
3. **Backup database** secara berkala
4. **Restrict SSH access** hanya dari IP bot server

### Cara Restrict SSH:

Di server VPN, edit `/etc/ssh/sshd_config`:

```bash
# Hanya izinkan dari IP bot server
AllowUsers root@IP_BOT_SERVER

# Atau gunakan firewall
ufw allow from IP_BOT_SERVER to any port 22
```

---

## 📋 Files yang Diubah

1. **`bot/app.js`**
   - Line 4037: Prompt berubah dari "auth server" → "password root VPS"
   - Line 4042: Validasi berubah

2. **`bot/modules/createSSH.js`**
   - Menggunakan `ssh2` library
   - Connect ke server via SSH
   - Eksekusi command `addsh`

3. **`bot/modules/createVMESS.js`**
   - Menggunakan `ssh2` library
   - Connect ke server via SSH
   - Eksekusi command `addvmess`

---

## 🐛 Troubleshooting

### Error: "Gagal koneksi SSH ke server"

**Penyebab:**
- Password root salah
- SSH port bukan 22
- Firewall block koneksi
- Server offline

**Solusi:**
```bash
# Test SSH manual dari bot server
ssh root@vpn1.example.com

# Cek firewall di VPS
ufw status

# Cek SSH service
systemctl status ssh
```

### Error: "Gagal eksekusi command SSH"

**Penyebab:**
- Script `addsh`, `addvmess` dll tidak terinstall
- Script tidak executable

**Solusi:**
```bash
# Cek apakah script ada
which addsh addvmess addvless addtrojan

# Install ulang script dari setup.sh
cd /home/son/Projects/sc-vpn
bash setup.sh

# Atau buat script executable
chmod +x /usr/bin/addsh /usr/bin/addvmess /usr/bin/addvless /usr/bin/addtrojan
```

### Error: "Promise timed out"

**Penyebab:**
- Script terlalu lama eksekusi (>30 detik)
- Koneksi SSH lambat

**Solusi:**
```bash
# Increase timeout di modules/*.js
# Ubah readyTimeout dari 30000 → 60000

.connect({
  host: server.domain,
  port: 22,
  username: 'root',
  password: server.auth,
  readyTimeout: 60000  // 60 detik
});
```

---

## ✅ Testing

### 1. Test SSH Connection Manual

```bash
# Dari bot server, test SSH ke VPN server
ssh root@vpn1.example.com "addsh testuser testpass123 1 1"
```

### 2. Test via Bot

```
/create
→ SSH
→ Pilih server
→ Username: testuser
→ Password: testpass123
→ Exp: 1
→ IP Limit: 1
```

### 3. Check Logs

```bash
pm2 logs sellvpn --lines 100
```

---

## 📚 Next Steps

Jika semua berjalan lancar:

1. ✅ Update modules lainnya (VLESS, Trojan, Shadowsocks)
2. ✅ Implement untuk renew akun
3. ✅ Implement untuk trial
4. ✅ Add logging untuk audit trail
5. ✅ Encrypt password di database

---

## 🔗 Related Files

- [`bot/app.js`](/home/son/Projects/sc-vpn/bot/app.js) - Main bot logic
- [`bot/modules/createSSH.js`](/home/son/Projects/sc-vpn/bot/modules/createSSH.js) - SSH creation
- [`bot/modules/createVMESS.js`](/home/son/Projects/sc-vpn/bot/modules/createVMESS.js) - VMESS creation
- [`setup.sh`](/home/son/Projects/sc-vpn/setup.sh) - VPN server setup script

---

**✨ By: Alrescha79 | Updated: 2025-11-17**
