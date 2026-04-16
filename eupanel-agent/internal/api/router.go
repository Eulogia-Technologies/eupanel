package api

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"

	"github.com/eucloudhost/eupanel-agent/internal/config"
)

func NewRouter(cfg *config.Config) http.Handler {
	r := chi.NewRouter()

	// Middleware
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.RequestID)
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins: []string{"http://127.0.0.1:*", "http://localhost:*"},
		AllowedMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders: []string{"Authorization", "Content-Type"},
	}))
	r.Use(authMiddleware(cfg.SecretKey))

	h := &Handlers{cfg: cfg}

	// Health
	r.Get("/health", h.Health)

	// Domains
	r.Route("/domains", func(r chi.Router) {
		r.Get("/", h.ListDomains)
		r.Post("/", h.CreateDomain)
		r.Delete("/{domain}", h.DeleteDomain)
	})

	// SSL
	r.Route("/ssl", func(r chi.Router) {
		r.Post("/{domain}/issue", h.IssueSSL)
		r.Post("/{domain}/renew", h.RenewSSL)
		r.Get("/{domain}/status", h.SSLStatus)
	})

	// Nginx
	r.Route("/nginx", func(r chi.Router) {
		r.Post("/reload", h.ReloadNginx)
		r.Get("/status", h.NginxStatus)
	})

	// Databases
	r.Route("/databases", func(r chi.Router) {
		r.Get("/", h.ListDatabases)
		r.Post("/", h.CreateDatabase)
		r.Delete("/{db}", h.DeleteDatabase)
	})

	// phpMyAdmin
	r.Route("/phpmyadmin", func(r chi.Router) {
		r.Get("/url", h.PMAUrl)
		r.Post("/install", h.PMAInstall)
	})

	// System
	r.Route("/system", func(r chi.Router) {
		r.Get("/info", h.SystemInfo)
		r.Get("/disk", h.DiskUsage)
	})

	return r
}
