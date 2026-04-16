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
	"github.com/eucloudhost/eupanel-agent/internal/ftpuser"
	"github.com/eucloudhost/eupanel-agent/internal/nginx"
	"github.com/eucloudhost/eupanel-agent/internal/systemuser"
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
	Domain     string `json:"domain"`
	RootPath   string `json:"root_path"`   // optional — if empty, defaults to /var/www/{domain}/public
	PHP        string `json:"php_version"` // e.g. "8.3"
}

func (h *Handlers) CreateDomain(w http.ResponseWriter, r *http.Request) {
	var req createDomainRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Domain == "" {
		respondErr(w, http.StatusBadRequest, "domain is required")
		return
	}

	// 1. Resolve web root
	// If root_path is provided (subscription-based flow), use it directly.
	// Otherwise fall back to /var/www/{domain}/public for standalone use.
	webRoot := req.RootPath
	if webRoot == "" {
		webRoot = filepath.Join(h.cfg.WebRoot, req.Domain, "public")
	}

	// Ensure the directory exists (it may already exist from subscription provisioning)
	if err := os.MkdirAll(webRoot, 0755); err != nil {
		respondErr(w, http.StatusInternalServerError, "failed to create web root: "+err.Error())
		return
	}

	// 2. Write index.html placeholder only if directory is empty
	index := filepath.Join(webRoot, "index.html")
	if _, err := os.Stat(index); os.IsNotExist(err) {
		placeholder := "<!DOCTYPE html><html><head><title>" + req.Domain + "</title></head><body><h1>" + req.Domain + " is live on EuPanel</h1></body></html>"
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

type deleteDomainRequest struct {
	RemoveFiles bool   `json:"remove_files"` // only true for standalone (non-subscription) domains
	RootPath    string `json:"root_path"`    // only used when remove_files=true
}

func (h *Handlers) DeleteDomain(w http.ResponseWriter, r *http.Request) {
	d := chi.URLParam(r, "domain")
	if d == "" {
		respondErr(w, http.StatusBadRequest, "domain is required")
		return
	}

	var req deleteDomainRequest
	json.NewDecoder(r.Body).Decode(&req) // ignore decode error — body is optional

	// Always remove nginx config and reload
	nginx.RemoveVhost(h.cfg.NginxSitesDir, d)
	nginx.Reload(h.cfg.NginxBin)

	// Only remove files for standalone domains that explicitly request it.
	// Never delete subscription home directories (under /home/).
	if req.RemoveFiles && req.RootPath != "" && !filepath.HasPrefix(req.RootPath, "/home/") {
		os.RemoveAll(req.RootPath)
	}

	respond(w, http.StatusOK, map[string]string{"deleted": d})
}

// ── SSL ───────────────────────────────────────────────────────────────────────

type sslRequest struct {
	Email    string `json:"email"`
	RootPath string `json:"root_path"`   // must match the path used when the domain was created
	PHP      string `json:"php_version"` // e.g. "8.3"
}

func (h *Handlers) IssueSSL(w http.ResponseWriter, r *http.Request) {
	d := chi.URLParam(r, "domain")
	var req sslRequest
	json.NewDecoder(r.Body).Decode(&req)

	if err := certbot.Issue(h.cfg.CertbotBin, d, req.Email); err != nil {
		respondErr(w, http.StatusInternalServerError, err.Error())
		return
	}

	// Resolve web root — use provided path or fall back to convention.
	// IMPORTANT: must match the path used when the domain was first created,
	// otherwise the rewritten vhost will serve from the wrong directory.
	webRoot := req.RootPath
	if webRoot == "" {
		webRoot = filepath.Join(h.cfg.WebRoot, d, "public")
	}
	phpVersion := req.PHP
	if phpVersion == "" {
		phpVersion = "8.3"
	}

	// Rewrite nginx vhost with SSL enabled
	vhostCfg := nginx.VhostConfig{
		Domain:     d,
		WebRoot:    webRoot,
		PHPVersion: phpVersion,
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

// ── System Users ──────────────────────────────────────────────────────────────

type createSystemUserRequest struct {
	Username   string `json:"username"`
	PHPVersion string `json:"php_version"`
}

func (h *Handlers) CreateSystemUser(w http.ResponseWriter, r *http.Request) {
	var req createSystemUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Username == "" {
		respondErr(w, http.StatusBadRequest, "username is required")
		return
	}

	homeDir, err := systemuser.Create(req.Username)
	if err != nil {
		respondErr(w, http.StatusInternalServerError, err.Error())
		return
	}

	respond(w, http.StatusCreated, map[string]any{
		"username":       req.Username,
		"home_directory": homeDir,
		"public_html":    homeDir + "/public_html",
	})
}

func (h *Handlers) DeleteSystemUser(w http.ResponseWriter, r *http.Request) {
	username := chi.URLParam(r, "username")
	if err := systemuser.Delete(username); err != nil {
		respondErr(w, http.StatusInternalServerError, err.Error())
		return
	}
	respond(w, http.StatusOK, map[string]string{"deleted": username})
}

// ── FTP Users ─────────────────────────────────────────────────────────────────

type createFTPUserRequest struct {
	Username      string `json:"username"`
	HomeDirectory string `json:"home_directory"`
}

func (h *Handlers) CreateFTPUser(w http.ResponseWriter, r *http.Request) {
	var req createFTPUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Username == "" {
		respondErr(w, http.StatusBadRequest, "username and home_directory are required")
		return
	}
	if req.HomeDirectory == "" {
		req.HomeDirectory = "/home/" + req.Username
	}

	username, err := ftpuser.Create(req.Username, req.HomeDirectory)
	if err != nil {
		respondErr(w, http.StatusInternalServerError, err.Error())
		return
	}

	respond(w, http.StatusCreated, map[string]any{
		"username":       username,
		"home_directory": req.HomeDirectory,
	})
}

func (h *Handlers) DeleteFTPUser(w http.ResponseWriter, r *http.Request) {
	username := chi.URLParam(r, "username")
	if err := ftpuser.Delete(username); err != nil {
		respondErr(w, http.StatusInternalServerError, err.Error())
		return
	}
	respond(w, http.StatusOK, map[string]string{"deleted": username})
}

// ── Database handlers (stubs — wired from router) ─────────────────────────────

func (h *Handlers) ListDatabases(w http.ResponseWriter, r *http.Request) {
	respond(w, http.StatusOK, map[string]any{"databases": []any{}})
}

func (h *Handlers) CreateDatabase(w http.ResponseWriter, r *http.Request) {
	respondErr(w, http.StatusNotImplemented, "database creation coming in Phase 2")
}

func (h *Handlers) DeleteDatabase(w http.ResponseWriter, r *http.Request) {
	respondErr(w, http.StatusNotImplemented, "database deletion coming in Phase 2")
}

// ── phpMyAdmin handlers (stubs) ───────────────────────────────────────────────

func (h *Handlers) PMAUrl(w http.ResponseWriter, r *http.Request) {
	respondErr(w, http.StatusNotImplemented, "phpMyAdmin coming in Phase 2")
}

func (h *Handlers) PMAInstall(w http.ResponseWriter, r *http.Request) {
	respondErr(w, http.StatusNotImplemented, "phpMyAdmin coming in Phase 2")
}
