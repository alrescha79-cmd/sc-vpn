// 🌐 Core Modules
const os = require('os');
const fs = require('fs');
const path = require('path');
const { exec, execSync } = require('child_process');
const sqlite3 = require('sqlite3').verbose();
const express = require('express');
const app = express();
const axios = require('axios');
const cron = require('node-cron');

const fetch = require('node-fetch');
const TELEGRAM_UPLOAD_DIR = '/root/BotVPN2/uploaded_restore';
const BACKUP_DIR = '/root/BotVPN2/backups';
const DB_PATH = path.resolve('./sellvpn.db');
const UPLOAD_DIR = '/root/BotVPN2/uploaded_restore';

// Buat folder kalau belum ada
if (!fs.existsSync(TELEGRAM_UPLOAD_DIR)) fs.mkdirSync(TELEGRAM_UPLOAD_DIR, { recursive: true });
if (!fs.existsSync(BACKUP_DIR)) fs.mkdirSync(BACKUP_DIR, { recursive: true });

// 🛠️ Load Config (.vars.json) lebih awal
const vars = JSON.parse(fs.readFileSync('./.vars.json', 'utf8'));
const {
  BOT_TOKEN,
  USER_ID,
  GROUP_ID,
  PORT = 50123,
  NAMA_STORE = 'GabutStore',
  DATA_QRIS,
  MERCHANT_ID,
  API_KEY
} = vars;

// 💬 Telegram
const { Telegraf, session } = require('telegraf');
const bot = new Telegraf(BOT_TOKEN);
bot.use(session());

// 📦 Tools
const { promisify } = require('util');
const QRISPayment = require('qris-payment');

const util = require('util');
const execAsync = util.promisify(exec);
const dns = require('dns').promises;

// 🧠 Admin List
const rawAdmin = USER_ID;
const adminIds = Array.isArray(rawAdmin) ? rawAdmin.map(String) : [String(rawAdmin)];
const FormData = require('form-data'); // ⬅️ FIX PENTING!
// 📝 Logger
const winston = require('winston');
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.printf(({ timestamp, level, message }) =>
      `${timestamp} [${level.toUpperCase()}]: ${message}`
    )
  ),
  transports: [
    new winston.transports.File({ filename: 'bot-error.log', level: 'error' }),
    new winston.transports.File({ filename: 'bot-combined.log' })
  ]
});
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({ format: winston.format.simple() }));
}
logger.info('Bot initialized');

// 🕛 Reset trial_count_today setiap hari jam 00:00
cron.schedule('0 0 * * *', async () => {
  try {
    await dbRunAsync(`UPDATE users SET trial_count_today = 0, last_trial_date = date('now')`);
    logger.info('✅ Berhasil reset trial harian semua user.');
  } catch (err) {
    logger.error('❌ Gagal reset trial harian:', err.message);
  }
});

// Jadwal restart harian 04:00
cron.schedule('0 4 * * *', () => {
  logger.warn('🌀 Restart harian bot (jadwal 04:00)...');
  exec('pm2 restart sellvpn', async (err, stdout, stderr) => {
    if (err) {
      logger.error('❌ Gagal restart via PM2:', err.message);
    } else {
      logger.info('✅ Bot berhasil direstart oleh scheduler harian.');

      const restartMsg = `♻️ Bot di-restart otomatis (jadwal harian).\n🕓 Waktu: ${new Date().toLocaleString('id-ID')}`;
      try {
        await bot.telegram.sendMessage(GROUP_ID || adminIds[0], restartMsg);
        logger.info('📢 Notifikasi restart harian dikirim.');
      } catch (e) {
        logger.warn('⚠️ Gagal kirim notifikasi restart:', e.message);
      }
    }
  });
});

// ✅ RESET KOMISI BULANAN OTOMATIS TIAP TANGGAL 1 JAM 01:00
cron.schedule('0 1 1 * *', () => {
  db.serialize(() => {
    db.run(`DELETE FROM reseller_sales`, (err) => {
      if (err) {
        logger.error('❌ Gagal reset reseller_sales otomatis:', err.message);
      } else {
        logger.info('✅ reseller_sales berhasil direset otomatis bulanan');
      }
    });

    db.run(`UPDATE users SET reseller_level = 'silver' WHERE role = 'reseller'`, (err) => {
      if (err) {
        logger.error('❌ Gagal reset level reseller otomatis:', err.message);
      } else {
        logger.info('✅ Level reseller direset jadi silver (otomatis)');
      }
    });

    if (GROUP_ID) {
      bot.telegram.sendMessage(GROUP_ID, `🧹 *Reset Komisi Bulanan:*\n\nSemua komisi reseller telah direset dan level dikembalikan ke *SILVER*.`, {
        parse_mode: 'Markdown'
      }).catch((err) => {
        logger.error('❌ Gagal kirim notifikasi reset bulanan:', err.message);
      });
    }
  });
});

// 📡 Express Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 📂 Load Modules

const { createssh } = require('./modules/createSSH');
const { createvmess } = require('./modules/createVMESS');
const { createvless } = require('./modules/createVLESS');
const { createtrojan } = require('./modules/createTROJAN');
const { createshadowsocks } = require('./modules/createSHADOWSOCKS');

const { renewssh } = require('./modules/renewSSH');
const { renewvmess } = require('./modules/renewVMESS');
const { renewvless } = require('./modules/renewVLESS');
const { renewtrojan } = require('./modules/renewTROJAN');
const { renewshadowsocks } = require('./modules/renewSHADOWSOCKS');

// 🗄️ SQLite Init
const db = new sqlite3.Database('./sellvpn.db', (err) => {
  if (err) {
    logger.error('Kesalahan koneksi SQLite3:', err.message);
  } else {
    logger.info('Terhubung ke SQLite3');
  }
});

// Promisify db methods
const dbGetAsync = (sql, params = []) => new Promise((resolve, reject) => {
  db.get(sql, params, (err, row) => (err ? reject(err) : resolve(row)));
});

const dbAllAsync = (sql, params = []) => new Promise((resolve, reject) => {
  db.all(sql, params, (err, rows) => (err ? reject(err) : resolve(rows)));
});

const dbRunAsync = (sql, params = []) => new Promise((resolve, reject) => {
  db.run(sql, params, function (err) {
    if (err) reject(err);
    else resolve(this);
  });
});

// Inisialisasi tabel reseller_upgrade_log
(async () => {
  try {
    await dbRunAsync(`
      CREATE TABLE IF NOT EXISTS reseller_upgrade_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        username TEXT,
        amount INTEGER,
        level TEXT,
        created_at TEXT
      )
    `);
    console.log('✅ Tabel reseller_upgrade_log siap digunakan.');
  } catch (error) {
    console.error('❌ Gagal membuat tabel reseller_upgrade_log:', error.message);
  }
})();

// 🔄 Cache status sistem (biar gak query terus)
const cacheStatus = {
  jumlahServer: 0,
  jumlahPengguna: 0,
  lastUpdated: 0  // timestamp dalam ms
};

///Coba markdown
const escapeMarkdownV2 = (text) => {
  return String(text).replace(/[_*[\]()~`>#+=|{}.!\\-]/g, '\\$&');
};

//testerr
db.run(`ALTER TABLE users ADD COLUMN username TEXT`, (err) => {
  if (err && !err.message.includes('duplicate column name')) {
    logger.error('❌ Gagal menambahkan kolom username:', err.message);
  } else {
    logger.info('✅ Kolom username ditambahkan ke tabel users');
  }
});
//bawaan
db.serialize(() => {
  // Tabel Users
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER UNIQUE,
    saldo INTEGER DEFAULT 0,
    role TEXT DEFAULT 'user',
    reseller_level TEXT DEFAULT 'silver',
    has_trial INTEGER DEFAULT 0,
    username TEXT,
    first_name TEXT
  )`);

  // Tabel Reseller Sales
  db.run(`CREATE TABLE IF NOT EXISTS reseller_sales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    reseller_id INTEGER,
    buyer_id INTEGER,
    akun_type TEXT,
    username TEXT,
    komisi INTEGER,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )`);

  // Tabel Akun Aktif
  db.run(`CREATE TABLE IF NOT EXISTS akun_aktif (
    username TEXT PRIMARY KEY,
    jenis TEXT
  )`);

  // Tabel Invoice Log
  db.run(`CREATE TABLE IF NOT EXISTS invoice_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    username TEXT,
    layanan TEXT,
    akun TEXT,
    hari INTEGER,
    harga INTEGER,
    komisi INTEGER,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )`);

  // Tabel Pending Deposit
  db.run(`CREATE TABLE IF NOT EXISTS pending_deposits (
    unique_code TEXT PRIMARY KEY,
    user_id INTEGER,
    amount INTEGER,
    original_amount INTEGER,
    timestamp INTEGER,
    status TEXT,
    qr_message_id INTEGER
  )`);

  // Tabel Trial Logs
  db.run(`CREATE TABLE IF NOT EXISTS trial_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    username TEXT,
    jenis TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )`);

  // Tabel Server
  db.run(`CREATE TABLE IF NOT EXISTS Server (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    domain TEXT,
    auth TEXT,
    harga INTEGER,
    nama_server TEXT,
    quota INTEGER,
    iplimit INTEGER,
    batas_create_akun INTEGER,
    total_create_akun INTEGER DEFAULT 0
  )`);

  // Tabel Transaksi
  db.run(`CREATE TABLE IF NOT EXISTS transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    type TEXT,
    username TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )`);

  // Tabel Transfer Saldo
  db.run(`CREATE TABLE IF NOT EXISTS saldo_transfers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_id INTEGER,
    to_id INTEGER,
    amount INTEGER,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )`);

  // Tabel Log Transfer (alternatif historis)
  db.run(`CREATE TABLE IF NOT EXISTS transfer_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_id INTEGER,
    to_id INTEGER,
    jumlah INTEGER,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )`);
});

db.run(`
  CREATE TABLE IF NOT EXISTS topup_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    username TEXT,
    amount INTEGER,
    reference TEXT,
    created_at TEXT
  )
`, (err) => {
  if (err) {
    console.error('❌ Gagal membuat tabel topup_log:', err.message);
  } else {
    console.log('✅ Tabel topup_log siap digunakan.');
  }
});

db.run(`ALTER TABLE Server ADD COLUMN isp TEXT`, (err) => {
  if (err && !err.message.includes('duplicate column name')) {
    logger.error('❌ Gagal tambah kolom isp:', err.message);
  }
});
db.run(`ALTER TABLE Server ADD COLUMN lokasi TEXT`, (err) => {
  if (err && !err.message.includes('duplicate column name')) {
    logger.error('❌ Gagal tambah kolom lokasi:', err.message);
  }
});

db.run(`CREATE TABLE IF NOT EXISTS akun (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  jenis TEXT,
  username TEXT,
  server_id INTEGER,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
)`);

db.run(`ALTER TABLE users ADD COLUMN last_trial_date TEXT`, () => {});
db.run(`ALTER TABLE users ADD COLUMN trial_count_today INTEGER DEFAULT 0`, () => {});

const userState = {};
global.adminState = {}; // Untuk menyimpan context step admin
logger.info('User state initialized');

