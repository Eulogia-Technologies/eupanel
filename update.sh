#!/usr/bin/env bash
# =============================================================================
#  EuPanel â€” One-Command Updater
#  Usage: curl -fsSL https://raw.githubusercontent.com/Eulogia-Technologies/eupanel/master/update.sh | bash
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

log()     { echo -e "${GREEN}[âœ“]${NC} $*"; }
info()    { echo -e "${BLUE}[â†’]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
die()     { echo -e "${RED}[âœ—]${NC} $*"; exit 1; }
section() { echo -e "\n${BOLD}${CYAN}â”â”â”  $*  â”â”â”${NC}\n"; }

[[ $EUID -ne 0 ]] && die "Run as root: sudo bash update.sh"
[[ ! -d /opt/eupanel ]] && die "EuPanel is not installed. Run install.sh first."

export PATH="$PATH:/usr/lib/dart/bin"
# Load profile paths if available
[[ -f /etc/profile.d/eupanel-paths.sh ]] && source /etc/profile.d/eupanel-paths.sh

FLINT_DART_REPO_URL="https://github.com/flint-dart/flint_dart.git"
FLINT_UI_REPO_URL="https://github.com/flint-dart/flint_ui.git"
FLINT_DART_DIR="/opt/flint/flint_dart"
FLINT_UI_DIR="/opt/flint/flint_ui"

section "EuPanel Update"
echo -e "  Repo    : /opt/eupanel"
echo -e "  Time    : $(date)"
echo ""

# â”€â”€ 1. Pull latest code â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
section "1 / 4 â€” Pulling latest code"
git -C /opt/eupanel fetch origin master
CURRENT=$(git -C /opt/eupanel rev-parse HEAD)
LATEST=$(git -C /opt/eupanel rev-parse origin/master)

if [[ "$CURRENT" == "$LATEST" ]]; then
    echo -e "  ${GREEN}Already up to date.${NC} Nothing to do."
    echo ""
    systemctl is-active --quiet eupanel-backend  && log "eupanel-backend  running" || true
    exit 0
fi

# Show what changed
echo -e "  ${BOLD}Changes:${NC}"
git -C /opt/eupanel log --oneline HEAD..origin/master | sed 's/^/    /'
echo ""

git -C /opt/eupanel pull --rebase --autostash
log "Code updated."

# â”€â”€ 2. Backend â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
section "2 / 4 â€” Backend (Dart)"
mkdir -p "$(dirname "$FLINT_DART_DIR")"
if [[ -d "$FLINT_DART_DIR/.git" ]]; then
    info "Updating local Flint Dart source..."
    git -C "$FLINT_DART_DIR" pull --rebase --autostash
else
    info "Cloning local Flint Dart source..."
    git clone --depth 1 "$FLINT_DART_REPO_URL" "$FLINT_DART_DIR"
fi
if [[ -d "$FLINT_UI_DIR/.git" ]]; then
    info "Updating local Flint UI source..."
    git -C "$FLINT_UI_DIR" pull --rebase --autostash
else
    info "Cloning local Flint UI source..."
    git clone --depth 1 "$FLINT_UI_REPO_URL" "$FLINT_UI_DIR"
fi
info "Installing Dart dependenciesâ€¦"
(cd /opt/eupanel/fullstack && dart pub get)
dart pub global activate flint_dart
ln -sf /root/.pub-cache/bin/flint /usr/local/bin/flint 2>/dev/null || true
log "Backend dependencies ready."

# 3. Flint Web UI bundle
section "3 / 4 â€” Flint Web UI"
info "Building Flint Web UI bundleâ€¦"
(cd /opt/eupanel/fullstack && dart compile js lib/ui/main.dart -o public/main.dart.js)
log "Flint Web UI bundle built."

# â”€â”€ 4. Agent â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
section "DB Migration"
info "Syncing database tablesâ€¦"
set -a; source /opt/eupanel/fullstack/.env; set +a
(cd /opt/eupanel/fullstack && flint migrate) \
    && log "Database tables up to date." \
    || warn "Migration warning â€” check logs if backend fails."

# â”€â”€ Fix permissions & stop services cleanly â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
chown -R www-data:www-data /opt/eupanel/fullstack
chmod 600 /opt/eupanel/fullstack/.env 2>/dev/null || true

info "Stopping servicesâ€¦"
systemctl stop eupanel-backend eupanel-agent 2>/dev/null || true
systemctl disable eupanel-agent 2>/dev/null || true
rm -f /etc/systemd/system/eupanel-frontend.service \
      /etc/systemd/system/eupanel-agent.service \
      /usr/local/bin/eupanel-agent \
      /etc/eupanel/agent.env
systemctl daemon-reload
sleep 2

info "Starting servicesâ€¦"
systemctl start eupanel-backend
sleep 3

# â”€â”€ Status â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo ""
echo -e "${BOLD}${GREEN}  EuPanel updated successfully!${NC}"
echo ""

for svc in eupanel-backend; do
    if systemctl is-active --quiet "$svc"; then
        echo -e "  ${GREEN}â—${NC} $svc  ${GREEN}running${NC}"
    else
        echo -e "  ${RED}â—${NC} $svc  ${RED}FAILED${NC} â€” check: journalctl -u $svc -n 30"
    fi
done

echo ""
COMMIT=$(git -C /opt/eupanel rev-parse --short HEAD)
echo -e "  Version : ${CYAN}$COMMIT${NC}  ($(git -C /opt/eupanel log -1 --format='%s'))"
echo ""

