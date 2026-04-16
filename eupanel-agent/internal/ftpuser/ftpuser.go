package ftpuser

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
	vsftpdUserDir  = "/etc/vsftpd/users"
	vsftpdUserFile = "/etc/vsftpd/virtual_users.txt"
	vsftpdPamFile  = "/etc/pam.d/vsftpd-virtual"
	vsftpdConf     = "/etc/vsftpd.conf"
)

// Create creates a virtual FTP user for vsftpd.
// Returns the generated FTP username.
func Create(username, homeDirectory string) (string, error) {
	if !isValidFTPUsername(username) {
		return "", fmt.Errorf("invalid FTP username: %q", username)
	}

	// Ensure vsftpd is installed
	if _, err := exec.LookPath("vsftpd"); err != nil {
		return "", fmt.Errorf("vsftpd is not installed — run: apt install vsftpd")
	}

	// Generate a random password for this FTP user
	password := randomPassword()

	// Create per-user config directory
	userConfDir := filepath.Join(vsftpdUserDir, username)
	if err := os.MkdirAll(userConfDir, 0700); err != nil {
		return "", fmt.Errorf("failed to create vsftpd user dir: %w", err)
	}

	// Write per-user vsftpd config
	userConf := fmt.Sprintf(`local_root=%s
write_enable=YES
download_enable=YES
`, homeDirectory)
	confPath := filepath.Join(vsftpdUserDir, username+".conf")
	if err := os.WriteFile(confPath, []byte(userConf), 0600); err != nil {
		return "", fmt.Errorf("failed to write vsftpd user config: %w", err)
	}

	// Add to virtual users password db
	if err := addVirtualUser(username, password); err != nil {
		os.Remove(confPath)
		return "", fmt.Errorf("failed to add virtual FTP user: %w", err)
	}

	// Reload vsftpd
	reloadVsftpd()

	return username, nil
}

// Delete removes a virtual FTP user.
func Delete(username string) error {
	if !isValidFTPUsername(username) {
		return fmt.Errorf("invalid FTP username: %q", username)
	}

	// Remove per-user config
	os.Remove(filepath.Join(vsftpdUserDir, username+".conf"))
	os.RemoveAll(filepath.Join(vsftpdUserDir, username))

	// Remove from virtual users db
	removeVirtualUser(username)

	reloadVsftpd()
	return nil
}

// ── Virtual user management ───────────────────────────────────────────────────

// addVirtualUser appends user:pass to the virtual users file and rebuilds the db.
func addVirtualUser(username, password string) error {
	os.MkdirAll(filepath.Dir(vsftpdUserFile), 0700)

	// Read existing
	existing, _ := os.ReadFile(vsftpdUserFile)
	lines := strings.Split(strings.TrimSpace(string(existing)), "\n")

	// Remove existing entry for this user if any
	var filtered []string
	skipNext := false
	for _, line := range lines {
		if skipNext {
			skipNext = false
			continue
		}
		if strings.TrimSpace(line) == username {
			skipNext = true
			continue
		}
		filtered = append(filtered, line)
	}

	// Append new user
	filtered = append(filtered, username, password)
	content := strings.Join(filtered, "\n") + "\n"

	if err := os.WriteFile(vsftpdUserFile, []byte(content), 0600); err != nil {
		return fmt.Errorf("write virtual users file: %w", err)
	}

	// Rebuild berkeley db
	out, err := exec.Command("db_load", "-T", "-t", "hash",
		"-f", vsftpdUserFile,
		"/etc/vsftpd/virtual_users.db").CombinedOutput()
	if err != nil {
		// db_load may not be installed
		out2, err2 := exec.Command("db5.3_load", "-T", "-t", "hash",
			"-f", vsftpdUserFile,
			"/etc/vsftpd/virtual_users.db").CombinedOutput()
		if err2 != nil {
			return fmt.Errorf("db_load failed: %s — %w (also tried db5.3_load: %s)", string(out), err, string(out2))
		}
	}

	return nil
}

func removeVirtualUser(username string) {
	existing, err := os.ReadFile(vsftpdUserFile)
	if err != nil {
		return
	}

	lines := strings.Split(strings.TrimSpace(string(existing)), "\n")
	var filtered []string
	skipNext := false
	for _, line := range lines {
		if skipNext {
			skipNext = false
			continue
		}
		if strings.TrimSpace(line) == username {
			skipNext = true
			continue
		}
		filtered = append(filtered, line)
	}

	content := strings.Join(filtered, "\n") + "\n"
	os.WriteFile(vsftpdUserFile, []byte(content), 0600)

	exec.Command("db_load", "-T", "-t", "hash",
		"-f", vsftpdUserFile,
		"/etc/vsftpd/virtual_users.db").Run()
}

func reloadVsftpd() {
	exec.Command("systemctl", "reload-or-restart", "vsftpd").Run()
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func isValidFTPUsername(username string) bool {
	if len(username) == 0 || len(username) > 64 {
		return false
	}
	for _, c := range username {
		if !((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_') {
			return false
		}
	}
	return true
}

func randomPassword() string {
	b := make([]byte, 12)
	rand.Read(b)
	return hex.EncodeToString(b)
}
