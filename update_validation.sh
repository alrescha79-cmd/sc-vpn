#!/bin/bash

# ===============================
# SCRIPT UPDATE VALIDASI AKSES VPS
# ===============================
# Script untuk menambahkan validasi akses ke semua script menu dan fungsi utama
# Author: Alrescha79
# Usage: ./update_validation.sh [--dry-run]

# Colors
green="\e[38;5;87m"
red="\e[38;5;196m"
yellow="\e[38;5;226m"
neutral="\e[0m"
blue="\e[38;5;130m"

echo -e "${blue}════════════════════════════════════════════════════════════════${neutral}"
echo -e "${blue}║                  UPDATE VALIDASI AKSES VPS                     ║${neutral}"
echo -e "${blue}════════════════════════════════════════════════════════════════${neutral}"

# Path yang akan digunakan di VPS (bukan local path)
BASE_PATH="/usr/bin"

# Array file-file yang perlu diperbarui (relative path dari BASE_PATH)
files_to_update=(
    "addssh"
    "addshadowsocks" 
    "addtrojan"
    "addvless"
    "addvmess"
    "checkssh"
    "checkshadowsocks"
    "checktrojan"
    "checkvless"
    "checkvmess"
    "dellssh"
    "dellshadowsocks"
    "delltrojan"
    "dellvless"
    "dellvmess"
    "renewssh"
    "renewshadowsocks"
    "renewtrojan"
    "renewvless"
    "renewvmess"
    "trial"
    "trialssh"
    "trialshadowsocks"
    "trialtrojan"
    "trialvless"
    "trialvmess"
    "exp"
    "autokill"
    "limitip"
    "quota"
    "logclear"
    "features"
    "backuprestore"
    "limitipssh"
)

# Teks validasi yang akan ditambahkan
validation_text="
# Validasi masa aktif sebelum mengakses menu
source /home/son/Projects/sclite/project/validate_access.sh
validate_user_access
"

# ===============================
# FUNCTION UNTUK MEMBUAT TEMPLATE SCRIPT DENGAN VALIDASI
# ===============================
create_validation_template() {
    local script_name="$1"
    local description="$2"
    
    cat << 'EOF'
#!/bin/bash

# ===============================
# SCRIPT_DESCRIPTION_PLACEHOLDER
# ===============================
# Author: Alrescha79
# Created: $(date +"%Y-%m-%d")

# Valid Script - Dapatkan IP dan tanggal server
ipsaya=$(curl -sS ipv4.icanhazip.com)
data_server=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
date_list=$(date +"%Y-%m-%d" -d "$data_server")

# Validasi masa aktif sebelum mengakses fungsi
source /usr/bin/validate_access.sh
validate_user_access

# ===============================
# ORIGINAL SCRIPT CONTENT STARTS HERE
# ===============================

EOF
}

# ===============================
# FUNCTION UNTUK MENAMBAHKAN VALIDASI KE FILE EXISTING
# ===============================
add_validation() {
    local file="$1"
    local dry_run="$2"
    
    if [ -f "$file" ]; then
        # Cek apakah file sudah memiliki validasi
        if ! grep -q "validate_user_access" "$file"; then
            if [ "$dry_run" = "--dry-run" ]; then
                echo -e "${yellow}[DRY-RUN] Akan memperbarui: $file${neutral}"
                return
            fi
            
            echo -e "${green}✓ Memperbarui: $file${neutral}"
            
            # Buat backup dengan timestamp
            local backup_file="${file}.backup.$(date +%s)"
            cp "$file" "$backup_file"
            
            # Ambil baris pertama (shebang)
            local shebang=$(head -n 1 "$file")
            
            # Ambil sisa file tanpa shebang dan baris kosong di awal
            local rest_content=$(tail -n +2 "$file" | sed '/^$/d' | sed '1s/^/\n/')
            
            # Deteksi jenis script untuk kustomisasi
            local script_type="General Script"
            case "$(basename "$file")" in
                add*) script_type="Account Creation Script" ;;
                dell*) script_type="Account Deletion Script" ;;
                renew*) script_type="Account Renewal Script" ;;
                check*) script_type="Account Check Script" ;;
                trial*) script_type="Trial Account Script" ;;
                menu*) script_type="Menu Interface Script" ;;
            esac
            
            # Tulis ulang file dengan validasi
            cat > "$file" << EOF
$shebang

# ===============================
# ${script_type^^}
# ===============================
# Author: Alrescha79
# Updated: $(date +"%Y-%m-%d %H:%M:%S")

# Valid Script - Dapatkan IP dan tanggal server
ipsaya=\$(curl -sS ipv4.icanhazip.com)
data_server=\$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
date_list=\$(date +"%Y-%m-%d" -d "\$data_server")

# Validasi masa aktif sebelum mengakses fungsi
source /usr/bin/validate_access.sh
validate_user_access
$rest_content
EOF
            echo -e "${green}  → Backup disimpan: $backup_file${neutral}"
        else
            echo -e "${blue}ℹ Sudah memiliki validasi: $file${neutral}"
        fi
    else
        echo -e "${red}✗ File tidak ditemukan: $file${neutral}"
    fi
}

# ===============================
# MAIN EXECUTION
# ===============================
dry_run_mode=""
if [ "$1" = "--dry-run" ]; then
    dry_run_mode="--dry-run"
    echo -e "${yellow}MODE: DRY RUN (tidak ada perubahan yang dibuat)${neutral}"
    echo ""
fi

echo -e "${blue}Memproses ${#files_to_update[@]} file...${neutral}"
echo ""

processed_count=0
skipped_count=0
error_count=0

# Update semua file
for file_name in "${files_to_update[@]}"; do
    file_path="${BASE_PATH}/${file_name}"
    
    if [ -f "$file_path" ]; then
        add_validation "$file_path" "$dry_run_mode"
        processed_count=$((processed_count + 1))
    else
        echo -e "${red}✗ File tidak ditemukan: $file_path${neutral}"
        error_count=$((error_count + 1))
    fi
done

echo ""
echo -e "${blue}════════════════════════════════════════════════════════════════${neutral}"
echo -e "${blue}║                           RINGKASAN                            ║${neutral}"
echo -e "${blue}════════════════════════════════════════════════════════════════${neutral}"
echo -e "${green}✓ File diproses: $processed_count${neutral}"
echo -e "${red}✗ File error: $error_count${neutral}"
echo -e "${blue}════════════════════════════════════════════════════════════════${neutral}"

if [ "$dry_run_mode" != "--dry-run" ] && [ $processed_count -gt 0 ]; then
    echo ""
    echo -e "${green}🎉 Update validasi akses selesai!${neutral}"
    echo -e "${yellow}📝 Backup file asli disimpan dengan ekstensi .backup.[timestamp]${neutral}"
    echo -e "${blue}📁 Lokasi validasi: /usr/bin/validate_access.sh${neutral}"
    echo ""
    echo -e "${yellow}⚠️  Pastikan file validate_access.sh sudah di-copy ke /usr/bin/ di setiap VPS!${neutral}"
fi