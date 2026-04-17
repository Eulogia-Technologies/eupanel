#!/usr/bin/env bash
# =============================================================================
#  EuPanel — One-Command Updater
#  Usage: curl -fsSL https://raw.githubusercontent.com/Eulogia-Technologies/eupanel/master/update.sh | bash
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'
RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

log()     { echo -e "${GREEN}[✓]${NC} $*"; }
info()    { echo -e "${BLUE}[→]${NC} $*"; }
die()     { echo -e "${RED}[✗]${NC} $*"; exit 1; }
section() { echo -e "\n${BOLD}${CYAN}━━━  $*  ━━━${NC}\n"; }

[[ $EUID -ne 0 ]] && die "Run as root: sudo bash update.sh"
[[ ! -d /opt/eupanel ]] && die "EuPanel is not installed. Run install.sh first."

export PATH="$PATH:/usr/local/go/bin:/usr/lib/dart/bin"
export GOPATH="/root/go"
# Load profile paths if available
[[ -f /etc/profile.d/eupanel-paths.sh ]] && source /etc/profile.d/eupanel-paths.sh

section "EuPanel Update"
echo -e "  Repo    : /opt/eupanel"
echo -e "  Time    : $(date)"
echo ""

# ── 1. Pull latest code ───────────────────────────────────────────────────────
section "1 / 4 — Pulling latest code"
git -C /opt/eupanel fetch origin master
CURRENT=$(git -C /opt/eupanel rev-parse HEAD)
LATEST=$(git -C /opt/eupanel rev-parse origin/master)

if [[ "$CURRENT" == "$LATEST" ]]; then
    echo -e "  ${GREEN}Already up to date.${NC} Nothing to do."
    echo ""
    systemctl is-active --quiet eupanel-backend  && log "eupanel-backend  running" || true
    systemctl is-active --quiet eupanel-frontend && log "eupanel-frontend running" || true
    systemctl is-active --quiet eupanel-agent    && log "eupanel-agent    running" || true
    exit 0
fi

# Show what changed
echo -e "  ${BOLD}Changes:${NC}"
git -C /opt/eupanel log --oneline HEAD..origin/master | sed 's/^/    /'
echo ""

git -C /opt/eupanel pull --rebase --autostash
log "Code updated."

# ── 2. Backend ────────────────────────────────────────────────────────────────
section "2 / 4 — Backend (Dart)"
info "Installing Dart dependencies…"
(cd /opt/eupanel/backend && dart pub get)
dart pub global activate flint_dart
ln -sf /root/.pub-cache/bin/flint /usr/local/bin/flint 2>/dev/null || true
log "Backend dependencies ready."

# ── 3. Frontend ───────────────────────────────────────────────────────────────
section "3 / 4 — Frontend (Next.js)"
info "Installing npm packages…"
(cd /opt/eupanel/frontend && npm ci --silent)
info "Building frontend…"
(cd /opt/eupanel/frontend && npm run build)
log "Frontend built."

# ── 4. Agent ──────────────────────────────────────────────────────────────────
section "4 / 4 — Agent (Go)"
info "Compiling eupanel-agent…"
(
  cd /opt/eupanel/eupanel-agent
  rm -f go.sum
  GOPATH="/root/go" GONOSUMCHECK=* go mod tidy
  GOPATH="/root/go" CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
      go build -ldflags="-s -w" -o /usr/local/bin/eupanel-agent .
)
log "Agent binary updated."

# ── Run any new migrations ────────────────────────────────────────────────────
section "DB Migration"
info "Syncing database tables…"
set -a; source /opt/eupanel/backend/.env; set +a
(cd /opt/eupanel/backend && dart run flint_dart migrate) \
    && log "Database tables up to date." \
    || warn "Migration warning — check logs if backend fails."

# ── Fix permissions & stop services cleanly ───────────────────────────────────
chown -R www-data:www-data /opt/eupanel/backend /opt/eupanel/frontend
chmod 600 /opt/eupanel/backend/.env /opt/eupanel/frontend/.env.local 2>/dev/null || true

info "Stopping services…"
systemctl stop eupanel-frontend eupanel-backend eupanel-agent 2>/dev/null || true
sleep 2

info "Starting services…"
systemctl start eupanel-agent
systemctl start eupanel-backend
systemctl start eupanel-frontend
sleep 3

# ── Status ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}  EuPanel updated successfully!${NC}"
echo ""

for svc in eupanel-agent eupanel-backend eupanel-frontend; do
    if systemctl is-active --quiet "$svc"; then
        echo -e "  ${GREEN}●${NC} $svc  ${GREEN}running${NC}"
    else
        echo -e "  ${RED}●${NC} $svc  ${RED}FAILED${NC} — check: journalctl -u $svc -n 30"
    fi
done

echo ""
COMMIT=$(git -C /opt/eupanel rev-parse --short HEAD)
echo -e "  Version : ${CYAN}$COMMIT${NC}  ($(git -C /opt/eupanel log -1 --format='%s'))"
echo ""
