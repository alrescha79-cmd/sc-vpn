# VPN Panel Uninstaller

Script uninstaller untuk menghapus semua komponen yang diinstal oleh **Alrescha79 VPN Panel**.

## 📋 Daftar Isi

- [Fitur](#fitur)
- [File Script](#file-script)
- [Cara Penggunaan](#cara-penggunaan)
- [Yang Dihapus](#yang-dihapus)
- [Backup](#backup)
- [Peringatan](#peringatan)

## ✨ Fitur

- **Uninstall Lengkap**: Menghapus semua komponen VPN Panel
- **Backup Otomatis**: Opsi backup sebelum uninstall
- **Progress Tracking**: Menampilkan progress real-time
- **Konfirmasi Keamanan**: Meminta konfirmasi sebelum eksekusi
- **Clean Removal**: Menghapus files, services, dan konfigurasi

## 📁 File Script

### 1. `uninstall.sh`
Script utama untuk uninstall VPN Panel

### 2. `backup-before-uninstall.sh`
Script backup konfigurasi sebelum uninstall (opsional)

## 🚀 Cara Penggunaan

### Opsi 1: Uninstall Langsung
```bash
# Download dan jalankan uninstaller
wget https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/dev/uninstall.sh
chmod +x uninstall.sh
sudo ./uninstall.sh
```

### Opsi 2: Backup + Uninstall
```bash
# Download script backup
wget https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/dev/backup-before-uninstall.sh
chmod +x backup-before-uninstall.sh

# Jalankan backup (akan otomatis lanjut ke uninstall)
sudo ./backup-before-uninstall.sh
```

### Opsi 3: Dari Repository
```bash
# Clone repository
git clone https://github.com/alrescha79-cmd/sc-vpn.git
cd sc-vpn

# Jalankan uninstaller
sudo ./uninstall.sh

# Atau dengan backup
sudo ./backup-before-uninstall.sh
```

## 🗑️ Yang Dihapus

### Services
- ✅ Xray (VMess, VLess, Trojan, Shadowsocks)
- ✅ OpenVPN
- ✅ HAProxy
- ✅ Nginx
- ✅ Dropbear SSH
- ✅ WebSocket
- ✅ UDP Custom
- ✅ BadVPN
- ✅ Limit IP/Quota services

### Konfigurasi
- ✅ `/etc/xray/` - Semua konfigurasi Xray
- ✅ `/etc/openvpn/` - Konfigurasi OpenVPN
- ✅ `/etc/haproxy/haproxy.cfg` - Konfigurasi HAProxy
- ✅ `/etc/nginx/conf.d/xray.conf` - Konfigurasi Nginx
- ✅ `/etc/ssh/sshd_config` - Konfigurasi SSH
- ✅ `/etc/default/dropbear` - Konfigurasi Dropbear

### Database & Logs
- ✅ Database pengguna (VMess, VLess, Trojan, SSH, Shadowsocks)
- ✅ Log files Xray
- ✅ Setup logs
- ✅ Access logs

### Sertifikat
- ✅ SSL certificates (Let's Encrypt)
- ✅ HAProxy certificates
- ✅ ACME certificates

### Binary & Scripts
- ✅ Menu scripts (`add-*`, `del-*`, `check-*`, `renew-*`)
- ✅ Gotop monitoring tool
- ✅ UDP custom binary
- ✅ BadVPN binary
- ✅ WebSocket script

### System Configuration
- ✅ Systemd service files
- ✅ Cron jobs
- ✅ IPTables rules
- ✅ Sysctl configurations
- ✅ Security limits
- ✅ Swap file (jika dibuat oleh setup)

### Repository
- ✅ Nginx repository
- ✅ HAProxy repository
- ✅ Repository keys

## 💾 Backup

Script `backup-before-uninstall.sh` akan membuat backup berisi:

- 📁 **Konfigurasi**: Semua file konfigurasi VPN
- 🗃️ **Database**: Database pengguna semua service
- 🔒 **Sertifikat**: SSL certificates dan keys
- ⚙️ **System**: Systemd services dan cron jobs
- 📊 **Logs**: Log files terbaru
- 📝 **Info**: Detail backup dan instruksi restore

**Lokasi Backup**: `/root/vpn_backup_YYYYMMDD_HHMMSS.tar.gz`

## ⚠️ Peringatan

### 🚨 PENTING - BACA SEBELUM MENGGUNAKAN

1. **TIDAK DAPAT DIBATALKAN**: Proses uninstall tidak dapat dibatalkan setelah dijalankan
2. **BACKUP DULU**: Selalu buat backup sebelum uninstall jika Anda ingin restore nanti
3. **ROOT ACCESS**: Script harus dijalankan dengan privilese root
4. **DOWNTIME**: Server VPN akan tidak dapat diakses setelah uninstall
5. **DATA HILANG**: Semua data pengguna dan konfigurasi akan terhapus

### 🔒 Keamanan

- Script meminta konfirmasi eksplisit sebelum eksekusi
- Menampilkan daftar lengkap yang akan dihapus
- Progress tracking untuk monitoring proses
- Error handling untuk mencegah kerusakan sistem

### 🖥️ Kompatibilitas

- ✅ Ubuntu 18.04, 20.04, 22.04, 24.04
- ✅ Debian 10, 11, 12
- ✅ Tested dengan Alrescha79 VPN Panel setup script

## 🔄 Restore dari Backup

Jika Anda memiliki backup dan ingin restore:

1. **Install VPN Panel baru** di server target
2. **Stop semua services**:
   ```bash
   systemctl stop vmess@config vless@config trojan@config shadowsocks@config
   systemctl stop haproxy nginx openvpn dropbear
   ```
3. **Extract backup**:
   ```bash
   tar -xzf vpn_backup_YYYYMMDD_HHMMSS.tar.gz
   cd vpn_backup_YYYYMMDD_HHMMSS
   ```
4. **Copy konfigurasi**:
   ```bash
   cp -r etc/xray/* /etc/xray/
   cp -r etc/openvpn/* /etc/openvpn/
   # Copy konfigurasi lainnya sesuai kebutuhan
   ```
5. **Restart services**:
   ```bash
   systemctl restart vmess@config vless@config trojan@config shadowsocks@config
   systemctl restart haproxy nginx openvpn
   ```

## 📞 Support

Jika mengalami masalah:

- 💬 **Telegram**: [@Alrescha79](https://t.me/Alrescha79)
- 📧 **Email**: anggun@cakson.my.id
- 🐛 **Issues**: [GitHub Issues](https://github.com/alrescha79-cmd/sc-vpn/issues)

## 📄 Lisensi

Copyright (C) 2024 Alrescha79. All rights reserved.

---

**⚡ Quick Commands:**

```bash
# Uninstall only
wget -O uninstaller.sh https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/dev/uninstall.sh && chmod +x uninstaller.sh && sudo ./uninstaller.sh

# Backup + Uninstall
wget -O backup-uninstall.sh https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/dev/backup-before-uninstall.sh && chmod +x backup-uninstall.sh && sudo ./backup-uninstall.sh
```