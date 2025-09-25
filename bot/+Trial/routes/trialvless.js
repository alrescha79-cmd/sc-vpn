const express = require('express');
const router = express.Router();
const { exec } = require('child_process');

router.post('/api/trial/vless', (req, res) => {
  exec('bash scripts/trialvless.sh', (err, stdout, stderr) => {
    if (err) {
      return res.status(500).json({ status: 'error', message: stderr });
    }

    try {
      const json = JSON.parse(stdout);
      res.json(json);
    } catch {
      res.status(500).json({ status: 'error', message: 'Invalid JSON', raw: stdout });
    }
  });
});

module.exports = router;