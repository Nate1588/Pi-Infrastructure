#!/bin/bash

echo "🔧 Quick Fix - Adding Uptime Kuma First"
echo "======================================="

cd ~/pi-infrastructure/config

# First, let's just add Uptime Kuma manually to test
echo "📝 Adding Uptime Kuma service to docker-compose.yml..."

# Backup first
cp docker-compose.yml docker-compose.yml.backup-$(date +%H%M%S)

# Add Uptime Kuma service manually
cat >> docker-compose.yml << 'EOF'

  # Service uptime monitoring
  uptime-kuma:
    container_name: uptime-kuma
    image: louislam/uptime-kuma:latest
    ports:
      - "3001:3001"
    volumes:
      - './uptime-kuma:/app/data'
    restart: unless-stopped
    networks:
      - monitoring_net
EOF

echo "✅ Added Uptime Kuma to docker-compose.yml"

# Create directory
mkdir -p uptime-kuma
echo "✅ Created uptime-kuma directory"

# Test YAML syntax
echo "🔍 Testing YAML syntax..."
if docker compose config > /dev/null 2>&1; then
    echo "✅ YAML syntax is valid"
    
    # Start the service
    echo "🚀 Starting Uptime Kuma..."
    docker compose up -d uptime-kuma
    
    echo "⏳ Waiting 15 seconds for service to start..."
    sleep 15
    
    # Check status
    echo "📊 Service status:"
    docker compose ps uptime-kuma
    
    echo ""
    echo "🎉 SUCCESS! Uptime Kuma should be available at:"
    echo "   http://100.72.38.61:3001"
    echo ""
    echo "✅ Test this URL, then we can add the next service!"
    
else
    echo "❌ YAML syntax error. Restoring backup..."
    mv docker-compose.yml.backup-* docker-compose.yml
    echo "🔙 Backup restored"
    echo ""
    echo "📋 Error details:"
    docker compose config 2>&1 | head -10
fi
