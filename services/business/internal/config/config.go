package config

import "os"

type Config struct {
	Port         string
	PostgresHost string
	PostgresPort string
	PostgresUser string
	PostgresPass string
	PostgresDB   string
	JWTSecret    string
}

func Load() Config {
	return Config{
		Port:         getenv("PORT", "8303"),
		PostgresHost: getenv("POSTGRES_HOST", "localhost"),
		PostgresPort: getenv("POSTGRES_PORT", "5432"),
		PostgresUser: getenv("POSTGRES_USER", "nusa_dhipa"),
		PostgresPass: getenv("POSTGRES_PASSWORD", "change_me"),
		PostgresDB:   getenv("POSTGRES_DB", "nusa_dhipa"),
		JWTSecret:    getenv("JWT_SECRET", "change-this-secret"),
	}
}

func getenv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
