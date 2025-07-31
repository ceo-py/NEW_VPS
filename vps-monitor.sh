#!/bin/bash
# VPS Daily Monitoring Script

echo "🖥️  VPS Health Check - $(date)"
echo "=================================="

# System Resources
echo "📊 SYSTEM RESOURCES"
echo "Memory Usage:"
free -h
echo ""
echo "Disk Usage:"
df -h /
echo ""
echo "CPU Load:"
uptime
echo ""

# Security Status
echo "🛡️  SECURITY STATUS"
echo "Firewall Status:"
sudo ufw status
echo ""
echo "Fail2Ban Status:"
sudo fail2ban-client status
echo ""
echo "SSH Failed Attempts (Today):"
sudo grep "$(date '+%b %d')" /var/log/auth.log | grep "Failed password" | wc -l
echo ""

# Services Status
echo "🔧 SERVICES STATUS"
services=("ssh" "fail2ban" "cloudflared" "apache2" "nginx")
for service in "${services[@]}"; do
    if systemctl is-active --quiet $service 2>/dev/null; then
        echo "✅ $service: Running"
    else
        echo "❌ $service: Not running"
    fi
done
echo ""

# Cloudflare Tunnel Status
echo "☁️  CLOUDFLARE TUNNEL"
if systemctl is-active --quiet cloudflared; then
    echo "✅ Tunnel Status: Active"
    echo "Recent tunnel logs:"
    sudo journalctl -u cloudflared --since "1 hour ago" --no-pager | tail -3
else
    echo "❌ Tunnel Status: Inactive"
fi
echo ""

# Recent Security Events
echo "🚨 RECENT SECURITY EVENTS"
echo "Fail2Ban bans (Last 24h):"
sudo grep "$(date '+%Y-%m-%d')" /var/log/fail2ban.log 2>/dev/null | grep "Ban " | wc -l
echo ""

echo "=================================="
echo "Health check completed!"
EOF