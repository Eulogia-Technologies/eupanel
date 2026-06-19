#!/usr/bin/env bash
# =============================================================================
#  EuPanel — Complete One-Shot Installer
#  Ubuntu 22.04 / 24.04 LTS
#
#  Installs: nginx · PHP 8.3 · MariaDB · phpMyAdmin · PowerDNS · vsftpd
#            Certbot · Dart · Tinyfilemanager
#            EuPanel fullstack backend (Flint Dart + Flint Web UI)
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
PHP_VERSION="8.3"
PMA_VERSION="5.2.1"
REPO_URL="https://github.com/Eulogia-Technologies/eupanel.git"
FLINT_DART_REPO_URL="https://github.com/flint-dart/flint_dart.git"
FLINT_UI_REPO_URL="https://github.com/flint-dart/flint_ui.git"
INSTALL_DIR="/opt/eupanel"
FLINT_DART_DIR="/opt/flint/flint_dart"
FLINT_UI_DIR="/opt/flint/flint_ui"
BACKEND_PORT=4054

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

# ── Load previously saved values (shown as defaults) ──────────────────────
PREV_DOMAIN=""; PREV_EMAIL=""; PREV_USER="admin"
if [[ -f /etc/eupanel/install.conf ]]; then
    # shellcheck source=/dev/null
    source /etc/eupanel/install.conf 2>/dev/null || true
    PREV_DOMAIN="${SAVED_DOMAIN:-}"
    PREV_EMAIL="${SAVED_EMAIL:-}"
    PREV_USER="${SAVED_USER:-admin}"
fi

# ── Prompts — press Enter to keep the suggested default ───────────────────
_DOM_DEFAULT="${PREV_DOMAIN:-$SERVER_IP}"
printf "Panel domain [%s]: " "$_DOM_DEFAULT" > $TTY
read -r PANEL_DOMAIN < $TTY
PANEL_DOMAIN="${PANEL_DOMAIN:-$_DOM_DEFAULT}"

if [[ -n "$PREV_EMAIL" ]]; then
    printf "Admin e-mail [%s]: " "$PREV_EMAIL" > $TTY
else
    printf "Admin e-mail (used for SSL + first admin account): " > $TTY
fi
read -r ADMIN_EMAIL < $TTY
ADMIN_EMAIL="${ADMIN_EMAIL:-$PREV_EMAIL}"
[[ -z "$ADMIN_EMAIL" ]] && die "Admin e-mail is required."

printf "Admin username [%s]: " "$PREV_USER" > $TTY
read -r ADMIN_USER < $TTY
ADMIN_USER="${ADMIN_USER:-$PREV_USER}"

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
[[ "${_CONFIRM,,}" != "y" && "${_CONFIRM,,}" != "yes" ]] && exit 0

# ── Persist answers for next run (shown as defaults) ─────────────────────────
mkdir -p /etc/eupanel
cat > /etc/eupanel/install.conf <<CONF
SAVED_DOMAIN="${PANEL_DOMAIN}"
SAVED_EMAIL="${ADMIN_EMAIL}"
SAVED_USER="${ADMIN_USER}"
CONF
chmod 600 /etc/eupanel/install.conf

# ── Generate secrets ──────────────────────────────────────────────────────────
DB_PASS=$(gen_pass)
JWT_SECRET=$(gen_hex 32)
PDNS_API_KEY=$(gen_hex 16)
PMA_TOKEN="pma_$(gen_hex 10)"
DEPLOY_SECRET=$(gen_hex 32)

# ── Resolve panel URL (needed by backend .env) ────────────────────────────────
if [[ "${USE_SSL,,}" == "y" ]]; then
    PANEL_BASE_URL="https://${PANEL_DOMAIN}"
else
    PANEL_BASE_URL="http://${PANEL_DOMAIN}"
fi

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
CREATE OR REPLACE USER 'eupanel'@'localhost' IDENTIFIED BY '${DB_PASS}';
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
CREATE OR REPLACE USER 'pdns'@'localhost' IDENTIFIED BY '${DB_PASS}';
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
#  9. LANGUAGE RUNTIMES  (Dart)
# =============================================================================
section "9 / 12 — Dart"

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
# Symlink dart into /usr/local/bin so it's on PATH everywhere (scripts, systemd, ssh)
ln -sf /usr/lib/dart/bin/dart /usr/local/bin/dart
# Install flint_dart globally so the `flint` CLI is available system-wide
dart pub global activate flint_dart
ln -sf /root/.pub-cache/bin/flint /usr/local/bin/flint
log "Dart $(dart --version 2>&1 | head -1) — flint CLI installed."

