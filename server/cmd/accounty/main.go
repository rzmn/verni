package main

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"

	"accounty/internal/config"
	"accounty/internal/http-server/router/auth"
	"accounty/internal/http-server/router/friends"
	"accounty/internal/http-server/router/users"
	"accounty/internal/storage/sqlite"
)

func main() {
	cfg := config.Load()

	sqlStorage, err := sqlite.New(cfg.StoragePath)
	if err != nil {
		log.Fatalf("failed to init storage: %s", err)
	}

	gin.SetMode(cfg.Server.RunMode)
	router := gin.New()
	auth.RegisterRoutes(router, sqlStorage)
	users.RegisterRoutes(router, sqlStorage)
	friends.RegisterRoutes(router, sqlStorage)

	server := &http.Server{
		Addr:         cfg.Server.Address,
		Handler:      router,
		ReadTimeout:  cfg.Server.IdleTimeout,
		WriteTimeout: cfg.Server.IdleTimeout,
	}
	log.Printf("[info] start http server listening %s", cfg.Server.Address)

	server.ListenAndServe()
}
