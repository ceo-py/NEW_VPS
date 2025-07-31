# 🚀 Complete VPS Security Hardening & Setup Guide

<div align="center">

**Security Setup for Production VPS**

![Security](https://img.shields.io/badge/Security-Hardened-green?style=for-the-badge)
![Fail2Ban](https://img.shields.io/badge/Fail2Ban-Configured-blue?style=for-the-badge)
![Cloudflare](https://img.shields.io/badge/Cloudflare-Tunnel-orange?style=for-the-badge)
![SSH](https://img.shields.io/badge/SSH-Key_Auth-red?style=for-the-badge)

</div>

---

## 📋 Prerequisites Checklist

- ✅ Fresh VPS with Ubuntu 20.04+ or Debian 11+
- ✅ Root access to the server
- ✅ Your local machine's public IP address

## 📋 Prerequisites ChecklistNot
- ✅ Cloudflare account (free tier works)
- ✅ Domain name managed by Cloudflare

---

## 🔧 Complete Setup Commands

**Copy and execute the following commands step by step:**

# ============================================================================
# 🏗️ INITIAL SERVER SETUP
# ============================================================================

# Step 1: Generate SSH Key Pair (Run on LOCAL machine)
`ssh-keygen -t rsa -b 4096 -C "your-email@example.com"`
# Press Enter for default location, set a strong passphrase

# Step 2: Connect to VPS as root
`ssh root@YOUR_SERVER_IP`

# Step 3: Create new user (replace 'username' with your desired username)
`adduser username`
# Follow prompts to set password and info

# Step 4: Grant sudo privileges
`usermod -aG sudo username`
`groups username`

# Step 5: Setup SSH directory for new user
`su - username`
`mkdir -p ~/.ssh`
`chmod 700 ~/.ssh`
`touch ~/.ssh/authorized_keys`
`chmod 600 ~/.ssh/authorized_keys`
`exit`

# Step 6: Copy SSH key (Run on LOCAL machine)
`ssh-copy-id username@YOUR_SERVER_IP`

# Step 7: Test SSH key authentication (Run on LOCAL machine)
`ssh username@YOUR_SERVER_IP`

# ============================================================================
# 🔐 SSH SECURITY HARDENING
# ============================================================================

# Step 8: Backup original SSH config
`sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup`

# Step 9: Configure SSH security
`sudo tee /etc/ssh/sshd_config > /dev/null << 'EOF'`
# SSH Security Configuration
`Port 22`
`Protocol 2`
`HostKey /etc/ssh/ssh_host_rsa_key`
`HostKey /etc/ssh/ssh_host_ecdsa_key`
`HostKey /etc/ssh/ssh_host_ed25519_key`

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

# Security settings
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

# Allow only specific user
AllowUsers username
EOF

# Step 10: Test and reload SSH
`sudo sshd -t`
`sudo systemctl reload ssh`
`sudo systemctl status ssh`

# ============================================================================
# 🔥 FIREWALL CONFIGURATION
# ============================================================================

# Step 11: Configure UFW firewall
`sudo ufw allow OpenSSH`
`sudo ufw allow 80/tcp`
`sudo ufw allow 443/tcp`
`sudo ufw default deny incoming`
`sudo ufw default allow outgoing`
`sudo ufw show added`
`sudo ufw --force enable`
`sudo ufw status verbose`

# ============================================================================
# 🛡️ FAIL2BAN INSTALLATION & CONFIGURATION
# ============================================================================

# Step 12: Install Fail2Ban
`sudo apt update && sudo apt install fail2ban -y`
`sudo systemctl start fail2ban`
`sudo systemctl enable fail2ban`

# Step 13: Create comprehensive Fail2Ban configuration
`sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'`
# Copy the content from the jail.local file in this repository

# Step 14: Test and restart Fail2Ban
`sudo fail2ban-client -t`
`sudo systemctl restart fail2ban`
`sudo fail2ban-client status`

# ============================================================================
# ☁️ CLOUDFLARE TUNNEL SETUP
# ============================================================================

# Step 15: Install Cloudflared
`wget -O cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb`
`sudo dpkg -i cloudflared.deb`
`cloudflared --version`
`rm cloudflared.deb`

# Step 16: Login to Cloudflare (this will open browser)
`cloudflared tunnel login`

# Step 17: Create tunnel (replace 'my-tunnel' with your preferred name)
`cloudflared tunnel create my-tunnel`
# Note the tunnel ID displayed

# Step 18: Create tunnel configuration
`mkdir -p ~/.cloudflared`
`cat > ~/.cloudflared/config.yml << 'EOF'`
# Copy the content from the config.yml file in this repository

# Cloudflare Tunnel Configuration
`tunnel: YOUR_TUNNEL_ID_HERE`
`credentials-file: /home/username/.cloudflared/YOUR_TUNNEL_ID_HERE.json`


# Step 19: Create DNS records
`cloudflared tunnel route dns my-tunnel yourdomain.com`
`cloudflared tunnel route dns my-tunnel www.yourdomain.com`
`cloudflared tunnel route dns my-tunnel api.yourdomain.com`
`cloudflared tunnel route dns my-tunnel admin.yourdomain.com`

# Step 20: Install tunnel as service
`sudo cloudflared service install`
`sudo systemctl start cloudflared`
`sudo systemctl enable cloudflared`
`sudo systemctl status cloudflared`

# ============================================================================
# 📊 MONITORING SCRIPT SETUP
# ============================================================================

# Step 21: Create monitoring script
`sudo tee /usr/local/bin/vps-monitor.sh > /dev/null << 'EOF'`
# Copy the content from the vps-monitor.sh file in this repository

# Step 22: Make monitoring script executable
`sudo chmod +x /usr/local/bin/vps-monitor.sh`

# ============================================================================
# ✅ VERIFICATION COMMANDS
# ============================================================================

# Step 23: Verify everything is working
`echo "🔍 RUNNING VERIFICATION CHECKS..."`

# Check SSH configuration
`sudo sshd -t`

# Verify firewall status
`sudo ufw status verbose`

# Check Fail2Ban status
`sudo fail2ban-client status`

# Test local web server (if installed)
`curl -I http://localhost 2>/dev/null || echo "No web server detected"`

# Check Cloudflare tunnel
`sudo systemctl status cloudflared`

# Run monitoring script
`sudo /usr/local/bin/vps-monitor.sh`

# ============================================================================
# 🎯 USEFUL MAINTENANCE COMMANDS
# ============================================================================

# Update system packages
`sudo apt update && sudo apt upgrade -y`

# Check Fail2Ban banned IPs
`sudo fail2ban-client status sshd`

# Manually ban an IP
`sudo fail2ban-client set sshd banip 1.2.3.4`

# Manually unban an IP
`sudo fail2ban-client set sshd unbanip 1.2.3.4`

# View real-time logs
`sudo tail -f /var/log/auth.log`          # SSH attempts
`sudo tail -f /var/log/fail2ban.log`      # Fail2Ban activity
`sudo journalctl -u cloudflared -f`       # Cloudflare tunnel logs

# Restart services
`sudo systemctl restart fail2ban`
`sudo systemctl restart cloudflared`
`sudo systemctl restart ssh`

# ============================================================================
# 🚨 EMERGENCY COMMANDS (Use only if locked out)
# ============================================================================

# Emergency SSH access reset (via console)
`sudo nano /etc/ssh/sshd_config`
# Set: PasswordAuthentication yes`
# sudo systemctl restart ssh

# Emergency firewall disable
# sudo ufw disable

# Emergency Fail2Ban disable
# sudo systemctl stop fail2ban

# View system logs
# sudo journalctl -xe

# ============================================================================
# 📝 IMPORTANT NOTES
# ============================================================================

🔄 Quick Reference Commands
After setup, use these commands for daily management:

# Daily health check
`sudo /usr/local/bin/vps-monitor.sh`

# Check security status
`sudo fail2ban-client status`
`sudo ufw status`

# View recent attacks
`sudo tail -f /var/log/fail2ban.log`
`sudo grep "Failed password" /var/log/auth.log | tail -10`

# Update system
`sudo apt update && sudo apt upgrade -y`

# Restart services if needed
`sudo systemctl restart fail2ban`
`sudo systemctl restart cloudflared`


🆘 Emergency Recovery
If you get locked out, use VPS console access:

# Reset SSH to allow password temporarily
`sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config`
`sudo systemctl restart ssh`

# Disable firewall temporarily
`sudo ufw disable`

# Stop Fail2Ban temporarily
`sudo systemctl stop fail2ban`
