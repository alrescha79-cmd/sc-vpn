const express = require('express');
const router = express.Router();
const { exec } = require('child_process');

router.post('/api/trial/trojan', (req, res) => {
  exec('bash scripts/trialtrojan.sh', (err, stdout, stderr) => {
    if (err) return res.status(500).json({ status: 'error', message: stderr });

    try {
      const result = JSON.parse(stdout);
      res.json(result);
    } catch {
      res.status(500).json({ status: 'error', message: 'Invalid JSON', raw: stdout });
    }
  });
});

module.exports = router;