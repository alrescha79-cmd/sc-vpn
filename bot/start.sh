#!/bin/bash
# Quick Start Bot VPN (No Auth Required)

echo "🚀 Starting VPN Bot Setup..."
echo ""

# 1. Cek .vars.json
if [ ! -f ".vars.json" ]; then
    echo "❌ File .vars.json tidak ditemukan!"
    echo ""
    echo "Buat file .vars.json dengan isi:"
    echo ""
    cat << 'EOF'
{
  "BOT_TOKEN": "YOUR_BOT_TOKEN_FROM_BOTFATHER",
  "USER_ID": "YOUR_TELEGRAM_USER_ID",
  "GROUP_ID": "YOUR_GROUP_ID",
  "NAMA_STORE": "Your Store Name",
  "PORT": "50123",
  "DATA_QRIS": "your_qris_data",
  "MERCHANT_ID": "your_merchant_id",
  "API_KEY": "your_api_key"
}
EOF
    echo ""
    echo "Cara mendapatkan:"
    echo "  - BOT_TOKEN: @BotFather di Telegram"
    echo "  - USER_ID: @userinfobot di Telegram"
    echo "  - GROUP_ID: Tambahkan @userinfobot ke grup"
    echo ""
    exit 1
fi

# 2. Cek BOT_TOKEN
BOT_TOKEN=$(grep -o '"BOT_TOKEN"[[:space:]]*:[[:space:]]*"[^"]*"' .vars.json | cut -d'"' -f4)
if [ "$BOT_TOKEN" == "ISIDISNI" ] || [ -z "$BOT_TOKEN" ]; then
    echo "❌ BOT_TOKEN belum diisi di .vars.json!"
    echo "Dapatkan token dari @BotFather di Telegram"
    exit 1
fi

# 3. Install dependencies
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# 4. Set user admin jika database sudah ada
if [ -f "sellvpn.db" ]; then
    echo "🔧 Setting up admin user..."
    USER_ID=$(grep -o '"USER_ID"[[:space:]]*:[[:space:]]*"[^"]*"' .vars.json | cut -d'"' -f4)
    if [ ! -z "$USER_ID" ] && [ "$USER_ID" != "ISIDISNI" ]; then
        sqlite3 sellvpn.db "UPDATE users SET role='admin' WHERE user_id=$USER_ID;" 2>/dev/null || true
    fi
fi

echo ""
echo "✅ Setup selesai!"
echo ""
echo "📝 Cara menggunakan:"
echo "   1. Jalankan bot: node app.js"
echo "   2. Di Telegram, kirim /start"
echo "   3. Add server dengan /addserver (auth otomatis dummy)"
echo "   4. Mulai buat akun!"
echo ""
echo "🚀 Starting bot..."
echo ""

node app.js
