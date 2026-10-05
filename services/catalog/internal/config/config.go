package config

import "os"

type Config struct {
	Port       string
	DBHost     string
	DBPort     string
	DBName     string
	DBUser     string
	DBPassword string
	JWTSecret  string
}

func getenv(key, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	return value
}

func Load() Config {
	return Config{
		Port:       getenv("PORT", "8304"),
		DBHost:     getenv("DB_HOST", "localhost"),
		DBPort:     getenv("DB_PORT", "15440"),
		DBName:     getenv("DB_NAME", "nusa_dhipa"),
		DBUser:     getenv("DB_USER", "nusa_dhipa"),
		DBPassword: getenv("DB_PASSWORD", "change_me"),
		JWTSecret:  getenv("JWT_SECRET", "nusa-dhipa-development-secret-change-me"),
	}
}
