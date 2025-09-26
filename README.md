# ⚡ Panel VPN Auto Installer (Xray / OVPN / SSH / SlowDNS)

![Panel VPN Auto Installer: Xray | OVPN | SSH | SlowDNS](https://readme-typing-svg.demolab.com?font=Capriola&size=40&duration=4000&pause=450&color=F70069&background=FFFFAA00&center=true&random=false&width=600&height=100&lines=Panel+VPN+Auto+Installer;Xray+%7C+OVPN+%7C+SSH+%7C+SlowDNS;by+Alrescha79)

(EN) This repository provides an automated multi-protocol VPN & SSH account management system with modular scripts, Go-based REST API, and account lifecycle utilities.

(ID) Repositori ini menyediakan sistem otomatis untuk instalasi & manajemen akun VPN/SSH multi-protokol, lengkap dengan skrip modular, API REST berbasis Go, serta utilitas pembuatan / pengecekan / perpanjangan / penghapusan akun.

---

> [!NOTE]  
> Script ini tidak gratis, Anda dapat mengghubungi saya di [Telegram](https://t.me/Alrescha79) untuk akses lebih lanjut.

> [!CAUTION]
> Penggunaan skrip ini untuk tujuan ilegal adalah dilarang. Penulis tidak bertanggung jawab atas penyalahgunaan yang dilakukan oleh pengguna.

## 🧭 Ringkasan (Overview)

Tujuan proyek ini:

- Mempermudah penyebaran layanan tunneling (VMess, VLESS, Trojan, Shadowsocks, SSH, dll).
- Menstandarkan perintah manajemen akun di `/usr/local/bin/`.
- Menyediakan API untuk integrasi panel eksternal / bot Telegram / dashboard.
- Meminimalkan konfigurasi manual yang rawan kesalahan.

---

## ✨ Fitur Utama

| Fitur | Deskripsi Ringkas |
|-------|-------------------|
| Multi Protokol | VMess, VLESS, Trojan, Shadowsocks, SSH (+ opsi SlowDNS / OVPN jika skrip aktif) |
| Manajemen Akun | add / del / check / renew untuk tiap protokol |
| Notifikasi Telegram | (Jika token & chat ID disediakan) Setiap kali ada perubahan akun |
| API Go (Opsional) | REST endpoint untuk automasi (instal via `rest-go.sh`) |
| Trial Accounts | Mendukung akun uji coba terbatas waktu |
| Konfigurasi Cron | Auto reboot (opsional) |
| Backup / Restore | (Jika modul tersedia dalam skrip) |
| Optimasi Kernel | Dukungan BBR & tweak jaringan (bila diaktifkan) |
| Modular | Mudah menambah protokol / handler baru |

---

## 📂 Struktur

| Path / File | Fungsi |
|-------------|--------|
| `setup.sh` | Skrip utama instalasi & orchestrator |
| `golang/rest-go.sh` | Instalasi dan setup service API Go |
| `package-gohide.sh` | Instalasi utilitas tambahan & symlink perintah manajemen akun |
| `install.md` | Panduan instalasi (Bahasa Indonesia) |
| `LICENSE` | Lisensi MIT |
| `README.md` | Dokumentasi utama (Bahasa Indonesia & Inggris) |

---

## 🧪 Contoh Alur Kerja

1. Jalankan instalasi dasar (lihat [install.md](./install.md)).
2. Verifikasi service (misal: `systemctl status xray` atau `ss -tulpn`).
3. Masuk ke menu utama jika tidak otomatis muncul:
   ```bash
   menu
   ```
4. Tampilkan detail akun & link / JSON konfigurasi.
5. (Opsional) Instal API:
   ```bash
   bash golang/rest-go.sh
   ```
6. Integrasikan dengan panel / bot.

---

## 🛡️ Keamanan (Rekomendasi)

- Ganti port default (Xray / Trojan / Shadowsocks) bila perlu.
- Aktifkan firewall dasar (UFW / nftables).
- Batasi API hanya untuk IP tepercaya (reverse proxy + basic auth / token).
- Monitor log:
  - `/var/log/xray/`
  - Log API (cek definisi di `rest-go.sh`)

---

## 🔌 Manajemen Akun (Ringkas)

| Aksi | VMess | VLESS | Trojan | Shadowsocks | SSH |
|------|-------|-------|--------|-------------|-----|
| Tambah | `add-vmess` | `add-vless` | `add-trojan` | `add-shadowsocks` | `add-ssh` |
| Hapus | `del-vmess` | `del-vless` | `del-trojan` | `del-shadowsocks` | `del-ssh` |
| Cek | `check-vmess` | `check-vless` | `check-trojan` | `check-shadowsocks` | `check-ssh` |
| Perpanjang | `renew-vmess` | `renew-vless` | `renew-trojan` | `renew-shadowsocks` | `renew-ssh` |

---

## 📦 Kebutuhan Sistem

Lihat bagian [Kebutuhan Sistem](./install.md#️-kebutuhan-sistem) untuk daftar OS & paket wajib.

---

## ⏰ Auto Reboot

Tidak aktif default. Lihat [Konfigurasi Auto Reboot](./install.md#-konfigurasi-auto-reboot).

---

## ♻️ Hapus Instalasi

### Langkah Cepat

```bash
wget -O uninstall.sh https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/uninstall.sh
chmod +x uninstall.sh
sudo ./uninstall.sh
```

Saat diminta konfirmasi, ketik:
```
YES
```

### Menjalankan dengan Mode Debug
Jika ingin melihat perintah yang dieksekusi:
```bash
bash -x ./uninstall.sh
```

Atau lihat panduan lengkap [Hapus Instalasi](./uninstall.md).

---

## 🆘 Dukungan

| Kanal | Link |
|-------|------|
| Telegram | [Hubungi di Telegram](https://t.me/Alrescha79) |
| Email | [Kirim Email](mailto:anggun@cakson.my.id) |

---

## 🤝 Kontribusi

1. Fork repository
2. Buat branch fitur: `git checkout -b fitur-baru`
3. Commit: `git commit -m "Tambah fitur X"`
4. Push: `git push origin fitur-baru`
5. Buka Pull Request

---

## 📜 Lisensi

MIT License – lihat [LICENSE](./LICENSE).

Copyright © 2025  
[Alrescha79](https://github.com/alrescha79-cmd)

---
