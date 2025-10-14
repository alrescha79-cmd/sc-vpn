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
echo -e "${blue}${bold}             MENERAPKAN UPDATE TERBARU DARI GITHUB           ${neutral}"
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


# Update check akun
log_action "Mengunduh dan memperbarui file checkvmess..."
if curl -fsSL -o /usr/bin/checkvmess "${GITHUB_BASE}/project/checkvmess"; then
    chmod +x /usr/bin/checkvmess
    log_action "✓ checkvmess berhasil diperbarui"
else
    log_error "Gagal memperbarui checkvmess"
fi

log_action "Mengunduh dan memperbarui file checkvless..."
if curl -fsSL -o /usr/bin/checkvless "${GITHUB_BASE}/project/checkvless"; then
    chmod +x /usr/bin/checkvless
    log_action "✓ checkvless berhasil diperbarui"
else
    log_error "Gagal memperbarui checkvless"
fi

log_action "Mengunduh dan memperbarui file checktrojan..."
if curl -fsSL -o /usr/bin/checktrojan "${GITHUB_BASE}/project/checktrojan"; then
    chmod +x /usr/bin/checktrojan
    log_action "✓ checktrojan berhasil diperbarui"
else
    log_error "Gagal memperbarui checktrojan"
fi

log_action "Mengunduh dan memperbarui file checkshadowsocks..."
if curl -fsSL -o /usr/bin/checkshadowsocks "${GITHUB_BASE}/project/checkshadowsocks"; then
    chmod +x /usr/bin/checkshadowsocks
    log_action "✓ checkshadowsocks berhasil diperbarui"
else
    log_error "Gagal memperbarui checkshadowsocks"
fi

log_action "Mengunduh dan memperbarui file checkssh..."
if curl -fsSL -o /usr/bin/checkssh "${GITHUB_BASE}/project/checkssh"; then
    chmod +x /usr/bin/checkssh
    log_action "✓ checkssh berhasil diperbarui"
else
    log_error "Gagal memperbarui checkssh"
fi

# Update Dellete akun
log_action "Mengunduh dan memperbarui file delvmess..."
if curl -fsSL -o /usr/bin/delvmess "${GITHUB_BASE}/project/delvmess"; then
    chmod +x /usr/bin/delvmess
    log_action "✓ delvmess berhasil diperbarui"
else
    log_error "Gagal memperbarui delvmess"
fi

log_action "Mengunduh dan memperbarui file delvless..."
if curl -fsSL -o /usr/bin/delvless "${GITHUB_BASE}/project/delvless"; then
    chmod +x /usr/bin/delvless
    log_action "✓ delvless berhasil diperbarui"
else
    log_error "Gagal memperbarui delvless"
fi

log_action "Mengunduh dan memperbarui file deltrojan..."
if curl -fsSL -o /usr/bin/deltrojan "${GITHUB_BASE}/project/deltrojan"; then
    chmod +x /usr/bin/deltrojan
    log_action "✓ deltrojan berhasil diperbarui"
else
    log_error "Gagal memperbarui deltrojan"
fi

log_action "Mengunduh dan memperbarui file delshadowsocks..."
if curl -fsSL -o /usr/bin/delshadowsocks "${GITHUB_BASE}/project/delshadowsocks"; then
    chmod +x /usr/bin/delshadowsocks
    log_action "✓ delshadowsocks berhasil diperbarui"
else
    log_error "Gagal memperbarui delshadowsocks"
fi

log_action "Mengunduh dan memperbarui file delssh..."
if curl -fsSL -o /usr/bin/delssh "${GITHUB_BASE}/project/delssh"; then
    chmod +x /usr/bin/delssh
    log_action "✓ delssh berhasil diperbarui"
else
    log_error "Gagal memperbarui delssh"
fi

# Update renew akun
log_action "Mengunduh dan memperbarui file renewvmess..."
if curl -fsSL -o /usr/bin/renewvmess "${GITHUB_BASE}/project/renewvmess"; then
    chmod +x /usr/bin/renewvmess
    log_action "✓ renewvmess berhasil diperbarui"
else
    log_error "Gagal memperbarui renewvmess"
fi

log_action "Mengunduh dan memperbarui file renewvless..."
if curl -fsSL -o /usr/bin/renewvless "${GITHUB_BASE}/project/renewvless"; then
    chmod +x /usr/bin/renewvless
    log_action "✓ renewvless berhasil diperbarui"
else
    log_error "Gagal memperbarui renewvless"
fi

log_action "Mengunduh dan memperbarui file renewtrojan..."
if curl -fsSL -o /usr/bin/renewtrojan "${GITHUB_BASE}/project/renewtrojan"; then
    chmod +x /usr/bin/renewtrojan
    log_action "✓ renewtrojan berhasil diperbarui"
