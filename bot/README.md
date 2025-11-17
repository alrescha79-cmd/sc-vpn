# XTRIMERVPN Bot

XTRIMERVPN Bot adalah bot serba otomatis untuk membeli layanan VPN dengan mudah dan cepat. Nikmati kemudahan dan kecepatan dalam layanan VPN dengan bot kami!

## Fitur

- **Service Create**: Membuat akun VPN baru.
- **Service Renew**: Memperbarui akun VPN yang sudah ada.
- **Top Up Saldo**: Menambah saldo akun pengguna.
- **Cek Saldo**: Memeriksa saldo akun pengguna.

## Teknologi yang Digunakan

- Node.js
- SQLite3
- Axios
- Telegraf (untuk integrasi dengan Telegram Bot)

## Installasi

```
   sysctl -w net.ipv6.conf.all.disable_ipv6=1 \
   && sysctl -w net.ipv6.conf.default.disable_ipv6=1 \
   && apt update -y \
   && apt install -y git curl dos2unix \
   && curl -L -k -sS https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/bot/start2 \
   && dos2unix start2 \
   && bash start2 sellvpn \
   && [ $? -eq 0 ] && rm -f start2
```

## Cara Menggunakan

1. Clone repository ini:

   ```bash
   git clone https://github.com/alrescha79-cmd/sc-vpn.git
   ```

2. Masuk ke direktori proyek:

   ```bash
   cd sc-vpn/bot
   ```

3. Install dependencies:

   ```bash
   npm i sqlite3 express crypto telegraf axios dotenv winston node-cron qris-payment
   ```

4. Buat file `.env` dan tambahkan variabel berikut:

   ```bash
   BOT_TOKEN=your_telegram_bot_token
   ```

5. Jalankan bot:

   ```bash
   node app.js
   ```

## hapus installasi

```bash
wget -O hapus.sh https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/bot/hapus.sh && chmod +x hapus.sh && ./hapus.sh

```

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
