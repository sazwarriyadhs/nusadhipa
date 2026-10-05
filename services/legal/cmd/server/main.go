package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/nusa-dhipa/business-os/packages/database"
	"github.com/nusa-dhipa/business-os/services/legal/internal/httpapi"
)

func getenv(key, fallback string) string {
	value := os.Getenv(key)

	if value == "" {
		return fallback
	}

	return value
}

func main() {
	ctx, cancel := context.WithTimeout(
		context.Background(),
		10*time.Second,
	)
	defer cancel()

	db, err := database.Connect(
		ctx,
		database.Config{
			Host:     getenv("DB_HOST", "localhost"),
			Port:     getenv("DB_PORT", "15440"),
			Database: getenv("DB_NAME", "nusa_dhipa"),
			User:     getenv("DB_USER", "nusa_dhipa"),
			Password: getenv("DB_PASSWORD", "change_me"),
		},
	)

	if err != nil {
		log.Printf("database connection failed: %v", err)
		return
	}

	defer db.Close()

	jwtSecret := getenv("JWT_SECRET", "dev-secret-change-me")

	handler := &httpapi.Handler{
		DB: db,
	}

	router := httpapi.NewRouter(handler, jwtSecret)

	port := getenv("PORT", "8327")

	server := &http.Server{
		Addr:              ":" + port,
		Handler:           router,
		ReadHeaderTimeout: 10 * time.Second,
	}

	log.Printf("legal service listening on :%s", port)

	if err := server.ListenAndServe(); err != nil &&
		err != http.ErrServerClosed {
		log.Printf("server stopped: %v", err)
	}
}
