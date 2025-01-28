package defaultServer

import (
	"net/http"

	"verni/internal/services/logging"
)

type defaultServer struct {
	server http.Server
	logger logging.Service
}

func (c *defaultServer) ListenAndServe() {
	c.logger.LogInfo("[info] start http server listening %s", c.server.Addr)
	c.server.ListenAndServe()
}
