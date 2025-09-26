# ⚡ Installer Otomatis Panel VPN (Xray, OVPN, SSH, SlowDNS)

![Panel VPN Auto Installer: Xray | OVPN | SSH | SlowDNS](https://readme-typing-svg.demolab.com?font=Capriola&size=40&duration=4000&pause=450&color=F70069&background=FFFFAA00&center=true&random=false&width=600&height=100&lines=Panel+VPN+Auto+Installer;Xray+%7C+OVPN+%7C+SSH+%7C+SlowDNS)

Script ini membantu Anda memasang layanan SSH / VPN multi-protokol (VMess, VLESS, Trojan, Shadowsocks, SlowDNS, dsb) secara otomatis disertai utilitas manajemen akun dan API sederhana.

---

## 📋 Daftar Isi

- [Persiapan](#-persiapan)
- [Instalasi](#-instalasi)
- [Cara Penggunaan](#cara-penggunaan)
- [Fitur](#-fitur)
- [Protokol Didukung](#-protokol-didukung)
- [Manajemen API](#-manajemen-api)
- [Perintah Manajemen Akun](#-perintah-manajemen-akun)
- [Konfigurasi Auto Reboot](#-konfigurasi-auto-reboot)
- [Kebutuhan Sistem](#️-kebutuhan-sistem)
- [Dukungan](#-dukungan)
- [Lisensi](#-lisensi)

---

## 📦 Persiapan

1. **VPS dengan Akses Root**  
   Pastikan Anda memiliki VPS dengan akses root. VPS harus memiliki akses IPv4 publik.
2. **Sistem Operasi**  
   Sistem operasi yang didukung:
   - Ubuntu 20.04, 22.04, 24.04
   - Debian 10, 11
   - Lainnya (belum diuji, gunakan dengan risiko sendiri)
3. **Domain dan Subdomain**
   Harus memiliki domain/subdomain yang mengarah ke IP VPS Anda (A record). Contoh: `vpn.example.com`
4. **Akun Cloudflare (Opsional)**
    Jika menggunakan Cloudflare, pastikan proxy dimatikan (ikon awan abu-abu) untuk domain/subdomain yang digunakan.
5. **Akses ke Script**
  Pastikan Anda memiliki akses ke script ini (IP dan tengggat waktu) yang didaftarkan.
  Hubungi saya di Telegram: [@Alrescha79](https://t.me/Alrescha79) untuk informasi lebih lanjut.

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
apt-get --reinstall --fix-missing install -y whois bzip2 gzip coreutils wget screen nscd build-essential&& \
wget --inet4-only --no-check-certificate -O setup.sh https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/setup.sh && \
chmod +x setup.sh && \
screen -S setup ./setup.sh
```

### ⚠️ Informasi Penting

- Jika saat proses instalasi (Langkah 1) sesi terminal terputus, jangan jalankan ulang perintah instalasi dari awal. Cukup masuk kembali dan jalankan:
  ```bash
  screen -r setup
  ```
- Jika `screen -r setup` tidak ada atau tidak berfungsi, jalankan ulang setup dengan perintah:
  ```bash
  ./setup.sh
  ```
- Log instalasi dapat dilihat di:
  ```
  /root/syslog.log
  ```

---

## Cara Penggunaan

Setelah instalasi selesai, Anda dapat menggunakan perintah berikut untuk mengakses menu utama jika tidak otomatis muncul:

```bash
menu
```

## ✨ Fitur

- Instalasi otomatis layanan SSH / VPN multi-protokol.
- Mendukung beberapa protokol (Shadowsocks, Trojan, VLESS, VMess, dll).
- Pembuatan, perpanjangan, pengecekan, dan penghapusan akun.
- Opsi auto reboot via cron (manual, tidak dipasang default).
- Arsitektur modular — mudah dikembangkan / ditambah.
- Antarmuka backup & restore berbasis web (bila tersedia dalam build Anda).
- Optimasi jaringan (misal BBR congestion control).
- Sistem akun trial.
- REST API berbasis Go (opsional) untuk automasi manajemen akun.

---

## 🔌 Protokol Didukung

1. **SSH** – Akses aman shell & tunneling dasar.
2. **VMess** – Protokol terenkripsi berperforma tinggi (Xray / V2Ray).
3. **VLESS** – Generasi penerus VMess dengan desain lebih ringan.
4. **Trojan** – Menyamarkan trafik menjadi HTTPS.
5. **Shadowsocks** – Proxy terenkripsi ringan untuk bypass & optimasi rute.

---

## 🌐 Manajemen API

Skrip menyediakan instalasi REST API (Go) untuk automasi manajemen akun.

### Instalasi API

```bash
wget https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/golang/rest-go.sh
chmod +x rest-go.sh
bash rest-go.sh
```

Setelah terpasang:

- Binary / service biasanya ditempatkan di `/usr/local/bin` atau direktori yang ditentukan skrip.
- Pastikan port API tidak diblok firewall (contoh: `ufw allow <PORT>` bila memakai UFW).
- Untuk keamanan, pasang reverse proxy + limit akses (misal iptables / fail2ban).

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

Secara default TIDAK dipasang. Jika ingin menyalakan auto reboot harian pukul 04:00:

```bash
crontab -l > /tmp/cron.txt
sed -i "/reboot$/d" /tmp/cron.txt
echo -e "\n"'0 4 * * * '"$(which reboot)" >> /tmp/cron.txt
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

## 🖥️ Kebutuhan Sistem

### Sistem Operasi Didukung

![Ubuntu 20.04](https://img.shields.io/badge/Ubuntu-20.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Ubuntu 22.04](https://img.shields.io/badge/Ubuntu-22.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Debian 10](https://img.shields.io/badge/Debian-10-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![Debian 11](https://img.shields.io/badge/Debian-11-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![Other Distros](https://img.shields.io/badge/Other-Distros-4D4D4D?style=for-the-badge&logo=linux&logoColor=white)

### Sistem Operasi yang Telah Diuji

![Ubuntu 22.04](https://img.shields.io/badge/Ubuntu-22.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)

### Paket Wajib

- whois
- bzip2
- gzip
- coreutils
- wget
- screen
- nscd

Pastikan VPS Anda:

- Akses IPv4 publik
- Storage bebas cukup (≥ 2 GB disarankan)
- RAM minimal 512 MB (lebih tinggi lebih stabil untuk multi-protokol)

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
