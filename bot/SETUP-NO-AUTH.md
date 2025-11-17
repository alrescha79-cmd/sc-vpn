# 🔧 Setup Bot Tanpa Auth Panel

Bot ini sekarang **tidak memerlukan auth/API key** dari panel management. Bot akan langsung mengeksekusi script ke server VPN.

## ✅ Perubahan yang Sudah Dibuat:

1. **Auth menjadi opsional/dummy** - Saat add server, auth otomatis diset ke `no-auth-required`
2. **Semua modules diupdate** - Parameter `&auth=` dihapus dari URL API
3. **Langsung eksekusi script** - Bot menggunakan SSH langsung ke server

## 🚀 Cara Menggunakan:

### 1. Setup Server VPN
```bash
# Di server VPN, jalankan setup.sh
bash <(curl -sL https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/main/setup.sh)
```

### 2. Jalankan Bot
```bash
cd /home/son/Projects/sc-vpn/bot
node app.js
```

### 3. Add Server via Bot
```
/addserver
- Domain: vpn1.example.com
- Nama Server: SG Premium
- Quota: 50
- IP Limit: 2
- Batas Create: 100
- Harga: 1000
```

**Auth akan otomatis diset sebagai dummy, tidak perlu input!**

## 📋 Update Server yang Sudah Ada:

Jika sudah punya server di database dengan auth lama:

```bash
cd /home/son/Projects/sc-vpn/bot
./setup-auth-dummy.sh
```

## 🔍 Verifikasi:

```bash
# Cek database
sqlite3 sellvpn.db "SELECT id, domain, auth, nama_server FROM Server;"

# Semua auth harus berisi 'no-auth-required'
```

## 📝 Notes:

- ✅ Tidak perlu install panel management (X-UI, 3X-UI, dll)
- ✅ Bot langsung SSH ke server dan eksekusi script
- ✅ Setup lebih sederhana dan ringan
- ⚠️ Pastikan port SSH (22) terbuka di firewall
- ⚠️ Pastikan bot bisa SSH ke server tanpa password (gunakan SSH key)

## 🔐 SSH Key Setup (Opsional tapi Direkomendasikan):

```bash
# Generate SSH key di server bot
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Copy ke server VPN
ssh-copy-id root@IP_SERVER_VPN

# Test koneksi
ssh root@IP_SERVER_VPN "echo 'SSH OK'"
```

Dengan SSH key, bot bisa otomatis akses server tanpa input password!