# ── Permanent PATH for all runtimes ───────────────────────────────────────────
cat > /etc/profile.d/eupanel-paths.sh <<'PATHFILE'
# EuPanel runtime paths — added by installer
export PATH="$PATH:/usr/lib/dart/bin"         # Dart
export PATH="$PATH:$HOME/.pub-cache/bin"     # Dart global tools (flint, etc.)
PATHFILE
chmod 644 /etc/profile.d/eupanel-paths.sh

# Also apply to current session right now
export PATH="$PATH:/usr/lib/dart/bin"

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

# -- Local Flint source packages -------------------------------------------
# EuPanel depends on unpublished Flint packages by local path:
# /opt/eupanel/fullstack -> ../../flint/flint_dart and ../../flint/flint_ui.
mkdir -p "$(dirname "$FLINT_DART_DIR")"
if [[ -d "$FLINT_DART_DIR/.git" ]]; then
    info "Updating local Flint Dart source…"
    git -C "$FLINT_DART_DIR" pull --rebase --autostash
else
    info "Cloning local Flint Dart source…"
    git clone --depth 1 "$FLINT_DART_REPO_URL" "$FLINT_DART_DIR"
fi
log "Flint Dart source ready at $FLINT_DART_DIR"

if [[ -d "$FLINT_UI_DIR/.git" ]]; then
    info "Updating local Flint UI source…"
    git -C "$FLINT_UI_DIR" pull --rebase --autostash
else
    info "Cloning local Flint UI source…"
    git clone --depth 1 "$FLINT_UI_REPO_URL" "$FLINT_UI_DIR"
fi
log "Flint UI source ready at $FLINT_UI_DIR"

# ── Backend (.env) ─────────────────────────────────────────────────────────
cat > "${INSTALL_DIR}/fullstack/.env" <<ENV
APP_ENV=production
APP_PORT=${BACKEND_PORT}

DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=eupanel
DB_USER=eupanel
DB_PASSWORD=${DB_PASS}

JWT_SECRET=${JWT_SECRET}

PDNS_API_URL=http://127.0.0.1:8081
PDNS_API_KEY=${PDNS_API_KEY}

STORAGE_PATH=${INSTALL_DIR}/fullstack/storage

# GitHub OAuth (fill in after creating your OAuth App at github.com/settings/developers)
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
PANEL_BASE_URL=${PANEL_BASE_URL}
PANEL_FRONTEND_URL=${PANEL_BASE_URL}

# Auto-deploy webhook — used by POST /webhooks/deploy
# Set this as the Secret when adding the webhook in your GitHub repo settings
DEPLOY_WEBHOOK_SECRET=${DEPLOY_SECRET}
ENV
chmod 600 "${INSTALL_DIR}/fullstack/.env"

# ── Backend: dart pub get ──────────────────────────────────────────────────
info "Installing Dart dependencies…"
export PATH="$PATH:/usr/lib/dart/bin"
# Store pub cache inside install dir so www-data can access it at runtime
export PUB_CACHE="${INSTALL_DIR}/.pub-cache"
(cd "${INSTALL_DIR}/fullstack" && dart pub get)
log "Dart dependencies resolved."

# ── Flint Web UI bundle ────────────────────────────────────────────────────
info "Building Flint Web UI bundle…"
(cd "${INSTALL_DIR}/fullstack" && dart compile js lib/ui/main.dart -o public/main.dart.js)
log "Flint Web UI bundle built."

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

# ── eupanel-backend ────────────────────────────────────────────────────────
cat > /etc/systemd/system/eupanel-backend.service <<SVC
[Unit]
Description=EuPanel Backend (Flint Dart)
After=network.target mariadb.service

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}/fullstack
EnvironmentFile=${INSTALL_DIR}/fullstack/.env
ExecStart=/usr/local/bin/flint run
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVC

