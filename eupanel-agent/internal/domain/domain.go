package domain

import (
	"os"
	"path/filepath"
)

type DomainInfo struct {
	Name    string `json:"name"`
	WebRoot string `json:"web_root"`
	HasSSL  bool   `json:"has_ssl"`
}

// List returns all domains that have a web root directory.
func List(webRoot string) ([]DomainInfo, error) {
	entries, err := os.ReadDir(webRoot)
	if err != nil {
		if os.IsNotExist(err) {
			return []DomainInfo{}, nil
		}
		return nil, err
	}

	var domains []DomainInfo
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		name := entry.Name()
		root := filepath.Join(webRoot, name, "public")

		// Check if web root exists
		if _, err := os.Stat(root); os.IsNotExist(err) {
			continue
		}

		// Check if SSL cert exists
		certPath := filepath.Join("/etc/letsencrypt/live", name, "fullchain.pem")
		_, sslErr := os.Stat(certPath)

		domains = append(domains, DomainInfo{
			Name:    name,
			WebRoot: root,
			HasSSL:  sslErr == nil,
		})
	}

	return domains, nil
}
