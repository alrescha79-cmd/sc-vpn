# VPN Account Management API

A REST API built with GoFiber implementing Clean Architecture for managing VPN accounts (VMESS, SSH, TROJAN, VLESS, SHADOWSOCKS).

## Postman Documentation

For detailed API documentation and examples, visit our [Postman Documentation](https://documenter.getpostman.com/view/26294023/2sB3HhsN7H)

## Architecture

This API follows Clean Architecture principles with the following layers:

1. **Models**: Data structures and entities
2. **Controllers**: Handle HTTP requests and responses
3. **Usecases**: Business logic implementation
4. **Utils**: Utility functions and helpers
5. **Routes**: API route definitions
6. **Config**: Configuration management

The architecture has been separated by protocol:
- Each protocol (VMESS, SSH, VLESS, TROJAN, SHADOWSOCKS) has its own usecase and controller
- A main account usecase and controller coordinate between the protocol-specific components

## Authentication

The API requires authentication for all protected endpoints. You can authenticate using:

1. **API Key in Authorization Header**:
   ```
   Authorization: Bearer YOUR_API_KEY
   ```

2. **API Key in X-API-Key Header**:
   ```
   X-API-Key: YOUR_API_KEY
   ```

The API key can be configured in the `.env` file.

## API Endpoints

### Health Check
- `GET /health` - Check if the API is running (No authentication required)

### General Account Management
- `POST /api/v1/accounts` - Create a new account (specify account_type in request)
- `POST /api/v1/accounts/check` - Check an existing account (specify account_type in request)
- `POST /api/v1/accounts/delete` - Delete an existing account (specify account_type in request)
- `POST /api/v1/accounts/renew` - Renew an existing account (specify account_type in request)

### Protocol Specific Routes

#### VMESS
- `POST /api/v1/vmess/` - Create VMESS account
- `POST /api/v1/vmess/check` - Check VMESS account
- `POST /api/v1/vmess/delete` - Delete VMESS account
- `POST /api/v1/vmess/renew` - Renew VMESS account

#### SSH
- `POST /api/v1/ssh/` - Create SSH account
- `POST /api/v1/ssh/check` - Check SSH account
- `POST /api/v1/ssh/delete` - Delete SSH account
- `POST /api/v1/ssh/renew` - Renew SSH account

#### VLESS
- `POST /api/v1/vless/` - Create VLESS account
- `POST /api/v1/vless/check` - Check VLESS account
- `POST /api/v1/vless/delete` - Delete VLESS account
- `POST /api/v1/vless/renew` - Renew VLESS account

#### TROJAN
- `POST /api/v1/trojan/` - Create TROJAN account
- `POST /api/v1/trojan/check` - Check TROJAN account
- `POST /api/v1/trojan/delete` - Delete TROJAN account
- `POST /api/v1/trojan/renew` - Renew TROJAN account

#### SHADOWSOCKS
- `POST /api/v1/shadowsocks/` - Create SHADOWSOCKS account
- `POST /api/v1/shadowsocks/check` - Check SHADOWSOCKS account
- `POST /api/v1/shadowsocks/delete` - Delete SHADOWSOCKS account
- `POST /api/v1/shadowsocks/renew` - Renew SHADOWSOCKS account

## Request Examples

### Create Account (General)
```json
{
  "username": "testuser", // Required for username
  "password": "testpass", // Required for password
  "exp": "30", // Expiration in days
  "quota": "10", //  quota example 10GB
  "ip_quota": "5", // IP limit
  "account_type": "vmess" // vmess, ssh, trojan, vless, shadowsocks
}
```

### Create VMESS Account (Protocol Specific)
```json
{
  "username": "testuser",
  "exp": "30",
  "quota": "10GB",
  "ip_quota": "5"
}
```

### Check Account
```json
{
  "username": "testuser",
  "account_type": "vmess"
}
```

### Delete Account
```json
{
  "username": "testuser",
  "account_type": "vmess"
}
```

### Renew Account
```json
{
  "username": "testuser",
  "exp": "30", // Additional days to extend expiration
  "account_type": "vmess"
}
```

## Response Format

All responses follow this format:
```json
{
  "status": "success|error",
  "message": "Description of the operation result",
  "data": {} // Optional data field for successful operations
}
```

## Configuration

The API can be configured using environment variables or a `.env` file:

```
# Authentication Configuration
API_KEY=your_api_key_here
AllowOrigins=* // if you want to allow all origins or specific ones
# Server Configuration
PORT=3005
```

## Installation on Ubuntu VPS

Follow these steps to deploy the VPN Account Management API on your Ubuntu VPS:

### Prerequisites

- Ubuntu 18.04 or higher VPS
- SSH access to your VPS
- Sudo privileges


### Step 1: Prepare the Application

 instal auto rest backend :
   ```bash
   wget https://raw.githubusercontent.com/alrescha79-cmd/sc-vpn/refs/heads/dev/golang/rest-go.sh
   chmod +x rest-go.sh
   bash rest-go.sh
   ```



### if you custom a Systemd Service

1. Create a systemd service file:
   ```bash
   sudo nano /etc/systemd/system/vpn-api.service
   ```

2. Add the following content to the service file:
   ```ini
   [Unit]
   Description=VPN Account Management API
   After=network.target

   [Service]
   Type=simple
   User=root
   WorkingDirectory=/home/user/backend
   ExecStart=/home/user/backend/vpn-api
   Restart=always
   RestartSec=10
   Environment=PORT=3005
   Environment=API_KEY=c75258f0-940b-4972-b316-63c14a4bb7e3
   Environment=AllowOrigins=*


   [Install]
   WantedBy=multi-user.target
   ```

3. Set proper permissions for the service file:
   ```bash
   sudo chmod 644 /etc/systemd/system/vpn-api.service
   ```

### Step 6: Start and Enable the Service

1. Reload systemd to recognize the new service:
   ```bash
   sudo systemctl daemon-reload
   ```

2. Start the service:
   ```bash
   sudo systemctl start vpn-api
   ```

3. Enable the service to start on boot:
   ```bash
   sudo systemctl enable vpn-api
   ```

4. Check the service status:
   ```bash
   sudo systemctl status vpn-api
   ```

### Step 7: Configure Firewall (Optional)

If you have UFW firewall enabled, allow traffic to your API port:

```bash
sudo ufw allow 3000
```

### Step 8: Test the API

You can test if the API is running correctly:

```bash
# Check if the API responds
curl http://localhost:3000/health

# Expected response:
# {"message":"Account management API is running","status":"success"}
```


## quide rest api go to your system vps

This script will:
- rest api golang
- low memory usage
- very fast
- low cpu usage
- small file size 16mb

## Testing

The [tests](tests/) directory contains HTTP test files for each protocol:
- [VMESS tests](tests/vmess.http)
- [SSH tests](tests/ssh.http)
- [VLESS tests](tests/vless.http)
- [TROJAN tests](tests/trojan.http)
- [SHADOWSOCKS tests](tests/shadowsocks.http)
- [All protocols tests](tests/all_protocols.http)

These can be run using VS Code REST Client extension or any HTTP client that supports .http files.

## Command Paths

The application expects the following shell commands to be available on the system:

### Account Creation:
- VMESS: `/usr/local/bin/add-vmess-user`
- SSH: `/usr/local/bin/add-ssh-user`
- TROJAN: `/usr/local/bin/add-trojan-user`
- VLESS: `/usr/local/bin/add-vless-user`
- SHADOWSOCKS: `/usr/local/bin/add-shadowsocks-user`

### Account Deletion:
- VMESS: `/usr/local/bin/del-vmess`
- SSH: `/usr/local/bin/del-ssh`
- TROJAN: `/usr/local/bin/del-trojan`
- VLESS: `/usr/local/bin/del-vless`
- SHADOWSOCKS: `/usr/local/bin/del-shadowsocks`

### Account Renewal:
- VMESS: `/usr/local/bin/renew-vmess`
- SSH: `/usr/local/bin/renew-ssh`
- TROJAN: `/usr/local/bin/renew-trojan`
- VLESS: `/usr/local/bin/renew-vless`
- SHADOWSOCKS: `/usr/local/bin/renew-shadowsocks`

Make sure these commands are properly installed and accessible on your system.

## Pre-built Docker Image

You can pull the pre-built Docker image from Docker Hub:

```bash
docker pull hidessh99/vpn-rest:v1
```