# ── Fix permissions ────────────────────────────────────────────────────────
mkdir -p "${INSTALL_DIR}/fullstack/storage"
# Include .pub-cache so www-data (the service user) can access Dart packages
chown -R www-data:www-data "${INSTALL_DIR}/fullstack" "${INSTALL_DIR}/.pub-cache"
chmod -R 755 "${INSTALL_DIR}/fullstack" "${INSTALL_DIR}/.pub-cache"
chmod 600 "${INSTALL_DIR}/fullstack/.env"

# ── Stop any existing services / free up ports ─────────────────────────────
info "Stopping any existing EuPanel services…"
systemctl stop eupanel-agent    2>/dev/null || true
systemctl disable eupanel-agent 2>/dev/null || true
systemctl stop eupanel-backend  2>/dev/null || true
rm -f /etc/systemd/system/eupanel-agent.service /usr/local/bin/eupanel-agent /etc/eupanel/agent.env

# Kill anything still holding the ports (previous manual runs, etc.)
for PORT in ${BACKEND_PORT}; do
    PIDS=$(lsof -ti tcp:${PORT} 2>/dev/null || true)
    if [[ -n "$PIDS" ]]; then
        warn "Killing process(es) on port ${PORT}: $PIDS"
        kill -9 $PIDS 2>/dev/null || true
    fi
done
sleep 1

# ── Run database migration ─────────────────────────────────────────────────
section "DB Migration"
info "Creating tables in MariaDB (eupanel database)…"

# Load the .env vars so Dart can connect to the database
set -a; source "${INSTALL_DIR}/fullstack/.env"; set +a

(
  cd "${INSTALL_DIR}/fullstack"
  # Flint migrate — reads table_registry.dart via isolate and syncs all tables
  flint migrate
) && log "Database tables created." \
  || warn "Migration had warnings — check: journalctl -u eupanel-backend -n 30"

# ── Enable + start ─────────────────────────────────────────────────────────
rm -f /etc/systemd/system/eupanel-frontend.service
systemctl daemon-reload
systemctl enable --now eupanel-backend
sleep 3

# Verify services are actually running
for SVC in eupanel-backend; do
    if systemctl is-active --quiet "$SVC"; then
        log "$SVC is running."
    else
        warn "$SVC failed to start — check: journalctl -u $SVC -n 30"
    fi
done

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

    # ── Flint fullstack panel ───────────────────────────────────────────
    location / {
        proxy_pass         http://127.0.0.1:${BACKEND_PORT};
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

# Wait for backend to be ready (max 60s)
info "Waiting for backend to come up…"
_BACKEND_UP=0
for i in $(seq 1 30); do
    if curl -sf "http://127.0.0.1:${BACKEND_PORT}/" > /dev/null 2>&1; then
        _BACKEND_UP=1; break
    fi
    sleep 2
done

if [[ "$_BACKEND_UP" == "1" ]]; then
    curl -sf -X POST "http://127.0.0.1:${BACKEND_PORT}/auth/register" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"${ADMIN_USER}\",\"email\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASS}\",\"role\":\"admin\"}" \
        > /dev/null 2>&1 && log "Admin account created." \
        || warn "Could not auto-create admin — do it manually: POST /auth/register"
else
    warn "Backend did not start in time — check: journalctl -u eupanel-backend -n 50"
    warn "Then create admin manually: POST /auth/register {name, email, password, role: admin}"
fi

# =============================================================================
#  SAVE CREDENTIALS
# =============================================================================
CREDS_FILE="/root/eupanel-credentials.txt"
if [[ "${USE_SSL,,}" == "y" ]]; then
    PANEL_URL="https://${PANEL_DOMAIN}"
else
    PANEL_URL="http://${PANEL_DOMAIN}"
fi

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
  Password : ${DB_PASS}    ← stored as DB_PASSWORD in .env

── PowerDNS API ─────────────────────────────────────────────────
  URL      : http://127.0.0.1:8081
  API Key  : ${PDNS_API_KEY}

── JWT Secret ───────────────────────────────────────────────────
  ${JWT_SECRET}

── Auto-Deploy Webhook ──────────────────────────────────────────
  GitHub repo → Settings → Webhooks → Add webhook
  Payload URL : ${PANEL_BASE_URL}/api/webhooks/deploy
  Content type: application/json
  Secret      : ${DEPLOY_SECRET}
  Events      : Just the push event

── Service status ───────────────────────────────────────────────
  systemctl status eupanel-backend

── Logs ─────────────────────────────────────────────────────────
  journalctl -u eupanel-backend  -f
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

