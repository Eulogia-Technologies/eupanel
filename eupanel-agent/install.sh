#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  EuPanel Server Installer
#  Tested on: Ubuntu 22.04 LTS / 24.04 LTS
#  Run as root: bash install.sh
# ─────────────────────────────────────────────────────────────
set -e

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'
BLUE='\033[0;34m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${BLUE}▸${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
error()   { echo -e "${RED}✗${NC} $1"; exit 1; }
section() { echo -e "\n${BOLD}── $1 ──────────────────────────────────${NC}"; }

# ── Root check ────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && error "Run as root: sudo bash install.sh"

# ── OS check ─────────────────────────────────────────────────
. /etc/os-release
[[ "$ID" != "ubuntu" ]] && error "Ubuntu 22.04 or 24.04 required"

# ── Versions & Paths ──────────────────────────────────────────
PHP_VERSION="8.3"
PMA_VERSION="5.2.1"
GO_VERSION="1.22.3"
AGENT_PORT="${AGENT_PORT:-7820}"
AGENT_SECRET="${AGENT_SECRET:-$(openssl rand -hex 32)}"
MYSQL_ROOT_PASS="${MYSQL_ROOT_PASS:-$(openssl rand -hex 24)}"
INSTALL_DIR="/opt/eupanel-agent"
PMA_DIR="/var/www/phpmyadmin"
PMA_TOKEN="pma_$(openssl rand -hex 10)"
WEB_ROOT="/var/www"

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║      EuPanel Server Installer        ║"
echo "  ║      Ubuntu $(lsb_release -rs) — $(date +%Y)               ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"

# ─────────────────────────────────────────────────────────────
section "System Update"
# ─────────────────────────────────────────────────────────────
info "Updating package lists..."
apt-get update -qq
apt-get install -y -qq \
    curl wget git unzip tar openssl software-properties-common \
    ca-certificates gnupg lsb-release ufw

# ─────────────────────────────────────────────────────────────
section "Nginx"
# ─────────────────────────────────────────────────────────────
info "Installing Nginx..."
apt-get install -y -qq nginx

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Create snippets dir
mkdir -p /etc/nginx/snippets

# Write security headers snippet
cat > /etc/nginx/snippets/eupanel-security.conf <<'EOF'
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
EOF

systemctl enable nginx
systemctl start nginx
success "Nginx installed"

# ─────────────────────────────────────────────────────────────
section "PHP ${PHP_VERSION}"
# ─────────────────────────────────────────────────────────────
info "Adding PHP repository..."
add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1
apt-get update -qq

info "Installing PHP ${PHP_VERSION} + extensions..."
apt-get install -y -qq \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-redis \
    php${PHP_VERSION}-imagick 2>/dev/null || true

systemctl enable php${PHP_VERSION}-fpm
systemctl start php${PHP_VERSION}-fpm
success "PHP ${PHP_VERSION} installed"

# ─────────────────────────────────────────────────────────────
section "MySQL (MariaDB)"
# ─────────────────────────────────────────────────────────────
info "Installing MariaDB..."
apt-get install -y -qq mariadb-server mariadb-client

systemctl enable mariadb
systemctl start mariadb

# Secure MariaDB
info "Securing MariaDB..."
mysql -u root <<MYSQL_SCRIPT
  ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';
  DELETE FROM mysql.user WHERE User='';
  DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
  DROP DATABASE IF EXISTS test;
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
  FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Save root password
mkdir -p /etc/eupanel
echo "${MYSQL_ROOT_PASS}" > /etc/eupanel/mysql_root_pass
chmod 600 /etc/eupanel/mysql_root_pass

success "MariaDB installed and secured"

# ─────────────────────────────────────────────────────────────
section "phpMyAdmin ${PMA_VERSION}"
# ─────────────────────────────────────────────────────────────
info "Downloading phpMyAdmin ${PMA_VERSION}..."

PMA_URL="https://files.phpmyadmin.net/phpMyAdmin/${PMA_VERSION}/phpMyAdmin-${PMA_VERSION}-all-languages.tar.gz"
wget -q "$PMA_URL" -O /tmp/phpmyadmin.tar.gz

info "Extracting phpMyAdmin..."
tar -xzf /tmp/phpmyadmin.tar.gz -C /var/www/
mv "/var/www/phpMyAdmin-${PMA_VERSION}-all-languages" "$PMA_DIR"
rm /tmp/phpmyadmin.tar.gz

# Generate blowfish secret
BLOWFISH=$(openssl rand -hex 32)

# Write phpMyAdmin config
cat > "${PMA_DIR}/config.inc.php" <<EOF
<?php
\$cfg['blowfish_secret'] = '${BLOWFISH}';
\$i = 0;
\$i++;
\$cfg['Servers'][\$i]['auth_type']       = 'cookie';
\$cfg['Servers'][\$i]['host']            = '127.0.0.1';
\$cfg['Servers'][\$i]['connect_type']    = 'tcp';
\$cfg['Servers'][\$i]['compress']        = false;
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;
\$cfg['UploadDir']          = '/tmp/phpmyadmin-upload';
\$cfg['SaveDir']            = '/tmp/phpmyadmin-save';
\$cfg['SendErrorReports']   = 'never';
\$cfg['ShowPhpInfo']        = false;
\$cfg['ShowServerInfo']     = false;
\$cfg['PmaAbsoluteUri']     = '/${PMA_TOKEN}/';
EOF

