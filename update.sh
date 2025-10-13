#!/bin/bash
# filepath: apply-exp-warning-update.sh

# Color definitions
green="\e[38;5;82m"
red="\e[38;5;196m"
blue="\e[38;5;39m"
yellow="\e[38;5;226m"
neutral="\e[0m"
bold="\e[1m"

# GitHub repository info
GITHUB_BASE="https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev"

echo -e "${blue}${bold}═══════════════════════════════════════════════════════════════════════${neutral}"
echo -e "${blue}${bold}            MENERAPKAN UPDATE SISTEM PERINGATAN EXPIRED AKUN            ${neutral}"
echo -e "${blue}${bold}═══════════════════════════════════════════════════════════════════════${neutral}"
echo ""

# Function untuk logging
log_action() {
    echo -e "${green}[$(date '+%H:%M:%S')]${neutral} $1"
}

log_error() {
    echo -e "${red}[ERROR]${neutral} $1"
}

log_warning() {
    echo -e "${yellow}[WARNING]${neutral} $1"
}

# Pastikan script dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
   log_error "Script ini harus dijalankan sebagai root!"
   exit 1
fi

# Cek koneksi internet
log_action "Memeriksa koneksi internet..."
if ! curl -fsSL --connect-timeout 10 https://github.com >/dev/null 2>&1; then
    log_error "Tidak ada koneksi internet atau GitHub tidak dapat diakses!"
    exit 1
fi
log_action "✓ Koneksi internet tersedia"

echo -e "${yellow}Memulai download dan update file dari GitHub...${neutral}"
echo ""

# 1. Update script exp-warning (file baru)
log_action "Mengunduh dan menginstall script exp-warning..."
if curl -fsSL -o /usr/bin/exp-warning "${GITHUB_BASE}/project/exp-warning"; then
    chmod +x /usr/bin/exp-warning
    log_action "✓ Script exp-warning berhasil diupdate dan installed"
else
    log_error "Gagal mengunduh script exp-warning!"
    exit 1
fi

# 2. Update script add dengan notifikasi telegram lengkap
log_action "Mengupdate script addssh dengan notifikasi telegram lengkap..."

# Update addssh
if curl -fsSL -o /usr/bin/addssh "${GITHUB_BASE}/project/addssh"; then
    chmod +x /usr/bin/addssh
    log_action "✓ addssh berhasil diupdate dengan notifikasi lengkap"
else
    log_warning "Gagal mengunduh addssh yang diupdate"
fi

# Update addvless
if curl -fsSL -o /usr/bin/addvless "${GITHUB_BASE}/project/addvless"; then
    chmod +x /usr/bin/addvless
    log_action "✓ addvless berhasil diupdate dengan notifikasi lengkap"
else
    log_warning "Gagal mengunduh addvless yang diupdate"
fi

# Update addtrojan
if curl -fsSL -o /usr/bin/addtrojan "${GITHUB_BASE}/project/addtrojan"; then
    chmod +x /usr/bin/addtrojan
    log_action "✓ addtrojan berhasil diupdate dengan notifikasi lengkap"
else
    log_warning "Gagal mengunduh addtrojan yang diupdate"
fi

# Update addvmess
if curl -fsSL -o /usr/bin/addvmess "${GITHUB_BASE}/project/addvmess"; then
    chmod +x /usr/bin/addvmess
    log_action "✓ addvmess berhasil diupdate dengan notifikasi lengkap"
else
    log_warning "Gagal mengunduh addvmess yang diupdate"
fi


# Update autokill
if curl -fsSL -o /usr/bin/autokill "${GITHUB_BASE}/project/autokill"; then
    chmod +x /usr/bin/autokill
    log_action "✓ autokill berhasil diupdate dengan notifikasi lengkap"
else
    log_warning "Gagal mengunduh autokill yang diupdate"
fi

# 3. Update script trial dengan notifikasi telegram lengkap
log_action "Mengupdate script trial dengan notifikasi telegram lengkap..."

# Update trialvless
if curl -fsSL -o /usr/bin/trialvless "${GITHUB_BASE}/project/trialvless"; then
    chmod +x /usr/bin/trialvless
    log_action "✓ trialvless berhasil diupdate dengan notifikasi lengkap"
else
    log_warning "Gagal mengunduh trialvless yang diupdate"
fi

