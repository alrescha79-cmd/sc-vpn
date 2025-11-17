# 📦 Panduan Instalasi Bot VPN

## 🚀 Instalasi One-Line (Recommended)

### Metode 1: Langsung Install

```bash
curl -sL https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/dev/bot/start2 -o start2 && chmod +x start2 && bash start2 sellvpn
```

### Metode 2: Full Command dengan Setup

```bash
sysctl -w net.ipv6.conf.all.disable_ipv6=1 \
&& sysctl -w net.ipv6.conf.default.disable_ipv6=1 \
&& apt update -y \
&& apt install -y git curl dos2unix \
&& curl -L -k -sS -o start2 https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/dev/bot/start2 \
&& chmod +x start2 \
&& bash start2 sellvpn
```

### Metode 3: Manual Step by Step

```bash
# 1. Disable IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

# 2. Update & Install Dependencies
apt update -y
apt install -y git curl dos2unix npm nodejs

# 3. Download & Run Script
curl -L -o start2 https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/dev/bot/start2
chmod +x start2
bash start2 sellvpn
```

## 🔧 Install dari Repository Local

Jika sudah clone repository:

```bash
cd /home/son/Projects/sc-vpn/bot
chmod +x start2
bash start2 sellvpn
```

## 🐛 Troubleshooting

### Error: "No such file or directory"

**Problem:** File `start2` tidak ter-download

**Solution:**
```bash
# Pastikan curl dengan flag -o (output)
curl -sL -o start2 https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/dev/bot/start2
chmod +x start2
bash start2 sellvpn
```

### Error: "Skipping start2, not a regular file"

**Problem:** File tidak ter-download atau corrupt

**Solution:**
```bash
# Hapus file lama dan download ulang
rm -f start2
curl -sL -o start2 https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/dev/bot/start2
file start2  # Verifikasi file type
chmod +x start2
bash start2 sellvpn
```

### Error: "Gunakan perintah: start sellvpn"

**Problem:** Parameter salah

**Solution:**
```bash
# Pastikan parameter adalah "sellvpn"
bash start2 sellvpn
```

### Error: DNS/Network Issues

**Problem:** Tidak bisa akses GitHub

**Solution:**
```bash
# Coba dengan wget
wget -O start2 https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/dev/bot/start2
chmod +x start2
bash start2 sellvpn

# Atau gunakan proxy/VPN lain
export https_proxy=your_proxy
curl -sL -o start2 https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/dev/bot/start2
```

## ✅ Verifikasi Instalasi

Setelah instalasi selesai:

```bash
# Cek status bot
pm2 list

# Cek logs
pm2 logs sellvpn

# Cek service
systemctl status sellvpn
```

## 🔄 Update Bot

```bash
cd /root/Alrescha79
git pull
pm2 restart sellvpn
```

## 🗑️ Uninstall

```bash
wget -O hapus.sh https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/dev/bot/hapus.sh
chmod +x hapus.sh
./hapus.sh
```

## 📋 Setelah Instalasi

1. Edit konfigurasi:
   ```bash
   cd /root/Alrescha79
   nano .vars.json
   ```

2. Isi dengan data Anda:
   - BOT_TOKEN dari @BotFather
   - USER_ID dari @userinfobot
   - GROUP_ID (opsional)

3. Restart bot:
   ```bash
   pm2 restart sellvpn
   ```

4. Test di Telegram:
   - `/start` - Mulai bot
   - `/menu` - Lihat menu

---

💡 **Tips:** Gunakan Metode 1 untuk instalasi tercepat!