else
    log_error "Gagal memperbarui renewtrojan"
fi

log_action "Mengunduh dan memperbarui file renewssh..."
if curl -fsSL -o /usr/bin/renewssh "${GITHUB_BASE}/project/renewssh"; then
    chmod +x /usr/bin/renewssh
    log_action "✓ renewssh berhasil diperbarui"
else
    log_error "Gagal memperbarui renewssh"
fi

# Update menu akun
log_action "Mengunduh dan memperbarui file menu..."
if curl -fsSL -o /usr/bin/menu "${GITHUB_BASE}/project/menu"; then
    chmod +x /usr/bin/menu
    log_action "✓ menu berhasil diperbarui"
else
    log_error "Gagal memperbarui menu"
fi

log_action "Mengunduh dan memperbarui file menuvmess..."
if curl -fsSL -o /usr/bin/menuvmess "${GITHUB_BASE}/project/menuvmess"; then
    chmod +x /usr/bin/menuvmess
    log_action "✓ menuvmess berhasil diperbarui"
else
    log_error "Gagal memperbarui menuvmess"
fi

log_action "Mengunduh dan memperbarui file menuvless..."
if curl -fsSL -o /usr/bin/menuvless "${GITHUB_BASE}/project/menuvless"; then
    chmod +x /usr/bin/menuvless
    log_action "✓ menuvless berhasil diperbarui"
else
    log_error "Gagal memperbarui menuvless"
fi

log_action "Mengunduh dan memperbarui file menutrojan..."
if curl -fsSL -o /usr/bin/menutrojan "${GITHUB_BASE}/project/menutrojan"; then
    chmod +x /usr/bin/menutrojan
    log_action "✓ menutrojan berhasil diperbarui"
else
    log_error "Gagal memperbarui menutrojan"
fi

log_action "Mengunduh dan memperbarui file menushadowsocks..."
if curl -fsSL -o /usr/bin/menushadowsocks "${GITHUB_BASE}/project/menushadowsocks"; then
    chmod +x /usr/bin/menushadowsocks
    log_action "✓ menushadowsocks berhasil diperbarui"
else
    log_error "Gagal memperbarui menushadowsocks"
fi

log_action "Mengunduh dan memperbarui file menussh..."
if curl -fsSL -o /usr/bin/menussh "${GITHUB_BASE}/project/menussh"; then
    chmod +x /usr/bin/menussh
    log_action "✓ menussh berhasil diperbarui"
else
    log_error "Gagal memperbarui menussh"
fi


# Array file yang diupdate

declare -A updated_files=(
    ["/usr/bin/checkvmess"]="checkvmess"
    ["/usr/bin/checkvless"]="checkvless"
    ["/usr/bin/checktrojan"]="checktrojan"
    ["/usr/bin/checkshadowsocks"]="checkshadowsocks"
    ["/usr/bin/checkssh"]="checkssh"
    ["/usr/bin/delvmess"]="delvmess"
    ["/usr/bin/delvless"]="delvless"
    ["/usr/bin/deltrojan"]="deltrojan"
    ["/usr/bin/delshadowsocks"]="delshadowsocks"
    ["/usr/bin/delssh"]="delssh"
    ["/usr/bin/renewvmess"]="renewvmess"
    ["/usr/bin/renewvless"]="renewvless"
    ["/usr/bin/renewtrojan"]="renewtrojan"
    ["/usr/bin/renewssh"]="renewssh"
    ["/usr/bin/menu"]="menu"
    ["/usr/bin/menuvmess"]="menuvmess"
    ["/usr/bin/menuvless"]="menuvless"
    ["/usr/bin/menutrojan"]="menutrojan"
    ["/usr/bin/menushadowsocks"]="menushadowsocks"
    ["/usr/bin/menussh"]="menussh"
)

for file in "${!updated_files[@]}"; do
    if [[ -f "$file" ]]; then
        log_action "✓ ${updated_files[$file]}: OK"
    else
        log_error "✗ ${updated_files[$file]}: MISSING"
    fi
done


echo ""
echo -e "${green}${bold}═══════════════════════════════════════════════════════════════════════${neutral}"
echo -e "${green}${bold}                    UPDATE LENGKAP BERHASIL DITERAPKAN!                ${neutral}"
echo -e "${green}${bold}═══════════════════════════════════════════════════════════════════════${neutral}"
echo ""
echo -e "${yellow}Silakan jalankan perintah ${bold}menu${neutral}${yellow} untuk mengakses menu utama.${neutral}"
echo ""
echo -e "${yellow}Terima kasih telah menggunakan layanan kami!${neutral}"
echo ""