# Update trialvmess
if curl -fsSL -o /usr/bin/trialvmess "${GITHUB_BASE}/project/trialvmess"; then
    chmod +x /usr/bin/trialvmess
    log_action "✓ trialvmess berhasil diupdate dengan notifikasi lengkap"
else
    log_warning "Gagal mengunduh trialvmess yang diupdate"
fi

# Update trialtrojan
if curl -fsSL -o /usr/bin/trialtrojan "${GITHUB_BASE}/project/trialtrojan"; then
    chmod +x /usr/bin/trialtrojan
    log_action "✓ trialtrojan berhasil diupdate dengan notifikasi lengkap"
else
    log_warning "Gagal mengunduh trialtrojan yang diupdate"
fi

# Update trialshadowsocks
if curl -fsSL -o /usr/bin/trialshadowsocks "${GITHUB_BASE}/project/trialshadowsocks"; then
    chmod +x /usr/bin/trialshadowsocks
    log_action "✓ trialshadowsocks berhasil diupdate dengan notifikasi lengkap"
else
    log_warning "Gagal mengunduh trialshadowsocks yang diupdate"
fi

# Update trialssh
if curl -fsSL -o /usr/bin/trialssh "${GITHUB_BASE}/project/trialssh"; then
    chmod +x /usr/bin/trialssh
    log_action "✓ trialssh berhasil diupdate dengan notifikasi lengkap"
else
    log_warning "Gagal mengunduh trialssh yang diupdate"
fi

# 4. Setup cron job untuk exp-warning
log_action "Mengatur cron job untuk sistem peringatan expired..."
cat > "/etc/cron.d/exp_warning" << 'EOF'
# Cron job untuk sistem peringatan akun expired - Alrescha79 Panel
# Berjalan 2 kali sehari: pagi (09:00) dan sore (18:00)
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Sistem peringatan expired akun (7, 3, 1 hari sebelumnya)
0 9 * * * root /usr/bin/exp-warning >/dev/null 2>&1
0 18 * * * root /usr/bin/exp-warning >/dev/null 2>&1
EOF

chmod 644 "/etc/cron.d/exp_warning"
log_action "✓ Cron job exp-warning berhasil dikonfigurasi (2x sehari: 09:00 & 18:00)"

# 5. Buat direktori dan file log
log_action "Menyiapkan sistem logging..."
mkdir -p "/var/log"
touch "/var/log/exp-warning.log"
chmod 644 "/var/log/exp-warning.log"
log_action "✓ File log exp-warning berhasil dibuat: /var/log/exp-warning.log"

# 6. Restart cron service
log_action "Restart cron service..."
if systemctl restart cron 2>/dev/null || systemctl restart crond 2>/dev/null; then
    log_action "✓ Cron service berhasil direstart"
else
    log_warning "Gagal restart cron service, silakan restart manual: systemctl restart cron"
fi

# 7. Verifikasi konfigurasi Telegram
log_action "Memeriksa konfigurasi Telegram..."
if [[ -f "/root/.vars" ]]; then
    source /root/.vars 2>/dev/null
    if [[ -n "$bot_token" && -n "$telegram_id" ]]; then
        log_action "✓ Konfigurasi Telegram sudah tersedia dan siap digunakan"
    else
        log_warning "Konfigurasi Telegram belum lengkap. Gunakan addssh [6] untuk setup bot notifikasi."
    fi
else
    log_warning "File /root/.vars belum ada. Gunakan addssh [6] untuk setup bot notifikasi Telegram."
fi

# 8. Test script exp-warning
echo ""
log_action "Melakukan test script exp-warning..."
if /usr/bin/exp-warning 2>/dev/null; then
    log_action "✓ Script exp-warning berhasil dijalankan tanpa error"
else
    log_warning "Script exp-warning mungkin butuh konfigurasi Telegram untuk berfungsi penuh"
fi

# 9. Verifikasi semua update
echo ""
log_action "Verifikasi semua file yang diupdate..."

