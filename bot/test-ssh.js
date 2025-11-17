#!/usr/bin/env node

// Test SSH Connection Script
// Usage: node test-ssh.js

const { Client } = require('ssh2');
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./sellvpn.db');

console.log('🔍 Testing SSH Connection to VPN Server...\n');

// Get server dari database
db.get('SELECT * FROM Server LIMIT 1', [], (err, server) => {
  if (err || !server) {
    console.error('❌ Error:', err?.message || 'No server found in database');
    console.log('\n💡 Tambahkan server dulu dengan /addserver di bot');
    process.exit(1);
  }

  console.log('📋 Server Info:');
  console.log(`   Domain: ${server.domain}`);
  console.log(`   Auth: ${server.auth ? '***' + server.auth.slice(-4) : 'NOT SET'}`);
  console.log('');

  if (!server.auth || server.auth === 'ISIDISNI') {
    console.error('❌ Password root VPS belum diset!');
    console.log('💡 Update dengan: sqlite3 sellvpn.db "UPDATE Server SET auth=\'YourPassword\' WHERE id=' + server.id + ';"');
    process.exit(1);
  }

  const conn = new Client();
  let testPassed = false;

  console.log('🔌 Connecting to SSH...');

  const timeout = setTimeout(() => {
    if (!testPassed) {
      console.error('❌ Connection timeout after 10 seconds');
      conn.end();
      process.exit(1);
    }
  }, 10000);

  conn.on('ready', () => {
    console.log('✅ SSH Connection successful!\n');
    
    // Test command
    console.log('🔨 Testing command execution...');
    conn.exec('echo "TEST_SUCCESS"; whoami; hostname', (err, stream) => {
      if (err) {
        console.error('❌ Command exec error:', err.message);
        clearTimeout(timeout);
        conn.end();
        process.exit(1);
      }

      let output = '';
      
      stream.on('close', (code) => {
        clearTimeout(timeout);
        conn.end();
        testPassed = true;
        
        console.log(`\n📄 Command Output:\n${output}`);
        console.log(`\n📊 Exit Code: ${code}`);
        
        if (code === 0 && output.includes('TEST_SUCCESS')) {
          console.log('\n✅ ALL TESTS PASSED!');
          console.log('🎉 Server siap digunakan untuk create akun.\n');
          process.exit(0);
        } else {
          console.error('\n❌ Test failed!');
          process.exit(1);
        }
      })
      .on('data', (data) => {
        output += data.toString();
      })
      .stderr.on('data', (data) => {
        console.warn('⚠️ STDERR:', data.toString());
      });
    });
  })
  .on('error', (err) => {
    clearTimeout(timeout);
    console.error('\n❌ SSH Error:', err.message);
    
    if (err.code === 'ENOTFOUND') {
      console.log('💡 Domain/IP tidak ditemukan. Cek domain di database.');
    } else if (err.level === 'client-authentication') {
      console.log('💡 Password salah. Update dengan:');
      console.log(`   sqlite3 sellvpn.db "UPDATE Server SET auth='NewPassword' WHERE id=${server.id};"`);
    } else if (err.code === 'ETIMEDOUT' || err.code === 'ECONNREFUSED') {
      console.log('💡 Server offline atau port 22 tertutup. Cek firewall.');
    }
    
    process.exit(1);
  })
  .connect({
    host: server.domain,
    port: 22,
    username: 'root',
    password: server.auth,
    readyTimeout: 10000
  });
});
