package phpmyadmin

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const (
	pmaDir      = "/var/www/phpmyadmin"
	pmaConfDir  = "/etc/phpmyadmin"
	tokenFile   = "/etc/eupanel/pma_token"
	pmaVersion  = "5.2.1"
)

// Install installs phpMyAdmin and secures it with a secret URL token.
// Returns the URL path token (e.g. "pma_abc123").
func Install(nginxSitesDir string) (string, error) {
	token, err := getOrCreateToken()
	if err != nil {
		return "", err
	}

	// Download and extract phpMyAdmin if not present
	if _, err := os.Stat(pmaDir); os.IsNotExist(err) {
		if err := downloadPMA(); err != nil {
			return "", fmt.Errorf("download pma: %w", err)
		}
	}

	// Write config.inc.php
	if err := writeConfig(token); err != nil {
		return "", fmt.Errorf("write pma config: %w", err)
	}

	// Write nginx location block (included by each vhost that needs it,
	// or as a standalone server block on port 80/443)
	if err := writeNginxConf(nginxSitesDir, token); err != nil {
		return "", fmt.Errorf("write nginx pma conf: %w", err)
	}

	return token, nil
}

// Token returns the current secret URL token.
func Token() (string, error) {
	return getOrCreateToken()
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func getOrCreateToken() (string, error) {
	dir := filepath.Dir(tokenFile)
	os.MkdirAll(dir, 0700)

	data, err := os.ReadFile(tokenFile)
	if err == nil {
		t := strings.TrimSpace(string(data))
		if t != "" {
			return t, nil
		}
	}

	// Generate new token
	b := make([]byte, 12)
	rand.Read(b)
	token := "pma_" + hex.EncodeToString(b)

	if err := os.WriteFile(tokenFile, []byte(token), 0600); err != nil {
		return "", err
	}
	return token, nil
}

func downloadPMA() error {
	url := fmt.Sprintf(
		"https://files.phpmyadmin.net/phpMyAdmin/%s/phpMyAdmin-%s-all-languages.tar.gz",
		pmaVersion, pmaVersion,
	)

	tarPath := "/tmp/phpmyadmin.tar.gz"

	// Download
	out, err := exec.Command("curl", "-fsSL", "-o", tarPath, url).CombinedOutput()
	if err != nil {
		return fmt.Errorf("curl: %s — %w", string(out), err)
	}

	// Extract to /var/www
	os.MkdirAll("/var/www", 0755)
	out, err = exec.Command("tar", "-xzf", tarPath, "-C", "/var/www").CombinedOutput()
	if err != nil {
		return fmt.Errorf("tar: %s — %w", string(out), err)
	}

	// Rename extracted dir
	extractedDir := fmt.Sprintf("/var/www/phpMyAdmin-%s-all-languages", pmaVersion)
	if err := os.Rename(extractedDir, pmaDir); err != nil {
		return fmt.Errorf("rename: %w", err)
	}

	os.Remove(tarPath)
	return nil
}

func writeConfig(token string) error {
	blowfishSecret := randomHex(32)

	config := fmt.Sprintf(`<?php
$cfg['blowfish_secret'] = '%s';
$i = 0;
$i++;
$cfg['Servers'][$i]['auth_type']     = 'cookie';
$cfg['Servers'][$i]['host']          = '127.0.0.1';
$cfg['Servers'][$i]['connect_type']  = 'tcp';
$cfg['Servers'][$i]['compress']      = false;
$cfg['Servers'][$i]['AllowNoPassword'] = false;
$cfg['UploadDir'] = '';
$cfg['SaveDir']   = '';
$cfg['SendErrorReports'] = 'never';
// Security: hide phpMyAdmin version
$cfg['ShowPhpInfo'] = false;
$cfg['ShowServerInfo'] = false;
$cfg['ShowChgPassword'] = true;
// Secret URL path (stored so nginx knows it)
$cfg['PmaAbsoluteUri'] = '/%s/';
`, blowfishSecret, token)

	os.MkdirAll(pmaDir, 0755)
	return os.WriteFile(filepath.Join(pmaDir, "config.inc.php"), []byte(config), 0640)
}

func writeNginxConf(sitesDir, token string) error {
	conf := fmt.Sprintf(`# phpMyAdmin — accessed via secret URL /%s/
location = /%s {
    return 301 /%s/;
}
location /%s/ {
    alias %s/;
    index index.php;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $request_filename;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1d;
        add_header Cache-Control "public";
    }

    # Deny access to sensitive files
    location ~ ^/%s/(libraries|setup)/ {
        deny all;
    }
}
`, token, token, token, token, pmaDir, token)

	// Write as an include snippet, not a full vhost
	snippetPath := filepath.Join(sitesDir, "../snippets/eupanel-pma.conf")
	os.MkdirAll(filepath.Dir(snippetPath), 0755)
	return os.WriteFile(snippetPath, []byte(conf), 0644)
}

func randomHex(n int) string {
	b := make([]byte, n)
	rand.Read(b)
	return hex.EncodeToString(b)
}
