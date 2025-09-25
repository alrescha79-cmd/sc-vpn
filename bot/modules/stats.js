const sqlite3 = require('sqlite3');
const { promisify } = require('util');

async function getTopResellers(db, limit = 10) {
  const dbAll = promisify(db.all).bind(db);

  try {
    const rows = await dbAll(`
      SELECT
        reseller_id,
        COUNT(*) AS total_akun,
        SUM(komisi) AS total_komisi
      FROM reseller_sales
      GROUP BY reseller_id
      ORDER BY total_komisi DESC
      LIMIT ?
    `, [limit]);

    if (rows.length === 0) return '⚠️ Belum ada data reseller.';

    let text = `🏆 *Top ${limit} Reseller by Komisi (All Time)*:\n`;

    rows.forEach((row, index) => {
      text += `\n*#${index + 1}* 👤 ID ${row.reseller_id}\n` +
              `🛒 Akun Terjual: ${row.total_akun}\n` +
              `💰 Total Komisi : Rp${Number(row.total_komisi).toLocaleString('id-ID')}\n`;
    });

    return text;
  } catch (err) {
    console.error('❌ Gagal mengambil data top reseller:', err);
    return '❌ Gagal mengambil data reseller.';
  }
}

module.exports = {
  getTopResellers
};