package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/nusa-dhipa/business-os/services/order/internal/config"
	"github.com/nusa-dhipa/business-os/services/order/internal/httpapi"
	"github.com/nusa-dhipa/business-os/services/order/internal/repository"
	"github.com/nusa-dhipa/business-os/services/order/internal/service"
)

func main() {
	cfg := config.Load()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	dbURL := fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s",
		cfg.DBUser,
		cfg.DBPassword,
		cfg.DBHost,
		cfg.DBPort,
		cfg.DBName,
	)

	db, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		log.Fatalf("database pool: %v", err)
	}
	defer db.Close()

	if err := db.Ping(ctx); err != nil {
		log.Fatalf("database ping: %v", err)
	}

	repo := repository.New(db)
	svc := service.New(repo)
	router := httpapi.NewRouter(svc, cfg.JWTSecret)

	server := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           router,
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	log.Printf("order service listening on :%s", cfg.Port)

	if err := server.ListenAndServe(); err != nil &&
		err != http.ErrServerClosed {
		log.Fatalf("server: %v", err)
	}
}
