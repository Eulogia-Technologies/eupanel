package systemuser

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

// Create creates a Linux system user with a home directory and public_html.
// Returns the home directory path.
func Create(username string) (string, error) {
	if !isValidUsername(username) {
		return "", fmt.Errorf("invalid username: %q — must be lowercase alphanumeric, start with a letter", username)
	}

	homeDir := filepath.Join("/home", username)

	// Create user with home directory, no login shell (hosting-only account)
	out, err := exec.Command(
		"useradd",
		"--create-home",
		"--home-dir", homeDir,
		"--shell", "/usr/sbin/nologin",
		"--comment", "EuPanel hosting account",
		username,
	).CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("useradd failed for %q: %s — %w", username, string(out), err)
	}

	// Create public_html directory
	publicHTML := filepath.Join(homeDir, "public_html")
	if err := os.MkdirAll(publicHTML, 0755); err != nil {
		// User was created — clean up
		exec.Command("userdel", "--remove", username).Run()
		return "", fmt.Errorf("failed to create public_html: %w", err)
	}

	// Set correct ownership
	if err := chownR(homeDir, username); err != nil {
		exec.Command("userdel", "--remove", username).Run()
		return "", fmt.Errorf("failed to set ownership: %w", err)
	}

	// Write a placeholder index.html
	indexPath := filepath.Join(publicHTML, "index.html")
	placeholder := fmt.Sprintf(
		"<!DOCTYPE html><html><head><title>%s</title></head><body><p>Your hosting account is ready.</p></body></html>",
		username,
	)
	os.WriteFile(indexPath, []byte(placeholder), 0644)

	return homeDir, nil
}

// Delete removes a system user and their home directory.
func Delete(username string) error {
	if !isValidUsername(username) {
		return fmt.Errorf("invalid username: %q", username)
	}

	out, err := exec.Command("userdel", "--remove", username).CombinedOutput()
	if err != nil {
		// If user doesn't exist, that's fine
		if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 6 {
			return nil // user doesn't exist — already gone
		}
		return fmt.Errorf("userdel failed for %q: %s — %w", username, string(out), err)
	}
	return nil
}

// Exists checks if a system user exists.
func Exists(username string) bool {
	err := exec.Command("id", username).Run()
	return err == nil
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func chownR(path, username string) error {
	out, err := exec.Command("chown", "-R", username+":"+username, path).CombinedOutput()
	if err != nil {
		return fmt.Errorf("chown failed: %s — %w", string(out), err)
	}
	return nil
}

// isValidUsername enforces safe Linux username rules.
// Must start with a letter, only lowercase alphanumeric + underscore, max 32 chars.
func isValidUsername(username string) bool {
	if len(username) == 0 || len(username) > 32 {
		return false
	}
	if username[0] < 'a' || username[0] > 'z' {
		return false
	}
	for _, c := range username {
		if !((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_') {
			return false
		}
	}
	return true
}
