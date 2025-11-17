# XTRIMERVPN Bot

XTRIMERVPN Bot adalah bot serba otomatis untuk membeli layanan VPN dengan mudah dan cepat. Nikmati kemudahan dan kecepatan dalam layanan VPN dengan bot kami!

## ✨ Update Terbaru - No Auth Required!

**Auth sekarang opsional!** Bot tidak lagi memerlukan API Key/Auth dari panel management (X-UI, 3X-UI, dll). Bot akan langsung mengeksekusi script ke server VPN.

### Keuntungan:
- ✅ Setup lebih sederhana
- ✅ Tidak perlu install panel management
- ✅ Auth otomatis diset sebagai dummy
- ✅ Langsung SSH ke server
- ✅ Lebih ringan dan cepat

## Fitur

- **Service Create**: Membuat akun VPN baru (SSH, VMESS, VLESS, Trojan, Shadowsocks).
- **Service Renew**: Memperbarui akun VPN yang sudah ada.
- **Top Up Saldo**: Menambah saldo akun pengguna.
- **Cek Saldo**: Memeriksa saldo akun pengguna.
- **Multi Role**: Admin, Reseller, User dengan komisi otomatis.
- **QRIS Payment**: Integrasi pembayaran QRIS otomatis.

## Teknologi yang Digunakan

- Node.js
- SQLite3
- Telegraf (Telegram Bot)
- Express (REST API)
- QRIS Payment Gateway

## 🚀 Quick Start

### 1. Installasi Otomatis

```bash
sysctl -w net.ipv6.conf.all.disable_ipv6=1 \
&& sysctl -w net.ipv6.conf.default.disable_ipv6=1 \
&& apt update -y \
&& apt install -y git curl dos2unix \
&& curl -L -k -sS -o start2 https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/bot/start2 \
&& dos2unix start2 \
&& chmod +x start2 \
&& bash start2 sellvpn \
&& [ $? -eq 0 ] && rm -f start2
```

### 2. Installasi Manual

1. Clone repository:

   ```bash
   git clone https://github.com/alrescha79-cmd/sc-vpn.git
   cd sc-vpn/bot
   ```

2. Install dependencies:

   ```bash
   npm i sqlite3 express crypto telegraf axios dotenv winston node-cron qris-payment form-data
   ```

3. Setup konfigurasi `.vars.json`:

   ```json
   {
     "BOT_TOKEN": "YOUR_BOT_TOKEN_FROM_BOTFATHER",
     "USER_ID": "YOUR_TELEGRAM_USER_ID",
     "GROUP_ID": "YOUR_GROUP_ID",
     "NAMA_STORE": "Your Store Name",
     "PORT": "50123",
     "DATA_QRIS": "your_qris_data",
     "MERCHANT_ID": "your_merchant_id",
     "API_KEY": "your_api_key"
   }
   ```

   **Cara mendapatkan:**
   - `BOT_TOKEN`: Chat [@BotFather](https://t.me/BotFather) di Telegram
   - `USER_ID`: Chat [@userinfobot](https://t.me/userinfobot)
   - `GROUP_ID`: Tambahkan @userinfobot ke grup Anda

4. Set user pertama sebagai admin:

   ```bash
   sqlite3 sellvpn.db "UPDATE users SET role='admin' WHERE user_id=YOUR_USER_ID;"
   ```

5. Jalankan bot:

   ```bash
   ./start.sh
   # atau
   node app.js
   ```

## 📝 Cara Menggunakan

### Admin:
- `/start` - Memulai bot
- `/admin` - Panel admin
- `/addserver` - Tambah server (**AUTH OTOMATIS DUMMY!**)
- `/listserver` - Lihat daftar server
- `/broadcast` - Broadcast pesan ke semua user
- `/addreseller` - Tambah reseller baru

### Reseller:
- `/reseller` - Panel reseller
- `/create` - Buat akun VPN
- `/renew` - Perpanjang akun
- `/check` - Cek status akun

### User:
- `/start` - Memulai bot
- `/balance` - Cek saldo
- `/topup` - Topup saldo via QRIS

## 🗑️ Uninstall

```bash
wget -O hapus.sh https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/bot/hapus.sh && chmod +x hapus.sh && ./hapus.sh
```

## 📚 Dokumentasi Lengkap

- [SETUP-NO-AUTH.md](SETUP-NO-AUTH.md) - Setup tanpa auth panel
- [QUICK-REFERENCE.txt](QUICK-REFERENCE.txt) - Quick reference commands

## Struktur Proyek

- `app.js`: File utama yang mengatur bot dan server.
- `modules/create.js`: Modul untuk membuat akun VPN baru.
- `modules/renew.js`: Modul untuk memperbarui akun VPN yang sudah ada.
- `sellvpn.db`: Database SQLite yang menyimpan data pengguna dan server.

## Kontribusi

Jika Anda ingin berkontribusi pada proyek ini, silakan fork repository ini dan buat pull request dengan perubahan yang Anda usulkan.

## Kontak

Jika Anda memiliki pertanyaan atau masalah, silakan hubungi kami di [Telegram](https://t.me/otakkosong).

✨ Selamat menggunakan layanan kami! ✨
