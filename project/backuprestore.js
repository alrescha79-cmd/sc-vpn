const express = require('express');
const fileUpload = require('express-fileupload');
const { exec, execSync } = require('child_process');
const path = require('path');

const app = express();
const UPLOAD_FOLDER = '/root';
const NEW_FILE_NAME = 'restore.tar.gz';

app.use(fileUpload());
app.use(express.urlencoded({ extended: true }));

app.get('/', (req, res) => {
    res.send(`
    <!doctype html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Upload File</title>
        <link rel="icon" href="https://github.com/joytun21/gabut/blob/main/image/gerhanatunnel.ico" type="image/x-icon">
        <style>
            body {
                font-family: Arial, sans-serif;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                background: linear-gradient(135deg, red, orange, blue, lime);
                animation: gradient 5s ease infinite;
                background-size: 400% 400%;
            }
            @keyframes gradient {
                0% { background-position: 0% 50%; }
                50% { background-position: 100% 50%; }
                100% { background-position: 0% 50%; }
            }
            .container {
                background: rgba(255, 255, 255, 1);
                padding: 20px;
                border-radius: 8px;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
                text-align: center;
            }
            input[type="file"] {
                margin: 10px 0;
            }
            input[type="submit"] {
                background-color: #4CAF50;
                color: white;
                border: none;
                padding: 10px 20px;
                text-decoration: none;
                margin: 4px 2px;
                cursor: pointer;
                border-radius: 4px;
            }
            input[type="submit"]:hover {
                background-color: #45a049;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <img src="https://github.com/joytun21/gabut/raw/main/image/logo.png" alt="Logo" style="width: 100%; max-width: 300px;">
            <h1>Upload File to VPS</h1>
            <form method="post" enctype="multipart/form-data" action="/upload">
                <label for="file">Choose file:</label>
                <input type="file" name="file" id="file" required><br><br>
                <input type="submit" value="Upload">
            </form>
            <form method="post" action="/backup">
                <input type="submit" value="Backup">
            </form>
        </div>
    </body>
    </html>
    `);
});

app.post('/upload', (req, res) => {
    if (!req.files || Object.keys(req.files).length === 0) {
        return res.status(400).send('No files were uploaded');
    }

    let file = req.files.file;
    let localFilePath = path.join(UPLOAD_FOLDER, NEW_FILE_NAME);

    file.mv(localFilePath, (err) => {
        if (err) {
            return res.status(500).send(err);
        }

        // Run restore.sh after the file is successfully uploaded
        exec('backuprestore restore', (err, stdout, stderr) => {
            if (err) {
                return res.status(500).send(`
                <h1>Failed to Run Restore</h1>
                <p>An error occurred while running the restore process:</p>
                <pre>${stderr}</pre>
            `);
            }
            res.send(`
                <h1>File Successfully Uploaded</h1>
                <p>The restore process continues with the following output:</p>
                <pre>${stdout}</pre>
            `);
            process.exit(0); // Stop the process after completion
        });
    });
});

let ipv4;
try {
    ipv4 = execSync('wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ipv4.icanhazip.com || echo "Unable to detect IP"', { encoding: 'utf-8' }).trim();
} catch (error) {
    ipv4 = "Unable to detect IP";
}

const backup_dir = `${ipv4}-${new Date().toLocaleDateString('id-ID', { day: '2-digit', month: '2-digit', year: 'numeric' }).replace(/\//g, '')}`;

app.post('/backup', (req, res) => {
    // Run backup.sh
    exec('backuprestore backup', (err, stdout, stderr) => {
        if (err) {
            return res.status(500).send(`
                <h1>Failed to Run Backup</h1>
                <p>An error occurred while running the backup process:</p>
                <pre>${stderr}</pre>
            `);
        }
        res.download(`/var/www/html/${backup_dir}.tar.gz`, (err) => {
            if (err) {
                return res.status(500).send(`
                <h1>Failed to Download Backup File</h1>
                <p>An error occurred while downloading the backup file:</p>
                <pre>${err}</pre>
            `);
            }
            process.exit(0); // Stop the process after completion
        });
    });
});

app.listen(5000, () => {
    //console.log(`Server running at http://${ipv4}:5000`);
});