// Fungsi untuk escape karakter Markdown Telegram
function escapeMarkdown(text) {
  if (!text) return '';
  return text
    .replace(/_/g, '\\_')
    .replace(/\*/g, '\\*')
    .replace(//g, '\')
    .replace(//g, '\')
    .replace(//g, '\')
    .replace(//g, '\')
    .replace(/~/g, '\\~')
    .replace(/`/g, '\\`')
    .replace(/>/g, '\\>')
    .replace(/#/g, '\\#')
    .replace(/\+/g, '\\+')
    .replace(/-/g, '\\-')
    .replace(/=/g, '\\=')
    .replace(/\|/g, '\\|')
    .replace(/\{/g, '\\{')
    .replace(/\}/g, '\\}')
    .replace(/\./g, '\\.')
    .replace(/!/g, '\\!');
}
function getFlagEmojiByLocation(location) {
  const map = {
    'Singapore, SG': '🇸🇬',
    'Indonesia': '🇮🇩',
    'Japan': '🇯🇵',
    'USA': '🇺🇸',
    'Germany': '🇩🇪',
    'Malaysia': '🇲🇾',
    'France': '🇫🇷',
    'Netherlands': '🇳🇱',
    'United Kingdom': '🇬🇧',
    'India': '🇮🇳',
    'Thailand': '🇹🇭',
    'Hong Kong': '🇭🇰'
  };

  // Default emoji kalau tidak cocok
  return map[location?.trim()] || '??';
}

// Fungsi bantu parsing output JSON dari shell
function parseJsonOutput(raw) {
  try {
    const start = raw.indexOf('{');
    const end = raw.lastIndexOf('}');
    if (start !== -1 && end !== -1) {
      return JSON.parse(raw.substring(start, end + 1));
    }
    throw new Error('Output tidak mengandung JSON');
  } catch (e) {
    throw new Error('Gagal parsing JSON: ' + e.message);
  }
}

// Fungsi bantu kirim pesan dengan penanganan error
async function safeSend(bot, chatId, message, extra = {}) {
  try {
    await bot.telegram.sendMessage(chatId, message, extra);
  } catch (err) {
    console.warn(`⚠️ Gagal kirim ke ${chatId}: ${err.message}`);
  }
}

function cleanupOrphanResellers() {
  db.all(`
    SELECT DISTINCT reseller_id FROM reseller_sales
    WHERE reseller_id NOT IN (SELECT user_id FROM users)
  `, (err, rows) => {
    if (err) return console.error("❌ Gagal cek reseller yatim:", err.message);

    if (rows.length === 0) {
      console.log("✅ Tidak ada reseller yatim.");
      return;
    }

    const orphanIds = rows.map(row => row.reseller_id);
    console.log("⚠️ Reseller yatim ditemukan:", orphanIds);

    const placeholders = orphanIds.map(() => '?').join(',');
    db.run(`
      DELETE FROM reseller_sales WHERE reseller_id IN (${placeholders})
    `, orphanIds, function (err) {
      if (err) return console.error("❌ Gagal hapus reseller yatim:", err.message);
      console.log(`✅ ${this.changes} baris reseller_sales berhasil dibersihkan.`);
    });
  });
}

// Fungsi helper promisify db.all
function dbAll(db, sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) return reject(err);
      resolve(rows);
    });
  });
}

// Panggil saat startup
cleanupOrphanResellers();

// =========================================
// ✅ 4. COMMAND /start dan /menu
// =========================================
bot.command(['start', 'menu'], async (ctx) => {
  const userId = ctx.from.id;
  const username = ctx.from.username || null;
  const firstName = ctx.from.first_name || 'User';

  try {
    await dbRunAsync(`
      INSERT INTO users (user_id, username, first_name)
      VALUES (?, ?, ?)
      ON CONFLICT(user_id) DO UPDATE SET username = ?, first_name = ?
    `, [userId, username, firstName, username, firstName]);

    logger.info(`✅  User ${userId} berhasil terdaftar / diperbarui`);
  } catch (err) {
    logger.error('❌ Kesalahan saat menyimpan user:', err.message);
    return ctx.reply('❌ Gagal menyimpan data user. Silakan coba lagi.');
  }

  await sendMainMenu(ctx);
});
// Command Admin
bot.command('admin', async (ctx) => {
  const userId = ctx.from.id;
  logger.info(`🔐 Permintaan akses admin dari ${userId}`);

  if (!adminIds.includes(String(userId))) {
    return ctx.reply('🚫 Anda tidak memiliki izin untuk mengakses menu admin.');
  }

  await sendAdminMenu(ctx);
});

bot.command('invoice_last', async (ctx) => {
  const userId = String(ctx.from.id);
  const isAdmin = adminIds.includes(userId);
  const input = ctx.message.text.split(' ')[1];

  let targetUsername = input?.replace('@', '').trim();
  let query, params;

  if (isAdmin && targetUsername) {
    query = `
      SELECT * FROM invoice_log
      WHERE username = ?
      ORDER BY created_at DESC
      LIMIT 1
    `;
    params = [targetUsername];
  } else {
    query = `
      SELECT * FROM invoice_log
      WHERE user_id = ?
      ORDER BY created_at DESC
      LIMIT 1
    `;
    params = [userId];
  }

  try {
    const row = await dbGetAsync(query, params);

    if (!row) {
      return ctx.reply('📭 Tidak ditemukan invoice terakhir.');
    }

    const invoice = `
🧾 *INVOICE TERAKHIR*
━━━━━━━━━━━━━━━━━━━━━━
👤 *User:* ${row.username}
📦 *Layanan:* *${row.layanan.toUpperCase()}*
🔐 *Username:* \`${row.akun}\`
📅 *Durasi:* *${row.hari} hari*
💸 *Harga:* *Rp${row.harga.toLocaleString('id-ID')}*
${row.komisi ? `💰 *Komisi:* *Rp${row.komisi.toLocaleString('id-ID')}*` : ''}
🕒 *Waktu:* ${new Date(row.created_at).toLocaleString('id-ID')}
━━━━━━━━━━━━━━━━━━━━━━
`.trim();

    ctx.reply(invoice, { parse_mode: 'Markdown' });
  } catch (err) {
    logger.error('❌ Gagal ambil invoice terakhir:', err.message);
    ctx.reply('❌ Gagal mengambil data invoice.');
  }
});

bot.command('cleardummy', async (ctx) => {
  if (!adminIds.includes(String(ctx.from.id))) return;

  db.run("DELETE FROM reseller_sales WHERE username = 'testakun'", function(err) {
    if (err) {
      logger.error('❌ Gagal hapus data dummy:', err.message);
      return ctx.reply('❌ Gagal hapus data dummy.');
    }

    ctx.reply(`🧹 Berhasil hapus ${this.changes} data dummy (username: testakun).`);
  });
});

bot.command('statadmin', async (ctx) => {
  const userId = String(ctx.from.id);

  if (!adminIds.includes(userId)) {
    return ctx.reply('⚠️ Anda tidak memiliki izin untuk menggunakan perintah ini.');
  }

  try {
    const [jumlahUser, jumlahReseller, jumlahServer, totalSaldo] = await Promise.all([
      dbGetAsync('SELECT COUNT(*) AS count FROM users'),
      dbGetAsync("SELECT COUNT(*) AS count FROM users WHERE role = 'reseller'"),
      dbGetAsync('SELECT COUNT(*) AS count FROM Server'),
      dbGetAsync('SELECT SUM(saldo) AS total FROM users')
    ]);

    const replyText = `
📊 *Statistik Sistem*:

👥 Total Pengguna : *${jumlahUser.count}*
👑 Total Reseller : *${jumlahReseller.count}*
🖥️ Total Server   : *${jumlahServer.count}*
💰 Total Saldo     : *Rp${(totalSaldo.total || 0).toLocaleString('id-ID')}*
`.trim();

    await ctx.reply(replyText, { parse_mode: 'Markdown' });
  } catch (err) {
    logger.error('❌ Gagal ambil statistik admin:', err.message);
    await ctx.reply('❌ Gagal mengambil statistik.');
  }
});

bot.command('komisi', (ctx) => {
  const userId = ctx.from.id;

  db.get('SELECT role, reseller_level FROM users WHERE user_id = ?', [userId], (err, user) => {
    if (err || !user || user.role !== 'reseller') {
      return ctx.reply('❌ Kamu bukan reseller.');
    }

    db.get('SELECT COUNT(*) AS total_akun, SUM(komisi) AS total_komisi FROM reseller_sales WHERE reseller_id = ?', [userId], (err, summary) => {
      if (err) {
        logger.error('❌ Gagal ambil data komisi:', err.message);
        return ctx.reply('❌ Gagal ambil data komisi.');
      }

      db.all('SELECT akun_type, username, komisi, created_at FROM reseller_sales WHERE reseller_id = ? ORDER BY created_at DESC LIMIT 5', [userId], (err, rows) => {
        if (err) {
          return ctx.reply('❌ Gagal ambil riwayat komisi.');
        }

        const level = user.reseller_level ? user.reseller_level.toUpperCase() : 'SILVER';

        const list = rows.map((r, i) =>
          `🔹 ${r.akun_type.toUpperCase()} - ${r.username} (+${r.komisi}) 🕒 ${r.created_at}`
        ).join('\n');

        const text = `💰 *Statistik Komisi Reseller*\n\n` +
          `🎖️ Level: ${level}\n` +
          `🧑‍💻 Total Akun Terjual: ${summary.total_akun}\n` +
          `💸 Total Komisi: Rp${summary.total_komisi || 0}\n\n` +
          `📜 *Transaksi Terbaru:*\n${list}`;

        ctx.reply(text, { parse_mode: 'Markdown' });
      });
    });
  });
});

bot.command('send_backup', async (ctx) => {
  const input = ctx.message.text.split(' ');
  const filename = input[1];

  if (!filename) {
    return ctx.reply('❗ Format salah.\nContoh: `/send_backup backup_2025-06-10T21-30-00.enc`', { parse_mode: 'Markdown' });
  }

  const filePath = path.join(__dirname, 'restore', filename);

  if (!fs.existsSync(filePath)) {
    return ctx.reply(`❌ File \`${filename}\` tidak ditemukan di folder restore.`, { parse_mode: 'Markdown' });
  }

  try {
    await ctx.replyWithDocument({ source: filePath, filename });
  } catch (err) {
    logger.error('❌ Gagal kirim file backup:', err.message);
    ctx.reply('❌ Gagal mengirim file.');
  }
});

bot.command('list_backup', (ctx) => {
  const folderPath = path.join(__dirname, 'restore');

  if (!fs.existsSync(folderPath)) {
    return ctx.reply('📂 Folder `restore/` belum ada.');
  }

  const files = fs.readdirSync(folderPath)
    .filter(file => file.endsWith('.enc') || file.endsWith('.sql') || file.endsWith('.db'));

  if (files.length === 0) {
    return ctx.reply('📭 Tidak ada file backup ditemukan di folder `restore/`.');
  }

  const message = files
    .sort((a, b) => fs.statSync(path.join(folderPath, b)).mtime - fs.statSync(path.join(folderPath, a)).mtime)
    .map(file => {
      const stats = fs.statSync(path.join(folderPath, file));
      const sizeMB = (stats.size / 1024 / 1024).toFixed(2);
      return `📄 *${file}* — \`${sizeMB} MB\``;
    })
    .join('\n');

  ctx.reply(`📦 *Daftar File Backup:*\n\n${message}`, { parse_mode: 'Markdown' });
});


bot.command('cancel_restore', (ctx) => {
  if (ctx.session?.restoreMode) {
    ctx.session.restoreMode = null;
    return ctx.reply('❎ Mode restore telah *dibatalkan*.', { parse_mode: 'Markdown' });
  }

  ctx.reply('ℹ️ Tidak ada mode restore yang sedang aktif.');
});


bot.command('logtransfer', (ctx) => {
  const userId = ctx.from.id;

  db.get('SELECT role FROM users WHERE user_id = ?', [userId], (err, user) => {
    if (err || !user || user.role !== 'reseller') {
      return ctx.reply('❌ Kamu bukan reseller.');
    }

    db.all(
      `SELECT * FROM saldo_transfers WHERE from_id = ? ORDER BY created_at DESC LIMIT 5`,
      [userId],
      (err, rows) => {
        if (err || rows.length === 0) {
          return ctx.reply('📭 Belum ada log transfer.');
        }

        const list = rows.map(r =>
          `🔁 Rp${r.amount} ke \`${r.to_id}\` - 🕒 ${r.created_at}`
        ).join('\n');

        ctx.reply(`📜 *Riwayat Transfer Saldo:*\n\n${list}`, { parse_mode: 'Markdown' });
      }
    );
  });
});

bot.command('exportkomisi', (ctx) => {
  const userId = ctx.from.id;

  db.get('SELECT role FROM users WHERE user_id = ?', [userId], (err, row) => {
    if (err || !row || row.role !== 'reseller') {
      return ctx.reply('❌ Kamu bukan reseller.');
    }

    db.all('SELECT akun_type, username, komisi, created_at FROM reseller_sales WHERE reseller_id = ? ORDER BY created_at DESC LIMIT 20', [userId], (err, rows) => {
      if (err) {
        return ctx.reply('❌ Gagal mengambil data komisi.');
      }

      const now = new Date().toLocaleString('id-ID');
      let content = `===== LAPORAN KOMISI RESELLER =====\n\n`;
      content += `🧑‍💻 Reseller ID : ${userId}\n📅 Tanggal Export: ${now}\n\n`;
      content += `#  | Akun Type | Username   | Komisi | Tanggal\n`;
      content += `--------------------------------------------------\n`;

      rows.forEach((r, i) => {
        content += `${i + 1}  | ${r.akun_type.toUpperCase()}     | ${r.username.padEnd(10)} | ${r.komisi}     | ${r.created_at}\n`;
      });

      const filename = `komisi_${userId}.txt`;
      fs.writeFileSync(filename, content);

      ctx.replyWithDocument({ source: filename, filename }, {
        caption: '📁 Laporan Komisi Terbaru',
      });

      // Opsional: hapus file setelah dikirim
      setTimeout(() => fs.unlinkSync(filename), 5000);
    });
  });
});



bot.command('export_log', async (ctx) => {
  const userId = ctx.from.id;
  if (`${userId}` !== `${USER_ID}`) return ctx.reply('❌ Akses ditolak.');

  const filename = `/tmp/transactions-${Date.now()}.csv`;

  db.all('SELECT * FROM transactions ORDER BY created_at DESC', [], (err, rows) => {
    if (err) return ctx.reply('❌ Gagal ambil data.');

    const headers = Object.keys(rows[0] || {}).join(',') + '\n';
    const content = rows.map(r => Object.values(r).join(',')).join('\n');

    require('fs').writeFileSync(filename, headers + content);

    ctx.replyWithDocument({ source: filename });
  });
});


bot.command('promotereseller', async (ctx) => {
  const userId = ctx.message.from.id;
  if (!adminIds.includes(String(ctx.from.id))) {
  return ctx.reply('🚫 Anda tidak memiliki izin untuk mengakses menu admin.');
}

  const args = ctx.message.text.split(' ');
  if (args.length !== 2) {
    return ctx.reply('❗ Format: /promotereseller <user_id>');
  }

  const targetUserId = parseInt(args[1]);
  if (isNaN(targetUserId)) {
    return ctx.reply('❌ user_id harus berupa angka.');
  }

  db.run('UPDATE users SET role = "reseller" WHERE user_id = ?', [targetUserId], function (err) {
    if (err) {
      logger.error('❌ Error update role reseller:', err.message);
      return ctx.reply('❌ Gagal update role reseller.');
    }
    ctx.reply(`✅ User ${targetUserId} kini menjadi RESELLER.`);
  });
});

bot.command('hapuslog', async (ctx) => {
  if (!adminIds.includes(ctx.from.id)) return ctx.reply('Tidak ada izin!');
  try {
    if (fs.existsSync('bot-combined.log')) fs.unlinkSync('bot-combined.log');
    if (fs.existsSync('bot-error.log')) fs.unlinkSync('bot-error.log');
    ctx.reply('Log berhasil dihapus.');
    logger.info('Log file dihapus oleh admin.');
  } catch (e) {
    ctx.reply('Gagal menghapus log: ' + e.message);
    logger.error('Gagal menghapus log: ' + e.message);
  }
});

bot.command('helpadmin', async (ctx) => {
  const userId = ctx.message.from.id;

  // Pastikan userId di-casting ke string jika adminIds berupa string[]
  if (!adminIds.includes(String(userId))) {
    return ctx.reply('⚠️ Anda tidak memiliki izin untuk menggunakan perintah ini.', { parse_mode: 'Markdown' });
  }

  const helpMessage = `
*📋 Daftar Perintah Admin:*

1. /addserver - Menambahkan server baru.
2. /addsaldo - Menambahkan saldo ke akun pengguna.
3. /editharga - Mengedit harga layanan.
4. /editnama - Mengedit nama server.
5. /editdomain - Mengedit domain server.
6. /editauth - Mengedit auth server.
7. /editlimitquota - Mengedit batas quota server.
8. /editlimitip - Mengedit batas IP server.
9. /editlimitcreate - Mengedit batas pembuatan akun server.
10. /edittotalcreate - Mengedit total pembuatan akun server.
11. /broadcast - Mengirim pesan siaran ke semua pengguna.
12. /hapuslog - Menghapus log bot.

Gunakan perintah ini dengan format yang benar untuk menghindari kesalahan.
`.trim();

  await ctx.reply(helpMessage, { parse_mode: 'Markdown' });
});

bot.command('broadcast', async (ctx) => {
  const userId = String(ctx.from.id);

  // Validasi admin
  if (!adminIds.includes(userId)) {
    logger.info(`❌ User ${userId} bukan admin, tidak diizinkan broadcast.`);
    return ctx.reply('🚫 Anda tidak memiliki izin untuk melakukan broadcast.');
  }

  // Ambil isi pesan broadcast dari reply atau dari teks setelah /broadcast
  const message = ctx.message.reply_to_message
    ? ctx.message.reply_to_message.text
    : ctx.message.text.split(' ').slice(1).join(' ');

  if (!message || message.trim() === '') {
    return ctx.reply('⚠️ Mohon balas pesan yang ingin disiarkan, atau tulis setelah perintah `/broadcast`.', {
      parse_mode: 'Markdown'
    });
  }

  try {
    const rows = await new Promise((resolve, reject) => {
      db.all("SELECT user_id FROM users", [], (err, result) => {
        if (err) reject(err);
        else resolve(result);
      });
    });

    const results = await Promise.allSettled(rows.map(row => 
      ctx.telegram.sendMessage(row.user_id, message).catch(err => {
        logger.warn(`⚠️ Gagal kirim ke ${row.user_id}: ${err.message}`);
      })
    ));

    const sukses = results.filter(r => r.status === 'fulfilled').length;
    const gagal = results.length - sukses;

    await ctx.reply(`✅ Broadcast selesai.\n📤 Berhasil: ${sukses}\n❌ Gagal: ${gagal}`);
    logger.info(`📣 Broadcast selesai: ${sukses} sukses, ${gagal} gagal`);

  } catch (err) {
    logger.error('❌ Gagal melakukan broadcast:', err.message);
    return ctx.reply('⚠️ Terjadi kesalahan saat broadcast.');
  }
});
bot.command('saldo', (ctx) => {
  const state = userState[ctx.chat.id] || {}; // ⬅️ ini bikin gak error walau kosong
  const userId = ctx.from.id;

  db.get('SELECT saldo FROM users WHERE user_id = ?', [userId], (err, row) => {
    if (err) {
      logger.error('❌ Gagal mengambil saldo:', err.message);
      return ctx.reply('❌ Terjadi kesalahan saat mengambil saldo.');
    }

    if (!row) {
      return ctx.reply('⚠️ Akun tidak ditemukan.');
    }

    return ctx.reply(`💰 *Saldo Anda:* \`${row.saldo}\``, { parse_mode: 'Markdown' });
  });
});

bot.command('readlog', async (ctx) => {
  const userId = String(ctx.from.id);
  const logFile = '/var/log/sellvpn_backup.log';

  if (!adminIds.includes(userId)) {
    return ctx.reply('🚫 *Kamu tidak memiliki izin.*', { parse_mode: 'Markdown' });
  }

  try {
    if (!fs.existsSync(logFile)) {
      return ctx.reply('❌ *Log belum tersedia.*', { parse_mode: 'Markdown' });
    }

    const raw = fs.readFileSync(logFile, 'utf8');
    const lines = raw.trim().split('\n').slice(-10); // ambil 10 baris terakhir

    if (!lines.length) {
      return ctx.reply('⚠️ *Log kosong.*', { parse_mode: 'Markdown' });
    }

    const message = `📋 *Log Backup Terakhir:*\n\n\`\`\`\n${lines.join('\n')}\n\`\`\``;

    return ctx.reply(message, {
      parse_mode: 'Markdown',
      disable_web_page_preview: true
    });
  } catch (err) {
    logger.error('❌ Gagal baca log:', err.message);
    return ctx.reply('❌ *Gagal membaca log.*', { parse_mode: 'Markdown' });
  }
});

bot.command('clearlog', async (ctx) => {
  const userId = String(ctx.from.id);
  const logFile = '/var/log/sellvpn_backup.log';

  if (!adminIds.includes(userId)) {
    return ctx.reply('🚫 *Kamu tidak memiliki izin.*', { parse_mode: 'Markdown' });
  }

  try {
    if (!fs.existsSync(logFile)) {
      return ctx.reply('❌ *File log tidak ditemukan.*', { parse_mode: 'Markdown' });
    }

    fs.writeFileSync(logFile, '');
    logger.info(`[CLEARLOG] ${ctx.from.username} menghapus semua isi log.`);

    return ctx.reply('🧹 *Log berhasil dikosongkan.*', { parse_mode: 'Markdown' });
  } catch (err) {
    logger.error('❌ Gagal clear log:', err.message);
    return ctx.reply('❌ *Gagal menghapus log.*', { parse_mode: 'Markdown' });
  }
});

bot.command('riwayatreseller', (ctx) => {
  const userId = ctx.from.id;
  // 1. Cek role
  db.get('SELECT role FROM users WHERE user_id = ?', [userId], (err, user) => {
    if (err || !user || user.role !== 'reseller') {
      return ctx.reply('❌ Kamu bukan reseller.');
    }

    // 2. Ambil 10 transaksi terakhir
    db.all('SELECT akun_type, username, komisi, created_at FROM reseller_sales WHERE reseller_id = ? ORDER BY created_at DESC LIMIT 10', [userId], (err, rows) => {
      if (err || rows.length === 0) {
        return ctx.reply('ℹ️ Belum ada transaksi reseller.');
      }

      // 3. Format teks
      const list = rows.map((r, i) =>
        `${i + 1}. ${r.akun_type.toUpperCase()} - ${r.username} 💸 Rp${r.komisi} 🕒 ${r.created_at}`
      ).join('\n');

      const msg = `📜 *Riwayat Penjualan Terbaru (10)*\n\n${list}`;
      ctx.reply(msg, { parse_mode: 'Markdown' });
    });
  });
});


bot.command('addserver', async (ctx) => {
  const userId = ctx.message.from.id;
  if (!adminIds.includes(userId)) {
      return ctx.reply('⚠️ Anda tidak memiliki izin untuk menggunakan perintah ini.', { parse_mode: 'Markdown' });
  }

  const args = ctx.message.text.split(' ');
  if (args.length !== 7) {
      return ctx.reply('⚠️ Format salah. Gunakan: `/addserver <domain> <auth> <harga> <nama_server> <quota> <iplimit> <batas_create_account>`', { parse_mode: 'Markdown' });
  }

  const [domain, auth, harga, nama_server, quota, iplimit, batas_create_akun] = args.slice(1);

  const numberOnlyRegex = /^\d+$/;
  if (!numberOnlyRegex.test(harga) || !numberOnlyRegex.test(quota) || !numberOnlyRegex.test(iplimit) || !numberOnlyRegex.test(batas_create_akun)) {
      return ctx.reply('⚠️ `harga`, `quota`, `iplimit`, dan `batas_create_akun` harus berupa angka.', { parse_mode: 'Markdown' });
  }

  db.run("INSERT INTO Server (domain, auth, harga, nama_server, quota, iplimit, batas_create_akun) VALUES (?, ?, ?, ?, ?, ?, ?)", 
      [domain, auth, parseInt(harga), nama_server, parseInt(quota), parseInt(iplimit), parseInt(batas_create_akun)], function(err) {
      if (err) {
          logger.error('⚠️ Kesalahan saat menambahkan server:', err.message);
          return ctx.reply('⚠️ Kesalahan saat menambahkan server.', { parse_mode: 'Markdown' });
      }

      ctx.reply(`✅ Server \`${nama_server}\` berhasil ditambahkan.`, { parse_mode: 'Markdown' });
  });
});
bot.command('editharga', async (ctx) => {
  const userId = ctx.message.from.id;
  if (!adminIds.includes(userId)) {
      return ctx.reply('⚠️ Anda tidak memiliki izin untuk menggunakan perintah ini.', { parse_mode: 'Markdown' });
  }

  const args = ctx.message.text.split(' ');
  if (args.length !== 3) {
      return ctx.reply('⚠️ Format salah. Gunakan: `/editharga <domain> <harga>`', { parse_mode: 'Markdown' });
  }

  const [domain, harga] = args.slice(1);

  if (!/^\d+$/.test(harga)) {
      return ctx.reply('⚠️ `harga` harus berupa angka.', { parse_mode: 'Markdown' });
  }

  db.run("UPDATE Server SET harga = ? WHERE domain = ?", [parseInt(harga), domain], function(err) {
      if (err) {
          logger.error('⚠️ Kesalahan saat mengedit harga server:', err.message);
          return ctx.reply('⚠️ Kesalahan saat mengedit harga server.', { parse_mode: 'Markdown' });
      }

      if (this.changes === 0) {
          return ctx.reply('⚠️ Server tidak ditemukan.', { parse_mode: 'Markdown' });
      }

      ctx.reply(`✅ Harga server \`${domain}\` berhasil diubah menjadi \`${harga}\`.`, { parse_mode: 'Markdown' });
  });
});

bot.command('editnama', async (ctx) => {
  const userId = ctx.message.from.id;
  if (!adminIds.includes(userId)) {
      return ctx.reply('⚠️ Anda tidak memiliki izin untuk menggunakan perintah ini.', { parse_mode: 'Markdown' });
  }

  const args = ctx.message.text.split(' ');
  if (args.length !== 3) {
      return ctx.reply('⚠️ Format salah. Gunakan: `/editnama <domain> <nama_server>`', { parse_mode: 'Markdown' });
  }

  const [domain, nama_server] = args.slice(1);

  db.run("UPDATE Server SET nama_server = ? WHERE domain = ?", [nama_server, domain], function(err) {
      if (err) {
          logger.error('⚠️ Kesalahan saat mengedit nama server:', err.message);
          return ctx.reply('⚠️ Kesalahan saat mengedit nama server.', { parse_mode: 'Markdown' });
      }

      if (this.changes === 0) {
          return ctx.reply('⚠️ Server tidak ditemukan.', { parse_mode: 'Markdown' });
      }

      ctx.reply(`✅ Nama server \`${domain}\` berhasil diubah menjadi \`${nama_server}\`.`, { parse_mode: 'Markdown' });
  });
});

bot.command('editdomain', async (ctx) => {
  const userId = ctx.message.from.id;
  if (!adminIds.includes(userId)) {
      return ctx.reply('⚠️ Anda tidak memiliki izin untuk menggunakan perintah ini.', { parse_mode: 'Markdown' });
  }

  const args = ctx.message.text.split(' ');
  if (args.length !== 3) {
      return ctx.reply('⚠️ Format salah. Gunakan: `/editdomain <old_domain> <new_domain>`', { parse_mode: 'Markdown' });
  }

  const [old_domain, new_domain] = args.slice(1);

  db.run("UPDATE Server SET domain = ? WHERE domain = ?", [new_domain, old_domain], function(err) {
      if (err) {
          logger.error('⚠️ Kesalahan saat mengedit domain server:', err.message);
          return ctx.reply('⚠️ Kesalahan saat mengedit domain server.', { parse_mode: 'Markdown' });
      }

      if (this.changes === 0) {
          return ctx.reply('⚠️ Server tidak ditemukan.', { parse_mode: 'Markdown' });
      }

      ctx.reply(`✅ Domain server \`${old_domain}\` berhasil diubah menjadi \`${new_domain}\`.`, { parse_mode: 'Markdown' });
  });
});

bot.command('editauth', async (ctx) => {
  const userId = ctx.message.from.id;
  if (!adminIds.includes(userId)) {
      return ctx.reply('⚠️ Anda tidak memiliki izin untuk menggunakan perintah ini.', { parse_mode: 'Markdown' });
  }

  const args = ctx.message.text.split(' ');
  if (args.length !== 3) {
      return ctx.reply('⚠️ Format salah. Gunakan: `/editauth <domain> <auth>`', { parse_mode: 'Markdown' });
  }

  const [domain, auth] = args.slice(1);

  db.run("UPDATE Server SET auth = ? WHERE domain = ?", [auth, domain], function(err) {
      if (err) {
          logger.error('⚠️ Kesalahan saat mengedit auth server:', err.message);
          return ctx.reply('⚠️ Kesalahan saat mengedit auth server.', { parse_mode: 'Markdown' });
      }

      if (this.changes === 0) {
          return ctx.reply('⚠️ Server tidak ditemukan.', { parse_mode: 'Markdown' });
      }

      ctx.reply(`✅ Auth server \`${domain}\` berhasil diubah menjadi \`${auth}\`.`, { parse_mode: 'Markdown' });
  });
});

bot.command('editlimitquota', async (ctx) => {
  const userId = ctx.message.from.id;
  if (!adminIds.includes(userId)) {
      return ctx.reply('⚠️ Anda tidak memiliki izin untuk menggunakan perintah ini.', { parse_mode: 'Markdown' });
  }

  const args = ctx.message.text.split(' ');
  if (args.length !== 3) {
      return ctx.reply('⚠️ Format salah. Gunakan: `/editlimitquota <domain> <quota>`', { parse_mode: 'Markdown' });
  }

  const [domain, quota] = args.slice(1);

  if (!/^\d+$/.test(quota)) {
      return ctx.reply('⚠️ `quota` harus berupa angka.', { parse_mode: 'Markdown' });
  }

  db.run("UPDATE Server SET quota = ? WHERE domain = ?", [parseInt(quota), domain], function(err) {
      if (err) {
          logger.error('⚠️ Kesalahan saat mengedit quota server:', err.message);
          return ctx.reply('⚠️ Kesalahan saat mengedit quota server.', { parse_mode: 'Markdown' });
      }

      if (this.changes === 0) {
          return ctx.reply('⚠️ Server tidak ditemukan.', { parse_mode: 'Markdown' });
      }

      ctx.reply(`✅ Quota server \`${domain}\` berhasil diubah menjadi \`${quota}\`.`, { parse_mode: 'Markdown' });
  });
});

bot.command('editlimitip', async (ctx) => {
  const userId = ctx.message.from.id;
  if (!adminIds.includes(userId)) {
      return ctx.reply('⚠️ Anda tidak memiliki izin untuk menggunakan perintah ini.', { parse_mode: 'Markdown' });
  }

  const args = ctx.message.text.split(' ');
  if (args.length !== 3) {
      return ctx.reply('⚠️ Format salah. Gunakan: `/editlimitip <domain> <iplimit>`', { parse_mode: 'Markdown' });
  }

  const [domain, iplimit] = args.slice(1);

  if (!/^\d+$/.test(iplimit)) {
      return ctx.reply('⚠️ `iplimit` harus berupa angka.', { parse_mode: 'Markdown' });
  }

  db.run("UPDATE Server SET iplimit = ? WHERE domain = ?", [parseInt(iplimit), domain], function(err) {
      if (err) {
          logger.error('⚠️ Kesalahan saat mengedit iplimit server:', err.message);
          return ctx.reply('⚠️ Kesalahan saat mengedit iplimit server.', { parse_mode: 'Markdown' });
      }

      if (this.changes === 0) {
          return ctx.reply('⚠️ Server tidak ditemukan.', { parse_mode: 'Markdown' });
      }

      ctx.reply(`✅ Iplimit server \`${domain}\` berhasil diubah menjadi \`${iplimit}\`.`, { parse_mode: 'Markdown' });
  });
});

bot.command('editlimitcreate', async (ctx) => {
  const userId = ctx.message.from.id;
  if (!adminIds.includes(userId)) {
      return ctx.reply('⚠️ Anda tidak memiliki izin untuk menggunakan perintah ini.', { parse_mode: 'Markdown' });
  }

  const args = ctx.message.text.split(' ');
  if (args.length !== 3) {
      return ctx.reply('⚠️ Format salah. Gunakan: `/editlimitcreate <domain> <batas_create_akun>`', { parse_mode: 'Markdown' });
  }

  const [domain, batas_create_akun] = args.slice(1);

  if (!/^\d+$/.test(batas_create_akun)) {
      return ctx.reply('⚠️ `batas_create_akun` harus berupa angka.', { parse_mode: 'Markdown' });
  }

  db.run("UPDATE Server SET batas_create_akun = ? WHERE domain = ?", [parseInt(batas_create_akun), domain], function(err) {
      if (err) {
          logger.error('⚠️ Kesalahan saat mengedit batas_create_akun server:', err.message);
          return ctx.reply('⚠️ Kesalahan saat mengedit batas_create_akun server.', { parse_mode: 'Markdown' });
      }

      if (this.changes === 0) {
          return ctx.reply('⚠️ Server tidak ditemukan.', { parse_mode: 'Markdown' });
      }

      ctx.reply(`✅ Batas create akun server \`${domain}\` berhasil diubah menjadi \`${batas_create_akun}\`.`, { parse_mode: 'Markdown' });
  });
});

///reseller
bot.command('testnotifikasi', async (ctx) => {
  const axios = require('axios');
  const { BOT_TOKEN, GROUP_ID } = require('./.vars.json'); // sesuaikan path jika perlu

  const sender = ctx.from.username ? `@${ctx.from.username}` : ctx.from.first_name;
  const notif = `📦 Test Notifikasi Grup\n\n` +
                `👤 Dari: ${sender}\n` +
                `🕒 ${new Date().toLocaleString('id-ID')}`;

  try {
    await axios.post(`https://api.telegram.org/bot${BOT_TOKEN}/sendMessage`, {
      chat_id: GROUP_ID,
      text: notif
      // parse_mode dihapus biar aman tanpa markdown
    });

    await ctx.reply('✅ Test notifikasi terkirim ke grup!');
  } catch (err) {
    console.error('❌ Gagal kirim ke grup:', err.message);
    await ctx.reply('❌ Gagal kirim notifikasi ke grup.');
  }
});


bot.command('transfer', async (ctx) => {
  const [cmd, targetId, amountStr] = ctx.message.text.split(' ');

  const fromId = ctx.from.id;
  const amount = parseInt(amountStr);

  if (!targetId || isNaN(amount) || amount <= 0) {
    return ctx.reply('❌ Format salah.\n\nContoh:\n/transfer 123456789 5000');
  }

  db.get('SELECT saldo, role FROM users WHERE user_id = ?', [fromId], (err, fromUser) => {
    if (err || !fromUser || fromUser.role !== 'reseller') {
      return ctx.reply('❌ Kamu bukan reseller atau data tidak ditemukan.');
    }

    if (fromUser.saldo < amount) {
      return ctx.reply('❌ Saldo kamu tidak cukup untuk transfer.');
    }

    if (fromId.toString() === targetId.toString()) {
      return ctx.reply('❌ Tidak bisa transfer ke diri sendiri.');
    }

    db.get('SELECT user_id FROM users WHERE user_id = ?', [targetId], (err, targetUser) => {
      if (err) return ctx.reply('❌ Gagal cek user tujuan.');
      if (!targetUser) return ctx.reply('❌ User tujuan tidak ditemukan.');

      db.run('UPDATE users SET saldo = saldo - ? WHERE user_id = ?', [amount, fromId], (err) => {
        if (err) return ctx.reply('❌ Gagal potong saldo pengirim.');

        db.run('UPDATE users SET saldo = saldo + ? WHERE user_id = ?', [amount, targetId], (err) => {
          if (err) return ctx.reply('❌ Gagal tambahkan saldo ke penerima.');

          // ✅ Simpan log transfer ke database
          db.run(`
            INSERT INTO transfer_log (from_id, to_id, jumlah, created_at)
            VALUES (?, ?, ?, datetime('now'))
          `, [fromId, targetId, amount], (err) => {
            if (err) {
              console.error('❌ Gagal simpan log transfer:', err.message);
            }
          });

          ctx.reply(`✅ Transfer saldo Rp${amount.toLocaleString('id-ID')} ke user ${targetId} berhasil.`);
        });
      });
    });
  });
});

bot.command('me', async (ctx) => {
  db.get('SELECT role, reseller_level, saldo FROM users WHERE user_id = ?', [ctx.from.id], (err, row) => {
    if (!row) return ctx.reply('🚫 Kamu belum terdaftar.');

    const teks = `
👤 Akun Info:
- Role  : ${row.role}
- Level : ${row.reseller_level || 'N/A'}
- Saldo : Rp${row.saldo.toLocaleString('id-ID')}
    `.trim();

    ctx.reply(teks);
  });
});

bot.command('demote_reseller', async (ctx) => {
  const adminId = String(ctx.from.id);
  const text = ctx.message.text.trim();
  const args = text.split(' ');

  if (args.length < 2) {
    return ctx.reply('⚠️ Gunakan format: /demote_reseller <user_id>');
  }

  const targetId = parseInt(args[1]);
  if (isNaN(targetId)) {
    return ctx.reply('❌ ID tidak valid. Masukkan ID numerik.');
  }

  const rawAdmin = vars.USER_ID;
  const adminIds = Array.isArray(rawAdmin)
    ? rawAdmin.map(String)
    : [String(rawAdmin)];

  if (!adminIds.includes(adminId)) {
    return ctx.reply('⛔ Hanya admin yang bisa menggunakan perintah ini.');
  }

  db.run(
    `UPDATE users SET role = 'user', reseller_level = NULL WHERE user_id = ?`,
    [targetId],
    function (err) {
      if (err) {
        logger.error('❌ DB error saat demote:', err.message);
        return ctx.reply('❌ Gagal melakukan demote user.');
      }

      if (this.changes === 0) {
        return ctx.reply('⚠️ User belum terdaftar atau sudah bukan reseller.');
      }

      ctx.reply(`✅ User ${targetId} telah diubah menjadi USER biasa.`);
    }
  );
});

bot.command('promote_reseller', async (ctx) => {
  const adminId = String(ctx.from.id);
  const text = ctx.message.text.trim();
  const args = text.split(' ');

  // Validasi format
  if (args.length < 2) {
    return ctx.reply('⚠️ Gunakan format: /promote_reseller <user_id>');
  }

  const targetId = parseInt(args[1]);
  if (isNaN(targetId)) {
    return ctx.reply('❌ ID tidak valid. Masukkan ID numerik.');
  }

  const rawAdmin = vars.USER_ID;
  const adminIds = Array.isArray(rawAdmin)
    ? rawAdmin.map(String)
    : [String(rawAdmin)];

  if (!adminIds.includes(adminId)) {
    return ctx.reply('⛔ Hanya admin yang bisa menggunakan perintah ini.');
  }

  // Update DB
  db.run(
    `UPDATE users SET role = 'reseller', reseller_level = 'silver' WHERE user_id = ?`,
    [targetId],
    function (err) {
      if (err) {
        logger.error('❌ DB error saat promote reseller:', err.message);
        return ctx.reply('❌ Gagal mempromosikan user.');
      }

      if (this.changes === 0) {
        return ctx.reply('⚠️ User belum terdaftar. Tambahkan dulu ke sistem.');
      }

      ctx.reply(`✅ User ${targetId} telah dipromosikan jadi RESELLER!`);
    }
  );
});

bot.command('edittotalcreate', async (ctx) => {
  const userId = ctx.message.from.id;
  if (!adminIds.includes(userId)) {
      return ctx.reply('⚠️ Anda tidak memiliki izin untuk menggunakan perintah ini.', { parse_mode: 'Markdown' });
  }

  const args = ctx.message.text.split(' ');
  if (args.length !== 3) {
      return ctx.reply('⚠️ Format salah. Gunakan: `/edittotalcreate <domain> <total_create_akun>`', { parse_mode: 'Markdown' });
  }

  const [domain, total_create_akun] = args.slice(1);

  if (!/^\d+$/.test(total_create_akun)) {
      return ctx.reply('⚠️ `total_create_akun` harus berupa angka.', { parse_mode: 'Markdown' });
  }

  db.run("UPDATE Server SET total_create_akun = ? WHERE domain = ?", [parseInt(total_create_akun), domain], function(err) {
      if (err) {
          logger.error('⚠️ Kesalahan saat mengedit total_create_akun server:', err.message);
          return ctx.reply('⚠️ Kesalahan saat mengedit total_create_akun server.', { parse_mode: 'Markdown' });
      }

      if (this.changes === 0) {
          return ctx.reply('⚠️ Server tidak ditemukan.', { parse_mode: 'Markdown' });
      }

      ctx.reply(`✅ Total create akun server \`${domain}\` berhasil diubah menjadi \`${total_create_akun}\`.`, { parse_mode: 'Markdown' });
  });
});

//restore
bot.command('restore', async (ctx) => {
  const userId = String(ctx.from.id);
  if (!adminIds.includes(userId)) return;

  // Simpan state user untuk tunggu upload
  userState[ctx.chat.id] = {
    step: 'await_restore_upload'
  };

  await ctx.reply(
    '📤 Silakan kirim file backup database (.db) yang ingin direstore.\nContoh: sellvpn_2025-06-01_10-00.db'
  );
});

bot.command('restoreupload', async (ctx) => {
  const userId = String(ctx.from.id);
  const UPLOAD_DIR = '/root/BotVPN2/uploaded_restore';

  if (!adminIds.includes(userId)) return;

  try {
    const files = fs.readdirSync(UPLOAD_DIR)
      .filter(f => f.endsWith('.db'))
      .sort((a, b) => fs.statSync(path.join(UPLOAD_DIR, b)).mtimeMs - fs.statSync(path.join(UPLOAD_DIR, a)).mtimeMs);

    if (!files.length) {
      return ctx.reply('❌ Tidak ada file restore yang diupload.');
    }

    const buttons = files.map(f => [{
      text: `📂 ${f}`,
      callback_data: `restore_uploaded_file::${f}`
    }]);

    return ctx.reply('📦 Pilih file restore hasil upload:', {
      reply_markup: { inline_keyboard: buttons }
    });
  } catch (err) {
    logger.error('Gagal /restoreupload:', err.message);
    return ctx.reply('❌ Gagal membaca file upload.');
  }
});

bot.on('document', async (ctx) => {
  const userId = String(ctx.from.id);
  const state = userState[ctx.chat?.id];
  const doc = ctx.message.document;
  const fileName = doc.file_name;
  const filePath = path.join(UPLOAD_DIR, fileName);

  // Cek admin dan mode restore aktif
  if (!adminIds.includes(userId) || !state || state.step !== 'await_restore_upload') return;

  // Validasi file ekstensi
  if (!fileName.endsWith('.db')) {
    return ctx.reply('❌ Hanya file dengan ekstensi .db yang didukung.');
  }

  try {
    // Unduh file dari Telegram
    const fileLink = await ctx.telegram.getFileLink(doc.file_id);
    const res = await fetch(fileLink.href);
    const buffer = await res.arrayBuffer();
    fs.writeFileSync(filePath, Buffer.from(buffer));

    // ✅ CEK: Apakah file sama sudah direstore sebelumnya?
    if (fs.existsSync(DB_PATH)) {
      const dbStat = fs.statSync(DB_PATH);
      const uploadedStat = fs.statSync(filePath);
      const timeDiff = Math.abs(dbStat.mtimeMs - uploadedStat.mtimeMs);
      if (timeDiff < 1000) {
        return ctx.reply('⚠️ File ini sudah direstore sebelumnya.');
      }
    }

    // ✅ RESTORE
    fs.copyFileSync(filePath, DB_PATH);
    await ctx.reply(`✅ Restore berhasil dari file: ${fileName}\n\nBot siap digunakan kembali.`);

    // 🧠 Simpan log restore (kalau ada fungsi logRestoreAction)
    if (typeof logRestoreAction === 'function') {
      logRestoreAction('restore_cmd', fileName, ctx.from.username, ctx.from.id);
    }

  } catch (err) {
    logger?.error?.('Restore via /restore gagal:', err.message);
    ctx.reply('❌ Gagal restore file.');
  }

  // 🧹 Hapus state agar gak trigger ulang
  delete userState[ctx.chat.id];
});

// Fungsi updateGlobalStats
async function updateGlobalStats() {
  try {
    const resellerCount = await dbGetAsync('SELECT COUNT(*) AS count FROM users WHERE role = "reseller"');
    const totalAkun = await dbGetAsync('SELECT COUNT(*) AS count FROM akun');
    const totalServers = await dbGetAsync('SELECT COUNT(*) AS count FROM Server WHERE total_create_akun > 0');

    // Buat tabel jika belum ada (opsional, sekali saja)
    await dbRunAsync(`
      CREATE TABLE IF NOT EXISTS global_stats (
        id INTEGER PRIMARY KEY,
        reseller_count INTEGER DEFAULT 0,
        total_akun INTEGER DEFAULT 0,
        total_servers INTEGER DEFAULT 0
      )
    `);

    // Insert pertama jika kosong
    await dbRunAsync(`INSERT OR IGNORE INTO global_stats (id) VALUES (1)`);

    // Update isinya
    await dbRunAsync(`
      UPDATE global_stats
      SET reseller_count = ?, total_akun = ?, total_servers = ?
      WHERE id = 1
    `, [resellerCount.count, totalAkun.count, totalServers.count]);

    console.log('✅ Statistik global diperbarui');
  } catch (err) {
    console.error('❌ Gagal update statistik global:', err.message);
  }
}

///waktuuu
async function refreshCacheIfNeeded() {
  const now = Date.now();
  const delay = 60 * 1000; // 1 menit

  if (now - cacheStatus.lastUpdated < delay) return;

  try {
    const serverCount = await dbGetAsync('SELECT COUNT(*) AS count FROM Server');
    const userCount = await dbGetAsync('SELECT COUNT(*) AS count FROM users');

    cacheStatus.jumlahServer = serverCount?.count || 0;
    cacheStatus.jumlahPengguna = userCount?.count || 0;
    cacheStatus.lastUpdated = now;
    logger.info('✅ Cache status diperbarui otomatis');
  } catch (err) {
    logger.warn('⚠️ Gagal refresh cache status:', err.message);
  }
}

// 🔰 Kirim Menu Utama
async function sendMainMenu(ctx) {
  const userId = ctx.from.id;
  const uptime = os.uptime();
  const uptimeFormatted = `${Math.floor((uptime % 86400) / 3600)}j ${Math.floor((uptime % 3600) / 60)}m`;
  const tanggal = new Date().toLocaleDateString('id-ID');

  await refreshCacheIfNeeded();

  let saldo = 0, role = '', reseller_level = '', totalAkunDibuat = 0;
  let topResellerText = '';

  try {
    const akunData = await dbGetAsync('SELECT COUNT(*) AS total FROM invoice_log WHERE user_id = ?', [userId]);
    totalAkunDibuat = akunData?.total || 0;

    const user = await dbGetAsync('SELECT saldo, role, reseller_level FROM users WHERE user_id = ?', [userId]);
    saldo = user?.saldo || 0;
    role = user?.role || 'user';
    reseller_level = user?.reseller_level || 'silver';

    // Ambil Top 3 Reseller Mingguan
    const topReseller = await dbAllAsync(`
      SELECT 
  u.username,
  r.reseller_id,
  SUM(r.komisi) AS total_komisi,
  COUNT(DISTINCT i.id) AS total_create
FROM reseller_sales r
LEFT JOIN users u ON u.user_id = r.reseller_id
LEFT JOIN invoice_log i ON i.user_id = r.reseller_id AND i.created_at >= datetime('now', '-7 days')
WHERE r.created_at >= datetime('now', '-7 days')
GROUP BY r.reseller_id
ORDER BY total_komisi DESC
LIMIT 3
    `);

    if (topReseller.length > 0) {
      const medals = ['🥇', '🥈', '🥉'];
      topResellerText = `🏆 *Top Reseller Mingguan :*\n`;
      topReseller.forEach((r, i) => {
  const mention = r.username
    ? `@${escapeMarkdownV2(r.username)}`
    : `ID\\_${escapeMarkdownV2(r.reseller_id)}`;
  const komisi = escapeMarkdownV2((r.total_komisi || 0).toLocaleString('id-ID'));
  const totalAkun = escapeMarkdownV2(r.total_create || 0);
  topResellerText += `${medals[i]} ${mention} \\- ${totalAkun} akun\n`;
});
    }
  } catch (err) {
    logger.error(`❌ Gagal ambil data user/top reseller: ${err.message}`);
  }

  const roleLabel = role === 'admin'
    ? '👑 Admin'
    : role === 'reseller'
      ? `🏆 Reseller (${reseller_level.toUpperCase()})`
      : 'User';

  const keyboard = [];

  if (role === 'reseller') {
    keyboard.push([{ text: '⚙️ Menu Reseller', callback_data: 'menu_reseller' }]);
  }

  if (role === 'admin' || adminIds.includes(String(userId))) {
    keyboard.push([{ text: '🛠 Menu Admin', callback_data: 'menu_adminreseller' }]);
  }

  keyboard.push([
    { text: '🛒 Create Akun', callback_data: 'service_create' },
    { text: '🧪 Trial Akun', callback_data: 'service_trial' }
  ]);
  keyboard.push([
    { text: '♻️ Renew Akun', callback_data: 'service_renew' },
    { text: '💳 TopUp Saldo', callback_data: 'topup_saldo' }    
  ]);
  keyboard.push([
  { text: '🔼 Upgrade ke Reseller', callback_data: 'upgrade_to_reseller' },
  ]);
  const text = `
━━━━━━━━━━━━━━━━━━━━━━
📂 *BOT PANEL VPN AUTOMATIC*
━━━━━━━━━━━━━━━━━━━━━━
📋 *Informasi Akun*
🛍 *Store*     : ${escapeMarkdownV2(NAMA_STORE)}
💳 *Saldo*     : Rp${escapeMarkdownV2(saldo.toLocaleString('id-ID'))}
📜 *Akun Dibuat* : ${escapeMarkdownV2(totalAkunDibuat)}
🏷 *Status*    : ${escapeMarkdownV2(roleLabel)}
🆔 *ID Anda*   : \`${userId}\`
🔒 *Admin Bot* : @kapalduruk
🕒 *Update Cache* : ${escapeMarkdownV2(new Date(cacheStatus.lastUpdated).toLocaleTimeString('id-ID'))}
━━━━━━━━━━━━━━━━━━━━━━
${topResellerText.trim()}
━━━━━━━━━━━━━━━━━━━━━━
`.trim();

  try {
    if (ctx.updateType === 'callback_query') {
      await ctx.answerCbQuery();
      await ctx.editMessageText(text, {
        parse_mode: 'MarkdownV2',
        reply_markup: { inline_keyboard: keyboard }
      });
    } else {
      await ctx.reply(text, {
        parse_mode: 'MarkdownV2',
        reply_markup: { inline_keyboard: keyboard }
      });
    }
    logger.info(`✅ Menu utama dikirim ke ${userId}`);
  } catch (err) {
    logger.error(`❌ Gagal kirim menu utama: ${err.message}`);
    await ctx.reply('❌ Gagal menampilkan menu utama.');
  }
}

// 🔁 Handle Layanan: create / renew / trial
async function handleServiceAction(ctx, action) {
  const { keyboard, pesan } = generateServiceMenu(action);

  try {
    await ctx.editMessageText(pesan, {
      parse_mode: 'Markdown',
      reply_markup: { inline_keyboard: keyboard }
    });
  } catch (error) {
    await ctx.reply(pesan, {
      parse_mode: 'Markdown',
      reply_markup: { inline_keyboard: keyboard }
    });
  }
}

// 🔧 Generate tombol sesuai jenis layanan
function generateServiceMenu(action) {
  let keyboard = [], teks = '';

  if (action === 'create') {
    teks = `
🚀 *Pembuatan Akun VPN Premium*

Layanan *Bot* tersedia 24 jam, tanpa ribet!
Pilih jenis akun di bawah ini dan sistem
kami akan memprosesnya
secara otomatis 💯

Koneksi cepat, aman, dan stabil
`.trim();

    keyboard = [
      [
        { text: '🧿 Create Ssh', callback_data: 'create_ssh' },
        { text: '🌐 Create Vmess', callback_data: 'create_vmess' }
      ],
      [
        { text: '🔓 Create Vless', callback_data: 'create_vless' },
        { text: '⚡ Create Trojan', callback_data: 'create_trojan' }
      ],
      [
        { text: '🔙 Kembali', callback_data: 'send_main_menu' }
      ]
    ];

  } else if (action === 'renew') {
    teks = `
♻️ *Perpanjangan Akun VPN*

Ingin melanjutkan masa aktif akun kamu?
Pilih jenis akun di bawah ini dan pastikan
*Saldo Anda Cukup* dan pastikan juga
masa aktif akun sebelum *Expired*

Silahkan pilih sesuai akun *Anda*
`.trim();

    keyboard = [
      [
        { text: '🧿 Renew Ssh', callback_data: 'renew_ssh' },
        { text: '🌐 Renew Vmess', callback_data: 'renew_vmess' }
      ],
      [
        { text: '🔓 Renew Vless', callback_data: 'renew_vless' },
        { text: '⚡ Renew Trojan', callback_data: 'renew_trojan' }
      ],
      [
        { text: '🔙 Kembali', callback_data: 'send_main_menu' }
      ]
    ];

  } else if (action === 'trial') {
    teks = `
🧪 *Akun Trial Gratis*

Coba dulu sebelum berlangganan!!!
Akun trial ini cocok buat kamu yang ingin
menguji kecepatan, kestabilan,
dan kualitas layanan kami.

Pilih jenis layanan dibawah ini.
`.trim();

    keyboard = [
      [
        { text: '🧿 Trial Ssh', callback_data: 'trial_ssh' },
        { text: '🌐 Trial Vmess', callback_data: 'trial_vmess' }
      ],
      [
        { text: '🔓 Trial Vless', callback_data: 'trial_vless' },
        { text: '⚡ Trial Trojan', callback_data: 'trial_trojan' }
      ],
      [
        { text: '🔙 Kembali', callback_data: 'send_main_menu' }
      ]
    ];
  }

  return { keyboard, pesan: teks };
}
///  Trial
async function showTrialServerMenu(ctx, jenis) {
  try {
    const servers = await dbAllAsync('SELECT id, nama_server, lokasi FROM Server');
    if (!servers || servers.length === 0) {
      return ctx.reply('⚠️ *PERHATIAN!*\nTidak ada server yang tersedia saat ini. Coba lagi nanti!', {
        parse_mode: 'Markdown'
      });
    }

    const keyboard = servers.map(s => [{
      text: `🌐 ${s.nama_server}`,
      callback_data: `trial_server_${jenis}_${s.id}`
    }]);

    keyboard.push([{ text: '⬅️ Kembali', callback_data: 'service_trial' }]);

    const pesan = `
🧪 *Pilih server untuk Trial ${jenis.toUpperCase()}:*

⚠️ *Perhatian:*
- Trial hanya aktif selama 60 menit.
- Kuota trial terbatas, gunakan dengan bijak.
- Satu user hanya boleh ambil trial sekali.

Silakan pilih server di bawah:
    `.trim();

    await ctx.editMessageText(pesan, {
      parse_mode: 'Markdown',
      reply_markup: { inline_keyboard: keyboard }
    });
  } catch (err) {
    logger.error(`❌ Gagal tampilkan server trial untuk ${jenis}:`, err.message);
    await ctx.reply('❌ Terjadi kesalahan saat memuat daftar server.');
  }
}
///halaman
async function startSelectServer(ctx, action, type, page = 0) {
  try {
    logger.info(`Memulai proses ${action} untuk ${type} di halaman ${page + 1}`);

    const servers = await dbAllAsync('SELECT * FROM Server');
    if (!servers || servers.length === 0) {
      return ctx.reply('⚠️ *PERHATIAN!*\nTidak ada server yang tersedia saat ini. Coba lagi nanti!', {
        parse_mode: 'Markdown'
      });
    }

    const serversPerPage = 3;
    const totalPages = Math.ceil(servers.length / serversPerPage);
    const currentPage = Math.min(Math.max(page, 0), totalPages - 1);
    const start = currentPage * serversPerPage;
    const currentServers = servers.slice(start, start + serversPerPage);

    const keyboard = [];
    for (let i = 0; i < currentServers.length; i += 2) {
      const row = [];

      const s1 = currentServers[i];
      const s2 = currentServers[i + 1];

      row.push({
        text: `${s1.nama_server}`,
        callback_data: `${action}_username_${type}_${s1.id}`
      });

      if (s2) {
        row.push({
          text: `${s2.nama_server}`,
          callback_data: `${action}_username_${type}_${s2.id}`
        });
      }

      keyboard.push(row);
    }

    // Navigasi
    const navButtons = [];
    if (totalPages > 1) {
      if (currentPage > 0) {
        navButtons.push({
          text: '⬅️ Back',
          callback_data: `navigate_${action}_${type}_${currentPage - 1}`
        });
      }
      if (currentPage < totalPages - 1) {
        navButtons.push({
          text: '➡️ Next',
          callback_data: `navigate_${action}_${type}_${currentPage + 1}`
        });
      }
      keyboard.push(navButtons);
    }

    keyboard.push([{ text: '🔙 BACK TO MENU', callback_data: 'send_main_menu' }]);

    // Format teks server
    const serverList = currentServers.map(server => {
      const harga30 = server.harga * 30;
      const isFull = server.total_create_akun >= server.batas_create_akun;
      const flag = getFlagEmojiByLocation(server.lokasi);
      const status = isFull ? '❌ PENUH' : '✅ Tersedia';

      return `
━━━━━━━━━━━━━━━━━━━━━━
🌐 Server : *${server.nama_server}*
💵 Rp${server.harga.toLocaleString('id-ID')} / hari
💳 Rp${harga30.toLocaleString('id-ID')} / bulan
📊 Kuota   : *${server.quota} GB*
🔢 IP Max  : *${server.iplimit}*
📍 Lokasi  : *${server.lokasi || '-'}*
🏢 ISP  : *${server.isp || '-'}*
📈 Akun    : *${server.total_create_akun}/${server.batas_create_akun}*
🧭 Status  : *${status}*
━━━━━━━━━━━━━━━━━━━━━━`.trim();
    }).join('\n\n');

    const text = `📋 *List Server (Halaman ${currentPage + 1} dari ${totalPages}):*\n\n${serverList}`;

    await ctx.editMessageText(text, {
      parse_mode: 'Markdown',
      reply_markup: { inline_keyboard: keyboard }
    });

    userState[ctx.chat.id] = {
      step: `${action}_username_${type}`,
      page: currentPage
    };

  } catch (error) {
    logger.error(`❌ Error saat memulai proses ${action} untuk ${type}:`, error);
    await ctx.reply('❌ Terjadi kesalahan saat memuat server. Coba lagi nanti.', {
      parse_mode: 'Markdown'
    });
  }
}

async function sendAdminMenu(ctx) {
  const adminKeyboard = [
    [
      { text: '➕ Tambah Server', callback_data: 'addserver' },
      { text: '❌ Hapus Server', callback_data: 'deleteserver' }
    ],
    [
      { text: '💲 Edit Harga', callback_data: 'editserver_harga' },
      { text: '📝 Edit Nama', callback_data: 'nama_server_edit' }
    ],
    [
      { text: '🌐 Edit Domain', callback_data: 'editserver_domain' },
      { text: '🔑 Edit Auth', callback_data: 'editserver_auth' }
    ],
    [
      { text: '📊 Edit Quota', callback_data: 'editserver_quota' },
      { text: '📶 Edit Limit IP', callback_data: 'editserver_limit_ip' }
    ],
    [
      { text: '🔢 Edit Batas Create', callback_data: 'editserver_batas_create_akun' },
      { text: '🔢 Edit Total Create', callback_data: 'editserver_total_create_akun' }
    ],
    [
      { text: '💵 Tambah Saldo', callback_data: 'addsaldo_user' },
      { text: '📋 List Server', callback_data: 'listserver' }
    ],
    [
      { text: '♻️ Reset Server', callback_data: 'resetdb' },
      { text: 'ℹ️ Detail Server', callback_data: 'detailserver' }
    ],
    [
      { text: '🔙 Kembali', callback_data: 'send_main_menu' }
    ]
  ];

  try {
    await ctx.editMessageReplyMarkup({
      inline_keyboard: adminKeyboard
    });
    logger.info('Admin menu sent');
  } catch (error) {
    if (error.response && error.response.error_code === 400) {
      await ctx.reply('⚙️ MENU ADMIN', {
        reply_markup: {
          inline_keyboard: adminKeyboard
        }
      });
      logger.info('Admin menu sent as new message');
    } else {
      logger.error('Error saat mengirim menu admin:', error);
    }
  }
}

///Upgrade to reseller
bot.action('upgrade_to_reseller', async (ctx) => {
  const userId = ctx.from.id;

  const user = await dbGetAsync('SELECT saldo, role FROM users WHERE user_id = ?', [userId]);

  if (!user) {
    return ctx.reply('❌ Akun tidak ditemukan di sistem.');
  }

  if (user.role === 'reseller') {
    return ctx.reply('✅ Kamu sudah menjadi reseller.');
  }

  const minimumSaldo = 50000;

  if (user.saldo < minimumSaldo) {
    return ctx.reply(
      escapeMarkdownV2(
        `💸 Saldo kamu belum cukup untuk upgrade.\n` +
        `Minimal saldo: Rp${minimumSaldo.toLocaleString('id-ID')}\n` +
        `Saldo kamu: Rp${user.saldo.toLocaleString('id-ID')}`
      ),
      { parse_mode: 'MarkdownV2' }
    );
  }

  // Konfirmasi upgrade
  const pesanKonfirmasi = 
    `🆙 𝗨𝗽𝗴𝗿𝗮𝗱𝗲 𝗸𝗲 𝗥𝗲𝘀𝗲𝗹𝗹𝗲𝗿\n\n` +
    `💵 Biaya: Rp${minimumSaldo.toLocaleString('id-ID')}\n` +
    `🎯 Persyaratan:\n` +
    `• Wajib bisa cara buat config sendiri\n` +
    `• Sudah paham cara jualan\n` +
    `• Siap bertanggung jawab\n\n` +
    `Dengan menjadi Reseller, kamu bisa:\n` +
    `✅ Mendapat harga khusus\n` +
    `✅ Mengelola akun user sendiri\n` +
    `✅ Mengakses menu reseller di bot ini\n\n` +
    `Klik Ya kalau kamu siap upgrade 🚀`;

  return ctx.reply(escapeMarkdownV2(pesanKonfirmasi), {
    parse_mode: 'MarkdownV2',
    reply_markup: {
      inline_keyboard: [
        [{ text: '✅ Ya, Upgrade Sekarang', callback_data: 'confirm_upgrade_reseller' }],
        [{ text: '❌ Batal', callback_data: 'send_main_menu' }]
      ]
    }
  });
});

bot.action('confirm_upgrade_reseller', async (ctx) => {
  const userId = ctx.from.id;
  const minimumSaldo = 50000;

  const user = await dbGetAsync('SELECT saldo, role FROM users WHERE user_id = ?', [userId]);
  if (!user) return ctx.reply('❌ Akun tidak ditemukan.');
  if (user.role === 'reseller') return ctx.reply('✅ Kamu sudah menjadi reseller.');

  if (user.saldo < minimumSaldo) {
    return ctx.reply(escapeMarkdownV2(`❌ Saldo kamu tidak mencukupi untuk upgrade.`), { parse_mode: 'MarkdownV2' });
  }

  await dbRunAsync('UPDATE users SET role = "reseller", reseller_level = "silver", saldo = saldo - ? WHERE user_id = ?', [minimumSaldo, userId]);

  // ✅ Catat log upgrade reseller
  await dbRunAsync(`
    INSERT INTO reseller_upgrade_log (user_id, username, amount, level, created_at)
    VALUES (?, ?, ?, ?, datetime('now'))
  `, [userId, ctx.from.username || ctx.from.first_name, minimumSaldo, 'silver']);

  await ctx.reply(
    escapeMarkdownV2(
      '🏆 𝗦𝗲𝗹𝗮𝗺𝗮𝘁 Kamu telah berhasil upgrade ke Reseller.\n' +
      'Silakan mulai transaksi dengan harga lebih murah!'
    ),
    { parse_mode: 'MarkdownV2' }
  );

  // Opsional: kirim ke GROUP_ID
  if (GROUP_ID) {
    const mention = ctx.from.username
      ? `@${escapeMarkdownV2(ctx.from.username)}`
      : `[${escapeMarkdownV2(ctx.from.first_name)}](tg://user?id=${ctx.from.id})`;

    const notif = `
━━━━━━━━━━━━━━━━━━━━━━━
🏆 *UPGRADE KE RESELLER*
━━━━━━━━━━━━━━━━━━━━━━━
💌 *User:* ${mention}
💰 *Bayar:* Rp${escapeMarkdownV2(minimumSaldo.toLocaleString('id-ID'))}
📈 *Role:* Reseller  _Silver_
🕒 *Waktu:* ${escapeMarkdownV2(new Date().toLocaleString('id-ID'))}
━━━━━━━━━━━━━━━━━━━━━━━
    `.trim();

    await bot.telegram.sendMessage(GROUP_ID, notif, { parse_mode: 'MarkdownV2' });
  }
});

///admin
// ===== Admin Panel Main Menu =====
bot.action('menu_adminreseller', async (ctx) => {
  const userId = ctx.from.id;

  try {
    const user = await dbGetAsync('SELECT role FROM users WHERE user_id = ?', [userId]);

    if ((!user || user.role !== 'admin') && !adminIds.includes(String(userId))) {
      return ctx.reply('🚫 Kamu tidak memiliki izin.');
    }

    const keyboard = {
      inline_keyboard: [
        [{ text: '🖥️ Menu Server', callback_data: 'admin_server_menu' }],
        [{ text: '⚙️ Menu Sistem', callback_data: 'admin_system_menu' }],
        [{ text: '⬅️ Kembali', callback_data: 'send_main_menu' }]
      ]
    };

    const content = `
👑 *Menu Admin Panel*

🗓️ *${new Date().toLocaleDateString('id-ID', {
  weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
})}*
🕒 *${new Date().toLocaleTimeString('id-ID')}*

📌 Silakan pilih Layanan di bawah ini:
`.trim();

    await ctx.editMessageText(content, {
      parse_mode: 'Markdown',
      reply_markup: keyboard
    });
  } catch (err) {
    logger.error('❌ Gagal tampilkan menu admin:', err.message);
    await ctx.reply('❌ Gagal menampilkan menu admin.');
  }
});

// =================== MENU SERVER ===================
bot.action('admin_server_menu', async (ctx) => {
  const keyboardServer = {
    inline_keyboard: [
      [
        { text: '➕ Tambah Server', callback_data: 'addserver' },
        { text: '❌ Hapus Server', callback_data: 'deleteserver' }
      ],
      [
        { text: '💲 Edit Harga', callback_data: 'editserver_harga' },
        { text: '📝 Edit Nama', callback_data: 'nama_server_edit' }
      ],
      [
        { text: '🌐 Edit Domain', callback_data: 'editserver_domain' },
        { text: '🔑 Edit Auth', callback_data: 'editserver_auth' }
      ],
      [
        { text: '📊 Edit Quota', callback_data: 'editserver_quota' },
        { text: '📶 Edit Limit Ip', callback_data: 'editserver_limit_ip' }
      ],
      [
        { text: '💵 Tambah Saldo', callback_data: 'addsaldo_user' },
        { text: 'ℹ️ Detail Server', callback_data: 'detailserver' }
      ],
      [
        { text: '🔢 Batas Create', callback_data: 'editserver_batas_create_akun' },
        { text: '🔢 Total Create', callback_data: 'editserver_total_create_akun' }
      ],
      [
        { text: '📋 List Server', callback_data: 'listserver' },
        { text: '♻️ Reset Server', callback_data: 'resetdb' }
      ],
      [{ text: '⬅️ Kembali', callback_data: 'menu_adminreseller' }]
    ]
  };

  const message = `
🛠️ *Menu Admin - Server*

Silakan pilih manajemen server!!!
`.trim();

  try {
    await ctx.editMessageText(message, {
      parse_mode: 'Markdown',
      reply_markup: keyboardServer
    });
  } catch {
    await ctx.reply(message, {
      parse_mode: 'Markdown',
      reply_markup: keyboardServer
    });
  }
});

// =================== MENU SISTEM ===================
bot.action('admin_system_menu', async (ctx) => {
  const keyboardSystem = {
  inline_keyboard: [
    // 🔢 Statistik dan Pengguna
    [
      { text: '📊 Statistik Global', callback_data: 'admin_stats' },
      { text: '👥 List Pengguna', callback_data: 'admin_listuser' }
    ],

    // 📢 Broadcast dan Backup
    [
      { text: '📢 Broadcast', callback_data: 'admin_broadcast' },
      { text: '💾 Backup DB', callback_data: 'admin_backup_db' }
    ],

    // 🔄 Restore dan All Backup
    [
      { text: '♻️ Restore DB', callback_data: 'admin_restore2_db' },
      { text: '🗃️ All Backup', callback_data: 'admin_restore_all' }
    ],

    // 🔼🔽 Reseller Role
    [
      { text: '⬆️ Up Reseller', callback_data: 'admin_promote_reseller' },
      { text: '⬇️ Down Reseller', callback_data: 'admin_downgrade_reseller' }
    ],

    // 🎛 Level & List Reseller
    [
      { text: '🎛 Ubah Level', callback_data: 'admin_ubah_level' },
      { text: '🧾 List Reseller', callback_data: 'admin_listreseller' }
    ],

    // 🔁 Reset & Topup Log
    [
      { text: '🔁 Reset Komisi', callback_data: 'admin_resetkomisi' },
      { text: '🔄 Reset Trial', callback_data: 'admin_reset_trial' }
    ],
    [
      { text: '📋 Log All Topup', callback_data: 'admin_view_topup' }
    ],

    // ⬅️ Kembali
    [
      { text: '⬅️ Kembali', callback_data: 'menu_adminreseller' }
    ]
  ]
};

  const message = `
⚙️ *Menu Admin - Sistem*

Silahkan pilih manajemen sistem!!!
`.trim();

  try {
    await ctx.editMessageText(message, {
      parse_mode: 'Markdown',
      reply_markup: keyboardSystem
    });
  } catch {
    await ctx.reply(message, {
      parse_mode: 'Markdown',
      reply_markup: keyboardSystem
    });
  }
});

bot.action('admin_reset_trial', async (ctx) => {
  const userId = String(ctx.from.id);
  if (!adminIds.includes(userId)) {
    return ctx.answerCbQuery('❌ Akses ditolak bro.');
  }

  try {
    await dbRunAsync(`UPDATE users SET trial_count_today = 0, last_trial_date = date('now')`);
    await ctx.reply('✅ *Semua trial user telah direset ke 0.*', { parse_mode: 'Markdown' });
    logger.info(`🔄 Admin ${userId} melakukan reset trial harian.`);
  } catch (err) {
    logger.error('❌ Gagal reset trial harian:', err.message);
    await ctx.reply('❌ *Gagal melakukan reset trial.*', { parse_mode: 'Markdown' });
  }
});

bot.action('admin_view_topup', async (ctx) => {
  const userId = String(ctx.from.id);
  if (!adminIds.includes(userId)) {
    return ctx.answerCbQuery('❌ Tidak diizinkan.');
  }

  try {
    const rows = await dbAllAsync(`
      SELECT username, amount, reference, created_at
      FROM topup_log
      ORDER BY created_at DESC
      LIMIT 10
    `);

    if (rows.length === 0) {
      return ctx.editMessageText(escapeMarkdown('📭 Belum ada transaksi topup yang berhasil.'), {
        parse_mode: 'MarkdownV2'
      });
    }

    let teks = '*📋 Riwayat Topup Terakhir:*\n\n';

    rows.forEach((row, i) => {
      const mention = row.username
        ? `@${escapeMarkdown(row.username)}`
        : 'User\\_Tidak\\_Diketahui';

      const waktu = escapeMarkdown(
        new Date(row.created_at).toLocaleString('id-ID')
      );
      const ref = escapeMarkdown(row.reference || '-');
      const amount = escapeMarkdown(row.amount.toLocaleString('id-ID'));

      teks += `${i + 1}\\. 👤 ${mention}\n💰 Rp${amount}\n🔖 Ref: ${ref}\n🕒 ${waktu}\n\n`;
    });

    await ctx.editMessageText(teks, {
      parse_mode: 'MarkdownV2',
      reply_markup: {
        inline_keyboard: [
          [{ text: '🔙 Kembali', callback_data: 'menu_adminreseller' }]
        ]
      }
    });
  } catch (error) {
    logger.error('❌ Gagal tampilkan riwayat topup:', error.message);
    await ctx.reply(escapeMarkdown('❌ Terjadi kesalahan saat ambil riwayat topup.'), {
      parse_mode: 'MarkdownV2'
    });
  }
});

bot.action('admin_restore2_db', async (ctx) => {
  const userId = ctx.from.id;
  if (!adminIds.includes(String(userId))) return ctx.reply('🚫 Kamu tidak memiliki izin.');

  userState[ctx.chat.id] = { step: 'await_restore_upload' };

  await ctx.reply(
    '📤 *Silakan kirim file backup database (.db) yang ingin direstore.*\n' +
    '_Contoh: sellvpn_2025-06-01_10-00.db_',
    { parse_mode: 'Markdown' }
  );
});

bot.action('admin_listreseller', async (ctx) => {
  const userId = String(ctx.from.id);
  if (!adminIds.includes(userId)) {
    return ctx.reply('🚫 Kamu tidak memiliki izin.');
  }

  try {
    const rows = await new Promise((resolve, reject) => {
      db.all(`
        SELECT user_id, username, reseller_level, saldo 
        FROM users 
        WHERE role = 'reseller' 
        LIMIT 20
      `, (err, rows) => {
        if (err) reject(err);
        else resolve(rows);
      });
    });

    if (!rows || rows.length === 0) {
      return ctx.reply('📭 Belum ada reseller terdaftar.');
    }

    const list = rows.map((row, i) => {
      const mention = row.username
        ? `@${escapeMarkdownV2(row.username)}`
        : `ID: \`${escapeMarkdownV2(row.user_id)}\``;

      const level = escapeMarkdownV2(row.reseller_level || 'silver');
      const saldo = escapeMarkdownV2(row.saldo.toLocaleString('id-ID'));

      return `🔹 ${mention}\n🏷 Level: *${level}*\n💰 Saldo: Rp${saldo}`;
    }).join('\n\n');

    const text = `🏆 *List Reseller _Max 20_:*\n\n${list}`;

    await ctx.reply(text, {
      parse_mode: 'MarkdownV2'
    });

  } catch (err) {
    logger.error('❌ Gagal ambil list reseller:', err.message);
    ctx.reply('❌ Gagal mengambil daftar reseller.');
  }
});

bot.action('admin_stats', async (ctx) => {
  const userId = String(ctx.from.id);
  if (!adminIds.includes(userId)) {
    return ctx.answerCbQuery('❌ Tidak diizinkan.');
  }

  try {
    const [jumlahUser, jumlahReseller, jumlahServer, totalSaldo] = await Promise.all([
      dbGetAsync('SELECT COUNT(*) AS count FROM users'),
      dbGetAsync("SELECT COUNT(*) AS count FROM users WHERE role = 'reseller'"),
      dbGetAsync('SELECT COUNT(*) AS count FROM Server'),
      dbGetAsync('SELECT SUM(saldo) AS total FROM users')
    ]);

    const sistemText = `
📊 *Statistik Sistem  _Realtime_*

👥 *User*     : ${escapeMarkdownV2(jumlahUser?.count || 0)}
👑 *Reseller* : ${escapeMarkdownV2(jumlahReseller?.count || 0)}
🖥️ *Server*   : ${escapeMarkdownV2(jumlahServer?.count || 0)}
💰 *Saldo*    : Rp${escapeMarkdownV2((totalSaldo?.total || 0).toLocaleString('id-ID'))}
`.trim();

    const [totalTransaksi, totalKomisi, topReseller] = await Promise.all([
      dbGetAsync('SELECT COUNT(*) AS count FROM invoice_log'),
      dbGetAsync('SELECT SUM(komisi) AS total FROM reseller_sales'),
      dbAllAsync(`
        SELECT u.username, r.reseller_id, SUM(r.komisi) AS total_komisi
        FROM reseller_sales r
        LEFT JOIN users u ON u.user_id = r.reseller_id
        GROUP BY r.reseller_id
        ORDER BY total_komisi DESC
        LIMIT 3
      `)
    ]);

    let globalText = `
📊 *Statistik Global*

🌐 Server Aktif : ${escapeMarkdownV2(jumlahServer?.count || 0)}
👥 Pengguna     : ${escapeMarkdownV2(jumlahUser?.count || 0)}
📦 Transaksi    : ${escapeMarkdownV2(totalTransaksi?.count || 0)}
💰 Komisi Total : Rp${escapeMarkdownV2((totalKomisi?.total || 0).toLocaleString('id-ID'))}
`;

    if (topReseller && topReseller.length > 0) {
      globalText += `\n🏆 *Top 3 Reseller:*\n`;
      const medals = ['🥇', '🥈', '🥉'];
      topReseller.forEach((r, i) => {
        const mention = r.username
          ? `@${escapeMarkdownV2(r.username)}`
          : `ID\\_${escapeMarkdownV2(r.reseller_id)}`;
        const komisi = escapeMarkdownV2((r.total_komisi || 0).toLocaleString('id-ID'));
        globalText += `${medals[i] || '⭐'} ${mention} \\- Rp${komisi}\n`;
      });
    }

    await ctx.editMessageText(`${sistemText}\n\n${globalText}`.trim(), {
      parse_mode: 'MarkdownV2',
      disable_web_page_preview: true
    });

  } catch (err) {
    logger.error('❌ Gagal ambil statistik admin:', err.message);
    await ctx.reply('❌ Gagal mengambil data statistik.');
  }
});

bot.action('admin_broadcast', async (ctx) => {
  const userId = String(ctx.from.id);
  if (!adminIds.includes(userId)) {
    return ctx.reply('🚫 Kamu tidak punya izin untuk broadcast.');
  }

  userState[ctx.chat.id] = { step: 'await_broadcast_message' };
  return ctx.reply('📝 Silakan ketik pesan yang ingin dibroadcast ke semua pengguna.');
});


bot.action('admin_ubah_level', async (ctx) => {
  const adminId = String(ctx.from.id);
  const rawAdmin = vars.USER_ID;
  const adminIds = Array.isArray(rawAdmin) ? rawAdmin.map(String) : [String(rawAdmin)];

  if (!adminIds.includes(adminId)) {
    return ctx.reply('⛔ *Khusus admin.*', { parse_mode: 'Markdown' });
  }

  userState[ctx.chat.id] = { step: 'await_level_change' };
  ctx.reply('🧬 *Masukkan ID user dan level baru:*\n\nFormat: `123456789 platinum`', {
    parse_mode: 'Markdown'
  });

  // ⏱️ Timeout auto reset 30 detik
  setTimeout(() => {
    if (userState[ctx.chat.id]?.step === 'await_level_change') {
      delete userState[ctx.chat.id];
      ctx.reply('⏳ Waktu habis. Silakan klik ulang tombol *Ubah Level Reseller*.', {
        parse_mode: 'Markdown'
      });
    }
  }, 30000);
});

bot.action('admin_downgrade_reseller', async (ctx) => {
  const adminId = String(ctx.from.id);
  const rawAdmin = vars.USER_ID;
  const adminIds = Array.isArray(rawAdmin) ? rawAdmin.map(String) : [String(rawAdmin)];

  if (!adminIds.includes(adminId)) {
    return ctx.reply('⛔ *Khusus admin.*', { parse_mode: 'Markdown' });
  }

  userState[ctx.chat.id] = { step: 'await_downgrade_id' };
  return ctx.reply('📥 *Masukkan ID user yang ingin di-DOWNGRADE ke user biasa:*', {
    parse_mode: 'Markdown'
  });
});

bot.action('admin_promote_reseller', async (ctx) => {
  const adminId = String(ctx.from.id);
  const rawAdmin = vars.USER_ID;
  const adminIds = Array.isArray(rawAdmin)
    ? rawAdmin.map(String)
    : [String(rawAdmin)];

  if (!adminIds.includes(adminId)) {
    return ctx.reply('⛔ Hanya admin yang bisa akses fitur ini.');
  }

  // Prompt input user ID
  userState[ctx.chat.id] = { step: 'await_reseller_id' };
  setTimeout(() => {
  if (userState[ctx.chat.id]?.step === 'await_reseller_id') {
    delete userState[ctx.chat.id];
    ctx.reply('⏳ Waktu habis. Silakan ulangi /promote_reseller jika masih ingin mempromosikan user.');
  }
}, 30000); // 30 detik
  return ctx.reply('📥 Masukkan user ID yang ingin dipromosikan jadi reseller:');
});

bot.action('admin_resetkomisi', async (ctx) => {
  const adminId = ctx.from.id;
  const rawAdmin = vars.USER_ID;
  const adminIds = Array.isArray(rawAdmin) ? rawAdmin.map(String) : [String(rawAdmin)];

  if (!adminIds.includes(String(adminId))) {
    return ctx.reply(escapeMarkdown('⛔ Akses ditolak. Hanya admin.'), {
      parse_mode: 'MarkdownV2'
    });
  }

  userState[ctx.chat.id] = {
    step: 'reset_komisi_input'
  };

  return ctx.reply(escapeMarkdown('📨 Masukkan user_id yang ingin direset komisinya:'), {
    parse_mode: 'MarkdownV2'
  });
});

bot.action('admin_listserver', async (ctx) => {
  const userId = String(ctx.from.id);
  if (!adminIds.includes(userId)) {
    return ctx.reply('🚫 Kamu tidak memiliki izin.');
  }

  db.all('SELECT * FROM Server ORDER BY id DESC', [], (err, rows) => {
    if (err) {
      logger.error('❌ Error ambil list server:', err.message);
      return ctx.reply('⚠️ Gagal mengambil data server.');
    }

    if (!rows || rows.length === 0) {
      return ctx.reply('📭 Belum ada server yang ditambahkan.');
    }

    const list = rows.map((row, i) => {
      return `${i + 1}. ${row.nama_server}\n` +
             `🌐 Domain   : ${row.domain}\n` +
             `🔐 Auth     : ${row.auth}\n` +
             `💾 Quota    : ${row.quota} GB\n` +
             `🌍 IP Limit : ${row.iplimit}\n` +
             `📦 Harga    : Rp${row.harga.toLocaleString('id-ID')}\n` +
             `🧮 Total Buat: ${row.total_create_akun}`;
    }).join('\n──────────────\n');

    const msg = `📄 List Server Tersimpan:\n\n${list}`;
    ctx.reply(msg);
  });
});


bot.action('admin_listuser', async (ctx) => {
  const userId = String(ctx.from.id);
  if (!adminIds.includes(userId)) {
    return ctx.reply('🚫 Kamu tidak memiliki izin.');
  }

  try {
    const rows = await new Promise((resolve, reject) => {
      db.all('SELECT user_id, username, role, saldo FROM users LIMIT 20', (err, rows) => {
        if (err) reject(err);
        else resolve(rows);
      });
    });

    if (!rows || rows.length === 0) {
      return ctx.reply('📭 Tidak ada pengguna terdaftar.');
    }

    const list = rows.map((row, i) => {
      const mention = row.username
        ? `@${escapeMarkdownV2(row.username)}`
        : `ID: \`${escapeMarkdownV2(row.user_id)}\``;

      return `🔹 ${mention}\n*Role*: ${escapeMarkdownV2(row.role)}\n*Saldo*: Rp${escapeMarkdownV2(row.saldo.toLocaleString('id-ID'))}`;
    }).join('\n\n');

    const text = `👥 *List Pengguna _max 20_:*\n\n${list}`;

    await ctx.reply(text, {
      parse_mode: 'MarkdownV2'
    });

  } catch (err) {
    logger.error('❌ Gagal ambil list user:', err.message);
    ctx.reply('❌ Gagal mengambil daftar pengguna.');
  }
});
// -- handler Service --
bot.action('service_create', async (ctx) => {
  if (!ctx || !ctx.match) {
    return ctx.reply('❌ *GAGAL!* Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.', { parse_mode: 'Markdown' });
  }
  await handleServiceAction(ctx, 'create');
});

bot.action('service_renew', async (ctx) => {
  if (!ctx || !ctx.match) {
    return ctx.reply('❌ *GAGAL!* Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.', { parse_mode: 'Markdown' });
  }
  await handleServiceAction(ctx, 'renew');
});

bot.action('service_trial', async (ctx) => {
  if (!ctx || !ctx.match) {
    return ctx.reply('❌ *GAGAL!* Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.', { parse_mode: 'Markdown' });
  }
  await handleServiceAction(ctx, 'trial');
});

// ===================== ACTION: MENU RESELLER =====================
bot.action('menu_reseller', async (ctx) => {
  const userId = ctx.from.id;
  const username = ctx.from.username || ctx.from.first_name;

  try {
    const row = await new Promise((resolve, reject) => {
      db.get('SELECT role FROM users WHERE user_id = ?', [userId], (err, row) => {
        if (err) return reject(err);
        resolve(row);
      });
    });

    if (!row || row.role !== 'reseller') {
      return ctx.reply('❌ Kamu bukan reseller.', { parse_mode: 'Markdown' });
    }

    const keyboard = {
  inline_keyboard: [
    [
      { text: '📊 Statistik riwayat', callback_data: 'reseller_riwayat' },
      { text: '📖 Cek Komisi', callback_data: 'reseller_komisi' }
    ],
    [
      { text: '📓 Export Komisi', callback_data: 'reseller_export' },
      { text: '🎓 Top All Time', callback_data: 'reseller_top_all' }
    ],
    [
      { text: '🏆 Top Mingguan', callback_data: 'reseller_top_weekly' },
    ],
    [
      { text: '⬅️ Kembali', callback_data: 'send_main_menu' }
    ]
  ]
};

    const content = `
📂 *DASHBOARD RESELLER*

📋 Hari ini: ${new Date().toLocaleDateString('id-ID')}
🕒 Jam: ${new Date().toLocaleTimeString('id-ID')}

🏷 *Status:* Reseller Aktif
📋 Cek penghasilan dan statistik.
🏆 Cek daftar *TOP RESELLER*

🔽 Silakan pilih menu dibawah ini!!
`.trim();

    try {
      await ctx.editMessageText(content, {
        parse_mode: 'Markdown',
        reply_markup: keyboard
      });
    } catch (err) {
      if (err.response?.error_code === 400 || err.message.includes("message can't be edited")) {
        await ctx.reply(content, {
          parse_mode: 'Markdown',
          reply_markup: keyboard
        });
      } else {
        logger.error('❌ Gagal tampilkan menu reseller:', err.message);
      }
    }

  } catch (err) {
    logger.error('❌ Error query menu_reseller:', err.message);
    return ctx.reply('⚠️ Terjadi kesalahan saat memuat menu reseller.', { parse_mode: 'Markdown' });
  }
});

bot.action('reseller_top_weekly', async (ctx) => {
  try {
    const topRows = await dbAll(db, `
      SELECT u.user_id, u.username, SUM(r.komisi) AS total_komisi
      FROM reseller_sales r
      JOIN users u ON r.reseller_id = u.user_id
      WHERE r.created_at >= datetime('now', '-7 days')
      GROUP BY r.reseller_id
      ORDER BY total_komisi DESC
      LIMIT 5
    `);

    if (!topRows || topRows.length === 0) {
      return ctx.reply(escapeMarkdownV2('📭 Belum ada transaksi reseller minggu ini.'), {
        parse_mode: 'MarkdownV2'
      });
    }

    const topList = topRows.map((row, i) => {
      const mention = row.username
        ? `@${escapeMarkdownV2(row.username)}`
        : `ID\\_${row.user_id}`;
      const medal = ['🥇', '🥈', '🥉', '🎖️', '⭐'][i];
      const komisi = escapeMarkdownV2(row.total_komisi.toLocaleString('id-ID'));
      return `${medal} ${mention} \\- Rp${komisi}`;
    });

    const replyText = escapeMarkdownV2(`🏆 Top Reseller Minggu Ini:\n\n`) + topList.join('\n');
    
    await ctx.reply(replyText, { parse_mode: 'MarkdownV2' });

  } catch (err) {
    logger.error('❌ Gagal ambil top reseller mingguan:', err);
    return ctx.reply(escapeMarkdownV2('⚠️ Gagal mengambil data top reseller.'), {
      parse_mode: 'MarkdownV2'
    });
  }
});

bot.action('reseller_logtransfer', async (ctx) => {
  const userId = ctx.from.id;

  await ctx.reply('🕒 Memuat log transfer saldo...', {
    parse_mode: 'Markdown'
  });

  const header = '*🧾 Riwayat Transfer Saldo Terakhir:*\n\n';

  db.all(`
    SELECT to_id, jumlah AS amount, created_at FROM transfer_log 
    WHERE from_id = ? 
    ORDER BY datetime(created_at) DESC 
    LIMIT 5
  `, [userId], async (err, rows) => {
    if (err) {
      logger.error('❌ Gagal ambil log transfer:', err.message);
      return ctx.reply('⚠️ Gagal mengambil riwayat transfer.', {
        parse_mode: 'Markdown'
      });
    }

    if (!rows || rows.length === 0) {
      return ctx.reply('📭 Belum ada riwayat transfer saldo.', {
        parse_mode: 'Markdown'
      });
    }

    const list = await Promise.all(rows.map(async (row) => {
      let recipient = `ID ${row.to_id}`;
      try {
        const user = await bot.telegram.getChat(row.to_id);
        recipient = user.username
          ? `@${user.username}`
          : user.first_name || recipient;
      } catch {}

      const date = new Date(row.created_at).toLocaleString('id-ID');
      return `🔸 Ke ${escapeMarkdown(recipient)} (ID ${row.to_id}) +Rp${row.amount.toLocaleString('id-ID')} 🕒 ${escapeMarkdown(date)}`;
    }));

    const message = header + list.join('\n');

    ctx.reply(message, { parse_mode: 'Markdown' });
  });
});

// 📤 Export Komisi
bot.action('reseller_export', async (ctx) => {
  const userId = ctx.from.id;

  db.all(`
    SELECT akun_type, username, komisi, created_at 
    FROM reseller_sales 
    WHERE reseller_id = ?
    ORDER BY datetime(created_at) DESC
  `, [userId], async (err, rows) => {
    if (err) {
      logger.error('❌ Gagal ambil data komisi:', err.message);
      return ctx.reply('⚠️ Gagal mengambil data komisi.', { parse_mode: 'Markdown' });
    }

    if (!rows || rows.length === 0) {
      return ctx.reply('📭 Belum ada data komisi untuk diexport.', { parse_mode: 'Markdown' });
    }

    const lines = rows.map(row => {
      const waktu = new Date(row.created_at).toLocaleString('id-ID');
      return `📦 ${row.akun_type.toUpperCase()} | 👤 ${row.username} | 💰 Rp${row.komisi.toLocaleString('id-ID')} | 🕒 ${waktu}`;
    });

    const exportText = `📥 *Export Data Komisi:*\n\n${lines.join('\n')}`;
    return ctx.reply(exportText, { parse_mode: 'Markdown' });
  });
});

bot.action('reseller_top_all', async (ctx) => {
  try {
    db.all(`
      SELECT r.reseller_id, COUNT(r.id) AS total_akun, 
             SUM(COALESCE(r.komisi, 0)) AS total_komisi,
             u.username
      FROM reseller_sales r
      INNER JOIN users u ON r.reseller_id = u.user_id
      GROUP BY r.reseller_id
      HAVING total_komisi > 0
      ORDER BY total_komisi DESC
      LIMIT 10
    `, async (err, rows) => {
      if (err) {
        console.error('❌ Gagal ambil data top reseller:', err);
        return ctx.reply('❌ Gagal mengambil data top reseller.');
      }

      if (!rows || rows.length === 0) {
        return ctx.reply('📭 Belum ada transaksi reseller.');
      }

      let text = `🏆 Top 10 Reseller by Komisi (All Time):\n\n`;

      rows.forEach((r, i) => {
        const nama = r.username ? `@${r.username}` : `ID ${r.reseller_id}`;
        text += `#${i + 1} 👤 ${nama}\n`;
        text += `🛒 Akun Terjual: ${r.total_akun}\n`;
        text += `💰 Total Komisi : Rp${(r.total_komisi || 0).toLocaleString('id-ID')}\n\n`;
      });

      await ctx.reply(text.trim());
    });
  } catch (e) {
    console.error('❌ Terjadi kesalahan:', e);
    ctx.reply('❌ Terjadi kesalahan.');
  }
});

bot.action('reseller_komisi', (ctx) => {
  const userId = ctx.from.id;

  db.get('SELECT role, reseller_level FROM users WHERE user_id = ?', [userId], (err, user) => {
    if (err || !user || user.role !== 'reseller') {
      return ctx.reply('❌ Kamu bukan reseller.');
    }

    db.get('SELECT COUNT(*) AS total_akun, SUM(komisi) AS total_komisi FROM reseller_sales WHERE reseller_id = ?', [userId], (err, summary) => {
      if (err) {
        logger.error('❌ Gagal ambil data komisi:', err.message);
        return ctx.reply('❌ Gagal ambil data komisi.');
      }

      db.all('SELECT akun_type, username, komisi, created_at FROM reseller_sales WHERE reseller_id = ? ORDER BY created_at DESC LIMIT 5', [userId], (err, rows) => {
        if (err) {
          return ctx.reply('❌ Gagal ambil riwayat komisi.');
        }

        const level = user.reseller_level ? user.reseller_level.toUpperCase() : 'SILVER';

        const list = rows.map((r, i) =>
          `🔹 ${r.akun_type.toUpperCase()} - ${r.username} (+Rp${r.komisi}) 🕒 ${r.created_at}`
        ).join('\n') || '_Belum ada transaksi_';

        const text = `💰 *Statistik Komisi Reseller*\n\n` +
          `🎖️ Level: ${level}\n` +
          `🧑‍💻 Total Akun Terjual: ${summary.total_akun}\n` +
          `💸 Total Komisi: Rp${summary.total_komisi || 0}\n\n` +
          `📜 *Transaksi Terbaru:*\n${list}`;

        ctx.editMessageText(text, { parse_mode: 'Markdown' });
      });
    });
  });
});

bot.action('reseller_riwayat', async (ctx) => {
  const userId = ctx.from.id;

  db.all(`
    SELECT akun_type, username, komisi, created_at 
    FROM reseller_sales 
    WHERE reseller_id = ? 
    ORDER BY datetime(created_at) DESC 
    LIMIT 10
  `, [userId], async (err, rows) => {
    if (err) {
      logger.error('❌ Gagal ambil riwayat reseller:', err.message);
      return ctx.reply('⚠️ Gagal mengambil riwayat penjualan.', {
        parse_mode: 'Markdown'
      });
    }

    if (!rows || rows.length === 0) {
      return ctx.reply('📭 Belum ada riwayat penjualan.', {
        parse_mode: 'Markdown'
      });
    }

    let text = '*📊 Riwayat Penjualan Terakhir:*\n\n';
    rows.forEach((row, i) => {
      const tanggal = new Date(row.created_at).toLocaleString('id-ID');
      text += `🔹 ${i + 1}. ${row.akun_type.toUpperCase()} - \`${row.username}\`\n💰 Komisi: Rp${row.komisi.toLocaleString('id-ID')}\n🕒 ${tanggal}\n\n`;
    });

    ctx.reply(text.trim(), { parse_mode: 'Markdown' });
  });
});

bot.action('reseller_transfer', (ctx) => {
  ctx.editMessageText('💸 Gunakan format berikut:\n\n`/transfer USER_ID JUMLAH`\n\nContoh:\n`/transfer 123456789 5000`', {
    parse_mode: 'Markdown'
  });
});

// ===================== ACTION: TRIAL AKUN =====================
bot.action('trial_ssh', async (ctx) => {
  await ctx.answerCbQuery();
  await showTrialServerMenu(ctx, 'ssh');
});


bot.action('trial_vmess', async (ctx) => {
  await ctx.answerCbQuery();
  await showTrialServerMenu(ctx, 'vmess');
});

bot.action('trial_vless', async (ctx) => {
  await ctx.answerCbQuery();
  await showTrialServerMenu(ctx, 'vless');
});

bot.action('trial_trojan', async (ctx) => {
  await ctx.answerCbQuery();
  await showTrialServerMenu(ctx, 'trojan');
});

bot.action('trial_shadowsocks', async (ctx) => {
  await ctx.answerCbQuery();
  await showTrialServerMenu(ctx, 'shadowsocks');
});


bot.action(/^trial_server_ssh_(\d+)$/, async (ctx) => {
  const serverId = ctx.match[1];
  const userId = ctx.from.id;
  const chatId = ctx.chat.type === 'private' ? ctx.chat.id : ctx.from.id;
  const rawName = ctx.from.username ? `@${ctx.from.username}` : ctx.from.first_name;
  const mention = escapeMarkdown(rawName);

  await ctx.answerCbQuery();

  if (ctx.chat.type !== 'private') {
    await bot.telegram.sendMessage(chatId, '✅ Proses trial berjalan, cek DM ya bro!');
  }

  try {
    // Ambil data user
    const user = await dbGetAsync('SELECT role, last_trial_date, trial_count_today FROM users WHERE user_id = ?', [userId]);
    const role = user?.role || 'user';
    const now = new Date();
    const today = now.toISOString().split('T')[0];
    let trialCount = user?.trial_count_today || 0;
    const lastDate = user?.last_trial_date;

    // Atur limit trial harian berdasarkan role
    const maxTrial = role === 'reseller' ? 10 : role === 'admin' ? Infinity : 1;

    // Reset trial count jika beda hari
    if (lastDate !== today) {
      trialCount = 0;
      await dbRunAsync('UPDATE users SET trial_count_today = 0, last_trial_date = ? WHERE user_id = ?', [today, userId]);
    }

    // Cek apakah sudah melebihi limit
    if (trialCount >= maxTrial) {
      return await bot.telegram.sendMessage(chatId, `😅 Batas trial harian sudah tercapai bro.\nKamu hanya bisa ambil *${maxTrial}x* per hari.`, { parse_mode: 'Markdown' });
    }

    // Jalankan script trial
    exec(`bash ./scripts/trialssh.sh ${serverId}`, async (error, stdout, stderr) => {
      if (error) {
        logger.error('Gagal eksekusi script trialssh:', error.message);
        return bot.telegram.sendMessage(chatId, '❌ Gagal jalankan script trial.');
      }

      let json;
      try {
        const raw = stdout.trim();
        fs.appendFileSync('./debug_trial.log', `\n=== ${userId} - ${rawName} ===\n${raw}\n`);
        const start = raw.indexOf('{');
        const end = raw.lastIndexOf('}');
        if (start === -1 || end === -1) throw new Error('Output tidak mengandung JSON');
        json = JSON.parse(raw.substring(start, end + 1));
      } catch (e) {
        logger.error('❌ Gagal parsing hasil trial SSH:', e.message);
        return bot.telegram.sendMessage(chatId, '❌ Gagal membaca data trial.');
      }

      try {
        const {
          username, password, ip, domain, city, public_key, expiration,
          ports, openvpn_link, save_link, wss_payload
        } = json;

        // Update jumlah trial dan simpan log
        await dbRunAsync('UPDATE users SET trial_count_today = trial_count_today + 1, last_trial_date = ? WHERE user_id = ?', [today, userId]);
        await dbRunAsync('INSERT INTO trial_logs (user_id, username, jenis, created_at) VALUES (?, ?, ?, datetime("now"))',
          [userId, username, 'ssh']);

        const trialKe = trialCount + 1;
        const roleLabel = role === 'admin' ? 'Admin' : role === 'reseller' ? 'Reseller' : 'User';
        const serverRow = await dbGetAsync('SELECT nama_server FROM Server WHERE id = ?', [serverId]);
        const namaServer = serverRow?.nama_server || 'Unknown';

        const replyText = `
🔰 *AKUN SSH TRIAL*

👤 \`User:\` ${username}
🔑 \`Pass:\` ${password}
🌍 \`IP:\` ${ip}
🏙️ \`Lokasi:\` ${city}
📡 \`Domain:\` ${domain}
🔐 \`PubKey:\` ${public_key}

🔌 *PORT*
OpenSSH   : ${ports.openssh}
Dropbear  : ${ports.dropbear}
UDP SSH   : ${ports.udp_ssh}
DNS       : ${ports.dns}
WS        : ${ports.ssh_ws}
SSL WS    : ${ports.ssh_ssl_ws}
SSL/TLS   : ${ports.ssl_tls}
OVPN TCP  : ${ports.ovpn_tcp}
OVPN UDP  : ${ports.ovpn_udp}
OVPN SSL  : ${ports.ovpn_ssl}
BadVPN    : ${ports.badvpn}

🔗 *Link*
OVPN     : 
\`\`\`
${openvpn_link}
\`\`\`
Save     :
\`\`\`
${save_link}
\`\`\`
Payload  :
\`\`\`
${wss_payload}
\`\`\`

📆 *Expired:* ${expiration}
`.trim();

        await bot.telegram.sendMessage(chatId, replyText, {
          parse_mode: 'Markdown',
          disable_web_page_preview: true
        });

        if (GROUP_ID) {
          const notif = `
━━━━━━━━━━━━━━━━━━━━━━━        
🎁 𝗧𝗥𝗜𝗔𝗟 𝗔𝗖𝗖𝗢𝗨𝗡𝗧 𝗦𝗦𝗛 𝗡𝗘𝗪
━━━━━━━━━━━━━━━━━━━━━━━
👤 𝗨𝘀𝗲𝗿: ${mention}
📩 𝗧𝗿𝗶𝗮𝗹 𝗯𝘆: ${roleLabel} | ${trialKe} dari ${maxTrial}
🌐 𝗦𝗲𝗿𝘃𝗲𝗿: ${namaServer}
🏪 𝗣𝗿𝗼𝘁𝗼𝗰𝗼𝗹: SSH
⏳ 𝗗𝘂𝗿𝗮𝘀𝗶: 60 Menit
🕒 𝗪𝗮𝗸𝘁𝘂: ${new Date().toLocaleString('id-ID')}
━━━━━━━━━━━━━━━━━━━━━━━
          `.trim();

          await bot.telegram.sendMessage(GROUP_ID, notif, { parse_mode: 'Markdown' });
        }

      } catch (e) {
        logger.error('❌ Gagal kirim akun trial SSH:', e.message);
        return bot.telegram.sendMessage(chatId, '❌ Terjadi kesalahan saat kirim akun.');
      }
    });
  } catch (err) {
    logger.error('❌ Gagal proses trial:', err.message);
    return bot.telegram.sendMessage(chatId, '❌ Terjadi kesalahan saat cek data trial.');
  }
});

bot.action(/^trial_server_vmess_(\d+)$/, async (ctx) => {
  const serverId = ctx.match[1];
  const userId = ctx.from.id;
  const chatId = ctx.chat.type === 'private' ? ctx.chat.id : ctx.from.id;
  const rawName = ctx.from.username ? `@${ctx.from.username}` : ctx.from.first_name;
  const mention = escapeMarkdown(rawName);
  await ctx.answerCbQuery();
  if (ctx.chat.type !== 'private') {
    await bot.telegram.sendMessage(chatId, '✅ Proses trial berjalan, cek DM ya bro!');
  }

  try {
    const user = await dbGetAsync('SELECT role, last_trial_date, trial_count_today FROM users WHERE user_id = ?', [userId]);
    const role = user?.role || 'user';
    const now = new Date();
    const today = now.toISOString().split('T')[0];
    let trialCount = user?.trial_count_today || 0;
    const lastDate = user?.last_trial_date;
    const maxTrial = role === 'reseller' ? 10 : role === 'admin' ? Infinity : 1;
    if (lastDate !== today) {
      trialCount = 0;
      await dbRunAsync('UPDATE users SET trial_count_today = 0, last_trial_date = ? WHERE user_id = ?', [today, userId]);
    }
    if (trialCount >= maxTrial) {
      return await bot.telegram.sendMessage(chatId, `😅 Batas trial harian sudah tercapai bro. Kamu hanya bisa ambil *${maxTrial}x* per hari.`, { parse_mode: 'Markdown' });
    }

    exec(`bash ./scripts/trialvmess.sh ${serverId}`, async (error, stdout) => {
      if (error) return bot.telegram.sendMessage(chatId, '❌ Gagal jalankan script trial.');

      let json;
      try {
        const raw = stdout.trim();
        const start = raw.indexOf('{');
        const end = raw.lastIndexOf('}');
        if (start === -1 || end === -1) throw new Error('Output tidak mengandung JSON');
        json = JSON.parse(raw.substring(start, end + 1));
      } catch (e) {
        return bot.telegram.sendMessage(chatId, '❌ Gagal parsing data trial.');
      }

      const {
        username, uuid, ip, domain, ns_domain, city, public_key,
        expiration, link_tls, link_ntls, link_grpc
      } = json;

      await dbRunAsync('UPDATE users SET trial_count_today = trial_count_today + 1, last_trial_date = ? WHERE user_id = ?', [today, userId]);
      await dbRunAsync('INSERT INTO trial_logs (user_id, username, jenis, created_at) VALUES (?, ?, ?, datetime("now"))', [userId, username, 'vmess']);

      const trialKe = trialCount + 1;
      const roleLabel = role === 'admin' ? 'Admin' : role === 'reseller' ? 'Reseller' : 'User';
      const serverRow = await dbGetAsync('SELECT nama_server FROM Server WHERE id = ?', [serverId]);
      const namaServer = serverRow?.nama_server || 'Unknown';

      const replyText = `
⚡ *AKUN VMESS TRIAL*

👤 \`User:\` ${username}
🔐 \`UUID:\` ${uuid}
🌍 \`Domain:\` ${domain}
🏙️ \`Kota:\` ${city}
📡 \`NS:\` ${ns_domain}
🔑 \`PubKey:\` ${public_key}

🔌 *PORT*
TLS 443 | NTLS 80/8080 | gRPC 443

🔗 *Link*
TLS     : \`\`\`${link_tls}\`\`\`
Non-TLS : \`\`\`${link_ntls}\`\`\`
gRPC    : \`\`\`${link_grpc}\`\`\`

📆 *Expired:* ${expiration}
`.trim();

      await bot.telegram.sendMessage(chatId, replyText, {
        parse_mode: 'Markdown',
        disable_web_page_preview: true
      });

      if (GROUP_ID) {
        const notif = `
━━━━━━━━━━━━━━━━━━━━━━━        
🎁 𝗧𝗥𝗜𝗔𝗟 𝗔𝗖𝗖𝗢𝗨𝗡𝗧 𝗩𝗠𝗘𝗦𝗦 𝗡𝗘𝗪
━━━━━━━━━━━━━━━━━━━━━━━
👤 𝗨𝘀𝗲𝗿: ${mention}
📩 𝗧𝗿𝗶𝗮𝗹 𝗯𝘆: ${roleLabel} | ${trialKe} dari ${maxTrial}
🌐 𝗦𝗲𝗿𝘃𝗲𝗿: ${namaServer}
🏪 𝗣𝗿𝗼𝘁𝗼𝗰𝗼𝗹: VMESS
⏳ 𝗗𝘂𝗿𝗮𝘀𝗶: 60 Menit
🕒 𝗪𝗮𝗸𝘁𝘂: ${new Date().toLocaleString('id-ID')}
━━━━━━━━━━━━━━━━━━━━━━━`.trim();

        await bot.telegram.sendMessage(GROUP_ID, notif, { parse_mode: 'Markdown' });
      }
    });
  } catch (err) {
    logger.error('❌ Gagal proses trial:', err.message);
    return bot.telegram.sendMessage(chatId, '❌ Terjadi kesalahan saat cek data trial.');
  }
});

bot.action(/^trial_server_vless_(\d+)$/, async (ctx) => {
  const serverId = ctx.match[1];
  const userId = ctx.from.id;
  const chatId = ctx.chat.type === 'private' ? ctx.chat.id : ctx.from.id;
  const rawName = ctx.from.username ? `@${ctx.from.username}` : ctx.from.first_name;
  const mention = escapeMarkdown(rawName);

  await ctx.answerCbQuery();
  if (ctx.chat.type !== 'private') {
    await bot.telegram.sendMessage(chatId, '✅ Proses trial berjalan, cek DM ya bro!');
  }

  try {
    const now = new Date();
    const today = now.toISOString().split('T')[0];

    const [user, server] = await Promise.all([
      dbGetAsync('SELECT role, last_trial_date, trial_count_today FROM users WHERE user_id = ?', [userId]),
      dbGetAsync('SELECT nama_server FROM Server WHERE id = ?', [serverId])
    ]);

    const role = user?.role || 'user';
    let trialCount = user?.trial_count_today || 0;
    const lastDate = user?.last_trial_date;
    const maxTrial = role === 'reseller' ? 10 : role === 'admin' ? Infinity : 1;
    const namaServer = server?.nama_server || 'Unknown';
    const trialKe = trialCount + 1;

    if (lastDate !== today) {
      trialCount = 0;
      await dbRunAsync('UPDATE users SET trial_count_today = 0, last_trial_date = ? WHERE user_id = ?', [today, userId]);
    }

    if (trialCount >= maxTrial) {
      return await bot.telegram.sendMessage(chatId, `😅 Batas trial harian sudah tercapai bro.\nKamu hanya bisa ambil *${maxTrial}x* per hari.`, { parse_mode: 'Markdown' });
    }

    exec(`bash ./scripts/trialvless.sh ${serverId}`, async (error, stdout) => {
      if (error) {
        logger.error('❌ Gagal eksekusi script trialvless:', error.message);
        return bot.telegram.sendMessage(chatId, '❌ Gagal jalankan script trial.');
      }

      let json;
      try {
        const raw = stdout.trim();
        const start = raw.indexOf('{');
        const end = raw.lastIndexOf('}');
        if (start === -1 || end === -1) throw new Error('Output tidak valid');
        json = JSON.parse(raw.substring(start, end + 1));
      } catch (e) {
        logger.error('❌ Gagal parsing JSON VLESS:', e.message);
        return bot.telegram.sendMessage(chatId, '❌ Gagal parsing JSON.');
      }

      const {
        username, uuid, domain, city, ns_domain, public_key,
        expiration, link_tls, link_ntls, link_grpc
      } = json;

      await dbRunAsync('UPDATE users SET trial_count_today = trial_count_today + 1, last_trial_date = ? WHERE user_id = ?', [today, userId]);
      await dbRunAsync('INSERT INTO trial_logs (user_id, username, jenis, created_at) VALUES (?, ?, ?, datetime("now"))', [userId, username, 'vless']);

      const replyText = `
🚀 *AKUN VLESS TRIAL*

👤 \`User:\` ${username}
🔐 \`UUID:\` ${uuid}
🌐 \`Domain:\` ${domain}
🏙️ \`Kota:\` ${city}
📡 \`NS:\` ${ns_domain}
🔑 \`PubKey:\` ${public_key}

🔌 *PORT*
TLS 443 | NTLS 80/8080 | gRPC 443

🔗 *Link*
TLS     :
\`\`\`${link_tls}\`\`\`
Non-TLS :
\`\`\`${link_ntls}\`\`\`
gRPC    : 
\`\`\`${link_grpc}\`\`\`

📆 *Expired:* ${expiration}
      `.trim();

      await bot.telegram.sendMessage(chatId, replyText, {
        parse_mode: 'Markdown',
        disable_web_page_preview: true
      });

      if (GROUP_ID) {
        const roleLabel = role === 'admin' ? 'Admin' : role === 'reseller' ? 'Reseller' : 'User';
        const notif = `
━━━━━━━━━━━━━━━━━━━━━━━        
🎁 𝗧𝗥𝗜𝗔𝗟 𝗔𝗖𝗖𝗢𝗨𝗡𝗧 𝗩𝗟𝗘𝗦𝗦 𝗡𝗘𝗪
━━━━━━━━━━━━━━━━━━━━━━━
👤 𝗨𝘀𝗲𝗿: ${mention}
📩 𝗧𝗿𝗶𝗮𝗹 𝗯𝘆: ${roleLabel} | ${trialKe} dari ${maxTrial}
🌐 𝗦𝗲𝗿𝘃𝗲𝗿: ${namaServer}
🏪 𝗣𝗿𝗼𝘁𝗼𝗰𝗼𝗹: VLESS
⏳ 𝗗𝘂𝗿𝗮𝘀𝗶: 60 Menit
🕒 𝗪𝗮𝗸𝘁𝘂: ${new Date().toLocaleString('id-ID')}
━━━━━━━━━━━━━━━━━━━━━━━
        `.trim();

        await bot.telegram.sendMessage(GROUP_ID, notif, { parse_mode: 'Markdown' });
      }
    });
  } catch (err) {
    logger.error('❌ Gagal proses trial VLESS:', err.message);
    return bot.telegram.sendMessage(chatId, '❌ Terjadi kesalahan saat cek data trial.');
  }
});

bot.action(/^trial_server_trojan_(\d+)$/, async (ctx) => {
  const serverId = ctx.match[1];
  const userId = ctx.from.id;
  const chatId = ctx.chat.type === 'private' ? ctx.chat.id : ctx.from.id;
  const rawName = ctx.from.username ? `@${ctx.from.username}` : ctx.from.first_name;
  const mention = escapeMarkdown(rawName);

  await ctx.answerCbQuery();
  if (ctx.chat.type !== 'private') {
    await bot.telegram.sendMessage(chatId, '✅ Proses trial berjalan, cek DM ya bro!');
  }

  try {
    const now = new Date();
    const today = now.toISOString().split('T')[0];

    const [user, server] = await Promise.all([
      dbGetAsync('SELECT role, last_trial_date, trial_count_today FROM users WHERE user_id = ?', [userId]),
      dbGetAsync('SELECT nama_server FROM Server WHERE id = ?', [serverId])
    ]);

    const role = user?.role || 'user';
    let trialCount = user?.trial_count_today || 0;
    const lastDate = user?.last_trial_date;
    const maxTrial = role === 'reseller' ? 10 : role === 'admin' ? Infinity : 1;
    const namaServer = server?.nama_server || 'Unknown';
    const trialKe = trialCount + 1;

    if (lastDate !== today) {
      trialCount = 0;
      await dbRunAsync('UPDATE users SET trial_count_today = 0, last_trial_date = ? WHERE user_id = ?', [today, userId]);
    }

    if (trialCount >= maxTrial) {
      return await bot.telegram.sendMessage(chatId, `😅 Batas trial harian sudah tercapai bro.\nKamu hanya bisa ambil *${maxTrial}x* per hari.`, { parse_mode: 'Markdown' });
    }

    exec(`bash ./scripts/trialtrojan.sh ${serverId}`, async (error, stdout) => {
      if (error) {
        logger.error('Gagal eksekusi script trialtrojan:', error.message);
        return bot.telegram.sendMessage(chatId, '❌ Gagal jalankan script trial.');
      }

      let json;
      try {
        const raw = stdout.trim();
        const start = raw.indexOf('{');
        const end = raw.lastIndexOf('}');
        if (start === -1 || end === -1) throw new Error('Output tidak valid');
        json = JSON.parse(raw.substring(start, end + 1));
      } catch (e) {
        logger.error('❌ Gagal parsing JSON TROJAN:', e.message);
        return bot.telegram.sendMessage(chatId, '❌ Gagal parsing JSON.');
      }

      const {
        username, uuid, domain, city, ns_domain, public_key,
        expiration, link_tls, link_grpc
      } = json;

      await dbRunAsync('UPDATE users SET trial_count_today = trial_count_today + 1, last_trial_date = ? WHERE user_id = ?', [today, userId]);
      await dbRunAsync('INSERT INTO trial_logs (user_id, username, jenis, created_at) VALUES (?, ?, ?, datetime("now"))', [userId, username, 'trojan']);

      const replyText = `
🌀 *AKUN TROJAN TRIAL*

👤 \`User:\` ${username}
?? \`UUID:\` ${uuid}
🌐 \`Domain:\` ${domain}
🏙️ \`Kota:\` ${city}
📡 \`NS:\` ${ns_domain}
🔑 \`PubKey:\` ${public_key}

🔌 *PORT*
TLS-WS 443 | gRPC 443

🔗 *Link*
TLS-WS :
\`\`\`${link_tls}\`\`\`
gRPC   :
\`\`\`${link_grpc}\`\`\`

📆 *Expired:* ${expiration}
      `.trim();

      await bot.telegram.sendMessage(chatId, replyText, {
        parse_mode: 'Markdown',
        disable_web_page_preview: true
      });

      if (GROUP_ID) {
        const roleLabel = role === 'admin' ? 'Admin' : role === 'reseller' ? 'Reseller' : 'User';
        const notif = `
━━━━━━━━━━━━━━━━━━━━━━━        
🚀 𝗧𝗥𝗜𝗔𝗟 𝗔𝗖𝗖𝗢𝗨𝗡𝗧 𝗧𝗥𝗢𝗝𝗔𝗡 𝗡𝗘𝗪
━━━━━━━━━━━━━━━━━━━━━━━
👤 𝗨𝘀𝗲𝗿: ${mention}
📩 𝗧𝗿𝗶𝗮𝗹 𝗯𝘆: ${roleLabel} | ${trialKe} dari ${maxTrial}
🌐 𝗦𝗲𝗿𝘃𝗲𝗿: ${namaServer}
🏪 𝗣𝗿𝗼𝘁𝗼𝗰𝗼𝗹: TROJAN
⏳ 𝗗𝘂𝗿𝗮𝘀𝗶: 60 Menit
🕒 𝗪𝗮𝗸𝘁𝘂: ${new Date().toLocaleString('id-ID')}
━━━━━━━━━━━━━━━━━━━━━━━
        `.trim();

        await bot.telegram.sendMessage(GROUP_ID, notif, { parse_mode: 'Markdown' });
      }
    });
  } catch (err) {
    logger.error('❌ Gagal proses trial TROJAN:', err.message);
    return bot.telegram.sendMessage(chatId, '❌ Terjadi kesalahan saat cek data trial.');
  }
});

bot.action(/^trial_server_shadowsocks_(\d+)$/, async (ctx) => {
  const serverId = ctx.match[1];
  const userId = ctx.from.id;
  const chatId = ctx.chat.type === 'private' ? ctx.chat.id : ctx.from.id;
  const rawName = ctx.from.username ? `@${ctx.from.username}` : ctx.from.first_name;
  const mention = escapeMarkdown(rawName);

  await ctx.answerCbQuery();
  if (ctx.chat.type !== 'private') {
    await bot.telegram.sendMessage(chatId, '✅ Proses trial berjalan, cek DM ya bro!');
  }

  try {
    const now = new Date();
    const today = now.toISOString().split('T')[0];

    const [user, server] = await Promise.all([
      dbGetAsync('SELECT role, last_trial_date, trial_count_today FROM users WHERE user_id = ?', [userId]),
      dbGetAsync('SELECT nama_server FROM Server WHERE id = ?', [serverId])
    ]);

    const role = user?.role || 'user';
    let trialCount = user?.trial_count_today || 0;
    const lastDate = user?.last_trial_date;
    const maxTrial = role === 'reseller' ? 10 : role === 'admin' ? Infinity : 1;
    const namaServer = server?.nama_server || 'Unknown';
    const trialKe = trialCount + 1;

    if (lastDate !== today) {
      trialCount = 0;
      await dbRunAsync('UPDATE users SET trial_count_today = 0, last_trial_date = ? WHERE user_id = ?', [today, userId]);
    }

    if (trialCount >= maxTrial) {
      return await bot.telegram.sendMessage(chatId, `😅 Batas trial harian sudah tercapai bro.\nKamu hanya bisa ambil *${maxTrial}x* per hari.`, { parse_mode: 'Markdown' });
    }

    exec(`bash ./scripts/trialshadowsocks.sh ${serverId}`, async (error, stdout) => {
      if (error) {
        logger.error('Gagal eksekusi script trialshadowsocks:', error.message);
        return bot.telegram.sendMessage(chatId, '❌ Gagal jalankan script trial.');
      }

      let json;
      try {
        const raw = stdout.trim();
        const start = raw.indexOf('{');
        const end = raw.lastIndexOf('}');
        if (start === -1 || end === -1) throw new Error('Output tidak valid');

        json = JSON.parse(raw.substring(start, end + 1));
      } catch (e) {
        logger.error('❌ Gagal parsing JSON SHADOWSOCKS:', e.message);
        return bot.telegram.sendMessage(chatId, '❌ Gagal parsing JSON.');
      }

      const {
        username, password, method, domain, city, ns_domain,
        public_key, expiration, link_ws, link_grpc
      } = json;

      await dbRunAsync('UPDATE users SET trial_count_today = trial_count_today + 1, last_trial_date = ? WHERE user_id = ?', [today, userId]);
      await dbRunAsync('INSERT INTO trial_logs (user_id, username, jenis, created_at) VALUES (?, ?, ?, datetime("now"))', [userId, username, 'shadowsocks']);

      const replyText = `
🔒 *SHADOWSOCKS TRIAL*

👤 \`User:\` ${username}
🔑 \`Pass:\` ${password}
🔧 \`Method:\` ${method}
🌐 \`Domain:\` ${domain}
🏙️ \`Kota:\` ${city}
📡 \`NS:\` ${ns_domain}
🔑 \`PubKey:\` ${public_key}

🔌 *PORT*
443 (WS/gRPC)

🔗 *Link*
WS     : 
\`\`\`${link_ws}\`\`\`
gRPC   : 
\`\`\`${link_grpc}\`\`\`

📄 *OpenClash:* https://${domain}:81/shadowsocks-${username}.txt
📆 *Expired:* ${expiration}
      `.trim();

      await bot.telegram.sendMessage(chatId, replyText, {
        parse_mode: 'Markdown',
        disable_web_page_preview: true
      });

      if (GROUP_ID) {
        const roleLabel = role === 'admin' ? 'Admin' : role === 'reseller' ? 'Reseller' : 'User';
        const notif = `
━━━━━━━━━━━━━━━━━━━━━━━
♎ 𝗧𝗿𝗶𝗮𝗹 𝗔𝗸𝘂𝗻 𝗦𝗛𝗔𝗗𝗢𝗪𝗦𝗢𝗖𝗞𝗦 𝗡𝗲𝘄
━━━━━━━━━━━━━━━━━━━━━━━
👤 𝗨𝘀𝗲𝗿: ${mention}
👥 𝗧𝗿𝗶𝗮𝗹 𝗯𝘆: ${roleLabel} | ${trialKe} dari ${maxTrial}
🌐 Server: ${namaServer}
🎞 𝗟𝗮𝘆𝗮𝗻𝗮𝗻: SHADOWSOCKS
⏳ 𝗗𝘂𝗿𝗮𝘀𝗶: 60 Menit
🕒 𝗪𝗮𝗸𝘁𝘂: ${new Date().toLocaleString('id-ID')}
━━━━━━━━━━━━━━━━━━━━━━━
        `.trim();

        await bot.telegram.sendMessage(GROUP_ID, notif, { parse_mode: 'Markdown' });
      }
    });
  } catch (err) {
    logger.error('❌ Gagal proses trial SHADOWSOCKS:', err.message);
    return bot.telegram.sendMessage(chatId, '❌ Terjadi kesalahan saat cek data trial.');
  }
});


bot.action('send_main_menu', async (ctx) => {
  await sendMainMenu(ctx);
});

bot.action(/^service_(create|renew|trial)$/, async (ctx) => {
  const action = ctx.match[1];
  await handleServiceAction(ctx, action);
});

// ===================== ACTION: CREATE / RENEW =====================
bot.action('create_vmess', async (ctx) => {
  if (!ctx || !ctx.match) {
    return ctx.reply('❌ *GAGAL!* Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.', { parse_mode: 'Markdown' });
  }
  await startSelectServer(ctx, 'create', 'vmess');
});

bot.action('create_vless', async (ctx) => {
  if (!ctx || !ctx.match) {
    return ctx.reply('❌ *GAGAL!* Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.', { parse_mode: 'Markdown' });
  }
  await startSelectServer(ctx, 'create', 'vless');
});

bot.action('create_trojan', async (ctx) => {
  if (!ctx || !ctx.match) {
    return ctx.reply('❌ *GAGAL!* Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.', { parse_mode: 'Markdown' });
  }
  await startSelectServer(ctx, 'create', 'trojan');
});

bot.action('create_shadowsocks', async (ctx) => {
  if (!ctx || !ctx.match) {
    return ctx.reply('❌ *GAGAL!* Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.', { parse_mode: 'Markdown' });
  }
  await startSelectServer(ctx, 'create', 'shadowsocks');
});

bot.action('create_ssh', async (ctx) => {
  if (!ctx || !ctx.match) {
    return ctx.reply('❌ *GAGAL!* Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.', { parse_mode: 'Markdown' });
  }
  await startSelectServer(ctx, 'create', 'ssh');
});

bot.action('renew_vmess', async (ctx) => {
  if (!ctx || !ctx.match) {
    return ctx.reply('❌ *GAGAL!* Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.', { parse_mode: 'Markdown' });
  }
  await startSelectServer(ctx, 'renew', 'vmess');
});

bot.action('renew_vless', async (ctx) => {
  if (!ctx || !ctx.match) {
    return ctx.reply('❌ *GAGAL!* Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.', { parse_mode: 'Markdown' });
  }
  await startSelectServer(ctx, 'renew', 'vless');
});

bot.action('renew_trojan', async (ctx) => {
  if (!ctx || !ctx.match) {
    return ctx.reply('❌ *GAGAL!* Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.', { parse_mode: 'Markdown' });
  }
  await startSelectServer(ctx, 'renew', 'trojan');
});

bot.action('renew_shadowsocks', async (ctx) => {
  if (!ctx || !ctx.match) {
    return ctx.reply('❌ *GAGAL!* Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.', { parse_mode: 'Markdown' });
  }
  await startSelectServer(ctx, 'renew', 'shadowsocks');
});

bot.action('renew_ssh', async (ctx) => {
  if (!ctx || !ctx.match) {
    return ctx.reply('❌ *GAGAL!* Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.', { parse_mode: 'Markdown' });
  }
  await startSelectServer(ctx, 'renew', 'ssh');
});


bot.action(/navigate_(\w+)_(\w+)_(\d+)/, async (ctx) => {
  const [, action, type, page] = ctx.match;
  await startSelectServer(ctx, action, type, parseInt(page, 10));
});
bot.action(/(create|renew)_username_(vmess|vless|trojan|shadowsocks|ssh)_(.+)/, async (ctx) => {
  const action = ctx.match[1];
  const type = ctx.match[2];
  const serverId = ctx.match[3];
  userState[ctx.chat.id] = { step: `username_${action}_${type}`, serverId, type, action };

  db.get('SELECT batas_create_akun, total_create_akun FROM Server WHERE id = ?', [serverId], async (err, server) => {
    if (err) {
      logger.error('⚠️ Error fetching server details:', err.message);
      return ctx.reply('❌ *Terjadi kesalahan saat mengambil detail server.*', { parse_mode: 'Markdown' });
    }

    if (!server) {
      return ctx.reply('❌ *Server tidak ditemukan.*', { parse_mode: 'Markdown' });
    }

    const batasCreateAkun = server.batas_create_akun;
    const totalCreateAkun = server.total_create_akun;

    if (totalCreateAkun >= batasCreateAkun) {
      return ctx.reply('❌ *Server penuh. Tidak dapat membuat akun baru di server ini.*', { parse_mode: 'Markdown' });
    }

    await ctx.reply('👤 *Masukkan username:*', { parse_mode: 'Markdown' });
  });
});

bot.on('text', async (ctx) => {
  const userId = ctx.from.id;
  const chatId = ctx.chat.id;
  const state = userState[chatId];
  const text = ctx.message.text.trim();

  if (!state || typeof state !== 'object') return;

  try {
    // 🧾 Langkah 1: Username
    if (typeof state.step === 'string' && state.step.startsWith('username_')) {
      if (!/^[a-zA-Z0-9]{3,20}$/.test(text)) {
        return ctx.reply('❌ *Username tidak valid.*', { parse_mode: 'Markdown' });
      }

      state.username = text;

      if (state.action === 'create' && state.type === 'ssh') {
        state.step = `password_${state.action}_${state.type}`;
        return ctx.reply('🔑 *Masukkan password:*', { parse_mode: 'Markdown' });
      }

      state.step = `exp_${state.action}_${state.type}`;
      return ctx.reply('⏳ *Masukkan masa aktif (hari):*', { parse_mode: 'Markdown' });
    }

    // 🧾 Langkah 2: Password SSH
    if (state.step.startsWith('password_')) {
      if (!/^[a-zA-Z0-9]{6,}$/.test(text)) {
        return ctx.reply('❌ *Password minimal 6 karakter dan tanpa simbol.*', { parse_mode: 'Markdown' });
      }

      state.password = text;
      state.step = `exp_${state.action}_${state.type}`;
      return ctx.reply('⏳ *Masukkan masa aktif (hari):*', { parse_mode: 'Markdown' });
    }

    // 🧾 Langkah 3: Expired Days
    if (state.step.startsWith('exp_')) {
      const days = parseInt(text);
      if (isNaN(days) || days <= 0 || days > 365) {
        return ctx.reply('❌ *Masa aktif tidak valid.*', { parse_mode: 'Markdown' });
      }

      const { username, password, serverId, type, action } = state;
      state.exp = days;

      const server = await dbGetAsync(`
     SELECT nama_server, domain, quota, iplimit, harga 
     FROM Server 
     WHERE id = ?
     `, [serverId]);
      let user = await dbGetAsync('SELECT saldo, role, reseller_level FROM users WHERE user_id = ?', [userId]);

      if (!user) {
        await dbRunAsync(
          `INSERT INTO users (user_id, username, saldo, role, reseller_level) VALUES (?, ?, 0, 'user', 'silver')`,
          [userId, ctx.from.username]
        );
        user = { saldo: 0, role: 'user', reseller_level: 'silver' };
      }

      if (!server) return ctx.reply('❌ *Server tidak ditemukan.*', { parse_mode: 'Markdown' });
                  
      const diskon = user.role === 'reseller'
        ? user.reseller_level === 'gold' ? 0.2
        : user.reseller_level === 'platinum' ? 0.3
        : 0.1
        : 0;

      const hargaSatuan = Math.floor(server.harga * (1 - diskon));
      const totalHarga = hargaSatuan * days;
      const komisi = user.role === 'reseller' ? Math.floor(server.harga * days * 0.1) : 0;

      if (user.saldo < totalHarga) {
        return ctx.reply('❌ *Saldo tidak mencukupi.*', { parse_mode: 'Markdown' });
      }
      
      if (action === 'renew') {
        const row = await dbGetAsync(
          'SELECT * FROM akun_aktif WHERE username = ? AND jenis = ?',
          [username, type]
        );
        if (!row) {
          return ctx.reply('❌ *Akun tidak ditemukan atau tidak aktif.*', { parse_mode: 'Markdown' });
        }
      }

      await dbRunAsync('UPDATE users SET saldo = saldo - ? WHERE user_id = ?', [totalHarga, userId]);

      const handlerMap = {
        create: {
          vmess: () => createvmess(username, days, server.quota, server.iplimit, serverId),
          vless: () => createvless(username, days, server.quota, server.iplimit, serverId),
          trojan: () => createtrojan(username, days, server.quota, server.iplimit, serverId),
          shadowsocks: () => createshadowsocks(username, days, server.quota, server.iplimit, serverId),
          ssh: () => createssh(username, password, days, server.iplimit, serverId)
        },
        renew: {
          vmess: () => renewvmess(username, days, server.quota, server.iplimit, serverId),
          vless: () => renewvless(username, days, server.quota, server.iplimit, serverId),
          trojan: () => renewtrojan(username, days, server.quota, server.iplimit, serverId),
          shadowsocks: () => renewshadowsocks(username, days, server.quota, server.iplimit, serverId),
          ssh: () => renewssh(username, days, server.iplimit, serverId)
        }
      };

      const handler = handlerMap[action]?.[type];
      if (!handler) return ctx.reply('❌ *Tipe layanan tidak dikenali.*', { parse_mode: 'Markdown' });

      const msg = await handler();
      if (!msg || typeof msg !== 'string') {
        return ctx.reply('❌ *Terjadi kesalahan saat membuat akun.*', { parse_mode: 'Markdown' });
      }

      await dbRunAsync('UPDATE Server SET total_create_akun = total_create_akun + 1 WHERE id = ?', [serverId]);
      await dbRunAsync(`
        INSERT INTO invoice_log (user_id, username, layanan, akun, hari, harga, komisi, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
      `, [userId, ctx.from.username || ctx.from.first_name, type, username, days, totalHarga, komisi]);

      if (action === 'create') {
        await dbRunAsync('INSERT OR REPLACE INTO akun_aktif (username, jenis) VALUES (?, ?)', [username, type]);
      }

      if (user.role === 'reseller') {
        await dbRunAsync('UPDATE users SET saldo = saldo + ? WHERE user_id = ?', [komisi, userId]);
        await dbRunAsync(`
          INSERT INTO reseller_sales (reseller_id, buyer_id, akun_type, username, komisi, created_at)
          VALUES (?, ?, ?, ?, ?, datetime('now'))
        `, [userId, userId, type, username, komisi]);

        const res = await dbGetAsync('SELECT SUM(komisi) AS total_komisi FROM reseller_sales WHERE reseller_id = ?', [userId]);
        const totalKomisi = res?.total_komisi || 0;
        const prevLevel = user.reseller_level || 'silver';
        const level = totalKomisi >= 80000 ? 'platinum' : totalKomisi >= 50000 ? 'gold' : 'silver';
        const levelOrder = { silver: 1, gold: 2, platinum: 3 };

        if (level !== prevLevel) {
        await dbRunAsync('UPDATE users SET reseller_level = ? WHERE user_id = ?', [level, userId]);

        if (GROUP_ID) {
        const mention = ctx.from.username ? `@${ctx.from.username}` : ctx.from.first_name;
        const naik = levelOrder[level] > levelOrder[prevLevel];
        const icon = naik ? '📈 *Level Naik!*' : '📉 *Level Turun!*';
        const notif = `${icon}\n\n💌 ${mention}\n🎖️ Dari: *${prevLevel.toUpperCase()}* ke *${level.toUpperCase()}*`;

        await bot.telegram.sendMessage(GROUP_ID, notif, { parse_mode: 'Markdown' });
  }
}
      }

      const mention = ctx.from.username ? `@${ctx.from.username}` : ctx.from.first_name;
const isReseller = user?.role === 'reseller';
const label = isReseller ? 'Reseller' : 'User';
const actionLabel = action === 'renew' ? '♻️ 𝗥𝗲𝗻𝗲𝘄 𝗯𝘆' : '📩 𝗖𝗿𝗲𝗮𝘁𝗲 𝗯𝘆';

const serverNama = server?.nama_server || server?.domain || 'Unknown Server';
const ipLimit = server?.iplimit || iplimit || '-';
const hargaFinal = totalHarga || 0;
const durasiHari = days || 30;
const waktuSekarang = new Date().toLocaleString('id-ID');

// Template invoice
const invoice = `
━━━━━━━━━━━━━━━━━━━━━━━        
🚀 𝗦𝗨𝗖𝗖𝗘𝗦𝗦𝗙𝗨𝗟 𝗧𝗥𝗔𝗡𝗦𝗔𝗖𝗧𝗜𝗢𝗡
━━━━━━━━━━━━━━━━━━━━━━━
👤 𝗨𝘀𝗲𝗿: ${mention}
${actionLabel} : ${label}
🌐 𝗦𝗲𝗿𝘃𝗲𝗿: ${serverNama} | ${ipLimit} IP
🔖 𝗨𝘀𝗲𝗿𝗻𝗮𝗺𝗲: ${username}
🏪 𝗣𝗿𝗼𝘁𝗼𝗰𝗼𝗹: ${type.toUpperCase()}
💴 𝗛𝗮𝗿𝗴𝗮: Rp${hargaFinal.toLocaleString('id-ID')}
⏳ 𝗗𝘂𝗿𝗮𝘀𝗶: ${durasiHari} hari
${isReseller ? `📊 𝗞𝗼𝗺𝗶𝘀𝗶: Rp${komisi?.toLocaleString('id-ID') || 0}\n` : ''}🕒 𝗪𝗮𝗸𝘁𝘂: ${waktuSekarang}
━━━━━━━━━━━━━━━━━━━━━━━
`.trim();

        await bot.telegram.sendMessage(GROUP_ID, invoice);
      

      await ctx.reply(msg, { parse_mode: 'Markdown', disable_web_page_preview: true });
      delete userState[chatId];
    }
  } catch (err) {
    logger.error('❌ Error on text handler:', err.message);
    await ctx.reply('❌ *Terjadi kesalahan saat memproses permintaan.*', { parse_mode: 'Markdown' });
    delete userState[chatId];
  }


       ///ubahLevel
     if (state.step === 'await_level_change') {
  const [idStr, level] = text.split(' ');
  const validLevels = ['silver', 'gold', 'platinum'];
  const targetId = parseInt(idStr);

  if (isNaN(targetId) || !validLevels.includes(level)) {
    return ctx.reply('❌ *Format salah.*\nContoh: `123456789 gold`\nLevel valid: silver, gold, platinum', {
      parse_mode: 'Markdown'
    });
  }

  db.run(
    `UPDATE users SET reseller_level = ? WHERE user_id = ? AND role = 'reseller'`,
    [level, targetId],
    function (err) {
      if (err) {
        logger.error('❌ DB error saat ubah level:', err.message);
        return ctx.reply('❌ *Gagal mengubah level reseller.*', { parse_mode: 'Markdown' });
      }

      if (this.changes === 0) {
        return ctx.reply('⚠️ *User tidak ditemukan atau bukan reseller.*', { parse_mode: 'Markdown' });
      }

      ctx.reply(`✅ *User ${targetId} diubah menjadi reseller ${level.toUpperCase()}.*`, {
        parse_mode: 'Markdown'
      });
    }
  );

  delete userState[ctx.chat.id];
  return;
}
     // downgrade
     if (state.step === 'await_downgrade_id') {
  const targetId = parseInt(text);
  if (isNaN(targetId)) {
    return ctx.reply('❌ *ID tidak valid.*', { parse_mode: 'Markdown' });
  }

  db.run(
    `UPDATE users SET role = 'user', reseller_level = NULL WHERE user_id = ?`,
    [targetId],
    function (err) {
      if (err) {
        logger.error('❌ DB error saat downgrade reseller:', err.message);
        return ctx.reply('❌ *Gagal downgrade user.*', { parse_mode: 'Markdown' });
      }

      if (this.changes === 0) {
        return ctx.reply('⚠️ *User belum terdaftar.*', { parse_mode: 'Markdown' });
      }

      ctx.reply(`✅ *User ${targetId} telah di-*downgrade* menjadi USER biasa.*`, {
        parse_mode: 'Markdown'
      });
    }
  );

  delete userState[ctx.chat.id];
  return;
}

     // 🎖️ Promote Reseller - Input via tombol admin
if (state.step === 'await_reseller_id') {
  const targetId = parseInt(text);
  if (isNaN(targetId)) {
    return ctx.reply('⚠️ *ID tidak valid. Masukkan angka.*', { parse_mode: 'Markdown' });
  }

  db.run(
    `UPDATE users SET role = 'reseller', reseller_level = 'silver' WHERE user_id = ?`,
    [targetId],
    function (err) {
      if (err) {
        logger.error('❌ DB error saat promote:', err.message);
        return ctx.reply('❌ *Gagal promote user.*', { parse_mode: 'Markdown' });
      }

      if (this.changes === 0) {
        return ctx.reply('⚠️ *User belum terdaftar.*', { parse_mode: 'Markdown' });
      }

      ctx.reply(`✅ *User ${targetId} sukses dipromosikan jadi RESELLER level Silver!*`, {
        parse_mode: 'Markdown'
      });
    }
  );

  delete userState[ctx.chat.id];
  return;
}
     ///rsesetkomisi
     if (state.step === 'reset_komisi_input') {
  const targetId = parseInt(text);
  if (isNaN(targetId)) {
    return ctx.reply(escapeMarkdownV2('❌ User ID tidak valid. Masukkan angka.'), {
      parse_mode: 'MarkdownV2'
    });
  }

  try {
    await dbRunAsync('DELETE FROM reseller_sales WHERE reseller_id = ?', [targetId]);
    await dbRunAsync('UPDATE users SET reseller_level = ? WHERE user_id = ?', ['silver', targetId]);

    // ✅ Kirim pesan sukses ke admin
    await ctx.reply(escapeMarkdownV2(`✅ Komisi user ${targetId} berhasil direset.`), {
      parse_mode: 'MarkdownV2'
    });

    // 📢 Notifikasi ke grup
    if (GROUP_ID) {
      const mention = ctx.from.username
        ? `@${escapeMarkdownV2(ctx.from.username)}`
        : escapeMarkdownV2(ctx.from.first_name);

      const notif = escapeMarkdownV2(
        `🧹 Reset Komisi Reseller\n\n👤 Oleh: ${mention}\n🆔 User ID: ${targetId}\n📉 Komisi & level direset.`
      );

      await bot.telegram.sendMessage(GROUP_ID, notif, {
        parse_mode: 'MarkdownV2'
      });
    }

  } catch (err) {
    logger.error('❌ Gagal reset komisi:', err.message);
    await ctx.reply(escapeMarkdownV2('❌ Terjadi kesalahan saat reset komisi.'), {
      parse_mode: 'MarkdownV2'
    });
  }

  delete userState[ctx.chat.id];
  return;
}

// 📨 BROADCAST
  if (state.step === 'await_broadcast_message') {
    if (!adminIds.includes(String(userId))) {
      return ctx.reply('❌ Kamu tidak punya izin untuk melakukan broadcast.');
    }

    const broadcastMessage = text;
    delete userState[chatId];

    db.all('SELECT user_id FROM users', [], async (err, rows) => {
      if (err) {
        logger.error('❌ Gagal ambil daftar user:', err.message);
        return ctx.reply('❌ Gagal mengambil data user.');
      }

      let sukses = 0;
      let gagal = 0;

      for (const row of rows) {
        try {
          await bot.telegram.sendMessage(row.user_id, broadcastMessage);
          sukses++;
        } catch (e) {
          gagal++;
          logger.warn(`❌ Gagal kirim ke ${row.user_id}: ${e.message}`);
        }
      }

      ctx.reply(`📣 *Broadcast selesai:*\n✅ Berhasil: ${sukses}\n❌ Gagal: ${gagal}`, {
        parse_mode: 'Markdown'
      });
    });

    return;
  }

  // 4️⃣ Add Server Step-by-Step
  if (state.step === 'addserver') {
    const domain = text;
    if (!domain) return ctx.reply('⚠️ *Domain tidak boleh kosong.* Silakan masukkan domain server yang valid.', { parse_mode: 'Markdown' });
    state.domain = domain;
    state.step = 'addserver_auth';
    return ctx.reply('🔑 *Silakan masukkan auth server:*', { parse_mode: 'Markdown' });
  }

  if (state.step === 'addserver_auth') {
    const auth = text;
    if (!auth) return ctx.reply('⚠️ *Auth tidak boleh kosong.* Silakan masukkan auth server yang valid.', { parse_mode: 'Markdown' });
    state.auth = auth;
    state.step = 'addserver_nama_server';
    return ctx.reply('🏷️ *Silakan masukkan nama server:*', { parse_mode: 'Markdown' });
  }

  if (state.step === 'addserver_nama_server') {
    const nama_server = text;
    if (!nama_server) return ctx.reply('⚠️ *Nama server tidak boleh kosong.*', { parse_mode: 'Markdown' });
    state.nama_server = nama_server;
    state.step = 'addserver_quota';
    return ctx.reply('📊 *Silakan masukkan quota server:*', { parse_mode: 'Markdown' });
  }

  if (state.step === 'addserver_quota') {
    const quota = parseInt(text, 10);
    if (isNaN(quota)) return ctx.reply('⚠️ *Quota tidak valid.*', { parse_mode: 'Markdown' });
    state.quota = quota;
    state.step = 'addserver_iplimit';
    return ctx.reply('🔢 *Silakan masukkan limit IP server:*', { parse_mode: 'Markdown' });
  }

  if (state.step === 'addserver_iplimit') {
    const iplimit = parseInt(text, 10);
    if (isNaN(iplimit)) return ctx.reply('⚠️ *Limit IP tidak valid.*', { parse_mode: 'Markdown' });
    state.iplimit = iplimit;
    state.step = 'addserver_batas_create_akun';
    return ctx.reply('🔢 *Silakan masukkan batas create akun server:*', { parse_mode: 'Markdown' });
  }

  if (state.step === 'addserver_batas_create_akun') {
    const batas = parseInt(text, 10);
    if (isNaN(batas)) return ctx.reply('⚠️ *Batas create akun tidak valid.*', { parse_mode: 'Markdown' });
    state.batas_create_akun = batas;
    state.step = 'addserver_harga';
    return ctx.reply('💰 *Silakan masukkan harga server:*', { parse_mode: 'Markdown' });
  }

  if (state.step === 'addserver_harga') {
  const harga = parseFloat(text);
  if (isNaN(harga) || harga <= 0) return ctx.reply('⚠️ *Harga tidak valid.*', { parse_mode: 'Markdown' });

  const { domain, auth, nama_server, quota, iplimit, batas_create_akun } = state;

  try {
    const resolvedIP = await resolveDomainToIP(domain);
    let isp = 'Tidak diketahui', lokasi = 'Tidak diketahui';

    if (resolvedIP) {
      const info = await getISPAndLocation(resolvedIP);
      isp = info.isp;
      lokasi = info.lokasi;
    }

    db.run(`
      INSERT INTO Server (domain, auth, nama_server, quota, iplimit, batas_create_akun, harga, total_create_akun, isp, lokasi)
      VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, ?)
    `, [domain, auth, nama_server, quota, iplimit, batas_create_akun, harga, isp, lokasi], function(err) {
      if (err) {
        logger.error('❌ Error saat tambah server:', err.message);
        ctx.reply('❌ *Gagal menambahkan server.*', { parse_mode: 'Markdown' });
      } else {
        ctx.reply(
          `✅ *Server berhasil ditambahkan!*\n\n` +
          `🌐 Domain: ${domain}\n` +
          `📍 Lokasi: ${lokasi}\n` +
          `🏢 ISP: ${isp}`,
          { parse_mode: 'Markdown' }
        );
      }
    });

  } catch (err) {
    logger.error('❌ Gagal resolve/tambah server:', err.message);
    ctx.reply('❌ *Terjadi kesalahan saat menambahkan server.*', { parse_mode: 'Markdown' });
  }

  delete userState[ctx.chat.id];
  return;
}
});


bot.action('addserver', async (ctx) => {
  try {
    logger.info('📥 Proses tambah server dimulai');
    await ctx.answerCbQuery();
    await ctx.reply('🌐 *Silakan masukkan domain/ip server:*', { parse_mode: 'Markdown' });
    userState[ctx.chat.id] = { step: 'addserver' };
  } catch (error) {
    logger.error('❌ Kesalahan saat memulai proses tambah server:', error);
    await ctx.reply('❌ *GAGAL! Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.*', { parse_mode: 'Markdown' });
  }
});
bot.action('detailserver', async (ctx) => {
  try {
    logger.info('📋 Proses detail server dimulai');
    await ctx.answerCbQuery();
    
    const servers = await new Promise((resolve, reject) => {
      db.all('SELECT * FROM Server', [], (err, servers) => {
        if (err) {
          logger.error('⚠️ Kesalahan saat mengambil detail server:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil detail server.*');
        }
        resolve(servers);
      });
    });

    if (servers.length === 0) {
      logger.info('⚠️ Tidak ada server yang tersedia');
      return ctx.reply('⚠️ *PERHATIAN! Tidak ada server yang tersedia saat ini.*', { parse_mode: 'Markdown' });
    }

    const buttons = [];
    for (let i = 0; i < servers.length; i += 2) {
      const row = [];
      row.push({
        text: `${servers[i].nama_server}`,
        callback_data: `server_detail_${servers[i].id}`
      });
      if (i + 1 < servers.length) {
        row.push({
          text: `${servers[i + 1].nama_server}`,
          callback_data: `server_detail_${servers[i + 1].id}`
        });
      }
      buttons.push(row);
    }

    await ctx.reply('📋 *Silakan pilih server untuk melihat detail:*', {
      reply_markup: { inline_keyboard: buttons },
      parse_mode: 'Markdown'
    });
  } catch (error) {
    logger.error('⚠️ Kesalahan saat mengambil detail server:', error);
    await ctx.reply('⚠️ *Terjadi kesalahan saat mengambil detail server.*', { parse_mode: 'Markdown' });
  }
});

bot.action('listserver', async (ctx) => {
  try {
    logger.info('📜 Proses daftar server dimulai');
    await ctx.answerCbQuery();
    
    const servers = await new Promise((resolve, reject) => {
      db.all('SELECT * FROM Server', [], (err, servers) => {
        if (err) {
          logger.error('⚠️ Kesalahan saat mengambil daftar server:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil daftar server.*');
        }
        resolve(servers);
      });
    });

    if (servers.length === 0) {
      logger.info('⚠️ Tidak ada server yang tersedia');
      return ctx.reply('⚠️ *PERHATIAN! Tidak ada server yang tersedia saat ini.*', { parse_mode: 'Markdown' });
    }

    let serverList = '📜 *Daftar Server* 📜\n\n';
    servers.forEach((server, index) => {
      serverList += `🔹 ${index + 1}. ${server.domain}\n`;
    });

    serverList += `\nTotal Jumlah Server: ${servers.length}`;

    await ctx.reply(serverList, { parse_mode: 'Markdown' });
  } catch (error) {
    logger.error('⚠️ Kesalahan saat mengambil daftar server:', error);
    await ctx.reply('⚠️ *Terjadi kesalahan saat mengambil daftar server.*', { parse_mode: 'Markdown' });
  }
});
bot.action('resetdb', async (ctx) => {
  try {
    await ctx.answerCbQuery();
    await ctx.reply('🚨 *PERHATIAN! Anda akan menghapus semua server yang tersedia. Apakah Anda yakin?*', {
      reply_markup: {
        inline_keyboard: [
          [{ text: '✅ Ya', callback_data: 'confirm_resetdb' }],
          [{ text: '❌ Tidak', callback_data: 'cancel_resetdb' }]
        ]
      },
      parse_mode: 'Markdown'
    });
  } catch (error) {
    logger.error('❌ Error saat memulai proses reset database:', error);
    await ctx.reply(`❌ *${error}*`, { parse_mode: 'Markdown' });
  }
});

bot.action('confirm_resetdb', async (ctx) => {
  try {
    await ctx.answerCbQuery();
    await new Promise((resolve, reject) => {
      db.run('DELETE FROM Server', (err) => {
        if (err) {
          logger.error('❌ Error saat mereset tabel Server:', err.message);
          return reject('❗️ *PERHATIAN! Terjadi KESALAHAN SERIUS saat mereset database. Harap segera hubungi administrator!*');
        }
        resolve();
      });
    });
    await ctx.reply('🚨 *PERHATIAN! Database telah DIRESET SEPENUHNYA. Semua server telah DIHAPUS TOTAL.*', { parse_mode: 'Markdown' });
  } catch (error) {
    logger.error('❌ Error saat mereset database:', error);
    await ctx.reply(`❌ *${error}*`, { parse_mode: 'Markdown' });
  }
});

bot.action('cancel_resetdb', async (ctx) => {
  try {
    await ctx.answerCbQuery();
    await ctx.reply('❌ *Proses reset database dibatalkan.*', { parse_mode: 'Markdown' });
  } catch (error) {
    logger.error('❌ Error saat membatalkan reset database:', error);
    await ctx.reply(`❌ *${error}*`, { parse_mode: 'Markdown' });
  }
});
bot.action('deleteserver', async (ctx) => {
  try {
    logger.info('🗑️ Proses hapus server dimulai');
    await ctx.answerCbQuery();
    
    db.all('SELECT * FROM Server', [], (err, servers) => {
      if (err) {
        logger.error('⚠️ Kesalahan saat mengambil daftar server:', err.message);
        return ctx.reply('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil daftar server.*', { parse_mode: 'Markdown' });
      }

      if (servers.length === 0) {
        logger.info('⚠️ Tidak ada server yang tersedia');
        return ctx.reply('⚠️ *PERHATIAN! Tidak ada server yang tersedia saat ini.*', { parse_mode: 'Markdown' });
      }

      const keyboard = servers.map(server => {
        return [{ text: server.nama_server, callback_data: `confirm_delete_server_${server.id}` }];
      });
      keyboard.push([{ text: '🔙 Kembali ke Menu Utama', callback_data: 'kembali_ke_menu' }]);

      ctx.reply('🗑️ *Pilih server yang ingin dihapus:*', {
        reply_markup: {
          inline_keyboard: keyboard
        },
        parse_mode: 'Markdown'
      });
    });
  } catch (error) {
    logger.error('❌ Kesalahan saat memulai proses hapus server:', error);
    await ctx.reply('❌ *GAGAL! Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.*', { parse_mode: 'Markdown' });
  }
});


// Menangani aksi untuk mengecek saldo
bot.action('cek_saldo', async (ctx) => {
  try {
    const userId = ctx.from.id;
    
    const row = await new Promise((resolve, reject) => {
      db.get('SELECT saldo FROM users WHERE user_id = ?', [userId], (err, row) => {
        if (err) {
          logger.error('❌ Kesalahan saat memeriksa saldo:', err.message);
          return reject('❌ *Terjadi kesalahan saat memeriksa saldo Anda. Silakan coba lagi nanti.*');
        }
        resolve(row);
      });
    });

    if (row) {
      await ctx.reply(`📊 *Cek Saldo*\n\n🆔 ID Telegram: ${userId}\n💰 Sisa Saldo: Rp${row.saldo}`, 
      { 
        parse_mode: 'Markdown', 
        reply_markup: {
          inline_keyboard: [
            [{ text: '💸 Top Up', callback_data: 'topup_saldo' }, { text: '📝 Menu Utama', callback_data: 'send_main_menu' }]
          ]
        } 
      });
    } else {
      await ctx.reply('⚠️ *Anda belum memiliki saldo. Silakan tambahkan saldo terlebih dahulu.*', { parse_mode: 'Markdown' });
    }
    
  } catch (error) {
    logger.error('❌ Kesalahan saat memeriksa saldo:', error);
    await ctx.reply(`❌ *${error.message}*`, { parse_mode: 'Markdown' });
  }
});

// Fungsi untuk mengambil username berdasarkan ID
const getUsernameById = async (userId) => {
  try {
    const telegramUser = await bot.telegram.getChat(userId);
    return telegramUser.username || telegramUser.first_name;
  } catch (err) {
    logger.error('❌ Kesalahan saat mengambil username dari Telegram:', err.message);
    throw new Error('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil username dari Telegram.*');
  }
};

bot.action('addsaldo_user', async (ctx) => {
  try {
    logger.info('Add saldo user process started');
    await ctx.answerCbQuery();

    const users = await new Promise((resolve, reject) => {
      db.all('SELECT id, user_id FROM Users LIMIT 20', [], (err, users) => {
        if (err) {
          logger.error('❌ Kesalahan saat mengambil daftar user:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil daftar user.*');
        }
        resolve(users);
      });
    });

    const totalUsers = await new Promise((resolve, reject) => {
      db.get('SELECT COUNT(*) as count FROM Users', [], (err, row) => {
        if (err) {
          logger.error('❌ Kesalahan saat menghitung total user:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat menghitung total user.*');
        }
        resolve(row.count);
      });
    });

    const buttons = [];
    for (let i = 0; i < users.length; i += 2) {
      const row = [];
      const username1 = await getUsernameById(users[i].user_id);
      row.push({
        text: username1 || users[i].user_id,
        callback_data: `add_saldo_${users[i].id}`
      });
      if (i + 1 < users.length) {
        const username2 = await getUsernameById(users[i + 1].user_id);
        row.push({
          text: username2 || users[i + 1].user_id,
          callback_data: `add_saldo_${users[i + 1].id}`
        });
      }
      buttons.push(row);
    }

    const currentPage = 0;
    const replyMarkup = {
      inline_keyboard: [...buttons]
    };

    if (totalUsers > 20) {
      replyMarkup.inline_keyboard.push([{
        text: '➡️ Next',
        callback_data: `next_users_${currentPage + 1}`
      }]);
    }

    await ctx.reply('📊 *Silakan pilih user untuk menambahkan saldo:*', {
      reply_markup: replyMarkup,
      parse_mode: 'Markdown'
    });
  } catch (error) {
    logger.error('❌ Kesalahan saat memulai proses tambah saldo user:', error);
    await ctx.reply(`❌ *${error}*`, { parse_mode: 'Markdown' });
  }
});
bot.action(/next_users_(\d+)/, async (ctx) => {
  const currentPage = parseInt(ctx.match[1]);
  const offset = currentPage * 20;

  try {
    logger.info(`Next users process started for page ${currentPage + 1}`);
    await ctx.answerCbQuery();

    const users = await new Promise((resolve, reject) => {
      db.all(`SELECT id, user_id FROM Users LIMIT 20 OFFSET ${offset}`, [], (err, users) => {
        if (err) {
          logger.error('❌ Kesalahan saat mengambil daftar user:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil daftar user.*');
        }
        resolve(users);
      });
    });

    const totalUsers = await new Promise((resolve, reject) => {
      db.get('SELECT COUNT(*) as count FROM Users', [], (err, row) => {
        if (err) {
          logger.error('❌ Kesalahan saat menghitung total user:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat menghitung total user.*');
        }
        resolve(row.count);
      });
    });

    const buttons = [];
    for (let i = 0; i < users.length; i += 2) {
      const row = [];
      const username1 = await getUsernameById(users[i].user_id);
      row.push({
        text: username1 || users[i].user_id,
        callback_data: `add_saldo_${users[i].id}`
      });
      if (i + 1 < users.length) {
        const username2 = await getUsernameById(users[i + 1].user_id);
        row.push({
          text: username2 || users[i + 1].user_id,
          callback_data: `add_saldo_${users[i + 1].id}`
        });
      }
      buttons.push(row);
    }

    const replyMarkup = {
      inline_keyboard: [...buttons]
    };

    const navigationButtons = [];
    if (currentPage > 0) {
      navigationButtons.push([{
        text: '⬅️ Back',
        callback_data: `prev_users_${currentPage - 1}`
      }]);
    }
    if (offset + 20 < totalUsers) {
      navigationButtons.push([{
        text: '➡️ Next',
        callback_data: `next_users_${currentPage + 1}`
      }]);
    }

    replyMarkup.inline_keyboard.push(...navigationButtons);

    await ctx.editMessageReplyMarkup(replyMarkup);
  } catch (error) {
    logger.error('❌ Kesalahan saat memproses next users:', error);
    await ctx.reply(`❌ *${error}*`, { parse_mode: 'Markdown' });
  }
});

bot.action(/prev_users_(\d+)/, async (ctx) => {
  const currentPage = parseInt(ctx.match[1]);
  const offset = (currentPage - 1) * 20; 

  try {
    logger.info(`Previous users process started for page ${currentPage}`);
    await ctx.answerCbQuery();

    const users = await new Promise((resolve, reject) => {
      db.all(`SELECT id, user_id FROM Users LIMIT 20 OFFSET ${offset}`, [], (err, users) => {
        if (err) {
          logger.error('❌ Kesalahan saat mengambil daftar user:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil daftar user.*');
        }
        resolve(users);
      });
    });

    const totalUsers = await new Promise((resolve, reject) => {
      db.get('SELECT COUNT(*) as count FROM Users', [], (err, row) => {
        if (err) {
          logger.error('❌ Kesalahan saat menghitung total user:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat menghitung total user.*');
        }
        resolve(row.count);
      });
    });

    const buttons = [];
    for (let i = 0; i < users.length; i += 2) {
      const row = [];
      const username1 = await getUsernameById(users[i].user_id);
      row.push({
        text: username1 || users[i].user_id,
        callback_data: `add_saldo_${users[i].id}`
      });
      if (i + 1 < users.length) {
        const username2 = await getUsernameById(users[i + 1].user_id);
        row.push({
          text: username2 || users[i + 1].user_id,
          callback_data: `add_saldo_${users[i + 1].id}`
        });
      }
      buttons.push(row);
    }

    const replyMarkup = {
      inline_keyboard: [...buttons]
    };

    const navigationButtons = [];
    if (currentPage > 0) {
      navigationButtons.push([{
        text: '⬅️ Back',
        callback_data: `prev_users_${currentPage - 1}`
      }]);
    }
    if (offset + 20 < totalUsers) {
      navigationButtons.push([{
        text: '➡️ Next',
        callback_data: `next_users_${currentPage}`
      }]);
    }

    replyMarkup.inline_keyboard.push(...navigationButtons);

    await ctx.editMessageReplyMarkup(replyMarkup);
  } catch (error) {
    logger.error('❌ Kesalahan saat memproses previous users:', error);
    await ctx.reply(`❌ *${error}*`, { parse_mode: 'Markdown' });
  }
});
bot.action('editserver_limit_ip', async (ctx) => {
  try {
    logger.info('Edit server limit IP process started');
    await ctx.answerCbQuery();

    const servers = await new Promise((resolve, reject) => {
      db.all('SELECT id, nama_server FROM Server', [], (err, servers) => {
        if (err) {
          logger.error('❌ Kesalahan saat mengambil daftar server:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil daftar server.*');
        }
        resolve(servers);
      });
    });

    if (servers.length === 0) {
      return ctx.reply('⚠️ *PERHATIAN! Tidak ada server yang tersedia untuk diedit.*', { parse_mode: 'Markdown' });
    }

    const buttons = servers.map(server => ({
      text: server.nama_server,
      callback_data: `edit_limit_ip_${server.id}`
    }));

    const inlineKeyboard = [];
    for (let i = 0; i < buttons.length; i += 2) {
      inlineKeyboard.push(buttons.slice(i, i + 2));
    }

    await ctx.reply('📊 *Silakan pilih server untuk mengedit limit IP:*', {
      reply_markup: { inline_keyboard: inlineKeyboard },
      parse_mode: 'Markdown'
    });
  } catch (error) {
    logger.error('❌ Kesalahan saat memulai proses edit limit IP server:', error);
    await ctx.reply(`❌ *${error}*`, { parse_mode: 'Markdown' });
  }
});
bot.action('editserver_batas_create_akun', async (ctx) => {
  try {
    logger.info('Edit server batas create akun process started');
    await ctx.answerCbQuery();

    const servers = await new Promise((resolve, reject) => {
      db.all('SELECT id, nama_server FROM Server', [], (err, servers) => {
        if (err) {
          logger.error('❌ Kesalahan saat mengambil daftar server:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil daftar server.*');
        }
        resolve(servers);
      });
    });

    if (servers.length === 0) {
      return ctx.reply('⚠️ *PERHATIAN! Tidak ada server yang tersedia untuk diedit.*', { parse_mode: 'Markdown' });
    }

    const buttons = servers.map(server => ({
      text: server.nama_server,
      callback_data: `edit_batas_create_akun_${server.id}`
    }));

    const inlineKeyboard = [];
    for (let i = 0; i < buttons.length; i += 2) {
      inlineKeyboard.push(buttons.slice(i, i + 2));
    }

    await ctx.reply('📊 *Silakan pilih server untuk mengedit batas create akun:*', {
      reply_markup: { inline_keyboard: inlineKeyboard },
      parse_mode: 'Markdown'
    });
  } catch (error) {
    logger.error('❌ Kesalahan saat memulai proses edit batas create akun server:', error);
    await ctx.reply(`❌ *${error}*`, { parse_mode: 'Markdown' });
  }
});
bot.action('editserver_total_create_akun', async (ctx) => {
  try {
    logger.info('Edit server total create akun process started');
    await ctx.answerCbQuery();

    const servers = await new Promise((resolve, reject) => {
      db.all('SELECT id, nama_server FROM Server', [], (err, servers) => {
        if (err) {
          logger.error('❌ Kesalahan saat mengambil daftar server:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil daftar server.*');
        }
        resolve(servers);
      });
    });

    if (servers.length === 0) {
      return ctx.reply('⚠️ *PERHATIAN! Tidak ada server yang tersedia untuk diedit.*', { parse_mode: 'Markdown' });
    }

    const buttons = servers.map(server => ({
      text: server.nama_server,
      callback_data: `edit_total_create_akun_${server.id}`
    }));

    const inlineKeyboard = [];
    for (let i = 0; i < buttons.length; i += 2) {
      inlineKeyboard.push(buttons.slice(i, i + 2));
    }

    await ctx.reply('📊 *Silakan pilih server untuk mengedit total create akun:*', {
      reply_markup: { inline_keyboard: inlineKeyboard },
      parse_mode: 'Markdown'
    });
  } catch (error) {
    logger.error('❌ Kesalahan saat memulai proses edit total create akun server:', error);
    await ctx.reply(`❌ *${error}*`, { parse_mode: 'Markdown' });
  }
});
bot.action('editserver_quota', async (ctx) => {
  try {
    logger.info('Edit server quota process started');
    await ctx.answerCbQuery();

    const servers = await new Promise((resolve, reject) => {
      db.all('SELECT id, nama_server FROM Server', [], (err, servers) => {
        if (err) {
          logger.error('❌ Kesalahan saat mengambil daftar server:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil daftar server.*');
        }
        resolve(servers);
      });
    });

    if (servers.length === 0) {
      return ctx.reply('⚠️ *PERHATIAN! Tidak ada server yang tersedia untuk diedit.*', { parse_mode: 'Markdown' });
    }

    const buttons = servers.map(server => ({
      text: server.nama_server,
      callback_data: `edit_quota_${server.id}`
    }));

    const inlineKeyboard = [];
    for (let i = 0; i < buttons.length; i += 2) {
      inlineKeyboard.push(buttons.slice(i, i + 2));
    }

    await ctx.reply('📊 *Silakan pilih server untuk mengedit quota:*', {
      reply_markup: { inline_keyboard: inlineKeyboard },
      parse_mode: 'Markdown'
    });
  } catch (error) {
    logger.error('❌ Kesalahan saat memulai proses edit quota server:', error);
    await ctx.reply(`❌ *${error}*`, { parse_mode: 'Markdown' });
  }
});
bot.action('editserver_auth', async (ctx) => {
  try {
    logger.info('Edit server auth process started');
    await ctx.answerCbQuery();

    const servers = await new Promise((resolve, reject) => {
      db.all('SELECT id, nama_server FROM Server', [], (err, servers) => {
        if (err) {
          logger.error('❌ Kesalahan saat mengambil daftar server:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil daftar server.*');
        }
        resolve(servers);
      });
    });

    if (servers.length === 0) {
      return ctx.reply('⚠️ *PERHATIAN! Tidak ada server yang tersedia untuk diedit.*', { parse_mode: 'Markdown' });
    }

    const buttons = servers.map(server => ({
      text: server.nama_server,
      callback_data: `edit_auth_${server.id}`
    }));

    const inlineKeyboard = [];
    for (let i = 0; i < buttons.length; i += 2) {
      inlineKeyboard.push(buttons.slice(i, i + 2));
    }

    await ctx.reply('🌐 *Silakan pilih server untuk mengedit auth:*', {
      reply_markup: { inline_keyboard: inlineKeyboard },
      parse_mode: 'Markdown'
    });
  } catch (error) {
    logger.error('❌ Kesalahan saat memulai proses edit auth server:', error);
    await ctx.reply(`❌ *${error}*`, { parse_mode: 'Markdown' });
  }
});

bot.action('editserver_harga', async (ctx) => {
  try {
    logger.info('Edit server harga process started');
    await ctx.answerCbQuery();

    const servers = await new Promise((resolve, reject) => {
      db.all('SELECT id, nama_server FROM Server', [], (err, servers) => {
        if (err) {
          logger.error('❌ Kesalahan saat mengambil daftar server:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil daftar server.*');
        }
        resolve(servers);
      });
    });

    if (servers.length === 0) {
      return ctx.reply('⚠️ *PERHATIAN! Tidak ada server yang tersedia untuk diedit.*', { parse_mode: 'Markdown' });
    }

    const buttons = servers.map(server => ({
      text: server.nama_server,
      callback_data: `edit_harga_${server.id}`
    }));

    const inlineKeyboard = [];
    for (let i = 0; i < buttons.length; i += 2) {
      inlineKeyboard.push(buttons.slice(i, i + 2));
    }

    await ctx.reply('💰 *Silakan pilih server untuk mengedit harga:*', {
      reply_markup: { inline_keyboard: inlineKeyboard },
      parse_mode: 'Markdown'
    });
  } catch (error) {
    logger.error('❌ Kesalahan saat memulai proses edit harga server:', error);
    await ctx.reply(`❌ *${error}*`, { parse_mode: 'Markdown' });
  }
});

bot.action('editserver_domain', async (ctx) => {
  try {
    logger.info('Edit server domain process started');
    await ctx.answerCbQuery();

    const servers = await new Promise((resolve, reject) => {
      db.all('SELECT id, nama_server FROM Server', [], (err, servers) => {
        if (err) {
          logger.error('❌ Kesalahan saat mengambil daftar server:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil daftar server.*');
        }
        resolve(servers);
      });
    });

    if (servers.length === 0) {
      return ctx.reply('⚠️ *PERHATIAN! Tidak ada server yang tersedia untuk diedit.*', { parse_mode: 'Markdown' });
    }

    const buttons = servers.map(server => ({
      text: server.nama_server,
      callback_data: `edit_domain_${server.id}`
    }));

    const inlineKeyboard = [];
    for (let i = 0; i < buttons.length; i += 2) {
      inlineKeyboard.push(buttons.slice(i, i + 2));
    }

    await ctx.reply('🌐 *Silakan pilih server untuk mengedit domain:*', {
      reply_markup: { inline_keyboard: inlineKeyboard },
      parse_mode: 'Markdown'
    });
  } catch (error) {
    logger.error('❌ Kesalahan saat memulai proses edit domain server:', error);
    await ctx.reply(`❌ *${error}*`, { parse_mode: 'Markdown' });
  }
});

bot.action('nama_server_edit', async (ctx) => {
  try {
    logger.info('Edit server nama process started');
    await ctx.answerCbQuery();

    const servers = await new Promise((resolve, reject) => {
      db.all('SELECT id, nama_server FROM Server', [], (err, servers) => {
        if (err) {
          logger.error('❌ Kesalahan saat mengambil daftar server:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil daftar server.*');
        }
        resolve(servers);
      });
    });

    if (servers.length === 0) {
      return ctx.reply('⚠️ *PERHATIAN! Tidak ada server yang tersedia untuk diedit.*', { parse_mode: 'Markdown' });
    }

    const buttons = servers.map(server => ({
      text: server.nama_server,
      callback_data: `edit_nama_${server.id}`
    }));

    const inlineKeyboard = [];
    for (let i = 0; i < buttons.length; i += 2) {
      inlineKeyboard.push(buttons.slice(i, i + 2));
    }

    await ctx.reply('🏷️ *Silakan pilih server untuk mengedit nama:*', {
      reply_markup: { inline_keyboard: inlineKeyboard },
      parse_mode: 'Markdown'
    });
  } catch (error) {
    logger.error('❌ Kesalahan saat memulai proses edit nama server:', error);
    await ctx.reply(`❌ *${error}*`, { parse_mode: 'Markdown' });
  }
});

bot.action('topup_saldo', async (ctx) => {
  try {
    await ctx.answerCbQuery(); 
    const userId = ctx.from.id;
    logger.info(`🔍 User ${userId} memulai proses top-up saldo.`);
    

    if (!global.depositState) {
      global.depositState = {};
    }
    global.depositState[userId] = { action: 'request_amount', amount: '' };
    
    logger.info(`🔍 User ${userId} diminta untuk memasukkan jumlah nominal saldo.`);
    

    const keyboard = keyboard_nomor();
    
    await ctx.editMessageText('💰 *Silakan masukkan jumlah nominal saldo yang Anda ingin tambahkan ke akun Anda:*', {
      reply_markup: {
        inline_keyboard: keyboard
      },
      parse_mode: 'Markdown'
    });
  } catch (error) {
    logger.error('❌ Kesalahan saat memulai proses top-up saldo:', error);
    await ctx.editMessageText('❌ *GAGAL! Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.*', { parse_mode: 'Markdown' });
  }
});

bot.action(/edit_harga_(\d+)/, async (ctx) => {
  const serverId = ctx.match[1];
  logger.info(`User ${ctx.from.id} memilih untuk mengedit harga server dengan ID: ${serverId}`);
  userState[ctx.chat.id] = { step: 'edit_harga', serverId: serverId };

  await ctx.reply('💰 *Silakan masukkan harga server baru:*', {
    reply_markup: { inline_keyboard: keyboard_nomor() },
    parse_mode: 'Markdown'
  });
});
bot.action(/add_saldo_(\d+)/, async (ctx) => {
  const userId = ctx.match[1];
  logger.info(`User ${ctx.from.id} memilih untuk menambahkan saldo user dengan ID: ${userId}`);
  userState[ctx.chat.id] = { step: 'add_saldo', userId: userId };

  await ctx.reply('📊 *Silakan masukkan jumlah saldo yang ingin ditambahkan:*', {
    reply_markup: { inline_keyboard: keyboard_nomor() },
    parse_mode: 'Markdown'
  });
});
bot.action(/edit_batas_create_akun_(\d+)/, async (ctx) => {
  const serverId = ctx.match[1];
  logger.info(`User ${ctx.from.id} memilih untuk mengedit batas create akun server dengan ID: ${serverId}`);
  userState[ctx.chat.id] = { step: 'edit_batas_create_akun', serverId: serverId };

  await ctx.reply('📊 *Silakan masukkan batas create akun server baru:*', {
    reply_markup: { inline_keyboard: keyboard_nomor() },
    parse_mode: 'Markdown'
  });
});
bot.action(/edit_total_create_akun_(\d+)/, async (ctx) => {
  const serverId = ctx.match[1];
  logger.info(`User ${ctx.from.id} memilih untuk mengedit total create akun server dengan ID: ${serverId}`);
  userState[ctx.chat.id] = { step: 'edit_total_create_akun', serverId: serverId };

  await ctx.reply('📊 *Silakan masukkan total create akun server baru:*', {
    reply_markup: { inline_keyboard: keyboard_nomor() },
    parse_mode: 'Markdown'
  });
});
bot.action(/edit_limit_ip_(\d+)/, async (ctx) => {
  const serverId = ctx.match[1];
  logger.info(`User ${ctx.from.id} memilih untuk mengedit limit IP server dengan ID: ${serverId}`);
  userState[ctx.chat.id] = { step: 'edit_limit_ip', serverId: serverId };

  await ctx.reply('📊 *Silakan masukkan limit IP server baru:*', {
    reply_markup: { inline_keyboard: keyboard_nomor() },
    parse_mode: 'Markdown'
  });
});
bot.action(/edit_quota_(\d+)/, async (ctx) => {
  const serverId = ctx.match[1];
  logger.info(`User ${ctx.from.id} memilih untuk mengedit quota server dengan ID: ${serverId}`);
  userState[ctx.chat.id] = { step: 'edit_quota', serverId: serverId };

  await ctx.reply('📊 *Silakan masukkan quota server baru:*', {
    reply_markup: { inline_keyboard: keyboard_nomor() },
    parse_mode: 'Markdown'
  });
});
bot.action(/edit_auth_(\d+)/, async (ctx) => {
  const serverId = ctx.match[1];
  logger.info(`User ${ctx.from.id} memilih untuk mengedit auth server dengan ID: ${serverId}`);
  userState[ctx.chat.id] = { step: 'edit_auth', serverId: serverId };

  await ctx.reply('?? *Silakan masukkan auth server baru:*', {
    reply_markup: { inline_keyboard: keyboard_full() },
    parse_mode: 'Markdown'
  });
});
bot.action(/edit_domain_(\d+)/, async (ctx) => {
  const serverId = ctx.match[1];
  logger.info(`User ${ctx.from.id} memilih untuk mengedit domain server dengan ID: ${serverId}`);
  userState[ctx.chat.id] = { step: 'edit_domain', serverId: serverId };

  await ctx.reply('🌐 *Silakan masukkan domain server baru:*', {
    reply_markup: { inline_keyboard: keyboard_full() },
    parse_mode: 'Markdown'
  });
});
bot.action(/edit_nama_(\d+)/, async (ctx) => {
  const serverId = ctx.match[1];
  logger.info(`User ${ctx.from.id} memilih untuk mengedit nama server dengan ID: ${serverId}`);
  userState[ctx.chat.id] = { step: 'edit_nama', serverId: serverId };

  await ctx.reply('🏷️ *Silakan masukkan nama server baru:*', {
    reply_markup: { inline_keyboard: keyboard_abc() },
    parse_mode: 'Markdown'
  });
});
bot.action(/confirm_delete_server_(\d+)/, async (ctx) => {
  try {
    db.run('DELETE FROM Server WHERE id = ?', [ctx.match[1]], function(err) {
      if (err) {
        logger.error('Error deleting server:', err.message);
        return ctx.reply('⚠️ *PERHATIAN! Terjadi kesalahan saat menghapus server.*', { parse_mode: 'Markdown' });
      }

      if (this.changes === 0) {
        logger.info('Server tidak ditemukan');
        return ctx.reply('⚠️ *PERHATIAN! Server tidak ditemukan.*', { parse_mode: 'Markdown' });
      }

      logger.info(`Server dengan ID ${ctx.match[1]} berhasil dihapus`);
      ctx.reply('✅ *Server berhasil dihapus.*', { parse_mode: 'Markdown' });
    });
  } catch (error) {
    logger.error('Kesalahan saat menghapus server:', error);
    await ctx.reply('❌ *GAGAL! Terjadi kesalahan saat memproses permintaan Anda. Silakan coba lagi nanti.*', { parse_mode: 'Markdown' });
  }
});
bot.action(/server_detail_(\d+)/, async (ctx) => {
  const serverId = ctx.match[1];
  try {
    const server = await new Promise((resolve, reject) => {
      db.get('SELECT * FROM Server WHERE id = ?', [serverId], (err, server) => {
        if (err) {
          logger.error('⚠️ Kesalahan saat mengambil detail server:', err.message);
          return reject('⚠️ *PERHATIAN! Terjadi kesalahan saat mengambil detail server.*');
        }
        resolve(server);
      });
    });

    if (!server) {
      logger.info('⚠️ Server tidak ditemukan');
      return ctx.reply('⚠️ *PERHATIAN! Server tidak ditemukan.*', { parse_mode: 'Markdown' });
    }

    const serverDetails = `📋 *Detail Server* 📋\n\n` +
      `🌐 *Domain:* \`${server.domain}\`\n` +
      `🔑 *Auth:* \`${server.auth}\`\n` +
      `🏷️ *Nama Server:* \`${server.nama_server}\`\n` +
      `📊 *Quota:* \`${server.quota}\`\n` +
      `📶 *Limit IP:* \`${server.iplimit}\`\n` +
      `🔢 *Batas Create Akun:* \`${server.batas_create_akun}\`\n` +
      `📋 *Total Create Akun:* \`${server.total_create_akun}\`\n` +
      `💵 *Harga:* \`Rp ${server.harga}\`\n\n`;

    await ctx.reply(serverDetails, { parse_mode: 'Markdown' });
  } catch (error) {
    logger.error('⚠️ Kesalahan saat mengambil detail server:', error);
    await ctx.reply('⚠️ *Terjadi kesalahan saat mengambil detail server.*', { parse_mode: 'Markdown' });
  }
});

bot.on('callback_query', async (ctx) => {
  const userId = String(ctx.from.id);
  const data = ctx.callbackQuery.data;
  const userStateData = userState[ctx.chat?.id];

  await ctx.answerCbQuery(); // selalu akhiri loading tombol

  // 1️⃣ HANDLE DEPOSIT
  if (global.depositState?.[userId]?.action === 'request_amount') {
    return await handleDepositState(ctx, userId, data);
  }

  // 2️⃣ HANDLE USER STATE (EDIT, ADD SALDO, DLL)
  if (userStateData) {
    switch (userStateData.step) {
      case 'add_saldo': return await handleAddSaldo(ctx, userStateData, data);
      case 'edit_batas_create_akun': return await handleEditBatasCreateAkun(ctx, userStateData, data);
      case 'edit_limit_ip': return await handleEditiplimit(ctx, userStateData, data);
      case 'edit_quota': return await handleEditQuota(ctx, userStateData, data);
      case 'edit_auth': return await handleEditAuth(ctx, userStateData, data);
      case 'edit_domain': return await handleEditDomain(ctx, userStateData, data);
      case 'edit_harga': return await handleEditHarga(ctx, userStateData, data);
      case 'edit_nama': return await handleEditNama(ctx, userStateData, data);
      case 'edit_total_create_akun': return await handleEditTotalCreateAkun(ctx, userStateData, data);
    }
  }

  // 3️⃣ HANDLE INLINE ADMIN TOOLS
  if (!adminIds.includes(userId)) return ctx.reply('🚫 *Akses ditolak.*', { parse_mode: 'Markdown' });

  // === Backup DB
  if (data === 'admin_backup_db') {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupFile = path.join(BACKUP_DIR, `sellvpn_${timestamp}.db`);

    try {
      fs.copyFileSync(DB_PATH, backupFile);
      await ctx.reply('✅ *Backup berhasil dibuat dan dikirim.*', { parse_mode: 'Markdown' });
      await ctx.telegram.sendDocument(userId, { source: backupFile });
    } catch (err) {
      logger.error('❌ Backup gagal:', err.message);
      return ctx.reply('❌ *Gagal membuat backup.*', { parse_mode: 'Markdown' });
    }
    return;
  }

  // === Restore DB: tampilkan list file
  if (data === 'admin_restore_db') {
  const today = new Date().toISOString().slice(0, 10); // format: 2025-06-11

  const files = fs.readdirSync(BACKUP_DIR)
    .filter(f => f.endsWith('.db') && f.includes(today))
    .sort((a, b) => fs.statSync(path.join(BACKUP_DIR, b)).mtimeMs - fs.statSync(path.join(BACKUP_DIR, a)).mtimeMs)
    .slice(0, 10);

  if (!files.length) {
    return ctx.reply(`❌ *Tidak ada backup hari ini ditemukan (${today}).*`, { parse_mode: 'Markdown' });
  }

  const buttons = files.map(f => [
    { text: `🗂 ${f}`, callback_data: `restore_file::${f}` },
    { text: '?? Hapus', callback_data: `delete_file::${f}` }
  ]);

  return ctx.reply(`📂 *Backup Hari Ini (${today})*:\nPilih restore atau hapus:`, {
    parse_mode: 'Markdown',
    reply_markup: { inline_keyboard: buttons }
  });
}
  
 if (data.startsWith('restore_uploaded_file::')) {
  const fileName = data.split('::')[1];
  const filePath = path.join('/root/BotVPN2/uploaded_restore', fileName);

  if (!fs.existsSync(filePath)) {
    return ctx.reply(`❌ File tidak ditemukan: ${fileName}`);
  }

  try {
    fs.copyFileSync(filePath, DB_PATH);
    await ctx.editMessageText(`✅ Restore berhasil dari upload: ${fileName}`);
    logRestoreAction('restore_upload', fileName, ctx.from.username, ctx.from.id);
  } catch (err) {
    logger.error('Restore upload gagal:', err.message);
    await ctx.reply('❌ Gagal restore file.');
  }

  // 🧼 PENTING: bersihkan state untuk cegah double-respon
  delete userState[ctx.chat.id];
}

  if (data.startsWith('delete_uploaded_file::')) {
  const fileName = data.split('::')[1];
  const filePath = path.join('/root/BotVPN2/uploaded_restore', fileName);

  if (!fs.existsSync(filePath)) {
    return ctx.reply(`❌ *File tidak ditemukan:* \`${fileName}\``, { parse_mode: 'Markdown' });
  }

  try {
    fs.unlinkSync(filePath);
    await ctx.editMessageText(`🗑 *File upload dihapus:* \`${fileName}\``, {
      parse_mode: 'Markdown'
    });
    logRestoreAction('delete_upload', fileName, ctx.from.username, ctx.from.id);
  } catch (err) {
    logger.error('❌ Gagal hapus file upload:', err.message);
    ctx.reply('❌ *Gagal menghapus file restore upload.*', { parse_mode: 'Markdown' });
  }
}
  
   if (data === 'admin_restore_all') {
  const files = fs.readdirSync(BACKUP_DIR)
    .filter(f => f.endsWith('.db'))
    .sort((a, b) => fs.statSync(path.join(BACKUP_DIR, b)).mtimeMs - fs.statSync(path.join(BACKUP_DIR, a)).mtimeMs)
    .slice(0, 15);

  if (!files.length) {
    return ctx.reply('❌ *Tidak ada file backup ditemukan.*', { parse_mode: 'Markdown' });
  }

  const buttons = files.map(f => [
    { text: `🗂 ${f}`, callback_data: `restore_file::${f}` },
    { text: '🗑 Hapus', callback_data: `delete_file::${f}` }
  ]);

  return ctx.reply('📂 *Daftar Semua Backup:*\nPilih restore atau hapus:', {
    parse_mode: 'Markdown',
    reply_markup: { inline_keyboard: buttons }
  });
}

  //delete
  if (data.startsWith('delete_file::')) {
  const fileName = data.split('::')[1];

  return ctx.reply(
    `⚠️ *Yakin ingin menghapus backup berikut?*\n🗂 \`${fileName}\``,
    {
      parse_mode: 'Markdown',
      reply_markup: {
        inline_keyboard: [
          [
            { text: '✅ Ya, Hapus', callback_data: `confirm_delete::${fileName}` },
            { text: '❌ Batal', callback_data: 'cancel_delete' }
          ]
        ]
      }
    }
  );
}
   
   if (data.startsWith('confirm_delete::')) {
  const fileName = data.split('::')[1];
  const filePath = path.join(BACKUP_DIR, fileName);

  try {
    if (!fs.existsSync(filePath)) {
      return ctx.reply(`❌ *File tidak ditemukan:* \`${fileName}\``, { parse_mode: 'Markdown' });
    }

    fs.unlinkSync(filePath);
    await ctx.editMessageText(`🗑 *Backup dihapus:* \`${fileName}\``, {
      parse_mode: 'Markdown'
    });
    logger.info(`[CONFIRM_DELETE] ${ctx.from.username} deleted ${fileName}`);
  } catch (err) {
    logger.error('❌ Hapus gagal:', err.message);
    ctx.reply('❌ *Gagal hapus file backup.*', { parse_mode: 'Markdown' });
  }
}

if (data === 'cancel_delete') {
  await ctx.editMessageText('❎ *Penghapusan dibatalkan.*', { parse_mode: 'Markdown' });
}

  // === Restore dari file spesifik
  if (data.startsWith('restore_file::')) {
    const fileName = data.split('::')[1];
    const filePath = path.join(BACKUP_DIR, fileName);

    try {
      if (!fs.existsSync(filePath)) {
        return ctx.reply(`❌ *File tidak ditemukan:* \`${fileName}\``, { parse_mode: 'Markdown' });
      }

      fs.copyFileSync(filePath, DB_PATH);
      await ctx.editMessageText(`✅ *Restore berhasil dari:* \`${fileName}\``, { parse_mode: 'Markdown' });
      logger.info(`[RESTORE] ${ctx.from.username} restored ${fileName}`);
    } catch (err) {
      logger.error('❌ Restore file gagal:', err.message);
      return ctx.reply('❌ *Gagal restore file.*', { parse_mode: 'Markdown' });
    }
  }
});


async function handleDepositState(ctx, userId, data) {
  let currentAmount = global.depositState[userId].amount;

  if (data === 'delete') {
    currentAmount = currentAmount.slice(0, -1);
  } else if (data === 'confirm') {
    if (currentAmount.length === 0) {
      return await ctx.answerCbQuery('⚠️ Jumlah tidak boleh kosong!', { show_alert: true });
    }
    if (parseInt(currentAmount) < 100) {
      return await ctx.answerCbQuery('⚠️ Jumlah minimal top-up adalah  5000 Ya Kawan...!!!', { show_alert: true });
    }
    global.depositState[userId].action = 'confirm_amount';
    await processDeposit(ctx, currentAmount);
    return;
  } else {
    if (currentAmount.length < 12) {
      currentAmount += data;
    } else {
      return await ctx.answerCbQuery('⚠️ Jumlah maksimal adalah 12 digit!', { show_alert: true });
    }
  }

  global.depositState[userId].amount = currentAmount;
  const newMessage = `💰 *Silakan masukkan jumlah nominal saldo yang Anda ingin tambahkan ke akun Anda:*\n\nJumlah saat ini: *Rp ${currentAmount}*`;
  
  try {
    await ctx.editMessageText(newMessage, {
      reply_markup: { inline_keyboard: keyboard_nomor() },
      parse_mode: 'Markdown'
    });
  } catch (error) {
    if (error.description && error.description.includes('message is not modified')) {
      return;
    }
    logger.error('Error updating message:', error);
  }
}

//reseller
async function insertKomisi(ctx, type, username, komisi) {
  await dbRunAsync(
    'INSERT INTO reseller_sales (reseller_id, buyer_id, akun_type, username, komisi, created_at) VALUES (?, ?, ?, ?, ?, datetime("now"))',
    [ctx.from.id, ctx.from.id, type, username, komisi]
  );

  const res = await dbGetAsync('SELECT SUM(komisi) AS total_komisi FROM reseller_sales WHERE reseller_id = ?', [ctx.from.id]);
  const total = res?.total_komisi || 0;
  const level = total >= 80000 ? 'platinum' : total >= 50000 ? 'gold' : 'silver';

  await dbRunAsync('UPDATE users SET reseller_level = ? WHERE user_id = ?', [level, ctx.from.id]);

  if (GROUP_ID) {
    const mention = ctx.from.username ? `@${ctx.from.username}` : ctx.from.first_name;
    const notif = `📢 *Transaksi Reseller!*\n\n👤 ${mention}\n📦 ${type.toUpperCase()} - ${username}\n💰 Komisi: Rp${komisi.toLocaleString('id-ID')}`;
    await bot.telegram.sendMessage(GROUP_ID, notif, { parse_mode: 'Markdown' });
  }
}
function renderResellerPanel(ctx) {
  const menu = {
    reply_markup: {
      inline_keyboard: [
        [{ text: '💰 Komisi Saya', callback_data: 'komisi' }],
        [{ text: '📄 Riwayat Komisi', callback_data: 'riwayatreseller' }],
        [{ text: '🏆 Top Reseller', callback_data: 'topreseller' }],
        [{ text: '📤 Export Komisi (CSV)', callback_data: 'export_komisi' }],
        [{ text: '🔁 Transfer Saldo', callback_data: 'transfer' }],
        [{ text: '📃 Log Transfer', callback_data: 'logtransfer' }]
      ]
    }
  };
  return ctx.reply('🤖 *Panel Reseller Aktif*', { parse_mode: 'Markdown', ...menu });
}

// 💡 Fungsi validasi user harus reseller
async function onlyReseller(ctx) {
  const userId = ctx.from.id;
  return new Promise((resolve) => {
    db.get('SELECT role FROM users WHERE user_id = ?', [userId], (err, row) => {
      if (err || !row || row.role !== 'reseller') {
        ctx.reply('⛔ *Panel ini hanya tersedia untuk reseller.*', { parse_mode: 'Markdown' });
        resolve(false);
      } else {
        resolve(true);
      }
    });
  });
}
function insertKomisi(ctx, type, username, totalHarga) {
  const komisi = Math.floor(totalHarga * 0.1);
  db.run(
    'INSERT INTO reseller_sales (reseller_id, buyer_id, akun_type, username, komisi) VALUES (?, ?, ?, ?, ?)',
    [ctx.from.id, ctx.from.id, type, username, komisi]
  );
}

// Validasi DB: coba buka file sebagai SQLite
function isValidSQLiteDB(path) {
  return new Promise((resolve) => {
    const db = new sqlite3.Database(path, sqlite3.OPEN_READONLY, (err) => {
      if (err) return resolve(false);
      db.get("SELECT name FROM sqlite_master WHERE type='table'", (err2) => {
        db.close();
        resolve(!err2);
      });
    });
  });
}

function isValidSQLDump(filePath) {
  return new Promise((resolve, reject) => {
    fs.readFile(filePath, 'utf8', (err, sql) => {
      if (err) return resolve(false);
      const isSQL = sql.includes('CREATE TABLE') || sql.includes('INSERT INTO');
      resolve(isSQL);
    });
  });
}


async function handleAddSaldo(ctx, userStateData, data) {
  let currentSaldo = userStateData.saldo || '';

  if (data === 'delete') {
    currentSaldo = currentSaldo.slice(0, -1);
  } else if (data === 'confirm') {
    if (currentSaldo.length === 0) {
      return await ctx.answerCbQuery('⚠️ *Jumlah saldo tidak boleh kosong!*', { show_alert: true });
    }

    try {
      await updateUserSaldo(userStateData.userId, currentSaldo);
      ctx.reply(`✅ *Saldo user berhasil ditambahkan.*\n\n📄 *Detail Saldo:*\n- Jumlah Saldo: *Rp ${currentSaldo}*`, { parse_mode: 'Markdown' });
    } catch (err) {
      ctx.reply('❌ *Terjadi kesalahan saat menambahkan saldo user.*', { parse_mode: 'Markdown' });
    }
    delete userState[ctx.chat.id];
    return;
  } else {
    if (!/^[0-9]+$/.test(data)) {
      return await ctx.answerCbQuery('⚠️ *Jumlah saldo tidak valid!*', { show_alert: true });
    }
    if (currentSaldo.length < 10) {
      currentSaldo += data;
    } else {
      return await ctx.answerCbQuery('⚠️ *Jumlah saldo maksimal adalah 10 karakter!*', { show_alert: true });
    }
  }

  userStateData.saldo = currentSaldo;
  const newMessage = `📊 *Silakan masukkan jumlah saldo yang ingin ditambahkan:*\n\nJumlah saldo saat ini: *${currentSaldo}*`;
  if (newMessage !== ctx.callbackQuery.message.text) {
    await ctx.editMessageText(newMessage, {
      reply_markup: { inline_keyboard: keyboard_nomor() },
      parse_mode: 'Markdown'
    });
  }
}

async function handleEditBatasCreateAkun(ctx, userStateData, data) {
  await handleEditField(ctx, userStateData, data, 'batasCreateAkun', 'batas create akun', 'UPDATE Server SET batas_create_akun = ? WHERE id = ?');
}

async function handleEditTotalCreateAkun(ctx, userStateData, data) {
  await handleEditField(ctx, userStateData, data, 'totalCreateAkun', 'total create akun', 'UPDATE Server SET total_create_akun = ? WHERE id = ?');
}

async function handleEditiplimit(ctx, userStateData, data) {
  await handleEditField(ctx, userStateData, data, 'iplimit', 'limit IP', 'UPDATE Server SET iplimit = ? WHERE id = ?');
}

async function handleEditQuota(ctx, userStateData, data) {
  await handleEditField(ctx, userStateData, data, 'quota', 'quota', 'UPDATE Server SET quota = ? WHERE id = ?');
}

async function handleEditAuth(ctx, userStateData, data) {
  await handleEditField(ctx, userStateData, data, 'auth', 'auth', 'UPDATE Server SET auth = ? WHERE id = ?');
}

async function handleEditDomain(ctx, userStateData, data) {
  await handleEditField(ctx, userStateData, data, 'domain', 'domain', 'UPDATE Server SET domain = ? WHERE id = ?');
}

async function handleEditHarga(ctx, userStateData, data) {
  let currentAmount = userStateData.amount || '';

  if (data === 'delete') {
    currentAmount = currentAmount.slice(0, -1);
  } else if (data === 'confirm') {
    if (currentAmount.length === 0) {
      return await ctx.answerCbQuery('⚠️ *Jumlah tidak boleh kosong!*', { show_alert: true });
    }
    const hargaBaru = parseFloat(currentAmount);
    if (isNaN(hargaBaru) || hargaBaru <= 0) {
      return ctx.reply('❌ *Harga tidak valid. Masukkan angka yang valid.*', { parse_mode: 'Markdown' });
    }
    try {
      await updateServerField(userStateData.serverId, hargaBaru, 'UPDATE Server SET harga = ? WHERE id = ?');
      ctx.reply(`✅ *Harga server berhasil diupdate.*\n\n📄 *Detail Server:*\n- Harga Baru: *Rp ${hargaBaru}*`, { parse_mode: 'Markdown' });
    } catch (err) {
      ctx.reply('❌ *Terjadi kesalahan saat mengupdate harga server.*', { parse_mode: 'Markdown' });
    }
    delete userState[ctx.chat.id];
    return;
  } else {
    if (!/^\d+$/.test(data)) {
      return await ctx.answerCbQuery('⚠️ *Hanya angka yang diperbolehkan!*', { show_alert: true });
    }
    if (currentAmount.length < 12) {
      currentAmount += data;
    } else {
      return await ctx.answerCbQuery('⚠️ *Jumlah maksimal adalah 12 digit!*', { show_alert: true });
    }
  }

  userStateData.amount = currentAmount;
  const newMessage = `💰 *Silakan masukkan harga server baru:*\n\nJumlah saat ini: *Rp ${currentAmount}*`;
  if (newMessage !== ctx.callbackQuery.message.text) {
    await ctx.editMessageText(newMessage, {
      reply_markup: { inline_keyboard: keyboard_nomor() },
      parse_mode: 'Markdown'
    });
  }
}

async function handleEditNama(ctx, userStateData, data) {
  await handleEditField(ctx, userStateData, data, 'name', 'nama server', 'UPDATE Server SET nama_server = ? WHERE id = ?');
}

async function handleEditField(ctx, userStateData, data, field, fieldName, query) {
  let currentValue = userStateData[field] || '';

  if (data === 'delete') {
    currentValue = currentValue.slice(0, -1);
  } else if (data === 'confirm') {
    if (currentValue.length === 0) {
      return await ctx.answerCbQuery(`⚠️ *${fieldName} tidak boleh kosong!*`, { show_alert: true });
    }
    try {
      await updateServerField(userStateData.serverId, currentValue, query);
      ctx.reply(`✅ *${fieldName} server berhasil diupdate.*\n\n📄 *Detail Server:*\n- ${fieldName.charAt(0).toUpperCase() + fieldName.slice(1)}: *${currentValue}*`, { parse_mode: 'Markdown' });
    } catch (err) {
      ctx.reply(`❌ *Terjadi kesalahan saat mengupdate ${fieldName} server.*`, { parse_mode: 'Markdown' });
    }
    delete userState[ctx.chat.id];
    return;
  } else {
    if (!/^[a-zA-Z0-9.-]+$/.test(data)) {
      return await ctx.answerCbQuery(`⚠️ *${fieldName} tidak valid!*`, { show_alert: true });
    }
    if (currentValue.length < 253) {
      currentValue += data;
    } else {
      return await ctx.answerCbQuery(`⚠️ *${fieldName} maksimal adalah 253 karakter!*`, { show_alert: true });
    }
  }

  userStateData[field] = currentValue;
  const newMessage = `📊 *Silakan masukkan ${fieldName} server baru:*\n\n${fieldName.charAt(0).toUpperCase() + fieldName.slice(1)} saat ini: *${currentValue}*`;
  if (newMessage !== ctx.callbackQuery.message.text) {
    await ctx.editMessageText(newMessage, {
      reply_markup: { inline_keyboard: keyboard_nomor() },
      parse_mode: 'Markdown'
    });
  }
}
async function updateUserSaldo(userId, saldo) {
  return new Promise((resolve, reject) => {
    db.run('UPDATE Users SET saldo = saldo + ? WHERE id = ?', [saldo, userId], function (err) {
      if (err) {
        logger.error('⚠️ Kesalahan saat menambahkan saldo user:', err.message);
        reject(err);
      } else {
        resolve();
      }
    });
  });
}

async function updateServerField(serverId, value, query) {
  return new Promise((resolve, reject) => {
    db.run(query, [value, serverId], function (err) {
      if (err) {
        logger.error(`⚠️ Kesalahan saat mengupdate ${fieldName} server:`, err.message);
        reject(err);
      } else {
        resolve();
      }
    });
  });
}

function generateRandomAmount(baseAmount) {
  const random = Math.floor(Math.random() * 99) + 1;
  return baseAmount + random;
}

global.depositState = {};
global.pendingDeposits = {};
let lastRequestTime = 0;
const requestInterval = 1000; 

db.all('SELECT * FROM pending_deposits WHERE status = "pending"', [], (err, rows) => {
  if (err) {
    logger.error('Gagal load pending_deposits:', err.message);
    return;
  }
  rows.forEach(row => {
    global.pendingDeposits[row.unique_code] = {
      amount: row.amount,
      originalAmount: row.original_amount,
      userId: row.user_id,
      timestamp: row.timestamp,
      status: row.status,
      qrMessageId: row.qr_message_id
    };
  });
  logger.info('Pending deposit loaded:', Object.keys(global.pendingDeposits).length);
});

// const qris = new QRISPayment({
//    merchantId: MERCHANT_ID,
//    apiKey: API_KEY,
//    baseQrString: DATA_QRIS,
//    logoPath: 'logo.png'
// });

async function processDeposit(ctx, amount) {
  const currentTime = Date.now();
  
  // Cek apakah permintaan terlalu cepat
  if (currentTime - lastRequestTime < requestInterval) {
    await ctx.reply('⚠️ *Terlalu banyak permintaan. Silakan tunggu sebentar sebelum mencoba lagi.*', { parse_mode: 'Markdown' });
    return;
  }

  lastRequestTime = currentTime;
  const userId = ctx.from.id;
  const uniqueCode = `user-${userId}-${currentTime}`;
  
  const finalAmount = generateRandomAmount(parseInt(amount));

  // Inisialisasi pendingDeposits jika belum ada
  if (!global.pendingDeposits) {
    global.pendingDeposits = {};
  }

  try {
    // Menghasilkan QR Code
    const { qrBuffer } = await qris.generateQR(finalAmount);

    // Menyusun caption untuk pesan
    const caption = 
  `╭━━━━━ 🧾 *Detail Pembayaran* ━━━━━╮\n` +
  `┃ 💰 *Jumlah:* Rp ${finalAmount.toLocaleString()}\n` +
  `┃ ⏱️ *Batas Waktu:* 5 menit\n` +
  `┃ ⚠️ *Penting:* Transfer sesuai nominal\n` +
  `╰━━━━━━━━━━━━━━━━━━━━━━━━━╯\n\n` +

  `📌 *Catatan Penting:*\n` +
  `• Pembayaran *otomatis terverifikasi*\n` +
  `• *Jangan tutup halaman ini* sebelum selesai\n` +
  `• Jika berhasil, *saldo akan otomatis masuk* ✅`;
                    
    // Mengirim pesan dengan QR code
    const qrMessage = await ctx.replyWithPhoto({ source: qrBuffer }, {
      caption: caption,
      parse_mode: 'Markdown',     
    });

    // Menyimpan informasi deposit yang tertunda
    global.pendingDeposits[uniqueCode] = {
      amount: finalAmount,
      originalAmount: amount,
      userId,
      timestamp: Date.now(),
      status: 'pending',
      qrMessageId: qrMessage.message_id
    };

    // Menyimpan data ke database
    await insertPendingDeposit(uniqueCode, userId, finalAmount, amount, qrMessage.message_id);

    // Menghapus state deposit pengguna
    delete global.depositState[userId];

  } catch (error) {
    logger.error('❌ Kesalahan saat memproses deposit:', error);
    await ctx.reply('❌ *GAGAL! Terjadi kesalahan saat memproses pembayaran. Silakan coba lagi nanti.*', { parse_mode: 'Markdown' });
    
    // Menghapus state deposit dan pending deposit
    delete global.depositState[userId];
    delete global.pendingDeposits[uniqueCode];
    
    // Menghapus entri dari database jika ada kesalahan
    await deletePendingDeposit(uniqueCode);
  }
}

// Helper function to insert a pending deposit into the database
function insertPendingDeposit(uniqueCode, userId, finalAmount, originalAmount, qrMessageId) {
  return new Promise((resolve, reject) => {
    db.run(
      `INSERT INTO pending_deposits (unique_code, user_id, amount, original_amount, timestamp, status, qr_message_id)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [uniqueCode, userId, finalAmount, originalAmount, Date.now(), 'pending', qrMessageId],
      (err) => {
        if (err) {
          logger.error('Gagal insert pending_deposits:', err.message);
          reject(err);
        } else {
          resolve();
        }
      }
    );
  });
}

// Helper function to delete a pending deposit from the database
function deletePendingDeposit(uniqueCode) {
  return new Promise((resolve, reject) => {
    db.run('DELETE FROM pending_deposits WHERE unique_code = ?', [uniqueCode], (err) => {
      if (err) {
        logger.error('Gagal hapus pending_deposits (error):', err.message);
        reject(err);
      } else {
        resolve();
      }
    });
  });
}


// Fungsi untuk membatalkan top-up (tidak perlu lagi jika tombol diubah menjadi url)
async function checkQRISStatus() {
  try {
    const pendingDeposits = Object.entries(global.pendingDeposits);

    for (const [uniqueCode, deposit] of pendingDeposits) {
      if (deposit.status !== 'pending') continue;

      const depositAge = Date.now() - deposit.timestamp;

      // 🚫 Kadaluarsa
      if (depositAge > 5 * 60 * 1000) {
        try {
          if (deposit.qrMessageId) {
            await bot.telegram.deleteMessage(deposit.userId, deposit.qrMessageId);
          }

          await bot.telegram.sendMessage(deposit.userId,
            '⏳ *Transaksi Kadaluarsa*\n\n' +
            '❌ Waktu pembayaran telah habis. Silakan klik Top Up lagi untuk mendapatkan QR baru.',
            { parse_mode: 'Markdown' }
          );

          if (GROUP_ID) {
            const userRow = await dbGetAsync('SELECT username FROM users WHERE user_id = ?', [deposit.userId]);
            const mention = userRow?.username
              ? `@${escapeMarkdown(userRow.username)}`
              : `[${deposit.userId}](tg://user?id=${deposit.userId})`;

            const notif = `
━━━━━━━━━━━━━━━━━━━━━━━
⚠️ *TOPUP SALDO KADALUARSA*
━━━━━━━━━━━━━━━━━━━━━━━
👤 *User:* ${mention}
💴 *Nominal:* Rp${escapeMarkdown(deposit.amount.toLocaleString('id-ID'))}
🧭 *Kadaluarsa:* ${escapeMarkdown(new Date(deposit.timestamp + 5 * 60 * 1000).toLocaleString('id-ID'))}
━━━━━━━━━━━━━━━━━━━━━━━
            `.trim();

            await bot.telegram.sendMessage(GROUP_ID, notif, { parse_mode: 'MarkdownV2' });
          }

        } catch (error) {
          logger.error('Error deleting expired payment messages:', error);
        }

        delete global.pendingDeposits[uniqueCode];
        db.run('DELETE FROM pending_deposits WHERE unique_code = ?', [uniqueCode], (err) => {
          if (err) logger.error('Gagal hapus pending_deposits (expired):', err.message);
        });
        continue;
      }

      // ✅ Cek pembayaran
      try {
        const result = await qris.checkPayment(uniqueCode, deposit.amount);

        if (result.success && result.data.status === 'PAID') {
          const transactionKey = `${result.data.reference}_${result.data.amount}`;
          if (global.processedTransactions.has(transactionKey)) continue;
          if (parseInt(result.data.amount) !== deposit.amount) continue;

          const success = await processMatchingPayment(deposit, result.data, uniqueCode);
          if (success) {
  logger.info(`Payment processed successfully for ${uniqueCode}`);
  delete global.pendingDeposits[uniqueCode];

  db.run('DELETE FROM pending_deposits WHERE unique_code = ?', [uniqueCode], (err) => {
    if (err) logger.error('Gagal hapus pending_deposits (success):', err.message);
  });

  // 🔍 Ambil data user (untuk log dan notif)
  const userRow = await dbGetAsync('SELECT username FROM users WHERE user_id = ?', [deposit.userId]);

  // ✅ Simpan log topup
  await dbRunAsync(`
    INSERT INTO topup_log (user_id, username, amount, reference, created_at)
    VALUES (?, ?, ?, ?, datetime('now'))
  `, [
    deposit.userId,
    userRow?.username || '',
    deposit.amount,
    result.data.reference
  ]);

  if (GROUP_ID) {
    const mention = userRow?.username
      ? `@${escapeMarkdown(userRow.username)}`
      : `[${deposit.userId}](tg://user?id=${deposit.userId})`;

    const notif = `
━━━━━━━━━━━━━━━━━━━━━━━
✅ *TOPUP SALDO BERHASIL*
━━━━━━━━━━━━━━━━━━━━━━━
👤 *User:* ${mention}
💴 *Nominal:* Rp${escapeMarkdown(deposit.amount.toLocaleString('id-ID'))}
🧭 *Waktu:* ${escapeMarkdown(new Date().toLocaleString('id-ID'))}
━━━━━━━━━━━━━━━━━━━━━━━
    `.trim();

    await bot.telegram.sendMessage(GROUP_ID, notif, { parse_mode: 'MarkdownV2' });
            }
          }
        }
      } catch (error) {
        logger.error(`Error checking payment status for ${uniqueCode}:`, error.message);
      }
    }
  } catch (error) {
    logger.error('Error in checkQRISStatus:', error);
  }
}

