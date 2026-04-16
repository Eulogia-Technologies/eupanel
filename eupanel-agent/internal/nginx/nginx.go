package nginx

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

type VhostConfig struct {
	Domain     string
	WebRoot    string
	PHPVersion string
	SSL        bool
}

// WriteVhost writes an nginx vhost config file to sites-available.
func WriteVhost(sitesDir string, cfg VhostConfig) error {
	content := buildVhost(cfg)
	path := filepath.Join(sitesDir, cfg.Domain+".conf")
	return os.WriteFile(path, []byte(content), 0644)
}

// EnableSite creates a symlink in sites-enabled.
func EnableSite(sitesDir, domain string) error {
	available := filepath.Join(sitesDir, domain+".conf")
	enabled := filepath.Join(filepath.Dir(sitesDir), "sites-enabled", domain+".conf")

	// Remove existing symlink if any
	os.Remove(enabled)

	return os.Symlink(available, enabled)
}

// RemoveVhost removes the vhost config and symlink.
func RemoveVhost(sitesDir, domain string) {
	os.Remove(filepath.Join(sitesDir, domain+".conf"))
	os.Remove(filepath.Join(filepath.Dir(sitesDir), "sites-enabled", domain+".conf"))
}

// Reload sends reload signal to nginx.
func Reload(nginxBin string) error {
	out, err := exec.Command(nginxBin, "-s", "reload").CombinedOutput()
	if err != nil {
		return fmt.Errorf("nginx reload: %s — %w", string(out), err)
	}
	return nil
}

// IsRunning checks if nginx process is running.
func IsRunning() bool {
	err := exec.Command("pgrep", "-x", "nginx").Run()
	return err == nil
}
