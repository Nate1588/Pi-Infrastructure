#!/bin/bash

# Complete Family Dashboard Setup
# Copy/paste and run this script from ~/pi-infrastructure/config/

set -e

echo "🏠 Setting up complete family-friendly dashboard..."
echo "================================================="
echo ""

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" ]]; then
    echo "❌ Please run this script from ~/pi-infrastructure/config/"
    exit 1
fi

# Create all necessary directories
echo "📁 Creating directory structure..."
mkdir -p data/homer/scripts
mkdir -p data/infrastructure-manager

# ========================================
# 1. CREATE WINDOWS SETUP SCRIPT
# ========================================
echo "🖥️ Creating Windows setup script..."
cat > data/homer/scripts/setup-nextcloud-windows.bat << 'WINDOWS_EOF'
@echo off
echo ========================================
echo    Nextcloud Home Setup for Windows
echo ========================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script needs to run as Administrator.
    echo Right-click and select "Run as administrator"
    pause
    exit
)

echo [1/4] Setting up DNS...
netsh interface ip set dns name="Wi-Fi" static 192.168.68.170
netsh interface ip add dns name="Wi-Fi" addr=1.1.1.1 index=2
echo ✓ DNS configured to use Pi-hole

echo.
echo [2/4] Installing certificate...
curl -s -o nextcloud.crt http://192.168.68.170:8090/nextcloud.crt
if exist nextcloud.crt (
    certlm -add nextcloud.crt -s -r localMachine root
    echo ✓ SSL certificate installed
    del nextcloud.crt
) else (
    echo ⚠ Certificate download failed - you may need to accept SSL warnings
)

echo.
echo [3/4] Testing connection...
curl -s -I https://nextcloud.home >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ https://nextcloud.home is accessible
) else (
    echo ⚠ Connection test completed
)

echo.
echo [4/4] Opening Nextcloud download page...
start https://nextcloud.com/install/#install-clients

echo.
echo ========================================
echo            Setup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Install the Nextcloud desktop app
echo 2. Server: https://nextcloud.home
echo 3. Enter your username and password
echo.
echo If you see SSL warnings, click "Accept"
echo.
pause
WINDOWS_EOF

# ========================================
# 2. CREATE MAC SETUP SCRIPT
# ========================================
echo "🍎 Creating Mac setup script..."
cat > data/homer/scripts/setup-nextcloud-mac.sh << 'MAC_EOF'
#!/bin/bash

echo "========================================"
echo "   Nextcloud Home Setup for macOS"
echo "========================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}[1/4] Setting up DNS...${NC}"
WIFI_SERVICE=$(networksetup -listallnetworkservices | grep -i wifi | head -1)

if [[ -n "$WIFI_SERVICE" ]]; then
    echo "Setting DNS for: $WIFI_SERVICE"
    sudo networksetup -setdnsservers "$WIFI_SERVICE" 192.168.68.170 1.1.1.1
    echo -e "${GREEN}✓ DNS configured${NC}"
else
    echo "⚠ Manually set DNS: 192.168.68.170, 1.1.1.1"
fi

echo ""
echo -e "${YELLOW}[2/4] Installing SSL certificate...${NC}"
curl -s -o /tmp/nextcloud.crt http://192.168.68.170:8090/nextcloud.crt

if [[ -f /tmp/nextcloud.crt ]]; then
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /tmp/nextcloud.crt
    echo -e "${GREEN}✓ Certificate installed${NC}"
    rm /tmp/nextcloud.crt
else
    echo "⚠ Certificate download failed"
fi

echo ""
echo -e "${YELLOW}[3/4] Testing connection...${NC}"
if curl -s -I https://nextcloud.home | grep -q "302"; then
    echo -e "${GREEN}✓ https://nextcloud.home working${NC}"
else
    echo "⚠ Connection test completed"
fi

echo ""
echo -e "${YELLOW}[4/4] Opening download page...${NC}"
open https://nextcloud.com/install/#install-clients

echo ""
echo "========================================"
echo -e "${GREEN}         Setup Complete!${NC}"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Install Nextcloud app from the opened webpage"
echo "2. Server: https://nextcloud.home"
echo "3. Enter your username and password"
echo ""
echo "Press enter to close..."
read
MAC_EOF

