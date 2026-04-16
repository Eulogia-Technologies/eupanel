package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/eucloudhost/eupanel-agent/internal/api"
	"github.com/eucloudhost/eupanel-agent/internal/config"
)

const banner = `
  _____      ____                  _
 | ____| _  |  _ \ __ _ _ __   ___| |
 |  _|  (_) | |_) / _' | '_ \ / _ \ |
 | |___  _  |  __/ (_| | | | |  __/ |
 |_____|| | |_|   \__,_|_| |_|\___|_|
        |_|   Agent v0.1.0
`

func main() {
	fmt.Print(banner)

	cfg := config.Load()

	log.Printf("EuPanel Agent starting on port %s", cfg.Port)
	log.Printf("Web root: %s", cfg.WebRoot)
	log.Printf("Nginx sites: %s", cfg.NginxSitesDir)

	router := api.NewRouter(cfg)

	addr := fmt.Sprintf("127.0.0.1:%s", cfg.Port)
	log.Printf("Listening on %s (localhost only)", addr)

	if err := http.ListenAndServe(addr, router); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
