package main

import (
	"context"
	"log"
	"net/http"
	"time"

	"github.com/nusa-dhipa/business-os/packages/database"
	"github.com/nusa-dhipa/business-os/packages/events"
	"github.com/nusa-dhipa/business-os/services/inventory_service/internal/config"
	"github.com/nusa-dhipa/business-os/services/inventory_service/internal/httpapi"
)

func main() {
	cfg := config.Load()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	db, err := database.Connect(ctx, database.Config{
		Host:     cfg.PostgresHost,
		Port:     cfg.PostgresPort,
		Database: cfg.PostgresDB,
		User:     cfg.PostgresUser,
		Password: cfg.PostgresPass,
	})
	if err != nil {
		log.Fatalf("database connection failed: %v", err)
	}
	defer db.Close()

	publisher := events.NewRedisPublisher(
		cfg.RedisHost,
		cfg.RedisPort,
	)
	defer publisher.Close()

	handler := httpapi.NewRouter(&httpapi.Handler{
		DB:        db,
		JWTSecret: cfg.JWTSecret,
		Events:    publisher,
	})

	server := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           handler,
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	log.Printf("inventory service listening on :%s", cfg.Port)

	if err := server.ListenAndServe(); err != nil &&
		err != http.ErrServerClosed {
		log.Printf("server failed: %v", err)
	}
}