# Array file yang diupdate
declare -A updated_files=(
    ["/usr/bin/exp-warning"]="Script sistem peringatan expired"
    ["/usr/bin/addssh"]="addssh dengan notifikasi telegram"
    ["/usr/bin/addvless"]="addvless dengan notifikasi lengkap"
    ["/usr/bin/addtrojan"]="addtrojan dengan notifikasi lengkap"
    ["/usr/bin/addvmess"]="addvmess dengan notifikasi lengkap"
    ["/usr/bin/trialvless"]="Trial VLess dengan notifikasi lengkap"
    ["/usr/bin/trialvmess"]="Trial VMess dengan notifikasi lengkap"
    ["/usr/bin/trialtrojan"]="Trial Trojan dengan notifikasi lengkap"
    ["/usr/bin/trialshadowsocks"]="Trial Shadowsocks dengan notifikasi lengkap"
    ["/usr/bin/trialssh"]="Trial SSH dengan notifikasi lengkap"
    ["/etc/cron.d/exp_warning"]="Cron job sistem peringatan"
)

for file in "${!updated_files[@]}"; do
    if [[ -f "$file" ]]; then
        log_action "✓ ${updated_files[$file]}: OK"
    else
        log_error "✗ ${updated_files[$file]}: MISSING"
    fi
done

# 10. Tampilkan informasi cron job
echo ""
log_action "Cron jobs sistem yang aktif:"
if [[ -f "/etc/cron.d/exp_warning" ]]; then
    echo -e "${green}Cron job exp-warning:${neutral}"
    grep -v '^#\|^$' "/etc/cron.d/exp_warning" | sed 's/^/  /'
fi

echo ""
echo -e "${green}${bold}═══════════════════════════════════════════════════════════════════════${neutral}"
echo -e "${green}${bold}                    UPDATE LENGKAP BERHASIL DITERAPKAN!                ${neutral}"
echo -e "${green}${bold}═══════════════════════════════════════════════════════════════════════${neutral}"
echo ""

echo -e "${blue}📋 RINGKASAN UPDATE DARI GITHUB:${neutral}"
echo -e "   ✅ Repository: https://github.com/alrescha79-cmd/sc-vpn/tree/dev"
echo -e "   ✅ Script exp-warning: Sistem peringatan expired akun"
echo -e "   ✅ addssh: Tampilan notifikasi telegram diperbaiki"
echo -e "   ✅ All Trial Scripts: Notifikasi telegram lengkap dan konsisten"
echo -e "   ✅ Cron Job: Auto-warning 2x sehari (09:00 & 18:00)"
echo -e "   ✅ Logging: /var/log/exp-warning.log"
echo ""

echo -e "${yellow}🔔 FITUR BARU - SISTEM PERINGATAN EXPIRED AKUN:${neutral}"
echo -e "   • ⚠️  Peringatan 7 hari sebelum expired"
echo -e "   • 🔔 Peringatan 3 hari sebelum expired"  
echo -e "   • 🚨 Peringatan 1 hari sebelum expired"
echo -e "   • 📱 Notifikasi otomatis via Telegram"
echo -e "   • 🔄 Auto-running 2x sehari"
echo -e "   • 📊 Mendukung semua service: VMess, VLess, Trojan, Shadowsocks, SSH"
echo ""

echo -e "${yellow}🔧 PERBAIKAN NOTIFIKASI TELEGRAM:${neutral}"
echo -e "   • addssh: Status bot telegram yang lebih akurat"
echo -e "   • Trial Scripts: Informasi lengkap sesuai tampilan layar"
echo -e "   • Format konsisten: Emoji, struktur, dan konten seragam"
echo -e "   • Link lengkap: TLS, Non-TLS, gRPC untuk setiap akun"
echo ""

echo -e "${blue}📖 CARA PENGGUNAAN & MONITORING:${neutral}"
echo -e "   • Test exp-warning: ${green}/usr/bin/exp-warning${neutral}"
echo -e "   • Lihat log: ${green}tail -f /var/log/exp-warning.log${neutral}"
echo -e "   • Setup Telegram: ${green}Gunakan addssh [6] di panel utama${neutral}"
echo -e "   • Akses addssh: ${green}addssh${neutral}"
echo -e "   • Cek cron: ${green}systemctl status cron${neutral}"
echo ""

echo -e "${blue}🔄 UPDATE SELANJUTNYA:${neutral}"
echo -e "   • Jalankan script ini lagi untuk mendapat update terbaru"
echo -e "   • Atau gunakan command individual seperti:"
echo -e "     ${green}curl -o /usr/bin/addssh ${GITHUB_BASE}/project/addssh${neutral}"
echo ""

echo -e "${green}Semua update sistem berhasil diterapkan! 🚀${neutral}"
echo -e "${green}Selamat menggunakan fitur sistem peringatan expired akun! 🎉${neutral}"