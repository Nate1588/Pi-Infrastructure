#!/bin/bash

# Complete file replacement script
# Run this from ~/pi-infrastructure/config/

set -e

echo "🔄 Completely replacing all files with nginx setup..."

# Stop all services
docker compose down --remove-orphans

# Create directories
mkdir -p data/nginx/{conf.d,ssl}
mkdir -p data/etc-dnsmasq.d

# Replace docker-compose.yml completely
cat > docker-compose.yml << 'COMPOSE_EOF'
version: '3.8'

services:
  # nginx reverse proxy for HTTPS and clean domains
  nginx-proxy:
    container_name: nginx-proxy
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - './data/nginx/nginx.conf:/etc/nginx/nginx.conf:ro'
      - './data/nginx/conf.d:/etc/nginx/conf.d:ro'
      - './data/nginx/ssl:/etc/nginx/ssl:ro'
    restart: unless-stopped
    networks:
      - gateway_net
    depends_on:
      - pihole

  # Pi-hole DNS server with ad blocking
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    platform: linux/arm64
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "8080:80"
    environment:
      TZ: 'Australia/Perth'
      WEBPASSWORD: 'admin123'
      PIHOLE_DNS_: '1.1.1.1;1.0.0.1'
      DNSMASQ_LISTENING: 'all'
      FTLCONF_LOCAL_IPV4: '192.168.68.170'
      REV_SERVER: 'true'
      REV_SERVER_DOMAIN: 'local'
      REV_SERVER_TARGET: '192.168.68.1'
      REV_SERVER_CIDR: '192.168.68.0/24'
    volumes:
      - './data/etc-pihole/:/etc/pihole/'
      - './data/etc-dnsmasq.d/:/etc/dnsmasq.d/'
    restart: unless-stopped
    networks:
      - gateway_net

  # Service dashboard
  homer:
    container_name: homer
    image: b4bz/homer:latest
    platform: linux/arm64
    ports:
      - "8082:8080"
    volumes:
      - './data/homer:/www/assets'
    restart: unless-stopped
    networks:
      - gateway_net

  # Grafana monitoring dashboards  
  grafana:
    container_name: grafana
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin123
      GF_INSTALL_PLUGINS: grafana-piechart-panel
    volumes:
      - grafana_data:/var/lib/grafana
      - './data/grafana/provisioning:/etc/grafana/provisioning'
    restart: unless-stopped
    networks:
      - gateway_net

  # Prometheus metrics collection
  prometheus:
    container_name: prometheus
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - prometheus_data:/prometheus
      - './data/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml'
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    restart: unless-stopped
    networks:
      - gateway_net

  # Container management
  portainer:
    container_name: portainer
    image: portainer/portainer-ce:latest
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    restart: unless-stopped
    networks:
      - gateway_net

  # Service monitoring
  uptime-kuma:
    container_name: uptime-kuma
    image: louislam/uptime-kuma:latest
    ports:
      - "3001:3001"
    volumes:
      - uptime_kuma_data:/app/data
    restart: unless-stopped
    networks:
      - gateway_net

  # Alert manager
  alertmanager:
    container_name: alertmanager
    image: prom/alertmanager:latest
    ports:
      - "9093:9093"
    volumes:
      - './data/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml'
    restart: unless-stopped
    networks:
      - gateway_net

  # System metrics exporter
  node-exporter:
    container_name: node-exporter
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    restart: unless-stopped
    networks:
      - gateway_net

  # Container metrics
  cadvisor:
    container_name: cadvisor
    image: gcr.io/cadvisor/cadvisor:latest
    ports:
      - "8081:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    privileged: true
    restart: unless-stopped
    networks:
      - gateway_net

  # Pi-hole metrics
  pihole-exporter:
    container_name: pihole-exporter
    image: ekofr/pihole-exporter:latest
    ports:
      - "9617:9617"
    environment:
      PIHOLE_HOSTNAME: pihole
      PIHOLE_PASSWORD: admin123
    restart: unless-stopped
    networks:
      - gateway_net
    depends_on:
      - pihole

  # Service health checks
  blackbox-exporter:
    container_name: blackbox-exporter
    image: prom/blackbox-exporter:latest
    ports:
      - "9115:9115"
    volumes:
      - './data/blackbox/blackbox.yml:/etc/blackbox_exporter/config.yml'
    restart: unless-stopped
    networks:
      - gateway_net

  # Recursive DNS server
  unbound:
    container_name: unbound
    image: klutchell/unbound:latest
    ports:
      - "5353:53/tcp"
      - "5353:53/udp"
    volumes:
      - './data/unbound:/opt/unbound/etc/unbound/'
    restart: unless-stopped
    networks:
      - gateway_net

  # Infrastructure management interface
  infrastructure-manager:
    container_name: infrastructure-manager
    image: nginx:alpine
    ports:
      - "8090:80"
    volumes:
      - './data/infrastructure-manager:/usr/share/nginx/html'
    restart: unless-stopped
    networks:
      - gateway_net

  # Auto-update containers
  watchtower:
    container_name: watchtower
    image: containrrr/watchtower:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      WATCHTOWER_CLEANUP: true
      WATCHTOWER_SCHEDULE: "0 0 2 * * MON"  # Monday 2 AM
    restart: unless-stopped
    networks:
      - gateway_net