function keyboard_abc() {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz';
  const buttons = [];
  for (let i = 0; i < alphabet.length; i += 3) {
    const row = alphabet.slice(i, i + 3).split('').map(char => ({
      text: char,
      callback_data: char
    }));
    buttons.push(row);
  }
  buttons.push([{ text: '🔙 Hapus', callback_data: 'delete' }, { text: '✅ Konfirmasi', callback_data: 'confirm' }]);
  buttons.push([{ text: '🔙 Kembali ke Menu Utama', callback_data: 'send_main_menu' }]);
  return buttons;
}

function keyboard_nomor() {
  const alphabet = '1234567890';
  const buttons = [];
  for (let i = 0; i < alphabet.length; i += 3) {
    const row = alphabet.slice(i, i + 3).split('').map(char => ({
      text: char,
      callback_data: char
    }));
    buttons.push(row);
  }
  buttons.push([{ text: '🔙 Hapus', callback_data: 'delete' }, { text: '✅ Konfirmasi', callback_data: 'confirm' }]);
  buttons.push([{ text: '🔙 Kembali ke Menu Utama', callback_data: 'send_main_menu' }]);
  return buttons;
}

function keyboard_full() {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  const buttons = [];
  for (let i = 0; i < alphabet.length; i += 3) {
    const row = alphabet.slice(i, i + 3).split('').map(char => ({
      text: char,
      callback_data: char
    }));
    buttons.push(row);
  }
  buttons.push([{ text: '🔙 Hapus', callback_data: 'delete' }, { text: '✅ Konfirmasi', callback_data: 'confirm' }]);
  buttons.push([{ text: '🔙 Kembali ke Menu Utama', callback_data: 'send_main_menu' }]);
  return buttons;
}

