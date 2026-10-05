package main

import (
	"log"
	"net/http"
	"time"

	"github.com/nusa-dhipa/business-os/services/api_gateway/internal/config"
	"github.com/nusa-dhipa/business-os/services/api_gateway/internal/httpapi"
)

func main() {
	cfg := config.Load()

	router := httpapi.NewRouter(&httpapi.Handler{
		AuthURL:      cfg.AuthURL,
		TenantURL:    cfg.TenantURL,
		BusinessURL:  cfg.BusinessURL,
		LegalURL:     cfg.LegalURL,
		JWTSecret:    cfg.JWTSecret,
		CatalogURL:   cfg.CatalogURL,
		OrderURL:     cfg.OrderURL,
		InventoryURL: cfg.InventoryURL,
		AIURL:        cfg.AIURL,
	})

	server := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           httpapi.CORSMiddleware(router),
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	log.Printf("api gateway listening on :%s", cfg.Port)

	if err := server.ListenAndServe(); err != nil &&
		err != http.ErrServerClosed {
		log.Printf("server failed: %v", err)
	}
}
