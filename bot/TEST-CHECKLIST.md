# ✅ Test Checklist - Bot No Auth

## 1. Syntax Check
- [x] app.js - No errors
- [x] All modules/*.js - No errors

## 2. Files Created
- [x] setup-auth-dummy.sh
- [x] start.sh
- [x] SETUP-NO-AUTH.md
- [x] QUICK-REFERENCE.txt
- [x] TEST-CHECKLIST.md

## 3. Changes Made
- [x] app.js - Auth step removed in addserver
- [x] app.js - Auth auto set to 'no-auth-required'
- [x] All create*.js - &auth parameter removed
- [x] All renew*.js - &auth parameter removed
- [x] createSSH.js - Using exec command instead of axios
- [x] README.md - Updated with new info

## 4. Manual Testing Required

### Before Running:
```bash
cd /home/son/Projects/sc-vpn/bot

# 1. Check .vars.json
cat .vars.json
# Make sure BOT_TOKEN is filled

# 2. If database exists, update auth
./setup-auth-dummy.sh

# 3. Set user as admin (replace YOUR_ID)
sqlite3 sellvpn.db "UPDATE users SET role='admin' WHERE user_id=YOUR_ID;"
```

### Run Bot:
```bash
# Option 1: Quick start
./start.sh

# Option 2: Manual
node app.js

# Option 3: PM2 (recommended for production)
pm2 start app.js --name sellvpn
pm2 logs sellvpn
```

### Test in Telegram:
1. [ ] Send `/start` - Should work without errors
2. [ ] Send `/addserver` - Should NOT ask for auth
3. [ ] Complete addserver flow - Auth should be 'no-auth-required'
4. [ ] Check database:
   ```bash
   sqlite3 sellvpn.db "SELECT id, domain, auth FROM Server;"
   ```
5. [ ] Try create account (will fail without real VPN server, but should not error on auth)

## 5. Expected Behavior

### Adding Server:
1. `/addserver`
2. Enter domain (e.g., vpn1.example.com)
3. **SKIP AUTH** - Goes directly to nama server
4. Enter nama server
5. Enter quota
6. Enter iplimit
7. Enter batas create akun
8. Enter harga
9. ✅ Server added with auth='no-auth-required'

### Creating Account:
1. `/create` or via menu
2. Select server
3. Select service type (SSH/VMESS/etc)
4. Enter username
5. Enter password (for SSH)
6. Enter expiry days
7. Bot will try to execute command (may timeout if no real server)
8. **No auth error should appear**

## 6. Common Issues

### "404: Not Found"
- BOT_TOKEN invalid
- Fix: Update .vars.json with correct token from @BotFather

### "Promise timed out"
- Script execution taking too long
- Normal if server not accessible yet
- Not an auth issue

### "Server tidak ditemukan"
- No servers in database
- Fix: Add server with /addserver first

## 7. Rollback (if needed)

```bash
# Restore from git
cd /home/son/Projects/sc-vpn
git checkout bot/app.js
git checkout bot/modules/

# Or restore from backup if you made one
```

## 8. Production Checklist

Before going live:
- [ ] .vars.json filled with real values
- [ ] BOT_TOKEN from @BotFather
- [ ] USER_ID and GROUP_ID correct
- [ ] At least 1 server added
- [ ] Server VPN accessible via SSH
- [ ] Test create account on real server
- [ ] Backup database regularly
- [ ] Setup PM2 for auto-restart
- [ ] Monitor logs: `pm2 logs sellvpn`

## 9. Next Steps

After confirming bot works:
1. Setup SSH key for passwordless access to VPN servers
2. Configure firewall rules
3. Setup automated backup
4. Monitor disk space for database
5. Setup alert for bot crashes

---

✅ All syntax checks passed
✅ All files created
✅ Ready for testing

Run: `./start.sh` to begin!