global.processedTransactions = new Set();
async function updateUserBalance(userId, amount) {
  return new Promise((resolve, reject) => {
    db.run("UPDATE users SET saldo = saldo + ? WHERE user_id = ?", 
      [amount, userId],
      function(err) {
        if (err) {
          reject(err);
          return;
        }
        resolve(this.changes);
      }
    );
  });
}

async function getUserBalance(userId) {
  return new Promise((resolve, reject) => {
    db.get("SELECT saldo FROM users WHERE user_id = ?", [userId],
      (err, row) => {
        if (err) {
          reject(err);
          return;
        }
        resolve(row);
      }
    );
  });
}

async function sendPaymentSuccessNotification(userId, deposit, currentBalance) {
  try {
    const messageText = `
✅ *Pembayaran Berhasil!*

Terima kasih telah melakukan topup saldo 💳
Detail transaksi kamu sebagai berikut:

💰 *Nominal Bayar* : Rp ${deposit.amount.toLocaleString('id-ID')}
📥 *Saldo Masuk*   : Rp ${deposit.originalAmount.toLocaleString('id-ID')}
💼 *Saldo Sekarang*: Rp ${currentBalance.toLocaleString('id-ID')}

🎯 Saldo kamu bisa langsung digunakan
untuk membeli layanan VPN premium!

Silakan kembali ke menu utama untuk mulai transaksi 👇
`.trim();

    await bot.telegram.sendMessage(userId, messageText, {
      parse_mode: 'Markdown',
      reply_markup: {
        inline_keyboard: [
          [{ text: '🏠 Kembali ke Menu Utama', callback_data: 'send_main_menu' }]
        ]
      }
    });
    return true;
  } catch (error) {
    logger.error('Error sending payment notification:', error);
    return false;
  }
}

