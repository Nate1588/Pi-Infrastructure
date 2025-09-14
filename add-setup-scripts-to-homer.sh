<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Home Infrastructure Manager</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            max-width: 800px;
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
        }
        .download-item .subtitle {
            font-size: 0.9em;
            opacity: 0.8;
            margin-top: 5px;
        }
        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }
        .status-item {
            background: rgba(255, 255, 255, 0.15);
            border-radius: 8px;
            padding: 15px;
            text-align: center;
        }
        .status-online {
            border-left: 4px solid #4CAF50;
        }
        .status-offline {
            border-left: 4px solid #f44336;
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
                    <a href="http://homer.home/scripts/setup-nextcloud-windows.bat" download>🖥️ Windows Setup</a>
                    <div class="subtitle">Automated setup script</div>
                </div>
                <div class="download-item">
                    <a href="http://homer.home/scripts/setup-nextcloud-mac.sh" download>🍎 Mac Setup</a>
                    <div class="subtitle">Automated setup script</div>
                </div>
                <div class="download-item">
                    <a href="https://nextcloud.com/install/#install-clients" target="_blank">📲 Nextcloud Apps</a>
                    <div class="subtitle">Official desktop & mobile apps</div>
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
                    <a href="http://homer.home" target="_blank">🏠 Homer Dashboard</a>
                    <div class="subtitle">Service overview</div>
                </div>
                <div class="download-item">
                    <a href="http://pihole.home" target="_blank">🕳️ Pi-hole</a>
                    <div class="subtitle">DNS & ad blocking</div>
                </div>
                <div class="download-item">
                    <a href="http://grafana.home" target="_blank">📊 Grafana</a>
                    <div class="subtitle">System monitoring</div>
                </div>
            </div>
        </div>

        <div class="section">
            <h2>📋 Setup Instructions</h2>
            <div class="instructions">
                <h3>For Windows Users:</h3>
                <ol>
                    <li>Download the <strong>Windows Setup</strong> script above</li>
                    <li>Right-click the downloaded file → "Run as administrator"</li>
                    <li>Follow the automated setup process</li>
                    <li>Install Nextcloud app when prompted</li>
                    <li>Use server: <code>https://nextcloud.home</code></li>
                </ol>

                <h3>For Mac Users:</h3>
                <ol>
                    <li>Download the <strong>Mac Setup</strong> script above</li>
                    <li>Open Terminal and run: <code>chmod +x setup-nextcloud-mac.sh</code></li>
                    <li>Run: <code>./setup-nextcloud-mac.sh</code></li>
                    <li>Install Nextcloud app when prompted</li>
                    <li>Use server: <code>https://nextcloud.home</code></li>
                </ol>

                <h3>For Mobile Devices:</h3>
                <ol>
                    <li>Install Nextcloud app from App Store/Play Store</li>
                    <li>Configure device DNS: Primary <code>192.168.68.170</code></li>
                    <li>Use server: <code>https://nextcloud.home</code></li>
                    <li>Accept SSL certificate if prompted</li>
                </ol>
            </div>
        </div>

        <div class="footer">
            <p>🔧 Enterprise-grade home infrastructure • Built with nginx, Docker & love</p>
            <p>For technical support, contact the system administrator</p>
        </div>
    </div>
</body>
</html>
