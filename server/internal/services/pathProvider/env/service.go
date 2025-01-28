package envBasedPathProvider

import (
	"os"
	"path/filepath"

	"verni/internal/services/logging"
	"verni/internal/services/pathProvider"
)

func New(logger logging.Service) pathProvider.Service {
	root, present := os.LookupEnv("VERNI_PROJECT_ROOT")
	if !present {
		logger.LogFatal("`VERNI_PROJECT_ROOT` should be set")
	}
	logger.LogInfo("override relative paths root: %s", root)
	return &defaultService{
		root: root,
	}
}

type defaultService struct {
	root string
}

func (c *defaultService) AbsolutePath(relative string) string {
	return filepath.Join(c.root, relative)
}
