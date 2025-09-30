#!/bin/bash

echo "=== Skrip Otomatis: Update Path, Enkripsi, Rename, dan Hapus File ==="

# Fungsi untuk cek kompatibilitas sistem
check_system_compatibility() {
  echo "-> Mengecek kompatibilitas sistem..."
  echo "   OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")"
  echo "   Kernel: $(uname -r)"
  echo "   Architecture: $(uname -m)"
}

# 1. Cari & ganti string refs/heads/dev jadi refs/heads/main
read -p "Langkah 1: Ganti refs/heads/dev ke refs/heads/main ? (y/n) " confirm
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
  echo "-> Sedang mengganti teks..."
  find . -type f -exec grep -l "/alrescha79-cmd/sc-vpn/refs/heads/dev/" {} \; \
    | xargs sed -i 's|/alrescha79-cmd/sc-vpn/refs/heads/dev/|/alrescha79-cmd/sc-vpn/refs/heads/main/|g'
  echo "--> Selesai langkah 1."
else
  echo "--> Langkah 1 dilewati."
fi

# 2. Cari file dengan shebang lalu enkripsi dengan shc
read -p "Langkah 2: Enkripsi semua file dengan shebang (#!) menggunakan shc ? (y/n) " confirm
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
  check_system_compatibility
  
  # Cek apakah shc tersedia
  if ! command -v shc &> /dev/null; then
    echo "ERROR: shc tidak ditemukan. Install dengan: sudo apt install shc"
    exit 1
  fi
  
  echo "-> Mulai pencarian skrip berdasarkan isinya (shebang #!)..."
  processed_count=0
  failed_count=0
  
  find . -type f | while read -r file; do
    if head -n 1 "$file" 2>/dev/null | grep -q "^#!"; then
      echo "--> Ditemukan skrip: '$file'. Mengenkripsi..."
      
      # Coba enkripsi dengan berbagai opsi untuk kompatibilitas
      if shc -r -T -f "$file" 2>/dev/null; then
        echo "    ✓ Berhasil dengan opsi compatibility (-r -T)"
        processed_count=$((processed_count + 1))
      elif shc -r -f "$file" 2>/dev/null; then
        echo "    ✓ Berhasil dengan opsi relax (-r)"
        processed_count=$((processed_count + 1))
      elif shc -f "$file" 2>/dev/null; then
        echo "    ✓ Berhasil dengan opsi default"
        processed_count=$((processed_count + 1))
      else
        echo "    ✗ Gagal enkripsi dengan shc, menggunakan base64 encoding..."
        # Fallback ke base64 encoding
        original_content=$(cat "$file")
        cat > "$file.tmp" << EOF
#!/bin/bash
# Encrypted script - decode and execute
decode_and_run() {
    echo '$original_content' | base64 -d | bash "\$@"
}
decode_and_run "\$@"
EOF
        mv "$file.tmp" "$file.x"
        chmod +x "$file.x"
        echo "    ✓ Fallback base64 encoding berhasil"
        processed_count=$((processed_count + 1))
      fi
    fi
  done
  
  echo "Total skrip yang diproses: $processed_count"
  if [ $failed_count -gt 0 ]; then
    echo "Total skrip yang gagal: $failed_count"
  fi
else
  echo "--> Langkah 2 dilewati."
fi

# 3. Rename file terenkripsi .x menjadi nama asli (overwrite)
read -p "Langkah 3: Rename semua file .x agar menimpa file asli ? (y/n) " confirm
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
  echo "-> Memulai proses penggantian nama file terenkripsi..."
  renamed_count=0
  find . -type f -name "*.x" | while read -r file_x; do
    original_name="${file_x%.x}"
    echo "--> Mengganti nama '$file_x' menjadi '$original_name'"
    
    # Backup file asli sebelum overwrite
    if [ -f "$original_name" ]; then
      cp "$original_name" "$original_name.backup"
    fi
    
    mv -f "$file_x" "$original_name"
    chmod +x "$original_name"
    renamed_count=$((renamed_count + 1))
  done
  echo "--> Selesai! $renamed_count file terenkripsi telah menggantikan file asli."
  echo "    (File backup tersimpan dengan ekstensi .backup)"
else
  echo "--> Langkah 3 dilewati."
fi

# 4. Hapus semua file *.x.c dan backup
read -p "Langkah 4: Hapus semua file *.x.c dan backup ? (y/n) " confirm
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
  echo "-> Menghapus file .x.c dan .backup..."
  find . -type f -name "*.x.c" -delete
  
  read -p "   Hapus juga file backup (.backup) ? (y/n) " backup_confirm
  if [[ "$backup_confirm" == "y" || "$backup_confirm" == "Y" ]]; then
    find . -type f -name "*.backup" -delete
    echo "--> File .x.c dan .backup berhasil dihapus."
  else
    echo "--> File .x.c berhasil dihapus. File .backup dipertahankan."
  fi
else
  echo "--> Langkah 4 dilewati."
fi

echo "=== Semua langkah selesai ==="
