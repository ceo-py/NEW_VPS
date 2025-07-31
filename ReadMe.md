# VPS Security Hardening & Setup Guide

[![Security](https://img.shields.io/badge/Security-Hardened-green?style=flat-square)](https://github.com)
[![Fail2Ban](https://img.shields.io/badge/Fail2Ban-Configured-blue?style=flat-square)](https://github.com)
[![Cloudflare](https://img.shields.io/badge/Cloudflare-Tunnel-orange?style=flat-square)](https://github.com)
[![SSH](https://img.shields.io/badge/SSH-Key_Auth-red?style=flat-square)](https://github.com)

> A comprehensive guide for securing and configuring a production VPS with industry best practices.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
  - [Initial Server Setup](#1-initial-server-setup)
  - [SSH Security Hardening](#2-ssh-security-hardening)
  - [Firewall Configuration](#3-firewall-configuration)
  - [Fail2Ban Installation](#4-fail2ban-installation)
  - [Cloudflare Tunnel Setup](#5-cloudflare-tunnel-setup)
  - [Monitoring Setup](#6-monitoring-setup)
- [Verification](#verification)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Prerequisites

Before starting, ensure you have:

- [ ] Fresh VPS with Ubuntu 20.04+ or Debian 11+
- [ ] Root access to the server
- [ ] Local machine with SSH client
- [ ] Cloudflare account (free tier works)
- [ ] Domain name managed by Cloudflare

## Quick Start

For experienced users, run the automated setup:

```bash
# Download and run the setup script
curl -sSL https://raw.githubusercontent.com/your-repo/vps-setup/main/setup.sh | bash
```

For manual setup, follow the [Detailed Setup](#detailed-setup) section below.

## Detailed Setup

### 1. Initial Server Setup

#### 1.1 Generate SSH Key Pair (Local Machine)

```bash
# Generate a new SSH key pair
ssh-keygen -t ed25519 -C "your-email@example.com"

# For older systems that don't support ed25519
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

#### 1.2 Create Non-Root User

```bash
# Connect to VPS as root
ssh root@YOUR_SERVER_IP

# Create new user
adduser username
usermod -aG sudo username

# Verify user creation
groups username
```

#### 1.3 Setup SSH Key Authentication

```bash
# Switch to new user
su - username

# Create SSH directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit

# Copy SSH key from local machine
ssh-copy-id username@YOUR_SERVER_IP

# Test SSH key authentication
ssh username@YOUR_SERVER_IP
```

### 2. SSH Security Hardening

#### 2.1 Backup Original Configuration

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
```

#### 2.2 Apply Security Configuration

```bash
sudo tee /etc/ssh/sshd_config > /dev/null << 'EOF'
# SSH Security Configuration
Port 22
Protocol 2

# Host Keys
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Authentication
LoginGraceTime 60
PermitRootLogin no
StrictModes yes
MaxAuthTries 3
MaxSessions 2
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no
UsePAM no

# Security Settings
X11Forwarding no
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
Compression delayed
ClientAliveInterval 300
ClientAliveCountMax 2
MaxStartups 2
IgnoreRhosts yes
HostbasedAuthentication no

# User Restrictions
AllowUsers username
EOF
```

#### 2.3 Test and Apply Configuration

```bash
# Test configuration
sudo sshd -t

# Reload SSH service
sudo systemctl reload ssh
sudo systemctl status ssh
```

### 3. Firewall Configuration

```bash
# Configure UFW firewall
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Enable firewall
sudo ufw --force enable

# Verify configuration
sudo ufw status verbose
```

### 4. Fail2Ban Installation

#### 4.1 Install Fail2Ban

```bash
sudo apt update && sudo apt install fail2ban -y
sudo systemctl start fail2ban
sudo systemctl enable fail2ban
```

#### 4.2 Configure Fail2Ban

```bash
sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6

[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-noproxy]
enabled = true
port = http,https
filter = nginx-noproxy
logpath = /var/log/nginx/access.log
maxretry = 2
EOF
```

#### 4.3 Test and Restart Fail2Ban

```bash
sudo fail2ban-client -t
sudo systemctl restart fail2ban
sudo fail2ban-client status
```

### 5. Cloudflare Tunnel Setup

#### 5.1 Install Cloudflared

```bash
# Download and install cloudflared
wget -O cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
rm cloudflared.deb

# Verify installation
cloudflared --version
```

#### 5.2 Authenticate and Create Tunnel

```bash
# Login to Cloudflare (opens browser)
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create my-tunnel

# Note the tunnel ID from the output
```

#### 5.3 Configure Tunnel

```bash
# Create configuration directory
mkdir -p ~/.cloudflared

# Create tunnel configuration
cat > ~/.cloudflared/config.yml << 'EOF'
tunnel: YOUR_TUNNEL_ID_HERE
credentials-file: /home/username/.cloudflared/YOUR_TUNNEL_ID_HERE.json

ingress:
  - hostname: yourdomain.com
    service: http://localhost:80
  - hostname: www.yourdomain.com
    service: http://localhost:80
  - hostname: api.yourdomain.com
    service: http://localhost:3000
  - hostname: admin.yourdomain.com
    service: http://localhost:8080
  - service: http_status:404
EOF
```

#### 5.4 Setup DNS and Service

```bash
# Create DNS records
cloudflared tunnel route dns my-tunnel yourdomain.com
cloudflared tunnel route dns my-tunnel www.yourdomain.com
cloudflared tunnel route dns my-tunnel api.yourdomain.com
cloudflared tunnel route dns my-tunnel admin.yourdomain.com

# Install as system service
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
sudo systemctl status cloudflared
```

### 6. Monitoring Setup

```bash
# Create monitoring script
sudo tee /usr/local/bin/vps-monitor.sh > /dev/null << 'EOF'
#!/bin/bash

# VPS Monitoring Script
# Usage: ./vps-monitor.sh

echo "🔍 VPS Security & Performance Monitor"
echo "======================================"
echo

# System Information
echo "📊 System Information:"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo

# Memory Usage
echo "💾 Memory Usage:"
free -h
echo

# Disk Usage
echo "💿 Disk Usage:"
df -h / | tail -1
echo

# SSH Security Status
echo "🔐 SSH Security Status:"
echo "SSH Service: $(systemctl is-active ssh)"
echo "Root Login: $(grep '^PermitRootLogin' /etc/ssh/sshd_config | awk '{print $2}')"
echo "Password Auth: $(grep '^PasswordAuthentication' /etc/ssh/sshd_config | awk '{print $2}')"
echo

# Firewall Status
echo "🔥 Firewall Status:"
sudo ufw status | head -5
echo

# Fail2Ban Status
echo "🛡️ Fail2Ban Status:"
echo "Service: $(systemctl is-active fail2ban)"
if systemctl is-active fail2ban >/dev/null 2>&1; then
    echo "Active Jails:"
    sudo fail2ban-client status | grep "Jail list" | sed 's/.*Jail list://'
    echo "Banned IPs:"
    sudo fail2ban-client status sshd 2>/dev/null | grep "Banned IP list" | sed 's/.*Banned IP list://' || echo "None"
fi
echo

# Cloudflare Tunnel Status
echo "☁️ Cloudflare Tunnel Status:"
echo "Service: $(systemctl is-active cloudflared 2>/dev/null || echo 'Not installed')"
echo

# Recent Failed Login Attempts
echo "🚨 Recent Failed Login Attempts (Last 10):"
grep "Failed password" /var/log/auth.log 2>/dev/null | tail -10 | awk '{print $1, $2, $3, $11, $13}' || echo "No recent failed attempts"
echo

# Network Connections
echo "🌐 Active Network Connections:"
ss -tuln | grep LISTEN
echo

echo "✅ Monitoring complete!"
EOF

# Make script executable
sudo chmod +x /usr/local/bin/vps-monitor.sh
```

## Verification

Run these commands to verify your setup:

```bash
# Test SSH configuration
sudo sshd -t

# Check firewall status
sudo ufw status verbose

# Verify Fail2Ban
sudo fail2ban-client status

# Check Cloudflare tunnel
sudo systemctl status cloudflared

# Run monitoring script
sudo /usr/local/bin/vps-monitor.sh
```

## Maintenance

### Daily Commands

```bash
# Health check
sudo /usr/local/bin/vps-monitor.sh

# Update system
sudo apt update && sudo apt upgrade -y

# Check security logs
sudo tail -f /var/log/fail2ban.log
sudo grep "Failed password" /var/log/auth.log | tail -10
```

### Fail2Ban Management

```bash
# Check banned IPs
sudo fail2ban-client status sshd

# Manually ban an IP
sudo fail2ban-client set sshd banip 1.2.3.4

# Manually unban an IP
sudo fail2ban-client set sshd unbanip 1.2.3.4
```

### Service Management

```bash
# Restart services
sudo systemctl restart fail2ban
sudo systemctl restart cloudflared
sudo systemctl restart ssh

# View logs
sudo tail -f /var/log/auth.log          # SSH attempts
sudo tail -f /var/log/fail2ban.log      # Fail2Ban activity
sudo journalctl -u cloudflared -f       # Cloudflare tunnel logs
```

## Troubleshooting

### Emergency Access Recovery

If you get locked out, use VPS console access:

```bash
# Temporarily enable password authentication
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Temporarily disable firewall
sudo ufw disable

# Temporarily stop Fail2Ban
sudo systemctl stop fail2ban
```

### Common Issues

| Issue | Solution |
|-------|----------|
| SSH connection refused | Check if SSH service is running: `sudo systemctl status ssh` |
| Locked out by Fail2Ban | Use console to unban IP: `sudo fail2ban-client set sshd unbanip YOUR_IP` |
| Cloudflare tunnel not working | Check logs: `sudo journalctl -u cloudflared -f` |
| High memory usage | Check processes: `top` or `htop` |

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -am 'Add improvement'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**⚠️ Security Notice**: Always test configurations in a development environment before applying to production servers. Keep your system updated and monitor logs regularly.

**📞 Support**: For issues or questions, please open an issue in the repository or contact the maintainers.