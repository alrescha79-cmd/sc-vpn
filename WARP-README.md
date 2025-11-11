# Cloudflare WARP Setup Script

Script ini digunakan untuk menginstall dan mengkonfigurasi Cloudflare WARP pada VPS Ubuntu/Debian. Script akan mengalihkan semua traffic VPS melalui jaringan Cloudflare WARP untuk meningkatkan privasi dan keamanan.

## Fitur

- ✅ Instalasi otomatis Cloudflare WARP
- ✅ Konfigurasi routing untuk mengalihkan semua traffic
- ✅ Auto-start saat VPS reboot
- ✅ Management menu untuk kontrol WARP
- ✅ Support Ubuntu dan Debian
- ✅ Mode Always-On untuk koneksi persistent

## Cara Penggunaan

### Dari Menu Features

1. Jalankan menu utama VPN Panel
2. Pilih **Menu Pengaturan Sistem & Fitur**
3. Pilih opsi **[16] Setup Cloudflare WARP**
4. Ikuti instruksi instalasi

### Manual Installation

```bash
# Download script
wget https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/setup-warp.sh

# Berikan permission
chmod +x setup-warp.sh

# Jalankan script
sudo ./setup-warp.sh
```

## Sistem yang Didukung

- Ubuntu 18.04, 20.04, 22.04, 24.04
- Debian 10, 11, 12

## Fungsi Management Menu

Setelah instalasi, Anda dapat mengakses management menu dengan opsi:

1. **Status WARP** - Cek status koneksi WARP
2. **Connect WARP** - Hubungkan ke WARP
3. **Disconnect WARP** - Putuskan koneksi WARP
4. **Restart WARP** - Restart koneksi WARP
5. **Enable Always-On** - Aktifkan mode always-on
6. **Disable Always-On** - Nonaktifkan mode always-on
7. **Check IP Address** - Cek IP address (dengan/tanpa WARP)
8. **Uninstall WARP** - Hapus WARP dari sistem

## Command Line Usage

Setelah instalasi, Anda dapat menggunakan command berikut:

```bash
# Cek status
warp-cli status

# Connect
warp-cli connect

# Disconnect
warp-cli disconnect

# Enable always-on
warp-cli enable-always-on

# Disable always-on
warp-cli disable-always-on
```

## Cara Kerja

1. Script akan mendeteksi OS (Ubuntu/Debian)
2. Menginstall dependencies yang diperlukan
3. Menambahkan repository Cloudflare
4. Menginstall Cloudflare WARP client
5. Mendaftarkan device ke Cloudflare
6. Mengatur mode WARP (full VPN mode)
7. Menghubungkan ke WARP network
8. Mengkonfigurasi routing untuk semua traffic
9. Membuat systemd service untuk auto-start

## Keuntungan Menggunakan WARP

- 🔒 **Privasi Lebih Baik** - Traffic di-encrypt melalui Cloudflare network
- 🚀 **Performa Optimal** - Menggunakan infrastruktur global Cloudflare
- 🛡️ **Proteksi DDoS** - Perlindungan dari serangan DDoS
- 🌐 **Bypass Geo-Restrictions** - Akses konten yang diblokir regional
- 📊 **Traffic Routing** - Routing optimal melalui Cloudflare edge network

## Troubleshooting

### WARP tidak connect

```bash
# Cek status
warp-cli status

# Coba disconnect dan connect ulang
warp-cli disconnect
sleep 2
warp-cli connect
```

### Service tidak auto-start

```bash
# Cek service status
systemctl status warp-autoconnect.service

# Enable service
systemctl enable warp-autoconnect.service
systemctl start warp-autoconnect.service
```

### Uninstall WARP

Gunakan opsi [8] di management menu, atau jalankan:

```bash
# Disconnect WARP
warp-cli disconnect

# Disable service
systemctl disable warp-autoconnect.service

# Remove package
apt-get remove --purge cloudflare-warp

# Clean up
rm -f /etc/apt/sources.list.d/cloudflare-client.list
rm -f /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
```

## Catatan Penting

- ⚠️ Pastikan VPS memiliki koneksi internet yang stabil
- ⚠️ WARP memerlukan resources minimal (CPU & RAM)
- ⚠️ Beberapa service mungkin perlu restart setelah instalasi
- ⚠️ IP address VPS akan berubah menjadi IP Cloudflare

## Support

Untuk bantuan atau pertanyaan:
- Telegram: https://t.me/Alrescha79
- Repository: https://github.com/alrescha79-cmd/sc-vpn

## License

MIT License - Lihat file LICENSE untuk detail
