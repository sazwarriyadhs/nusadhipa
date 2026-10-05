package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/nusa-dhipa/business-os/packages/database"
	"github.com/nusa-dhipa/business-os/packages/events"
	"github.com/nusa-dhipa/business-os/services/business/internal/httpapi"
)

func main() {
	port := getenv("PORT", "8303")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

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

	redisHost := getenv("REDIS_HOST", "localhost")
	redisPort := getenv("REDIS_PORT", "16390")

	eventPublisher := events.NewRedisPublisher(redisHost, redisPort)
	defer eventPublisher.Close()
	handler := httpapi.NewRouter(&httpapi.Handler{
		DB:        db,
		JWTSecret: getenv("JWT_SECRET", "nusa-dhipa-development-secret-change-me"),
		Events:    eventPublisher,
	})

	server := &http.Server{
		Addr:              ":" + port,
		Handler:           handler,
		ReadHeaderTimeout: 10 * time.Second,
	}

	log.Printf("business service listening on :%s", port)

	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}

func getenv(key, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	return value
}
