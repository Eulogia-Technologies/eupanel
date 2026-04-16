package config

import "os"

type Config struct {
	// HTTP
	Port      string
	SecretKey string

	// Paths
	WebRoot       string
	NginxSitesDir string
	NginxBin      string
	CertbotBin    string

	// Server identity
	ServerID string
	Hostname string
}

func Load() *Config {
	hostname, _ := os.Hostname()

	return &Config{
		Port:          getEnv("AGENT_PORT", "7820"),
		SecretKey:     getEnv("AGENT_SECRET", "change-me-before-production"),
		WebRoot:       getEnv("AGENT_WEBROOT", "/var/www"),
		NginxSitesDir: getEnv("AGENT_NGINX_SITES", "/etc/nginx/sites-available"),
		NginxBin:      getEnv("AGENT_NGINX_BIN", "/usr/sbin/nginx"),
		CertbotBin:    getEnv("AGENT_CERTBOT_BIN", "/usr/bin/certbot"),
		ServerID:      getEnv("AGENT_SERVER_ID", ""),
		Hostname:      hostname,
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