volumes:
  grafana_data:
  prometheus_data:
  portainer_data:
  uptime_kuma_data:

networks:
  gateway_net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
COMPOSE_EOF

# Replace nginx.conf completely
cat > data/nginx/nginx.conf << 'NGINX_EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    server_tokens off;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        application/atom+xml
        application/geo+json
        application/javascript
        application/x-javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rdf+xml
        application/rss+xml
        application/xhtml+xml
        application/xml
        font/eot
        font/otf
        font/ttf
        image/svg+xml
        text/css
        text/javascript
        text/plain
        text/xml;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    include /etc/nginx/conf.d/*.conf;
}
NGINX_EOF

# Replace nextcloud.conf completely
cat > data/nginx/conf.d/nextcloud.conf << 'NEXTCLOUD_EOF'
server {
    listen 80;
    server_name nextcloud.home cloud.home;
    
    location /.well-known/acme-challenge/ {
        return 404;
    }
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name nextcloud.home cloud.home;

    ssl_certificate /etc/nginx/ssl/nextcloud.crt;
    ssl_certificate_key /etc/nginx/ssl/nextcloud.key;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy no-referrer;

    location / {
        proxy_pass http://192.168.68.133:11000;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-Ssl on;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        proxy_buffering off;
        proxy_request_buffering off;
        
        client_max_body_size 100G;
        proxy_max_temp_file_size 2048m;
    }

    location = /.well-known/carddav {
        return 301 $scheme://$host/remote.php/dav;
    }
    
    location = /.well-known/caldav {
        return 301 $scheme://$host/remote.php/dav;
    }
    
    location = /.well-known/webfinger {
        return 301 $scheme://$host/index.php/.well-known/webfinger;
    }
    
    location = /.well-known/nodeinfo {
        return 301 $scheme://$host/index.php/.well-known/nodeinfo;
    }
}
NEXTCLOUD_EOF

# Replace DNS config completely
cat > data/etc-dnsmasq.d/01-friendly-domains.conf << 'DNS_EOF'
address=/nextcloud.home/192.168.68.170
address=/cloud.home/192.168.68.170
address=/pihole.home/192.168.68.170
address=/grafana.home/192.168.68.170
address=/prometheus.home/192.168.68.170
address=/homer.home/192.168.68.170
address=/portainer.home/192.168.68.170
address=/uptime.home/192.168.68.170
address=/monitoring.home/192.168.68.170

address=/amy.home/192.168.68.133
address=/nas.home/192.168.68.133
address=/synology.home/192.168.68.133
address=/immich.home/192.168.68.133
address=/photos.home/192.168.68.133
address=/inventory.home/192.168.68.133
address=/homebox.home/192.168.68.133

address=/ha.home/192.168.68.129
address=/homeassistant.home/192.168.68.129

address=/holt.home/192.168.68.116
address=/backup.home/192.168.68.116
DNS_EOF

# Generate SSL certificates
cd data/nginx/ssl

if [[ ! -f nextcloud.crt ]]; then
    openssl genrsa -out nextcloud.key 2048

    cat > nextcloud.conf << 'SSL_EOF'
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=AU
ST=Western Australia
L=Perth
O=Home Infrastructure
OU=IT Department
CN=nextcloud.home

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = nextcloud.home
DNS.2 = cloud.home
DNS.3 = *.home
DNS.4 = localhost
IP.1 = 192.168.68.170
IP.2 = 127.0.0.1
SSL_EOF

    openssl req -new -x509 -key nextcloud.key -out nextcloud.crt -days 3650 -config nextcloud.conf -extensions v3_req
    chmod 600 nextcloud.key
    chmod 644 nextcloud.crt
    rm nextcloud.conf
    echo "✅ SSL certificates generated"
else
    echo "✅ SSL certificates already exist"
fi

cd ../../..

# Start services
echo "🚀 Starting nginx infrastructure..."
docker compose up -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 30

echo ""
echo "📊 Service status:"
docker compose ps

echo ""
echo "🧪 Testing nginx setup..."
curl -k -I https://nextcloud.home

echo ""
echo "✅ Complete file replacement finished!"
echo ""
echo "🖥️  Desktop app settings:"
echo "   Server: https://nextcloud.home"
echo "   (Accept SSL certificate warning)"
echo ""