//info server
async function resolveDomainToIP(domain) {
  try {
    const res = await dns.lookup(domain);
    return res.address;
  } catch (err) {
    logger.warn('⚠️ Gagal resolve domain:', err.message);
    return null;
  }
}

async function getISPAndLocation(ip) {
  try {
    const res = await fetch(`https://ipinfo.io/${ip}/json`);
    const data = await res.json();
    const isp = data.org || 'Tidak diketahui';
    const lokasi = data.city && data.country ? `${data.city}, ${data.country}` : 'Tidak diketahui';
    return { isp, lokasi };
  } catch (err) {
    logger.warn('⚠️ Gagal ambil ISP/Lokasi:', err.message);
    return { isp: 'Tidak diketahui', lokasi: 'Tidak diketahui' };
  }
}


async function processMatchingPayment(deposit, matchingTransaction, uniqueCode) {
  const transactionKey = `${matchingTransaction.reference_id}_${matchingTransaction.amount}`;
  if (global.processedTransactions.has(transactionKey)) {
    logger.info(`Transaction ${transactionKey} already processed, skipping...`);
    return false;
  }

  try {
    await updateUserBalance(deposit.userId, deposit.originalAmount);
    const userBalance = await getUserBalance(deposit.userId);
    
    if (!userBalance) {
      throw new Error('User balance not found after update');
    }
    const notificationSent = await sendPaymentSuccessNotification(
      deposit.userId,
      deposit,
      userBalance.saldo
    );

    if (notificationSent) {
      global.processedTransactions.add(transactionKey);
      delete global.pendingDeposits[uniqueCode];
      db.run('DELETE FROM pending_deposits WHERE unique_code = ?', [uniqueCode], (err) => {
        if (err) logger.error('Gagal hapus pending_deposits (success):', err.message);
      });
      return true;
    }
    
    return false;
  } catch (error) {
    logger.error('Error processing payment:', error);
    return false;
  }
}

setInterval(checkQRISStatus, 10000);

app.listen(PORT, () => {
  logger.info(`🚀 Server berjalan di port ${PORT}`);

  const startBot = async (retry = 0) => {
    try {
      await bot.launch();
      logger.info('🤖 Bot Telegram aktif!');
    } catch (err) {
      const MAX_RETRY = 5;
      const delay = Math.min(10000 * (retry + 1), 60000); // max 1 menit

      logger.error(`❌ Error saat memulai bot: ${err.message}`);

      if (
        ['ETIMEDOUT', 'ECONNRESET', 'ENOTFOUND'].includes(err.code) ||
        (err.response && err.response.status >= 500)
      ) {
        if (retry < MAX_RETRY) {
          logger.warn(`🔁 Coba reconnect (${retry + 1}/${MAX_RETRY}) dalam ${delay / 1000}s...`);
          setTimeout(() => startBot(retry + 1), delay);
        } else {
          logger.error('🚫 Gagal konek ke Telegram setelah beberapa percobaan. Periksa koneksi VPS.');
        }
      } else {
        logger.error('🚨 Error lain saat start bot. Tidak dilakukan retry.');
      }
    }
  };

  // 🚀 Mulai bot dengan reconnect logic
  startBot();
});
