# AGENTS.md

VPN panel auto-installer (Xray / OVPN / SSH / Shadowsocks) for Debian/Ubuntu VPS. Bash-heavy; no tests, no CI, no linter. Script output/comments are in Indonesian.

## Branches & deploy

- `main` is the primary and only branch.
- Installed servers fetch scripts directly from `raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/main/...` (hardcoded in setup.sh, menu.sh, package-gohide.sh, update.sh). Local edits reach servers after push to `main`.

## Install is free (no license gate)

Install requires no registered IP or license. Do not re-add server authorization checks (`izin`-style), `check-license`, or the `license-monitor` systemd timer; they were removed for open-sourcing.

## Layout

- `project/` — account-management commands servers install to `/usr/bin` (menu, addvmess, delssh, exp, features, trial*, checkusers*, ...). This is the "package" source for menu.sh / package-gohide.sh.
- `fodder/` — service configs (nginx, dropbear, openvpn, haproxy, udp, ws.py) pulled by setup.sh.
- `BadVPN-UDPWG/`, `VMess-VLESS-Trojan+Websocket+gRPC/` — binaries and xray config templates.
- Removed for open-sourcing: `bot/` (Telegram bot) and `golang/` (REST API) — do not restore.

## Conventions & gotchas

- Config files: server shell scripts source `/root/.vars` (KEY=VALUE, created by setup on the server).
- `VMess-VLESS-Trojan+Websocket+gRPC/*/config.json` are gitignored but tracked; edits there won't show in `git status`.
- Telegram admin token/chat-id for install notifications are base64-embedded in `setup.sh` (near top).
- setup.sh pins software versions inline: xray (XTLS install-release), node (deb.nodesource.com), vnstat (humdi.net). Bump there, not elsewhere.
- Only verification available: `bash -n <script>` for syntax. No unit tests.