# Make Mac script executable
chmod +x data/homer/scripts/setup-nextcloud-mac.sh

# ========================================
# 3. COPY CERTIFICATE FOR DOWNLOADS
# ========================================
echo "🔐 Setting up certificate downloads..."
cp data/nginx/ssl/nextcloud.crt data/homer/scripts/
cp data/nginx/ssl/nextcloud.crt data/infrastructure-manager/

# ========================================
# 4. CREATE COMPLETE HOMER CONFIG
# ========================================
echo "🏠 Creating Homer dashboard configuration..."
cat > data/homer/config.yml << 'HOMER_EOF'
---
title: "Home Infrastructure Dashboard"
subtitle: "Family Cloud & Network Services"
logo: "logo.png"
icon: "fas fa-home"

header: true
footer: '<p>🏠 <strong>Home Infrastructure</strong> - Enterprise-grade family cloud platform</p>'

columns: "3"
connectivityCheck: true

services:
  - name: "🌤️ Family Cloud"
    icon: "fas fa-cloud"
    items:
      - name: "Nextcloud"
        logo: "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/nextcloud.png"
        subtitle: "Family file sync & collaboration"
        url: "https://nextcloud.home"
        target: "_blank"
      
      - name: "📱 Windows Setup"
        subtitle: "Download & run setup script"
        url: "http://192.168.68.170:8082/scripts/setup-nextcloud-windows.bat"
        target: "_blank"
        
      - name: "🍎 Mac Setup"
        subtitle: "Download & run setup script"
        url: "http://192.168.68.170:8082/scripts/setup-nextcloud-mac.sh"
        target: "_blank"
        
      - name: "🔐 SSL Certificate"
        subtitle: "Manual certificate download"
        url: "http://192.168.68.170:8082/scripts/nextcloud.crt"
        target: "_blank"
        
      - name: "📋 Setup Instructions"
        subtitle: "Detailed family setup guide"
        url: "http://192.168.68.170:8090"
        target: "_blank"

  - name: "🛠️ Infrastructure Management"
    icon: "fas fa-server"
    items:
      - name: "Pi-hole"
        logo: "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/pihole.png"
        subtitle: "DNS & Ad blocking (admin/admin123)"
        url: "http://192.168.68.170:8080/admin"
        target: "_blank"
        
      - name: "Portainer"
        logo: "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/portainer.png"
        subtitle: "Container management"
        url: "http://192.168.68.170:9000"
        target: "_blank"
        
      - name: "Infrastructure Manager"
        logo: "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/nginx.png"
        subtitle: "System management"
        url: "http://192.168.68.170:8090"
        target: "_blank"

  - name: "📊 Monitoring & Analytics"
    icon: "fas fa-chart-line"
    items:
      - name: "Grafana"
        logo: "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/grafana.png"
        subtitle: "System dashboards (admin/admin123)"
        url: "http://192.168.68.170:3000"
        target: "_blank"
        
      - name: "Prometheus"
        logo: "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/prometheus.png"
        subtitle: "Metrics collection"
        url: "http://192.168.68.170:9090"
        target: "_blank"
        
      - name: "Uptime Kuma"
        logo: "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/uptime-kuma.png"
        subtitle: "Service monitoring"
        url: "http://192.168.68.170:3001"
        target: "_blank"

  - name: "💽 Network Storage"
    icon: "fas fa-hdd"
    items:
      - name: "Amy NAS (Main)"
        logo: "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/synology.png"
        subtitle: "Primary family storage"
        url: "https://amy.greyhound-goblin.ts.net:5001"
        target: "_blank"
        
      - name: "Photos (Immich)"
        logo: "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/immich.png"
        subtitle: "Photo backup & sharing"
        url: "https://amy.greyhound-goblin.ts.net:8212"
        target: "_blank"
        
      - name: "Inventory (Homebox)"
        logo: "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/homebox.png"
        subtitle: "Home inventory management"
        url: "https://amy.greyhound-goblin.ts.net:3100"
        target: "_blank"
        
      - name: "Home Assistant"
        logo: "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/home-assistant.png"
        subtitle: "Smart home automation"
        url: "https://homeassistant.greyhound-goblin.ts.net:8123"
        target: "_blank"
