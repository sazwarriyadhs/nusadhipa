package config

import "os"

type Config struct {
	Port         string
	PostgresHost string
	PostgresPort string
	PostgresUser string
	PostgresPass string
	PostgresDB   string
	RedisHost    string
	RedisPort    string
	JWTSecret    string
}

func Load() Config {
	return Config{
		Port:         getenv("PORT", "8305"),
		PostgresHost: getenv("DB_HOST", "localhost"),
		PostgresPort: getenv("DB_PORT", "15440"),
		PostgresUser: getenv("DB_USER", "nusa_dhipa"),
		PostgresPass: getenv("DB_PASSWORD", "change_me"),
		PostgresDB:   getenv("DB_NAME", "nusa_dhipa"),
		RedisHost:    getenv("REDIS_HOST", "localhost"),
		RedisPort:    getenv("REDIS_PORT", "16390"),
		JWTSecret:    getenv("JWT_SECRET", "nusa-dhipa-development-secret-change-me"),
	}
}

func getenv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}

	return fallback
}
