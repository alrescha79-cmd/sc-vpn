# 🚀 SC-VPN Validation System

Sistem validasi akses VPS untuk script SC-VPN dengan validasi IP dan masa aktif yang terintegrasi dengan GitHub.

## 📋 Features

- ✅ **Validasi IP Otomatis** - Deteksi IP publik VPS dengan multiple fallback
- ✅ **Validasi Masa Aktif** - Cek otomatis masa aktif berdasarkan data GitHub
- ✅ **Multi-Service IP Detection** - Fallback ke berbagai service IP detection
- ✅ **Error Handling yang Robust** - Pesan error yang informatif
- ✅ **Easy Installation** - Script installer otomatis
- ✅ **Backup System** - Backup otomatis sebelum update

## 🔧 Installation di VPS

### Method 1: Quick Install (Recommended)
```bash
# Download dan jalankan installer
wget -O install_validation.sh https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/install_validation.sh
chmod +x install_validation.sh
sudo bash install_validation.sh
```

### Method 2: Manual Install
```bash
# 1. Download script validasi
wget -O /usr/bin/validate_access.sh https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/project/validate_access.sh
chmod +x /usr/bin/validate_access.sh

# 2. Download menu scripts
wget -O /usr/bin/menu https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/project/menu
wget -O /usr/bin/menussh https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/project/menussh
wget -O /usr/bin/menuvmess https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/project/menuvmess
# ... dst untuk menu lainnya

# 3. Berikan permission
chmod +x /usr/bin/menu*
```

## 📝 Format Data Izin (file: izin)

File `izin` di GitHub harus menggunakan format:
```
### Username YYYY-MM-DD IP_ADDRESS
```

Contoh:
```
### user001 2025-12-31 192.168.1.100
### user002 2025-11-15 203.45.67.89
### user003 2025-10-30 123.456.789.012
```

## 🎯 Usage

### Menjalankan Menu
```bash
# Cara 1: Langsung
menu

# Cara 2: Full path
/usr/bin/menu

# Cara 3: Menu spesifik
menussh     # Menu SSH
menuvmess   # Menu VMess
menuvless   # Menu VLess
menutrojan  # Menu Trojan
menushadowsocks # Menu Shadowsocks
```

### Testing Validasi
```bash
# Test script validasi
source /usr/bin/validate_access.sh
validate_user_access --show-success
```

## 🔍 Troubleshooting

### 1. IP Tidak Terdeteksi
```bash
# Manual check IP
curl -s ipv4.icanhazip.com
curl -s api.ipify.org
```

### 2. Gagal Download dari GitHub
```bash
# Test koneksi GitHub
curl -I https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/izin
```

### 3. Permission Denied
```bash
# Fix permission
sudo chown root:root /usr/bin/validate_access.sh
sudo chmod +x /usr/bin/validate_access.sh
```

### 4. File Tidak Ditemukan
```bash
# Re-download script
sudo wget -O /usr/bin/validate_access.sh https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/project/validate_access.sh
sudo chmod +x /usr/bin/validate_access.sh
```

## 📁 File Structure di VPS

```
/usr/bin/
├── validate_access.sh      # Script validasi utama
├── menu                    # Menu utama  
├── menussh                 # Menu SSH
├── menuvmess              # Menu VMess
├── menuvless              # Menu VLess
├── menutrojan             # Menu Trojan
├── menushadowsocks        # Menu Shadowsocks
├── user                   # File username (auto-generated)
└── e                      # File expiry date (auto-generated)
```

## ⚙️ Environment Variables

Script akan otomatis menggunakan variabel berikut:
- `MYIP` - IP publik VPS yang terdeteksi
- `username` - Username dari file izin
- `valid` - Tanggal kadaluarsa dari file izin

## 🔐 Security Features

1. **IP Validation** - Hanya IP terdaftar yang bisa akses
2. **Date Validation** - Cek masa aktif otomatis
3. **Network Timeout** - Timeout untuk koneksi network
4. **Fallback System** - Multiple IP detection services
5. **Error Logging** - Log error untuk debugging

## 📞 Support

Jika mengalami masalah:

- 📱 **Telegram**: https://t.me/Alrescha79
- 📧 **Email**: anggun@cakson.my.id
- 💬 **WhatsApp**: +62-xxx-xxxx-xxxx

## 📜 Changelog

### v1.0.0 (2025-09-26)
- Initial release
- Basic IP and expiry validation
- Multiple IP detection fallback
- Automatic installer
- Menu integration

## 📄 License

Copyright © 2025 Alrescha79. All rights reserved.

---

**⚠️ PENTING**: Pastikan IP VPS sudah terdaftar di file `izin` sebelum menggunakan script ini.