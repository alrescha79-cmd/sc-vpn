const express = require('express');
const router = express.Router();
const { exec } = require('child_process');

router.post('/trial/vmess', async (req, res) => {
  exec('bash /root/scripts/trialvmess.sh', (error, stdout, stderr) => {
    if (error) {
      return res.status(500).json({ status: false, message: 'Gagal membuat trial vmess', error: stderr });
    }

    try {
      const jsonStart = stdout.indexOf('{');
      const jsonEnd = stdout.lastIndexOf('}') + 1;
      const jsonString = stdout.slice(jsonStart, jsonEnd);
      const result = JSON.parse(jsonString);
      return res.json(result);
    } catch (err) {
      return res.status(500).json({ status: false, message: 'Output tidak valid', raw: stdout });
    }
  });
});

module.exports = router;