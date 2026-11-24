# ⚡ Installer Otomatis Panel VPN (Xray, OVPN, SSH, SlowDNS)

![Panel VPN Auto Installer: Xray | OVPN | SSH | SlowDNS](https://readme-typing-svg.demolab.com?font=Capriola&size=40&duration=4000&pause=450&color=F70069&background=FFFFAA00&center=true&random=false&width=600&height=100&lines=Panel+VPN+Auto+Installer;Xray+%7C+OVPN+%7C+SSH+%7C+SlowDNS)

Script ini membantu Anda memasang layanan SSH / VPN multi-protokol (VMess, VLESS, Trojan, Shadowsocks, SlowDNS, dsb) secara otomatis disertai utilitas manajemen akun.

---

## 📋 Daftar Isi

- [Persiapan](#-persiapan)
- [Instalasi](#-instalasi)
- [Informasi Penting](#️-informasi-penting)
- [Setup Notifikasi Telegram](#setup-notifikasi-telegram)
- [Perintah Manajemen Akun](#-perintah-manajemen-akun)
- [Konfigurasi Auto Reboot](#-konfigurasi-auto-reboot)
- [Setting Domain/Subdomain Support Wildcard di Cloudflare](#setting-domainsubdomain-support-wildcard-di-cloudflare)
- [Dukungan](#-dukungan)
- [Lisensi](#-lisensi)

---

## 📦 Persiapan

1. **VPS dengan Akses Root**  
   Pastikan Anda memiliki VPS dengan `akses root`. VPS harus memiliki akses `IPv4 publik`.
2. **Sistem Operasi**  
   Sistem operasi yang didukung:
   - Ubuntu 20.04, `22.04`, 24.04
   - Debian 10, `11`, 12
   - Lainnya (belum diuji, gunakan dengan risiko sendiri)
3. **Domain dan Subdomain**  
   Harus memiliki domain/subdomain yang mengarah ke `IP VPS Anda` (A record). Contoh: `vpn.example.com`
4. **Akun Cloudflare (Opsional)**  
    Jika menggunakan Cloudflare, pastikan proxy dimatikan (ikon awan abu-abu) untuk domain/subdomain yang digunakan.
5. **Gratis & Open Source**  
   Script ini bersifat open source dan gratis. Tidak ada registrasi IP atau lisensi yang diperlukan untuk melakukan instalasi.

---

## 🚀 Instalasi

### Ganti ke User Root

```bash
sudo -i
```

atau:

```bash
sudo su
```

### Langkah 1: Jalankan Setup Script

```bash
apt-get update && \
apt-get --reinstall --fix-missing install -y whois bzip2 gzip coreutils wget screen nscd build-essential && \
wget --inet4-only --no-check-certificate -O setup.sh https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/setup.sh && \
chmod +x setup.sh && \
screen -S setup ./setup.sh
```

### ⚠️ Informasi Penting

Jika saat proses instalasi (Langkah 1) sesi terminal terputus, jangan jalankan ulang perintah instalasi dari awal. Cukup masuk kembali dan jalankan:

- Pastikan file `setup.sh` sudah tersimpan di `/root/setup.sh`.

  ```bash
  ls
  ```

- Jika ada, lanjutkan dengan menjalankan:

  ```bash
  ./setup.sh
  ```

- Masukkan `Domain/Subdomain` yang valid (A record mengarah ke IP VPS) saat diminta.
- Setelah reboot, menu utama akan otomatis muncul. Jika tidak, jalankan perintah:

  ```bash
  menu
  ```
  
- Jika tidak bisa masuk ke `opsi (8) Menu Features`, keluar dari `menu` dengan `CTRL  C`. Kemudian jalankan perintah:

  ```bash
  curl -o /usr/bin/features https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/project/features
  ```

- Jika ada masalah, silakan hubungi saya di Telegram: [@Alrescha79](https://t.me/Alrescha79)

---

## Setup Notifikasi Telegram

> [!NOTE]  
> Pastikan Anda sudah membuat bot Telegram dan mendapatkan `Token Bot` serta `Chat ID` Anda. [Cara membuat BOT Telegram dan mendapatkan Chat ID](https://gist-github-com.translate.goog/nafiesl/4ad622f344cd1dc3bb1ecbe468ff9f8a?_x_tr_sl=en&_x_tr_tl=id&_x_tr_hl=id&_x_tr_pto=tc)

Pastikan Anda berada di menu utama, jika tidak, jalankan perintah `menu`.

![Telegram Notification Setup](img/menu-utama.png)

1. Pilih opsi `6` untuk setup notifikasi Telegram.
2. Konfirmasi dengan `y` (Yes) jika ingin melanjutkan dan `n` (No) untuk membatalkan.
![Telegram Setup](img/setuptele.png)
3. Masukkan `Token Bot` Telegram Anda.
4. Masukkan `Chat ID` Telegram Anda.
5. Klik `Enter` untuk melanjutkan, notifikasi akan berjalan otomatis.

---

## 🧩 Perintah Manajemen Akun

Perintah-perintah berikut (di-install oleh `package-gohide.sh` atau bagian setup) tersedia di `/usr/local/bin/`:

### Pembuatan Akun

- `add-vmess` – Membuat akun VMess
- `add-vless` – Membuat akun VLESS
- `add-trojan` – Membuat akun Trojan
- `add-shadowsocks` – Membuat akun Shadowsocks
- `add-ssh` – Membuat akun SSH

### Penghapusan Akun

- `del-vmess`
- `del-vless`
- `del-trojan`
- `del-shadowsocks`
- `del-ssh`

### Pengecekan Akun

- `check-vmess`
- `check-vless`
- `check-trojan`
- `check-shadowsocks`
- `check-ssh`

### Perpanjangan Akun

- `renew-vmess`
- `renew-vless`
- `renew-trojan`
- `renew-shadowsocks`
- `renew-ssh`

> Gunakan `bash /usr/local/bin/add-vmess` (contoh) bila environment PATH bermasalah.

---

## ⏰ Konfigurasi Auto Reboot

Secara default auto reboot harian pukul 05:00. Jika ingin mengubah jadwal atau menonaktifkannya, ikuti langkah berikut:

### Menambahkan Auto Reboot menggunakan Menu

1. Pastikan Anda berada di menu utama, jika tidak, jalankan perintah `menu`.
2. Pilih opsi `8` untuk masuk ke menu pengaturan sistem.
![Menu Sistem](img/pengaturan.png)
3. Pilih `12` masuk ke menu pengaturan auto reboot.
![Menu Auto Reboot](img/set-jam.png)
4. Pilih `1` untuk mengubah/menambahkan jadwal auto reboot.
5. Masukkan jam dalam format 24 jam (HH:MM), contoh `02:00` untuk setiap jam 2 pagi.
6. Pilih `y` untuk menyimpan perubahan.
7. `Enter` untuk kembali ke menu pengaturan sistem.

### Menambahkan Auto Reboot menggunakan Crontab

pastikan Anda tidak berada di `menu` utama, jika tidak, jalankan perintah `Ctrl C` untuk keluar dari menu utama, lalu jalankan perintah berikut:

```bash
crontab -l > /tmp/cron.txt
sed -i "/reboot$/d" /tmp/cron.txt
echo -e "\n"'0 5 * * * '"$(which reboot)" >> /tmp/cron.txt
crontab /tmp/cron.txt
rm -rf /tmp/cron.txt
```

### Membatalkan Auto Reboot

```bash
crontab -l > /tmp/cron.txt
sed -i "/reboot$/d" /tmp/cron.txt
crontab /tmp/cron.txt
rm -rf /tmp/cron.txt
```

---

## Hostname Bertingkat dan Sertifikat Wildcard Cloudflare

Contoh hostname bertingkat: `bug.com.vpn.example.com`. Record `*.vpn.example.com` dapat mengarah ke VPS, tetapi sertifikat `*.vpn.example.com` **tidak** mencakup nama bertingkat itu. Daftarkan setiap hostname agar sertifikat mencantumkan nama tersebut secara eksplisit.

### DNS Cloudflare

1. Buat A record `vpn` dengan alamat IPv4 VPS.
2. Buat A record `*.vpn` dengan alamat IPv4 VPS untuk hostname turunannya.
3. Gunakan `DNS only` untuk koneksi langsung ke VPS. Record spesifik dapat diperlukan jika ada DNS record lebih spesifik yang mengalahkan wildcard.

### Daftarkan hostname

1. Buat Cloudflare API Token khusus zona dengan izin `Zone:DNS:Edit` dan `Zone:Zone:Read`.
2. Pastikan VPS dapat mencapai Cloudflare API dan port 443 VPS tidak memblokir validasi ACME HTTP-01 saat instalasi awal.
3. Buka menu `Features` lalu pilih `15. Kelola Hostname Bertingkat`.
4. Tambahkan nama lengkap, misalnya `bug.com.vpn.example.com`. Token diminta saat penerbitan sertifikat, tidak disimpan oleh pengelola.
5. Menu memperbarui sertifikat melalui DNS-01. Setiap nama terdaftar ditambahkan sebagai SAN sertifikat; hapus hostname lalu terbitkan ulang untuk menghapusnya.

Sertifikat memuat semua nama terdaftar. Let’s Encrypt membatasi jumlah SAN per sertifikat dan penerbitan berulang; daftarkan nama seperlunya. Penghapusan daftar lokal tidak mencabut sertifikat yang sudah diterbitkan.

![Screenshot Cloudflare DNS](img/wc.png)

---

## 🆘 Dukungan

Butuh bantuan / melaporkan bug:

[![Telegram: Klik di Sini](https://img.shields.io/badge/Telegram-Klik%20Di%20Sini-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/Alrescha79)
[![Email: Klik di Sini](https://img.shields.io/badge/Email-Klik%20Di%20Sini-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:anggun@cakson.my.id)

---

## 📜 Lisensi

Proyek ini dilisensikan di bawah MIT License - lihat berkas [LICENSE](./LICENSE).

Copyright © 2025 [Alrescha79](https://github.com/alrescha79-cmd)

---
