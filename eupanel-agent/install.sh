#!/bin/bash
# EuPanel Agent Installer
# Run as root on a fresh Ubuntu 22.04 / 24.04 server
# Usage: curl -fsSL https://your-cdn/install.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[eupanel]${NC} $1"; }
success() { echo -e "${GREEN}[eupanel]${NC} $1"; }
error()   { echo -e "${RED}[eupanel]${NC} $1"; exit 1; }

# ── Root check ────────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && error "Run as root: sudo bash install.sh"

# ── Config ────────────────────────────────────────────────────────────────────
AGENT_VERSION="${AGENT_VERSION:-0.1.0}"
AGENT_PORT="${AGENT_PORT:-7820}"
AGENT_SECRET="${AGENT_SECRET:-$(openssl rand -hex 32)}"
AGENT_USER="eupanel"
INSTALL_DIR="/opt/eupanel-agent"
SERVICE_FILE="/etc/systemd/system/eupanel-agent.service"

info "Installing EuPanel Agent v${AGENT_VERSION}..."

# ── Dependencies ──────────────────────────────────────────────────────────────
info "Installing dependencies..."
apt-get update -qq
apt-get install -y -qq nginx certbot python3-certbot-nginx openssl curl

# ── PHP (default 8.3) ─────────────────────────────────────────────────────────
if ! command -v php8.3 &>/dev/null; then
    info "Installing PHP 8.3..."
    apt-get install -y -qq software-properties-common
    add-apt-repository -y ppa:ondrej/php
    apt-get update -qq
    apt-get install -y -qq php8.3-fpm php8.3-cli php8.3-mysql php8.3-curl \
        php8.3-mbstring php8.3-xml php8.3-zip php8.3-gd
fi

# ── Go ────────────────────────────────────────────────────────────────────────
if ! command -v go &>/dev/null; then
    info "Installing Go..."
    GO_VERSION="1.22.3"
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile.d/go.sh
fi

# ── Create agent user ─────────────────────────────────────────────────────────
if ! id "$AGENT_USER" &>/dev/null; then
    info "Creating user: $AGENT_USER"
    useradd --system --no-create-home --shell /bin/false "$AGENT_USER"
fi

# ── Build agent ───────────────────────────────────────────────────────────────
info "Building agent binary..."
mkdir -p "$INSTALL_DIR"

# In production: download pre-built binary or clone and build
# For now: build from source if available, otherwise download release
BINARY_URL="https://releases.eupanel.io/agent/${AGENT_VERSION}/eupanel-agent-linux-amd64"
if curl --output /dev/null --silent --head --fail "$BINARY_URL"; then
    curl -fsSL "$BINARY_URL" -o "${INSTALL_DIR}/eupanel-agent"
else
    # Build from source (dev mode)
    info "Building from source..."
    cd /tmp
    git clone https://github.com/eucloudhost/eupanel-agent /tmp/eupanel-agent-src 2>/dev/null || true
    cd /tmp/eupanel-agent-src
    /usr/local/go/bin/go build -o "${INSTALL_DIR}/eupanel-agent" .
fi

chmod +x "${INSTALL_DIR}/eupanel-agent"

# ── Write env config ──────────────────────────────────────────────────────────
cat > "${INSTALL_DIR}/.env" <<EOF
AGENT_PORT=${AGENT_PORT}
AGENT_SECRET=${AGENT_SECRET}
AGENT_WEBROOT=/var/www
AGENT_NGINX_SITES=/etc/nginx/sites-available
AGENT_NGINX_BIN=/usr/sbin/nginx
AGENT_CERTBOT_BIN=/usr/bin/certbot
EOF
chmod 600 "${INSTALL_DIR}/.env"

# ── Systemd service ───────────────────────────────────────────────────────────
info "Installing systemd service..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=EuPanel Agent
After=network.target nginx.service

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
systemctl restart eupanel-agent

# ── Nginx default cleanup ─────────────────────────────────────────────────────
rm -f /etc/nginx/sites-enabled/default
nginx -s reload 2>/dev/null || true

# ── Done ──────────────────────────────────────────────────────────────────────
success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "EuPanel Agent installed successfully!"
success ""
success "  Agent port : ${AGENT_PORT}"
success "  Secret key : ${AGENT_SECRET}"
success ""
success "  Add this server in EuPanel:"
success "  Host   : $(hostname -I | awk '{print $1}')"
success "  Port   : ${AGENT_PORT}"
success "  Secret : ${AGENT_SECRET}"
success ""
success "  Save the secret key — it won't be shown again."
success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
