package defaultServer

import (
	"errors"
	"net/http"
	"path/filepath"
	"time"

	openapi "verni/internal/openapi/go"
	"verni/internal/server"
	"verni/internal/services/logging"
	"verni/internal/services/pathProvider"
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
	pathProvider pathProvider.Service,
	logger logging.Service,
) server.Server {
	logger.LogInfo("creating http server with config %v", config)
	router := openapi.NewRouter(
		openapi.NewDefaultAPIController(
			servicer,
			openapi.WithDefaultAPIErrorHandler(ErrorHandler),
		),
	)
	staticDir := pathProvider.AbsolutePath("./website/static")
	fs := http.FileServer(http.Dir(staticDir))
	router.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/" {
			http.ServeFile(w, r, filepath.Join(staticDir, "index.html"))
			return
		}
		// For all other paths, serve from static directory
		fs.ServeHTTP(w, r)
	})
	router.HandleFunc("/favicon.ico", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, filepath.Join(staticDir, "favicon.ico"))
	})
	router.HandleFunc("/openapi.yaml", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/yaml")
		http.ServeFile(w, r, pathProvider.AbsolutePath("./openapi.yaml"))
	})
	router.HandleFunc("/docs", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, filepath.Join(staticDir, "docs/index.html"))
	})
	router.HandleFunc("/operationsQueue", sseHandler)
	router.HandleFunc("/.well-known/apple-app-site-association", aasaHandler)
	router.HandleFunc("/apple-app-site-association", aasaHandler)
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

func ErrorHandler(w http.ResponseWriter, _ *http.Request, err error, _ *openapi.ImplResponse) {
	var (
		code        = http.StatusInternalServerError
		description *string
		reason      = openapi.INTERNAL
	)

	var parsingErr *openapi.ParsingError
	if ok := errors.As(err, &parsingErr); ok {
		code = http.StatusBadRequest
		desc := err.Error()
		description = &desc
		reason = openapi.BAD_REQUEST
	}

	var requiredErr *openapi.RequiredError
	if ok := errors.As(err, &requiredErr); ok {
		code = http.StatusBadRequest
		desc := err.Error()
		description = &desc
		reason = openapi.BAD_REQUEST
	}

	_ = openapi.EncodeJSONResponse(openapi.Response(code, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      reason,
			Description: description,
		},
	}), &code, w)
}
