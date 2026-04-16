package api

import (
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"syscall"

	"github.com/go-chi/chi/v5"

	"github.com/eucloudhost/eupanel-agent/internal/certbot"
	"github.com/eucloudhost/eupanel-agent/internal/config"
	"github.com/eucloudhost/eupanel-agent/internal/domain"
	"github.com/eucloudhost/eupanel-agent/internal/nginx"
)

type Handlers struct {
	cfg *config.Config
}

// ── Helpers ──────────────────────────────────────────────────────────────────

func respond(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func respondErr(w http.ResponseWriter, status int, msg string) {
	respond(w, status, map[string]string{"error": msg})
}

// ── Health ────────────────────────────────────────────────────────────────────

func (h *Handlers) Health(w http.ResponseWriter, r *http.Request) {
	respond(w, http.StatusOK, map[string]string{
		"status":   "ok",
		"hostname": h.cfg.Hostname,
		"version":  "0.1.0",
	})
}

// ── Domains ───────────────────────────────────────────────────────────────────

func (h *Handlers) ListDomains(w http.ResponseWriter, r *http.Request) {
	domains, err := domain.List(h.cfg.WebRoot)
	if err != nil {
		respondErr(w, http.StatusInternalServerError, err.Error())
		return
	}
	respond(w, http.StatusOK, map[string]any{"domains": domains})
}

type createDomainRequest struct {
	Domain string `json:"domain"`
	PHP    string `json:"php_version"` // e.g. "8.3"
}

func (h *Handlers) CreateDomain(w http.ResponseWriter, r *http.Request) {
	var req createDomainRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Domain == "" {
		respondErr(w, http.StatusBadRequest, "domain is required")
		return
	}

	// 1. Create web root
	webRoot := filepath.Join(h.cfg.WebRoot, req.Domain, "public")
	if err := os.MkdirAll(webRoot, 0755); err != nil {
		respondErr(w, http.StatusInternalServerError, "failed to create web root: "+err.Error())
		return
	}

	// 2. Write index.html placeholder
	index := filepath.Join(webRoot, "index.html")
	if _, err := os.Stat(index); os.IsNotExist(err) {
		placeholder := "<!DOCTYPE html><html><body><h1>" + req.Domain + " is live on EuPanel</h1></body></html>"
		os.WriteFile(index, []byte(placeholder), 0644)
	}

	// 3. Generate nginx vhost
	phpVersion := req.PHP
	if phpVersion == "" {
		phpVersion = "8.3"
	}
	vhostCfg := nginx.VhostConfig{
		Domain:     req.Domain,
		WebRoot:    webRoot,
		PHPVersion: phpVersion,
		SSL:        false,
	}
	if err := nginx.WriteVhost(h.cfg.NginxSitesDir, vhostCfg); err != nil {
		respondErr(w, http.StatusInternalServerError, "failed to write nginx config: "+err.Error())
		return
	}

	// 4. Enable site + reload nginx
	if err := nginx.EnableSite(h.cfg.NginxSitesDir, req.Domain); err != nil {
		respondErr(w, http.StatusInternalServerError, "failed to enable nginx site: "+err.Error())
		return
	}
	if err := nginx.Reload(h.cfg.NginxBin); err != nil {
		respondErr(w, http.StatusInternalServerError, "nginx reload failed: "+err.Error())
		return
	}

	respond(w, http.StatusCreated, map[string]any{
		"domain":   req.Domain,
		"web_root": webRoot,
		"status":   "active",
	})
}

func (h *Handlers) DeleteDomain(w http.ResponseWriter, r *http.Request) {
	d := chi.URLParam(r, "domain")
	if d == "" {
		respondErr(w, http.StatusBadRequest, "domain is required")
		return
	}

	// Remove nginx config
	nginx.RemoveVhost(h.cfg.NginxSitesDir, d)
	nginx.Reload(h.cfg.NginxBin)

	// Remove web root
	webRoot := filepath.Join(h.cfg.WebRoot, d)
	os.RemoveAll(webRoot)

	respond(w, http.StatusOK, map[string]string{"deleted": d})
}

// ── SSL ───────────────────────────────────────────────────────────────────────

type sslRequest struct {
	Email string `json:"email"`
}

func (h *Handlers) IssueSSL(w http.ResponseWriter, r *http.Request) {
	d := chi.URLParam(r, "domain")
	var req sslRequest
	json.NewDecoder(r.Body).Decode(&req)

	if err := certbot.Issue(h.cfg.CertbotBin, d, req.Email); err != nil {
		respondErr(w, http.StatusInternalServerError, err.Error())
		return
	}

	// Update nginx vhost to SSL
	vhostCfg := nginx.VhostConfig{
		Domain:     d,
		WebRoot:    filepath.Join(h.cfg.WebRoot, d, "public"),
		PHPVersion: "8.3",
		SSL:        true,
	}
	nginx.WriteVhost(h.cfg.NginxSitesDir, vhostCfg)
	nginx.Reload(h.cfg.NginxBin)

	respond(w, http.StatusOK, map[string]string{
		"domain": d,
		"ssl":    "issued",
	})
}

func (h *Handlers) RenewSSL(w http.ResponseWriter, r *http.Request) {
	d := chi.URLParam(r, "domain")
	if err := certbot.Renew(h.cfg.CertbotBin, d); err != nil {
		respondErr(w, http.StatusInternalServerError, err.Error())
		return
	}
	respond(w, http.StatusOK, map[string]string{"domain": d, "ssl": "renewed"})
}

func (h *Handlers) SSLStatus(w http.ResponseWriter, r *http.Request) {
	d := chi.URLParam(r, "domain")
	status, expiry, err := certbot.Status(d)
	if err != nil {
		respondErr(w, http.StatusInternalServerError, err.Error())
		return
	}
	respond(w, http.StatusOK, map[string]any{
		"domain": d,
		"status": status,
		"expiry": expiry,
	})
}

// ── Nginx ─────────────────────────────────────────────────────────────────────

func (h *Handlers) ReloadNginx(w http.ResponseWriter, r *http.Request) {
	if err := nginx.Reload(h.cfg.NginxBin); err != nil {
		respondErr(w, http.StatusInternalServerError, err.Error())
		return
	}
	respond(w, http.StatusOK, map[string]string{"nginx": "reloaded"})
}

func (h *Handlers) NginxStatus(w http.ResponseWriter, r *http.Request) {
	running := nginx.IsRunning()
	respond(w, http.StatusOK, map[string]any{"running": running})
}

// ── System ────────────────────────────────────────────────────────────────────

func (h *Handlers) SystemInfo(w http.ResponseWriter, r *http.Request) {
	respond(w, http.StatusOK, map[string]any{
		"hostname": h.cfg.Hostname,
		"os":       runtime.GOOS,
		"arch":     runtime.GOARCH,
		"cpus":     runtime.NumCPU(),
	})
}

func (h *Handlers) DiskUsage(w http.ResponseWriter, r *http.Request) {
	var stat syscall.Statfs_t
	if err := syscall.Statfs("/", &stat); err != nil {
		respondErr(w, http.StatusInternalServerError, err.Error())
		return
	}
	total := stat.Blocks * uint64(stat.Bsize)
	free := stat.Bfree * uint64(stat.Bsize)
	used := total - free

	respond(w, http.StatusOK, map[string]any{
		"total_bytes": total,
		"used_bytes":  used,
		"free_bytes":  free,
		"used_pct":    float64(used) / float64(total) * 100,
	})
}
