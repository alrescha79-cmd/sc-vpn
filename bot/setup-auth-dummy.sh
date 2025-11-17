#!/bin/bash
# Script untuk setup auth dummy pada database

DB_PATH="./sellvpn.db"

echo "🔧 Setup Auth Dummy untuk Database..."

# Cek apakah database ada
if [ ! -f "$DB_PATH" ]; then
    echo "⚠️  Database belum ada. Jalankan bot dulu untuk membuat database."
    exit 1
fi

# Update semua server yang auth-nya kosong
sqlite3 "$DB_PATH" <<EOF
UPDATE Server SET auth = 'no-auth-required' WHERE auth IS NULL OR auth = '' OR auth = 'ISIDISNI';
SELECT 'Server ID: ' || id || ' | Domain: ' || domain || ' | Auth: ' || auth FROM Server;
EOF

echo ""
echo "✅ Semua server berhasil diupdate dengan auth dummy!"
echo ""
echo "📝 Catatan:"
echo "   - Auth sekarang opsional dan tidak diperlukan"
echo "   - Bot akan langsung eksekusi script ke server tanpa API auth"
echo "   - Pastikan server VPN sudah terinstall dengan setup.sh"