# Create upload/save dirs
mkdir -p /tmp/phpmyadmin-upload /tmp/phpmyadmin-save
chown -R www-data:www-data "$PMA_DIR"

# Save PMA token
echo "${PMA_TOKEN}" > /etc/eupanel/pma_token
chmod 600 /etc/eupanel/pma_token

# Write nginx config for phpMyAdmin
cat > /etc/nginx/snippets/eupanel-pma.conf <<EOF
# phpMyAdmin — secret URL: /${PMA_TOKEN}/
location = /${PMA_TOKEN} {
    return 301 /${PMA_TOKEN}/;
}
location /${PMA_TOKEN}/ {
    alias ${PMA_DIR}/;
    index index.php;

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$request_filename;
        include fastcgi_params;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2)\$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    # Block access to sensitive files
    location ~ /(libraries|setup|sql|vendor)/ {
        deny all;
        return 404;
    }
}
EOF

# Create a default server block that includes PMA
cat > /etc/nginx/sites-available/eupanel-default.conf <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /var/www/html;
    index index.php index.html;

    include snippets/eupanel-security.conf;
    include snippets/eupanel-pma.conf;

    location / {
        return 200 'EuPanel Server Ready';
        add_header Content-Type text/plain;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
    }
}
EOF

ln -sf /etc/nginx/sites-available/eupanel-default.conf /etc/nginx/sites-enabled/
nginx -t && nginx -s reload
success "phpMyAdmin installed at /${PMA_TOKEN}/"

# ─────────────────────────────────────────────────────────────
section "Let's Encrypt (Certbot)"
# ─────────────────────────────────────────────────────────────
info "Installing Certbot..."
apt-get install -y -qq certbot python3-certbot-nginx
success "Certbot installed"

# ─────────────────────────────────────────────────────────────
section "Go ${GO_VERSION}"
# ─────────────────────────────────────────────────────────────
if ! command -v go &>/dev/null; then
    info "Installing Go ${GO_VERSION}..."
    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    export PATH=$PATH:/usr/local/go/bin
    success "Go ${GO_VERSION} installed"
else
    success "Go already installed: $(go version)"
fi

# ─────────────────────────────────────────────────────────────
section "EuPanel Agent"
# ─────────────────────────────────────────────────────────────
info "Building EuPanel Agent..."
mkdir -p "$INSTALL_DIR"

# Clone and build agent
if [[ -d /tmp/eupanel-agent-src ]]; then
    rm -rf /tmp/eupanel-agent-src
fi
git clone https://github.com/eucloudhost/eupanel-agent /tmp/eupanel-agent-src
cd /tmp/eupanel-agent-src
/usr/local/go/bin/go mod tidy
/usr/local/go/bin/go build -ldflags="-s -w" -o "${INSTALL_DIR}/eupanel-agent" .
cd /

# Write env config
cat > "${INSTALL_DIR}/.env" <<EOF
AGENT_PORT=${AGENT_PORT}
AGENT_SECRET=${AGENT_SECRET}
AGENT_WEBROOT=${WEB_ROOT}
AGENT_NGINX_SITES=/etc/nginx/sites-available
AGENT_NGINX_BIN=/usr/sbin/nginx
AGENT_CERTBOT_BIN=/usr/bin/certbot
AGENT_PHP_VERSION=${PHP_VERSION}
AGENT_MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS}
EOF
chmod 600 "${INSTALL_DIR}/.env"

# Write systemd service
cat > /etc/systemd/system/eupanel-agent.service <<EOF
[Unit]
Description=EuPanel Agent
After=network.target nginx.service mariadb.service

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
EnvironmentFile=${INSTALL_DIR}/.env
ExecStart=${INSTALL_DIR}/eupanel-agent
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable eupanel-agent
systemctl start eupanel-agent
success "EuPanel Agent started on port ${AGENT_PORT}"

# ─────────────────────────────────────────────────────────────
section "Firewall (UFW)"
# ─────────────────────────────────────────────────────────────
info "Configuring firewall..."
ufw --force reset > /dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
# Agent port is NOT opened — only accessible from localhost
ufw --force enable
success "Firewall configured (agent port ${AGENT_PORT} is localhost-only)"

# ─────────────────────────────────────────────────────────────
section "Cleanup"
# ─────────────────────────────────────────────────────────────
apt-get autoremove -y -qq
apt-get clean -qq
rm -rf /tmp/eupanel-agent-src

# ─────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║          EuPanel Installation Complete!          ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "  ${BOLD}Server IP${NC}         : ${SERVER_IP}"
echo ""
echo -e "  ${BOLD}phpMyAdmin URL${NC}    : http://${SERVER_IP}/${PMA_TOKEN}/"
echo -e "  ${BOLD}MySQL root pass${NC}   : ${MYSQL_ROOT_PASS}"
echo ""
echo -e "  ${BOLD}EuPanel Agent${NC}"
echo -e "    Host            : ${SERVER_IP}"
echo -e "    Port            : ${AGENT_PORT} (localhost only)"
echo -e "    Secret key      : ${AGENT_SECRET}"
echo ""
echo -e "  ${YELLOW}Add this server in EuPanel with the host, port and secret above.${NC}"
echo ""
echo -e "  ${BOLD}Credentials saved at:${NC}"
echo -e "    /etc/eupanel/mysql_root_pass"
echo -e "    /etc/eupanel/pma_token"
echo -e "    /opt/eupanel-agent/.env"
echo ""
echo -e "  ${YELLOW}⚠  Save these credentials — they won't be shown again.${NC}"
echo ""
