package certbot

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// Issue obtains a new certificate for the domain.
func Issue(certbotBin, domain, email string) error {
	args := []string{
		"certonly",
		"--nginx",
		"--non-interactive",
		"--agree-tos",
		"--email", email,
		"-d", domain,
		"-d", "www." + domain,
	}

	out, err := exec.Command(certbotBin, args...).CombinedOutput()
	if err != nil {
		return fmt.Errorf("certbot issue failed for %s: %s — %w", domain, string(out), err)
	}
	return nil
}

// Renew renews an existing certificate.
func Renew(certbotBin, domain string) error {
	args := []string{
		"renew",
		"--cert-name", domain,
		"--non-interactive",
	}

	out, err := exec.Command(certbotBin, args...).CombinedOutput()
	if err != nil {
		return fmt.Errorf("certbot renew failed for %s: %s — %w", domain, string(out), err)
	}
	return nil
}

// Status checks certificate status and expiry.
func Status(domain string) (status string, expiry *time.Time, err error) {
	certPath := filepath.Join("/etc/letsencrypt/live", domain, "fullchain.pem")

	out, err := exec.Command("openssl", "x509", "-enddate", "-noout", "-in", certPath).Output()
	if err != nil {
		return "none", nil, nil // no cert yet — not an error
	}

	// Parse: "notAfter=Apr 10 12:00:00 2026 GMT"
	line := strings.TrimSpace(string(out))
	parts := strings.SplitN(line, "=", 2)
	if len(parts) != 2 {
		return "unknown", nil, nil
	}

	t, err := time.Parse("Jan  2 15:04:05 2006 MST", strings.TrimSpace(parts[1]))
	if err != nil {
		// Try alternate format
		t, err = time.Parse("Jan _2 15:04:05 2006 MST", strings.TrimSpace(parts[1]))
		if err != nil {
			return "unknown", nil, nil
		}
	}

	now := time.Now()
	if t.Before(now) {
		return "expired", &t, nil
	}
	if t.Before(now.Add(30 * 24 * time.Hour)) {
		return "expiring_soon", &t, nil
	}
	return "valid", &t, nil
}
