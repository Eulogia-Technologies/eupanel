#!/usr/bin/env bash
# =============================================================================
#  EuPanel — Complete One-Shot Installer
#  Ubuntu 22.04 / 24.04 LTS
#
#  Installs: nginx · PHP 8.3 · MariaDB · phpMyAdmin · PowerDNS · vsftpd
#            Certbot · Go · Dart · Node.js 20 · Tinyfilemanager
#            EuPanel backend (Dart/Flint) · frontend (Next.js) · agent (Go)
#
#  Usage:
#    curl -fsSL https://raw.githubusercontent.com/Eulogia-Technologies/eupanel/master/install.sh | sudo bash
#  — or —
#    sudo bash install.sh
# =============================================================================
set -euo pipefail
IFS=$'\n\t'

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()     { echo -e "${GREEN}[✓]${NC} $*"; }
info()    { echo -e "${BLUE}[→]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
die()     { echo -e "${RED}[✗]${NC} $*"; exit 1; }
section() { echo -e "\n${BOLD}${CYAN}━━━  $*  ━━━${NC}\n"; }
gen_pass(){ openssl rand -base64 32 | tr -d '=/+' | cut -c1-28; }
gen_hex() { openssl rand -hex "$1"; }

# ── Sanity checks ─────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && die "Please run as root:  sudo bash install.sh"
[[ -f /etc/os-release ]] || die "Cannot detect OS."
# shellcheck source=/dev/null
source /etc/os-release
[[ "$ID" != "ubuntu" ]] && die "Only Ubuntu is supported (detected: $ID $VERSION_ID)."
[[ "$VERSION_ID" != "22.04" && "$VERSION_ID" != "24.04" ]] && \
    warn "Tested on 22.04/24.04. Continuing on $VERSION_ID…"

# ── Version pins ──────────────────────────────────────────────────────────────
GO_VERSION="1.22.3"
NODE_MAJOR="20"
PHP_VERSION="8.3"
PMA_VERSION="5.2.1"
REPO_URL="https://github.com/Eulogia-Technologies/eupanel.git"
INSTALL_DIR="/opt/eupanel"
BACKEND_PORT=4054
FRONTEND_PORT=3000
AGENT_PORT=7820

# =============================================================================
#  COLLECT INPUT
# =============================================================================
section "EuPanel Installer"

SERVER_IP=$(curl -4 -fsSL --max-time 5 ifconfig.me 2>/dev/null \
            || hostname -I | awk '{print $1}')

echo -e "${BOLD}Detected server IP: ${CYAN}${SERVER_IP}${NC}"
echo ""

# Write prompts directly to /dev/tty and read from /dev/tty so questions are
# always visible whether the script is run directly or piped via curl | bash.
TTY=/dev/tty

printf "Panel domain (e.g. panel.example.com) — blank to use IP: " > $TTY
read -r PANEL_DOMAIN < $TTY
PANEL_DOMAIN="${PANEL_DOMAIN:-$SERVER_IP}"

printf "Admin e-mail (used for SSL + first admin account): " > $TTY
read -r ADMIN_EMAIL < $TTY
[[ -z "$ADMIN_EMAIL" ]] && die "Admin e-mail is required."

printf "Admin username [admin]: " > $TTY
read -r ADMIN_USER < $TTY
ADMIN_USER="${ADMIN_USER:-admin}"

printf "Admin password (blank = auto-generate): " > $TTY
read -rs ADMIN_PASS < $TTY; echo > $TTY
ADMIN_PASS="${ADMIN_PASS:-$(gen_pass)}"

USE_SSL="n"
if [[ "$PANEL_DOMAIN" != "$SERVER_IP" ]]; then
    printf "Issue Let's Encrypt SSL for %s? (y/N): " "$PANEL_DOMAIN" > $TTY
    read -r USE_SSL < $TTY
    # Accept "yes", "y", "Y", "YES"
    [[ "${USE_SSL,,}" == "yes" ]] && USE_SSL="y"
fi

echo ""
echo -e "${BOLD}Summary${NC}"
echo "  Install dir : $INSTALL_DIR"
if [[ "${USE_SSL,,}" == "y" ]]; then
    echo "  Panel URL   : https://${PANEL_DOMAIN}  (SSL: YES)"
else
    echo "  Panel URL   : http://${PANEL_DOMAIN}  (SSL: NO)"
fi
echo "  Admin user  : $ADMIN_USER  <$ADMIN_EMAIL>"
echo ""
printf "Proceed? (y/N): " > $TTY
read -r _CONFIRM < $TTY
[[ "${_CONFIRM,,}" != "y" ]] && exit 0

# ── Generate secrets ──────────────────────────────────────────────────────────
DB_PASS=$(gen_pass)
JWT_SECRET=$(gen_hex 32)
AGENT_SECRET=$(gen_hex 32)
PDNS_API_KEY=$(gen_hex 16)
PMA_TOKEN="pma_$(gen_hex 10)"

# =============================================================================
#  1. SYSTEM UPDATE + BASE PACKAGES
# =============================================================================
section "1 / 12 — System update & base packages"

export DEBIAN_FRONTEND=noninteractive
# Remove any broken Dart repo left from a previous install attempt
rm -f /usr/share/keyrings/dart.gpg /etc/apt/sources.list.d/dart_stable.list
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq \
    curl wget git unzip zip tar gnupg2 lsb-release ca-certificates \
    software-properties-common apt-transport-https \
    openssl ufw fail2ban cron jq

log "Base packages installed."

# =============================================================================
#  2. NGINX
# =============================================================================
section "2 / 12 — nginx"

apt-get install -y -qq nginx
systemctl enable --now nginx
log "nginx installed and running."

# =============================================================================
#  3. PHP 8.3 + FPM
# =============================================================================
section "3 / 12 — PHP ${PHP_VERSION}"

add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1
apt-get update -qq
apt-get install -y -qq \
    "php${PHP_VERSION}" \
    "php${PHP_VERSION}-fpm" \
    "php${PHP_VERSION}-mysql" \
    "php${PHP_VERSION}-mbstring" \
    "php${PHP_VERSION}-xml" \
    "php${PHP_VERSION}-curl" \
    "php${PHP_VERSION}-zip" \
    "php${PHP_VERSION}-gd" \
    "php${PHP_VERSION}-bcmath" \
    "php${PHP_VERSION}-intl" \
    "php${PHP_VERSION}-readline" \
    "php${PHP_VERSION}-cli"

systemctl enable --now "php${PHP_VERSION}-fpm"
log "PHP ${PHP_VERSION}-FPM installed."

# =============================================================================
#  4. MARIADB
# =============================================================================
section "4 / 12 — MariaDB"

apt-get install -y -qq mariadb-server
systemctl enable --now mariadb

# Secure MariaDB and create eupanel DB
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket;
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE IF NOT EXISTS \`eupanel\`
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'eupanel'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`eupanel\`.* TO 'eupanel'@'localhost';
FLUSH PRIVILEGES;
EOF

log "MariaDB secured. Database 'eupanel' + user created."

# =============================================================================
#  5. phpMyAdmin
# =============================================================================
section "5 / 12 — phpMyAdmin (secret URL)"

PMA_DIR="/var/www/phpmyadmin"
PMA_TAR="/tmp/phpmyadmin.tar.gz"
PMA_URL="https://files.phpmyadmin.net/phpMyAdmin/${PMA_VERSION}/phpMyAdmin-${PMA_VERSION}-all-languages.tar.gz"

if [[ ! -d "$PMA_DIR" ]]; then
    info "Downloading phpMyAdmin ${PMA_VERSION}…"
    wget -q "$PMA_URL" -O "$PMA_TAR"
    mkdir -p "$PMA_DIR"
    tar -xzf "$PMA_TAR" -C /var/www
    mv "/var/www/phpMyAdmin-${PMA_VERSION}-all-languages" "$PMA_DIR"
    rm -f "$PMA_TAR"
fi

PMA_BLOWFISH=$(gen_hex 32)
cat > "${PMA_DIR}/config.inc.php" <<PHP
<?php
\$cfg['blowfish_secret'] = '${PMA_BLOWFISH}';
\$i = 0;
\$i++;
\$cfg['Servers'][\$i]['auth_type']       = 'cookie';
\$cfg['Servers'][\$i]['host']            = '127.0.0.1';
\$cfg['Servers'][\$i]['connect_type']    = 'tcp';
\$cfg['Servers'][\$i]['compress']        = false;
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;
\$cfg['UploadDir'] = '';
\$cfg['SaveDir']   = '';
\$cfg['SendErrorReports']  = 'never';
\$cfg['ShowPhpInfo']       = false;
\$cfg['ShowServerInfo']    = false;
\$cfg['PmaAbsoluteUri']    = '/${PMA_TOKEN}/';
PHP

chown -R www-data:www-data "$PMA_DIR"
mkdir -p /etc/eupanel
echo "$PMA_TOKEN" > /etc/eupanel/pma_token
chmod 600 /etc/eupanel/pma_token
log "phpMyAdmin installed at /${PMA_TOKEN}/"

# =============================================================================
#  6. PowerDNS (Authoritative + API)
# =============================================================================
section "6 / 12 — PowerDNS"

apt-get install -y -qq pdns-server pdns-backend-mysql

# Create PowerDNS database + user
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`pdns\`
    CHARACTER SET latin1 COLLATE latin1_swedish_ci;
CREATE USER IF NOT EXISTS 'pdns'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`pdns\`.* TO 'pdns'@'localhost';
FLUSH PRIVILEGES;
EOF

# Import PowerDNS schema
PDNS_SCHEMA=$(find /usr/share/pdns-backend-mysql -name "*.sql" 2>/dev/null | head -1)
if [[ -n "$PDNS_SCHEMA" ]]; then
    mysql -u root pdns < "$PDNS_SCHEMA" 2>/dev/null || true
fi

cat > /etc/powerdns/pdns.conf <<PDNS
launch=gmysql
gmysql-host=127.0.0.1
gmysql-port=3306
gmysql-dbname=pdns
gmysql-user=pdns
gmysql-password=${DB_PASS}
gmysql-dnssec=yes

# API
api=yes
api-key=${PDNS_API_KEY}
webserver=yes
webserver-address=127.0.0.1
webserver-port=8081
webserver-allow-from=127.0.0.1

# Logging
loglevel=4
log-dns-queries=no

local-address=0.0.0.0
local-port=53
PDNS

systemctl enable --now pdns 2>/dev/null || systemctl restart pdns || true
log "PowerDNS installed. API on 127.0.0.1:8081."

# =============================================================================
#  7. vsftpd (FTP)
# =============================================================================
section "7 / 12 — vsftpd"

apt-get install -y -qq vsftpd libpam-pwdfile db-util

# Stop and reconfigure
systemctl stop vsftpd 2>/dev/null || true

mkdir -p /etc/vsftpd/users
touch /etc/vsftpd/virtual_users.txt
chmod 600 /etc/vsftpd/virtual_users.txt

cat > /etc/vsftpd.conf <<FTP
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/run/vsftpd/empty

# Virtual users
guest_enable=YES
guest_username=www-data
virtual_use_local_privs=YES
pam_service_name=vsftpd-virtual
user_config_dir=/etc/vsftpd/users
user_sub_token=\$USER

# Passive mode (adjust IP for your server)
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=50000
pasv_address=${SERVER_IP}

xferlog_file=/var/log/vsftpd.log
FTP

# PAM config for virtual users
cat > /etc/pam.d/vsftpd-virtual <<PAM
auth    required pam_userdb.so db=/etc/vsftpd/virtual_users
account required pam_userdb.so db=/etc/vsftpd/virtual_users
PAM

systemctl enable --now vsftpd
log "vsftpd installed with virtual users support."

# =============================================================================
#  8. Certbot
# =============================================================================
section "8 / 12 — Certbot"

apt-get install -y -qq certbot python3-certbot-nginx
log "Certbot installed."

# =============================================================================
#  9. LANGUAGE RUNTIMES  (Go · Dart · Node.js)
# =============================================================================
section "9 / 12 — Go, Dart, Node.js"

# ── Go ─────────────────────────────────────────────────────────────────────
if ! command -v go &>/dev/null || [[ "$(go version 2>/dev/null | awk '{print $3}')" != "go${GO_VERSION}" ]]; then
    info "Installing Go ${GO_VERSION}…"
    GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
    wget -q "https://go.dev/dl/${GO_TAR}" -O "/tmp/${GO_TAR}"
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "/tmp/${GO_TAR}"
    rm -f "/tmp/${GO_TAR}"
    ln -sf /usr/local/go/bin/go   /usr/local/bin/go
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
fi
log "Go $(go version | awk '{print $3}')."

# ── Dart ───────────────────────────────────────────────────────────────────
if ! command -v dart &>/dev/null; then
    info "Installing Dart SDK…"
    # Remove any stale/broken repo entry from a previous attempt
    rm -f /usr/share/keyrings/dart.gpg /etc/apt/sources.list.d/dart_stable.list
    # Key must be dearmored (binary) for signed-by to work
    curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub \
        | gpg --dearmor -o /usr/share/keyrings/dart.gpg
    echo "deb [signed-by=/usr/share/keyrings/dart.gpg] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main" \
        > /etc/apt/sources.list.d/dart_stable.list
    apt-get update -qq
    apt-get install -y -qq dart
fi
log "Dart $(dart --version 2>&1 | head -1)."

# ── Node.js ────────────────────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
    info "Installing Node.js ${NODE_MAJOR}…"
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - > /dev/null 2>&1
    apt-get install -y -qq nodejs
fi
log "Node.js $(node --version)  npm $(npm --version)."

# ── Permanent PATH for all runtimes ───────────────────────────────────────────
cat > /etc/profile.d/eupanel-paths.sh <<'PATHFILE'
# EuPanel runtime paths — added by installer
export PATH="$PATH:/usr/local/go/bin"        # Go
export PATH="$PATH:/usr/lib/dart/bin"         # Dart
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
PATHFILE
chmod 644 /etc/profile.d/eupanel-paths.sh

# Also apply to current session right now
export PATH="$PATH:/usr/local/go/bin:/usr/lib/dart/bin"
export GOPATH="/root/go"

log "Runtime paths written to /etc/profile.d/eupanel-paths.sh"

# =============================================================================
#  10. CLONE + BUILD EUPANEL
# =============================================================================
section "10 / 12 — Clone & build EuPanel"

# ── Clone ──────────────────────────────────────────────────────────────────
if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Updating existing installation…"
    git -C "$INSTALL_DIR" pull --rebase --autostash
else
    info "Cloning EuPanel from GitHub…"
    git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
fi
log "Repository ready at $INSTALL_DIR"

# ── Backend (.env) ─────────────────────────────────────────────────────────
cat > "${INSTALL_DIR}/backend/.env" <<ENV
APP_ENV=production
APP_PORT=${BACKEND_PORT}

DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=eupanel
DB_USER=eupanel
DB_PASS=${DB_PASS}

JWT_SECRET=${JWT_SECRET}

PDNS_API_URL=http://127.0.0.1:8081
PDNS_API_KEY=${PDNS_API_KEY}

AGENT_SECRET=${AGENT_SECRET}
AGENT_BASE_URL=http://127.0.0.1:${AGENT_PORT}

STORAGE_PATH=${INSTALL_DIR}/backend/storage

# GitHub OAuth (fill in after creating your OAuth App at github.com/settings/developers)
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
PANEL_BASE_URL=${PANEL_BASE_URL}
PANEL_FRONTEND_URL=${PANEL_BASE_URL}
ENV
chmod 600 "${INSTALL_DIR}/backend/.env"

# ── Backend: dart pub get ──────────────────────────────────────────────────
info "Installing Dart dependencies…"
export PATH="$PATH:/usr/lib/dart/bin"
(cd "${INSTALL_DIR}/backend" && dart pub get)
log "Dart dependencies resolved."

# ── Frontend (.env.local) ──────────────────────────────────────────────────
if [[ "${USE_SSL,,}" == "y" ]]; then
    PANEL_BASE_URL="https://${PANEL_DOMAIN}"
else
    PANEL_BASE_URL="http://${PANEL_DOMAIN}"
fi

cat > "${INSTALL_DIR}/frontend/.env.local" <<ENV
NEXT_PUBLIC_API_URL=${PANEL_BASE_URL}/api
NEXT_PUBLIC_PANEL_URL=${PANEL_BASE_URL}
ENV

# ── Frontend: npm build ────────────────────────────────────────────────────
info "Building Next.js frontend (this takes a minute)…"
(cd "${INSTALL_DIR}/frontend" && npm ci --silent && npm run build)
log "Frontend built."

# ── Agent: go build ────────────────────────────────────────────────────────
info "Building eupanel-agent…"
(
  cd "${INSTALL_DIR}/eupanel-agent"
  GOPATH="/root/go" go mod download
  GOPATH="/root/go" CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
      go build -ldflags="-s -w" -o /usr/local/bin/eupanel-agent .
)
log "eupanel-agent built → /usr/local/bin/eupanel-agent"

# ── Agent .env ─────────────────────────────────────────────────────────────
mkdir -p /etc/eupanel
cat > /etc/eupanel/agent.env <<ENV
AGENT_PORT=${AGENT_PORT}
AGENT_SECRET=${AGENT_SECRET}
AGENT_WEBROOT=/var/www
AGENT_NGINX_SITES=/etc/nginx/sites-available
AGENT_NGINX_BIN=/usr/sbin/nginx
AGENT_CERTBOT_BIN=/usr/bin/certbot
ENV
chmod 600 /etc/eupanel/agent.env

# =============================================================================
#  11. TINYFILEMANAGER
# =============================================================================
section "11 / 12 — File Manager"

FM_DIR="/var/www/filemanager"
mkdir -p "$FM_DIR"
wget -q \
    "https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php" \
    -O "${FM_DIR}/index.php"

# Configure: hash passwords, set root to /home
FM_PASS_HASH=$(php -r "echo password_hash('${ADMIN_PASS}', PASSWORD_DEFAULT);")
sed -i "s|'admin' => '\$2y\$10\$[^']*'|'${ADMIN_USER}' => '${FM_PASS_HASH}'|" \
    "${FM_DIR}/index.php" 2>/dev/null || true

# Set filemanager root to /home so panel users can browse their files
sed -i "s|define('FM_ROOT_PATH', FM_ROOT_URL)|define('FM_ROOT_PATH', '/home')|" \
    "${FM_DIR}/index.php" 2>/dev/null || true

chown -R www-data:www-data "$FM_DIR"
log "Tinyfilemanager installed at /filemanager/"

# =============================================================================
#  12. SYSTEMD SERVICES
# =============================================================================
section "12 / 12 — Services & nginx"

# ── eupanel-agent ──────────────────────────────────────────────────────────
cat > /etc/systemd/system/eupanel-agent.service <<SVC
[Unit]
Description=EuPanel Agent
After=network.target

[Service]
Type=simple
User=root
EnvironmentFile=/etc/eupanel/agent.env
ExecStart=/usr/local/bin/eupanel-agent
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVC

# ── eupanel-backend ────────────────────────────────────────────────────────
cat > /etc/systemd/system/eupanel-backend.service <<SVC
[Unit]
Description=EuPanel Backend (Flint Dart)
After=network.target mariadb.service

[Service]
Type=simple
User=www-data
WorkingDirectory=${INSTALL_DIR}/backend
EnvironmentFile=${INSTALL_DIR}/backend/.env
ExecStart=/usr/lib/dart/bin/dart run lib/main.dart
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVC

# ── eupanel-frontend ───────────────────────────────────────────────────────
cat > /etc/systemd/system/eupanel-frontend.service <<SVC
[Unit]
Description=EuPanel Frontend (Next.js)
After=network.target eupanel-backend.service

[Service]
Type=simple
User=www-data
WorkingDirectory=${INSTALL_DIR}/frontend
EnvironmentFile=${INSTALL_DIR}/frontend/.env.local
ExecStart=/usr/bin/node node_modules/.bin/next start -p ${FRONTEND_PORT}
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVC

# ── Fix permissions ────────────────────────────────────────────────────────
mkdir -p "${INSTALL_DIR}/backend/storage"
chown -R www-data:www-data "${INSTALL_DIR}/backend" "${INSTALL_DIR}/frontend"
chmod -R 755 "${INSTALL_DIR}/backend" "${INSTALL_DIR}/frontend"
# .env files stay private
chmod 600 "${INSTALL_DIR}/backend/.env" "${INSTALL_DIR}/frontend/.env.local"

# ── Enable + start ─────────────────────────────────────────────────────────
systemctl daemon-reload
systemctl enable --now eupanel-agent
systemctl enable --now eupanel-backend
systemctl enable --now eupanel-frontend

log "All three EuPanel services started."

# =============================================================================
#  NGINX CONFIGURATION
# =============================================================================

# Remove default site
rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/eupanel.conf <<NGINX
# ── EuPanel panel vhost ────────────────────────────────────────────────────
server {
    listen 80;
    listen [::]:80;
    server_name ${PANEL_DOMAIN};

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # ── API → Dart backend ──────────────────────────────────────────────
    location /api/ {
        proxy_pass         http://127.0.0.1:${BACKEND_PORT}/;
        proxy_http_version 1.1;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_read_timeout 120s;
        client_max_body_size 50M;
    }

    # ── phpMyAdmin (secret URL) ─────────────────────────────────────────
    location = /${PMA_TOKEN} { return 301 /${PMA_TOKEN}/; }
    location /${PMA_TOKEN}/ {
        alias /var/www/phpmyadmin/;
        index index.php;

        location ~ \.php\$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
            fastcgi_param SCRIPT_FILENAME \$request_filename;
        }

        location ~* \.(js|css|png|jpg|gif|ico|svg|woff2?)\$ {
            expires 7d;
            add_header Cache-Control "public, immutable";
        }

        # Block sensitive phpMyAdmin paths
        location ~ ^/${PMA_TOKEN}/(libraries|setup)/ { deny all; }
    }

    # ── File Manager ───────────────────────────────────────────────────
    location /filemanager/ {
        alias /var/www/filemanager/;
        index index.php;

        location ~ \.php\$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
            fastcgi_param SCRIPT_FILENAME \$request_filename;
        }
    }

    # ── Frontend → Next.js ──────────────────────────────────────────────
    location / {
        proxy_pass         http://127.0.0.1:${FRONTEND_PORT};
        proxy_http_version 1.1;
        proxy_set_header   Upgrade           \$http_upgrade;
        proxy_set_header   Connection        "upgrade";
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/eupanel.conf /etc/nginx/sites-enabled/eupanel.conf
nginx -t && systemctl reload nginx
log "nginx configured."

# =============================================================================
#  SSL (optional)
# =============================================================================
if [[ "${USE_SSL,,}" == "y" ]]; then
    section "SSL — Let's Encrypt"
    certbot --nginx \
        -d "${PANEL_DOMAIN}" \
        --non-interactive \
        --agree-tos \
        --email "${ADMIN_EMAIL}" \
        --redirect \
        --no-eff-email || warn "SSL issuance failed — DNS may not be pointed yet. Run: certbot --nginx -d ${PANEL_DOMAIN}"
    # Auto-renew
    (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'") | crontab -
    log "SSL issued and auto-renew cron set."
fi

# =============================================================================
#  FIREWALL
# =============================================================================
section "Firewall (UFW)"

ufw default deny incoming > /dev/null
ufw default allow outgoing > /dev/null
ufw allow 22/tcp   comment "SSH"     > /dev/null
ufw allow 80/tcp   comment "HTTP"    > /dev/null
ufw allow 443/tcp  comment "HTTPS"   > /dev/null
ufw allow 21/tcp   comment "FTP"     > /dev/null
ufw allow 40000:50000/tcp comment "FTP passive" > /dev/null
ufw allow 53/tcp   comment "DNS TCP" > /dev/null
ufw allow 53/udp   comment "DNS UDP" > /dev/null
echo "y" | ufw enable > /dev/null
log "Firewall enabled."

# =============================================================================
#  CREATE FIRST ADMIN USER VIA API
# =============================================================================
section "Creating admin account"

# Wait for backend to be ready (max 30s)
for i in $(seq 1 15); do
    if curl -sf "http://127.0.0.1:${BACKEND_PORT}/" > /dev/null 2>&1; then
        break
    fi
    sleep 2
done

curl -sf -X POST "http://127.0.0.1:${BACKEND_PORT}/users" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"${ADMIN_USER}\",\"email\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASS}\",\"role\":\"admin\"}" \
    > /dev/null 2>&1 && log "Admin account created." \
    || warn "Could not auto-create admin — do it manually after install."

# =============================================================================
#  SAVE CREDENTIALS
# =============================================================================
CREDS_FILE="/root/eupanel-credentials.txt"
PANEL_URL="http${USE_SSL,,}://${PANEL_DOMAIN}"
[[ "${USE_SSL,,}" != "y" ]] && PANEL_URL="http://${PANEL_DOMAIN}"

cat > "$CREDS_FILE" <<CREDS
╔══════════════════════════════════════════════════════════════════╗
║                    EuPanel — Credentials                        ║
║         KEEP THIS FILE SAFE — delete after noting it down       ║
╚══════════════════════════════════════════════════════════════════╝

Installed : $(date)
Server IP : ${SERVER_IP}

── Panel ────────────────────────────────────────────────────────
  URL      : ${PANEL_URL}
  Username : ${ADMIN_USER}
  Password : ${ADMIN_PASS}
  E-mail   : ${ADMIN_EMAIL}

── phpMyAdmin ───────────────────────────────────────────────────
  URL      : ${PANEL_URL}/${PMA_TOKEN}/
  Login with your MariaDB credentials below.

── File Manager ─────────────────────────────────────────────────
  URL      : ${PANEL_URL}/filemanager/
  Username : ${ADMIN_USER}
  Password : ${ADMIN_PASS}

── MariaDB ──────────────────────────────────────────────────────
  Host     : 127.0.0.1:3306
  Database : eupanel
  User     : eupanel
  Password : ${DB_PASS}

── PowerDNS API ─────────────────────────────────────────────────
  URL      : http://127.0.0.1:8081
  API Key  : ${PDNS_API_KEY}

── EuPanel Agent ────────────────────────────────────────────────
  URL      : http://127.0.0.1:${AGENT_PORT}  (localhost only)
  Secret   : ${AGENT_SECRET}

── JWT Secret ───────────────────────────────────────────────────
  ${JWT_SECRET}

── Service status ───────────────────────────────────────────────
  systemctl status eupanel-backend
  systemctl status eupanel-frontend
  systemctl status eupanel-agent

── Logs ─────────────────────────────────────────────────────────
  journalctl -u eupanel-backend  -f
  journalctl -u eupanel-frontend -f
  journalctl -u eupanel-agent    -f
CREDS

chmod 600 "$CREDS_FILE"

# =============================================================================
#  DONE
# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}"
echo "  ███████╗██╗   ██╗██████╗  █████╗ ███╗   ██╗███████╗██╗"
echo "  ██╔════╝██║   ██║██╔══██╗██╔══██╗████╗  ██║██╔════╝██║"
echo "  █████╗  ██║   ██║██████╔╝███████║██╔██╗ ██║█████╗  ██║"
echo "  ██╔══╝  ██║   ██║██╔═══╝ ██╔══██║██║╚██╗██║██╔══╝  ██║"
echo "  ███████╗╚██████╔╝██║     ██║  ██║██║ ╚████║███████╗███████╗"
echo "  ╚══════╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝"
echo -e "${NC}"
echo -e "${BOLD}Installation complete!${NC}"
echo ""
echo -e "  Panel       : ${CYAN}${PANEL_URL}${NC}"
echo -e "  phpMyAdmin  : ${CYAN}${PANEL_URL}/${PMA_TOKEN}/${NC}"
echo -e "  File Manager: ${CYAN}${PANEL_URL}/filemanager/${NC}"
echo -e "  Username    : ${BOLD}${ADMIN_USER}${NC}"
echo -e "  Password    : ${BOLD}${ADMIN_PASS}${NC}"
echo ""
echo -e "  Full credentials saved to: ${YELLOW}${CREDS_FILE}${NC}"
echo ""
echo -e "${YELLOW}  Point your domain's A record to: ${SERVER_IP}${NC}"
[[ "${USE_SSL,,}" != "y" ]] && \
    echo -e "${YELLOW}  Then run: certbot --nginx -d ${PANEL_DOMAIN}${NC}"
echo ""
