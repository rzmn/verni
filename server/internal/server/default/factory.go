package defaultServer

import (
	"net/http"
	"time"

	openapi "verni/internal/openapi/go"
	"verni/internal/server"
	"verni/internal/services/logging"
)

type ServerConfig struct {
	TimeoutSec     int    `json:"timeoutSec"`
	IdleTimeoutSec int    `json:"idleTimeoutSec"`
	RunMode        string `json:"runMode"`
	Port           string `json:"port"`
}

func New(
	config ServerConfig,
	sseHandler func(w http.ResponseWriter, r *http.Request),
	servicer openapi.DefaultAPIServicer,
	logger logging.Service,
) server.Server {
	logger.LogInfo("creating gin server with config %v", config)
	router := openapi.NewRouter(
		openapi.NewDefaultAPIController(
			servicer,
		),
	)
	router.HandleFunc("/operationsQueue", sseHandler)
	return &defaultServer{
		server: http.Server{
			Addr:         ":" + config.Port,
			Handler:      router,
			ReadTimeout:  time.Second * time.Duration(config.IdleTimeoutSec),
			WriteTimeout: time.Second * time.Duration(config.IdleTimeoutSec),
		},
		logger: logger,
	}
}