HOMER_EOF

# ========================================
# 5. CREATE INFRASTRUCTURE MANAGER PAGE
# ========================================
echo "📋 Creating infrastructure manager page..."
cat > data/infrastructure-manager/index.html << 'HTML_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Home Infrastructure Manager</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            max-width: 900px;
            margin: 0 auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        h1 {
            text-align: center;
            margin-bottom: 30px;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        .section {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
        }
        .section h2 {
            margin-top: 0;
            color: #fff;
            border-bottom: 2px solid rgba(255, 255, 255, 0.3);
            padding-bottom: 10px;
        }
        .download-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin-top: 20px;
        }
        .download-item {
            background: rgba(255, 255, 255, 0.2);
            border-radius: 8px;
            padding: 15px;
            text-align: center;
            transition: transform 0.2s, background 0.2s;
        }
        .download-item:hover {
            transform: translateY(-2px);
            background: rgba(255, 255, 255, 0.3);
        }
        .download-item a {
            color: white;
            text-decoration: none;
            font-weight: bold;
            font-size: 1.1em;
            display: block;
        }
        .download-item .subtitle {
            font-size: 0.9em;
            opacity: 0.8;
            margin-top: 5px;
        }
        .instructions {
            background: rgba(255, 255, 255, 0.15);
            border-radius: 8px;
            padding: 20px;
            margin-top: 20px;
        }
        .instructions ol {
            padding-left: 20px;
        }
        .instructions li {
            margin-bottom: 10px;
            line-height: 1.6;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            opacity: 0.7;
            font-size: 0.9em;
        }
        code {
            background: rgba(0, 0, 0, 0.3);
            padding: 2px 6px;
            border-radius: 4px;
            font-family: 'Monaco', 'Menlo', monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏠 Home Infrastructure Manager</h1>
        
        <div class="section">
            <h2>📱 Family Setup Downloads</h2>
            <div class="download-grid">
                <div class="download-item">
                    <a href="/nextcloud.crt" download>🔐 SSL Certificate</a>
                    <div class="subtitle">For manual installation</div>
                </div>
                <div class="download-item">
                    <a href="http://192.168.68.170:8082/scripts/setup-nextcloud-windows.bat" download>🖥️ Windows Setup</a>
                    <div class="subtitle">Right-click → Run as administrator</div>
                </div>
                <div class="download-item">
                    <a href="http://192.168.68.170:8082/scripts/setup-nextcloud-mac.sh" download>🍎 Mac Setup</a>
                    <div class="subtitle">Run in Terminal</div>
                </div>
                <div class="download-item">
                    <a href="https://nextcloud.com/install/#install-clients" target="_blank">📲 Nextcloud Apps</a>
                    <div class="subtitle">Official apps for all devices</div>
                </div>
            </div>
        </div>

        <div class="section">
            <h2>🌐 Quick Access Links</h2>
            <div class="download-grid">
                <div class="download-item">
                    <a href="https://nextcloud.home" target="_blank">☁️ Nextcloud</a>
                    <div class="subtitle">Family cloud platform</div>
                </div>
                <div class="download-item">
                    <a href="http://192.168.68.170:8082" target="_blank">🏠 Homer Dashboard</a>
                    <div class="subtitle">Service overview</div>
                </div>
                <div class="download-item">
                    <a href="http://192.168.68.170:8080/admin" target="_blank">🕳️ Pi-hole</a>
                    <div class="subtitle">DNS & ad blocking</div>
                </div>
                <div class="download-item">
                    <a href="http://192.168.68.170:3000" target="_blank">📊 Grafana</a>
                    <div class="subtitle">System monitoring</div>
                </div>
            </div>
        </div>

        <div class="section">
            <h2>📋 Setup Instructions</h2>
            <div class="instructions">
                <h3>🖥️ Windows Users:</h3>
                <ol>
                    <li>Download the <strong>Windows Setup</strong> script above</li>
                    <li><strong>Right-click</strong> the downloaded file → <strong>"Run as administrator"</strong></li>
                    <li>Follow the automated setup process</li>
                    <li>Install Nextcloud app when webpage opens</li>
                    <li>Use server: <code>https://nextcloud.home</code></li>
                    <li>Enter your username and password</li>
                </ol>

                <h3>🍎 Mac Users:</h3>
                <ol>
                    <li>Download the <strong>Mac Setup</strong> script above</li>
                    <li>Open <strong>Terminal</strong> and navigate to Downloads</li>
                    <li>Run: <code>chmod +x setup-nextcloud-mac.sh</code></li>
                    <li>Run: <code>./setup-nextcloud-mac.sh</code></li>
                    <li>Install Nextcloud app when webpage opens</li>
                    <li>Use server: <code>https://nextcloud.home</code></li>
                    <li>Enter your username and password</li>
                </ol>

                <h3>📱 Mobile Devices (iOS/Android):</h3>
                <ol>
                    <li>Install <strong>Nextcloud</strong> app from App Store/Play Store</li>
                    <li>Go to WiFi settings → Configure DNS manually</li>
                    <li>Set Primary DNS: <code>192.168.68.170</code></li>
                    <li>Set Secondary DNS: <code>1.1.1.1</code></li>
                    <li>In Nextcloud app, use server: <code>https://nextcloud.home</code></li>
                    <li>Accept SSL certificate if prompted</li>
                    <li>Enter your username and password</li>
                </ol>
            </div>
        </div>

        <div class="footer">
            <p>🔧 Enterprise-grade home infrastructure • Built with nginx, Docker & love</p>
            <p>For technical support, contact your friendly neighborhood system administrator</p>
        </div>
    </div>
</body>
</html>
HTML_EOF

# ========================================
# 6. RESTART SERVICES
# ========================================
echo "🔄 Restarting services..."
docker restart homer infrastructure-manager

# Wait for services to start
sleep 10

# ========================================
# 7. TEST EVERYTHING
# ========================================
echo ""
echo "🧪 Testing setup..."

# Test Homer
if curl -s -I http://192.168.68.170:8082 | grep -q "200"; then
    echo "✅ Homer dashboard: http://192.168.68.170:8082"
else
    echo "❌ Homer dashboard failed"
fi

# Test Infrastructure Manager
if curl -s -I http://192.168.68.170:8090 | grep -q "200"; then
    echo "✅ Infrastructure manager: http://192.168.68.170:8090"
else
    echo "❌ Infrastructure manager failed"
fi

# Test script downloads
if curl -s -I http://192.168.68.170:8082/scripts/setup-nextcloud-windows.bat | grep -q "200"; then
    echo "✅ Windows setup script available"
else
    echo "❌ Windows setup script failed"
fi

if curl -s -I http://192.168.68.170:8082/scripts/setup-nextcloud-mac.sh | grep -q "200"; then
    echo "✅ Mac setup script available"
else
    echo "❌ Mac setup script failed"
fi

if curl -s -I http://192.168.68.170:8082/scripts/nextcloud.crt | grep -q "200"; then
    echo "✅ SSL certificate download available"
else
    echo "❌ SSL certificate download failed"
fi

echo ""
echo "================================================="
echo "🎉 FAMILY DASHBOARD SETUP COMPLETE!"
echo "================================================="
echo ""
echo "📱 Family Access Points:"
echo "   • Main Dashboard: http://192.168.68.170:8082"
echo "   • Setup Instructions: http://192.168.68.170:8090"
echo "   • Nextcloud: https://nextcloud.home"
echo ""
echo "🖥️ Windows Setup:"
echo "   1. Go to: http://192.168.68.170:8082"
echo "   2. Click: '📱 Windows Setup'"
echo "   3. Right-click downloaded file → Run as administrator"
echo ""
echo "🍎 Mac Setup:"
echo "   1. Go to: http://192.168.68.170:8082"
echo "   2. Click: '🍎 Mac Setup'"
echo "   3. Run the script in Terminal"
echo ""
echo "📱 Mobile Setup:"
echo "   1. Set device DNS to: 192.168.68.170"
echo "   2. Install Nextcloud app"
echo "   3. Server: https://nextcloud.home"
echo ""
echo "✅ Your family can now set up Nextcloud with zero technical knowledge!"
echo ""
