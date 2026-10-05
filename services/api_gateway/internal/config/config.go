package config

import "os"

type Config struct {
	Port         string
	AuthURL      string
	TenantURL    string
	BusinessURL  string
	CatalogURL   string
	OrderURL     string
	InventoryURL string
	LegalURL     string
	AIURL        string
	JWTSecret    string
}

func Load() Config {
	return Config{
		Port:         getenv("PORT", "8300"),
		AuthURL:      getenv("AUTH_URL", "http://localhost:8301"),
		TenantURL:    getenv("TENANT_URL", "http://localhost:8302"),
		BusinessURL:  getenv("BUSINESS_URL", "http://localhost:8303"),
		CatalogURL:   getenv("CATALOG_URL", "http://localhost:8304"),
		OrderURL:     getenv("ORDER_URL", "http://localhost:8305"),
		InventoryURL: getenv("INVENTORY_URL", "http://localhost:8305"),
		LegalURL:     getenv("LEGAL_URL", "http://localhost:8327"),
		AIURL:        getenv("AI_URL", "http://localhost:8390"),
		JWTSecret:    getenv("JWT_SECRET", "dev-secret-change-me"),
	}
}

func getenv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}

	return fallback
}