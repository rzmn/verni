package envBasedPathProvider

import (
	"os"
	"path/filepath"

	"verni/internal/services/logging"
	"verni/internal/services/pathProvider"
)

// findProjectRoot returns the path to the project root (where go.mod is located)
func findProjectRoot() (string, error) {
	// Start with the current working directory
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}

	// Keep going up until we find go.mod or hit the root
	for {
		// Check if go.mod exists in current directory
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir, nil
		}

		// Go up one directory
		parent := filepath.Dir(dir)
		if parent == dir {
			// We've hit the root without finding go.mod
			return "", os.ErrNotExist
		}
		dir = parent
	}
}

func New(logger logging.Service) pathProvider.Service {
	root, err := findProjectRoot()
	if err != nil {
		logger.LogFatal("failed to find `go.mod` file location: %s", err)
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
