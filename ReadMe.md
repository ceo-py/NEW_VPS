# VPS Security Hardening & Setup Guide

[![Security](https://img.shields.io/badge/Security-Hardened-green?style=flat-square)](#3-firewall-configuration)
[![Fail2Ban](https://img.shields.io/badge/Fail2Ban-Configured-blue?style=flat-square)](#4-fail2ban-installation)
[![Cloudflare](https://img.shields.io/badge/Cloudflare-Tunnel-orange?style=flat-square)](#5-cloudflare-tunnel-setup)
[![SSH](https://img.shields.io/badge/SSH-Key_Auth-red?style=flat-square)](#2-ssh-security-hardening)

> A comprehensive guide for securing and configuring a production VPS with industry best practices.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Detailed Setup](#detailed-setup)
  - [Initial Server Setup](#1-initial-server-setup)
  - [SSH Security Hardening](#2-ssh-security-hardening)
  - [Firewall Configuration](#3-firewall-configuration)
  - [Fail2Ban Installation](#4-fail2ban-installation)
  - [Cloudflare Tunnel Setup](#5-cloudflare-tunnel-setup)
  - [Monitoring Setup](#6-monitoring-setup)
  - [Automatic Updates Setup](#7-automatic-updates-setup-ubuntu)
- [Verification](#verification)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Prerequisites

Before starting, ensure you have:

- [ ] Fresh VPS with Ubuntu 20.04+ or Debian 11+
- [ ] Root access to the server
- [ ] Local machine with SSH client

Optional
- [ ] Cloudflare account (free tier works)
- [ ] Domain name managed by Cloudflare

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
# Download and apply Fail2Ban configuration
sudo wget -O /etc/fail2ban/jail.local https://raw.githubusercontent.com/ceo-py/NEW_VPS/refs/heads/main/jail.local

# Or manually copy the configuration from the repository
sudo cp jail.local /etc/fail2ban/jail.local
```

> 📁 **Configuration File**: [`jail.local`](./jail.local) - Complete Fail2Ban configuration with multiple protection rules

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

# Download and apply Cloudflare tunnel configuration
wget -O ~/.cloudflared/config.yml https://raw.githubusercontent.com/ceo-py/NEW_VPS/refs/heads/main/config.yml

# Or manually copy the configuration from the repository
cp config.yml ~/.cloudflared/config.yml

# Edit the configuration with your tunnel ID and credentials path
nano ~/.cloudflared/config.yml
```

> 📁 **Configuration File**: [`config.yml`](./config.yml) - Cloudflare tunnel configuration template

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
# Download and apply VPS monitor script
sudo wget -O /usr/local/bin/vps-monitor.sh https://raw.githubusercontent.com/ceo-py/NEW_VPS/refs/heads/main/vps-monitor.sh

# Or manually copy the script from the repository
sudo cp vps-monitor.sh /usr/local/bin/vps-monitor.sh
```

> 📁 **Script File**: [`vps-monitor.sh`](./vps-monitor.sh) - Complete VPS monitor script

```bash
# Make script executable
sudo chmod +x /usr/local/bin/vps-monitor.sh
```

### 7. Automatic Updates Setup (Ubuntu)

#### 7.1 Install and Configure Unattended Upgrades

```bash
# Install unattended-upgrades package
sudo apt update
sudo apt install unattended-upgrades -y

# Configure unattended upgrades (select "Yes" when prompted)
sudo dpkg-reconfigure unattended-upgrades
```

#### 7.2 Configure Auto-Reboot Settings

```bash
# Edit unattended upgrades configuration
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

Add these lines to enable automatic reboots when required:

```bash
# Automatic reboot configuration
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";

# Email notifications (optional)
Unattended-Upgrade::Mail "your-email@example.com";
Unattended-Upgrade::MailOnlyOnError "true";

# Keep old kernel versions for rollback
Unattended-Upgrade::Remove-Unused-Kernel-Packages "false";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "false";

# Skip updates that require interaction
Unattended-Upgrade::Skip-Updates-On-Metered-Connections "true";
```

#### 7.3 Configure Update Frequency

```bash
# Edit apt periodic configuration
sudo nano /etc/apt/apt.conf.d/20auto-upgrades
```

Ensure these settings are configured:

```bash
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
```

#### 7.4 Verify Automatic Updates

```bash
# Check unattended-upgrades service status
sudo systemctl status unattended-upgrades

# Test the configuration
sudo unattended-upgrades --dry-run --debug

# View automatic update logs
sudo tail -f /var/log/unattended-upgrades/unattended-upgrades.log

# Check when updates were last run
sudo cat /var/log/unattended-upgrades/unattended-upgrades-dpkg.log | tail -20
```

#### 7.5 Manual Control Commands

```bash
# Force run unattended upgrades now
sudo unattended-upgrades --debug

# Check what updates are available
sudo apt list --upgradable

# View update history
sudo grep "upgrade" /var/log/dpkg.log | tail -10

# Disable automatic updates temporarily
sudo systemctl stop unattended-upgrades
sudo systemctl disable unattended-upgrades

# Re-enable automatic updates
sudo systemctl enable unattended-upgrades
sudo systemctl start unattended-upgrades
```

> **📋 What This Setup Does:**
> - Automatically installs security updates daily
> - Downloads and installs package updates
> - Reboots server at 2:00 AM if kernel updates require it
> - Sends email notifications on errors (if configured)
> - Keeps your system current without manual intervention
> - Maintains system security with minimal maintenance

> **⚠️ Important Notes:**
> - The system will automatically reboot at 2:00 AM if kernel updates require it
> - Monitor `/var/log/unattended-upgrades/` logs regularly
> - Test in development environment before enabling auto-reboot in production
> - Consider setting up email notifications for update failures

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

# Verify automatic updates
sudo systemctl status unattended-upgrades

# Run monitoring script
sudo /usr/local/bin/vps-monitor.sh
```

## Maintenance

### Daily Commands

```bash
# Health check
sudo /usr/local/bin/vps-monitor.sh

# Update system (manual - automatic updates handle this)
sudo apt update && sudo apt upgrade -y

# Check security logs
sudo tail -f /var/log/fail2ban.log
sudo grep "Failed password" /var/log/auth.log | tail -10

# Check automatic updates status
sudo systemctl status unattended-upgrades
sudo tail -f /var/log/unattended-upgrades/unattended-upgrades.log
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
---

**⚠️ Security Notice**: Always test configurations in a development environment before applying to production servers. Keep your system updated and monitor logs regularly.