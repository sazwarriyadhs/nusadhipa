package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/nusa-dhipa/business-os/packages/database"
	"github.com/nusa-dhipa/business-os/services/auth/internal/httpapi"
)

func main() {
	ctx := context.Background()

	db, err := database.Connect(ctx, database.Config{
		Host:     getenv("DB_HOST", "localhost"),
		Port:     getenv("DB_PORT", "15440"),
		Database: getenv("DB_NAME", "nusa_dhipa"),
		User:     getenv("DB_USER", "nusa_dhipa"),
		Password: getenv("DB_PASSWORD", "change_me"),
	})
	if err != nil {
		log.Fatalf("database connection failed: %v", err)
	}
	defer db.Close()

	jwtSecret := getenv("JWT_SECRET", "dev-secret-change-me")

	handler := &httpapi.Handler{DB: db, JWTSecret: jwtSecret}
	router := httpapi.NewRouter(handler)

	port := getenv("PORT", "8301")

	server := &http.Server{
		Addr:              ":" + port,
		Handler:           router,
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	log.Printf("auth service listening on :%s", port)

	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("server failed: %v", err)
	}
}

func getenv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
