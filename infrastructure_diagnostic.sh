#!/bin/bash
# Infrastructure Diagnostic Script - Get Current Real Status
# Run this on the Pi to get accurate current state

echo "=================================================="
echo "🔍 INFRASTRUCTURE DIAGNOSTIC REPORT"
echo "📅 Generated: $(date)"
echo "=================================================="
echo ""

# Basic System Info
echo "=== 🖥️  SYSTEM INFORMATION ==="
echo "Hostname: $(hostname)"
echo "IP Address: $(hostname -I | awk '{print $1}')"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Uptime: $(uptime -p)"
echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
echo "Memory: $(free -h | grep Mem | awk '{print $3 "/" $2 " (" $4 " free)"}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $4 " available)"}')"
echo ""

# Docker Status
echo "=== 🐳 DOCKER INFRASTRUCTURE ==="
if command -v docker &> /dev/null; then
    echo "Docker version: $(docker --version | cut -d' ' -f3 | tr -d ',')"
    echo "Docker Compose version: $(docker compose version --short 2>/dev/null || echo 'Not found')"
    
    echo ""
    echo "📦 Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -20
    
    echo ""
    echo "📊 Container Resource Usage:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    
    echo ""
    echo "🗂️ Docker Compose Projects:"
    find /home -name "docker-compose.yml" 2>/dev/null | head -10
    
else
    echo "❌ Docker not found"
fi
echo ""

# Network Status
echo "=== 🌐 NETWORK STATUS ==="
echo "Network interfaces:"
ip addr show | grep -E '^[0-9]+:' | cut -d' ' -f2 | tr -d ':'

echo ""
echo "Active connections:"
ss -tuln | grep LISTEN | head -10

echo ""
echo "DNS resolution test:"
nslookup google.com 8.8.8.8 >/dev/null 2>&1 && echo "✅ Internet DNS working" || echo "❌ Internet DNS issues"

# Tailscale Status
echo ""
echo "=== 🔗 TAILSCALE STATUS ==="
if command -v tailscale &> /dev/null; then
    echo "Tailscale status:"
    tailscale status --json 2>/dev/null | jq -r '.Self.DNSName, .Self.TailscaleIPs[0]' 2>/dev/null || tailscale status
else
    echo "❌ Tailscale not found"
fi
echo ""

# Service Health Checks
echo "=== 🏥 SERVICE HEALTH CHECKS ==="
services=("8080:Pi-hole" "3000:Grafana" "8082:Homer" "9090:Prometheus" "8083:Nextcloud")

for service in "${services[@]}"; do
    port=$(echo $service | cut -d: -f1)
    name=$(echo $service | cut -d: -f2)
    
    if nc -z localhost $port 2>/dev/null; then
        echo "✅ $name (port $port): Responding"
    else
        echo "❌ $name (port $port): Not responding"
    fi
done
echo ""

# File System and Git Status
echo "=== 📁 FILE SYSTEM & GIT STATUS ==="
echo "Current directory: $(pwd)"
echo "Home directory contents:"
ls -la /home/nate/ 2>/dev/null | head -10

echo ""
echo "Looking for infrastructure directories:"
find /home -maxdepth 3 -name "*infrastructure*" -type d 2>/dev/null

echo ""
echo "Looking for Git repositories:"
find /home -maxdepth 3 -name ".git" -type d 2>/dev/null | head -5

# Check for common config directories
echo ""
echo "Common config locations:"
for dir in "/home/nate/pi-services" "/home/nate/pi-infrastructure" "/home/nate/config"; do
    if [ -d "$dir" ]; then
        echo "✅ Found: $dir"
        ls -la "$dir" | head -5
    else
        echo "❌ Not found: $dir"
    fi
done
echo ""

# Mount Status
echo "=== 💾 MOUNT STATUS ==="
echo "Current mounts:"
mount | grep -E "(cifs|nfs|fuse)" || echo "No network mounts found"

echo ""
echo "Mount points:"
df -h | grep -E "/mnt|/media" || echo "No additional mount points"
echo ""

# NAS Discovery
echo "=== 🏠 NAS DEVICE DISCOVERY ==="
echo "Scanning local network for NAS devices..."

# Check known NAS IPs from documentation
nas_ips=("192.168.68.133" "192.168.68.116" "192.168.68.160" "100.97.199.32" "100.105.154.30" "100.117.92.105")

for ip in "${nas_ips[@]}"; do
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        echo "✅ $ip: Reachable"
        # Check for common NAS ports
        for port in 22 80 443 5000 5001; do
            if nc -z "$ip" "$port" 2>/dev/null; then
                echo "   Port $port: Open"
            fi
        done
    else
        echo "❌ $ip: Not reachable"
    fi
done
echo ""

# Recent Changes
echo "=== 📈 RECENT ACTIVITY ==="
echo "Recent Docker events (last 10):"
docker events --since 24h --until now 2>/dev/null | tail -10 || echo "No recent Docker events"

echo ""
echo "Recent system logs (last 5):"
journalctl --since "1 hour ago" --no-pager | tail -5 2>/dev/null || echo "No recent system logs available"
echo ""

echo "=================================================="
echo "🎯 DIAGNOSTIC COMPLETE"
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. Review service status - identify what's running vs expected"
echo "2. Check Git repository status for current configuration version"
echo "3. Verify NAS connectivity and mounted storage"
echo "4. Test key service endpoints"
echo ""
echo "Run this command to get a quick service overview:"
echo "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' && echo '' && docker compose ps 2>/dev/null"
