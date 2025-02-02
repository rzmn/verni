package prodLoggingService

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"verni/internal/services/logging"
	standartOutputLoggingService "verni/internal/services/logging/standartOutput"
	"verni/internal/services/watchdog"
)

type ProdLoggerConfig struct {
	Watchdog         watchdog.Service
	LoggingDirectory string
}

func New(config ProdLoggerConfig) logging.Service {
	return &prodLoggingService{
		consoleLogger:   standartOutputLoggingService.New(),
		watchdog:        config.Watchdog,
		logsDirectory:   config.LoggingDirectory,
		watchdogContext: createWatchdogContext(),
	}
}

type watchdogContext struct {
	capacity int
	size     int
	head     int
	data     []string
}

func (c *watchdogContext) Append(value string) {
	if c.size < c.capacity {
		c.size += 1
	}
	c.data[c.head] = value
	c.head += 1
	c.head %= c.capacity
}

func (c *watchdogContext) Array() []string {
	result := make([]string, c.size)
	startIndex := (c.head - c.size + c.capacity) % c.capacity
	for i := 0; i < c.size; i++ {
		result[i] = c.data[(startIndex+i)%c.capacity]
	}
	return result
}

func createWatchdogContext() watchdogContext {
	capacity := 1000
	return watchdogContext{
		capacity: capacity,
		size:     0,
		head:     0,
		data:     make([]string, capacity),
	}
}

type prodLoggingService struct {
	consoleLogger   logging.Service
	watchdog        watchdog.Service
	logsDirectory   string
	watchdogContext watchdogContext
}

func (c *prodLoggingService) LogInfo(format string, v ...any) {
	message := prepare(format, v...)
	c.consoleLogger.LogInfo(message)
	c.writeToFile(message)
	c.watchdogContext.Append(message)
}

func (c *prodLoggingService) LogError(format string, v ...any) {
	withoutTag := prepare(format, v...)
	c.consoleLogger.LogError(withoutTag)
	message := fmt.Sprintf("[error] %s", withoutTag)
	c.writeToFile(message)
	c.watchdogContext.Append(message)
	c.fireWatchdog(message)
}

func (c *prodLoggingService) LogFatal(format string, v ...any) {
	withoutTag := prepare(format, v...)
	message := fmt.Sprintf("[error] %s", withoutTag)
	c.writeToFile(message)
	c.watchdogContext.Append(message)
	c.fireWatchdog(message)
	c.consoleLogger.LogFatal(withoutTag)
}

func prepare(format string, v ...any) string {
	startupTime := time.Now()
	message := fmt.Sprintf(format, v...)
	message = fmt.Sprintf("[%s] %s", startupTime.Format("2006.01.02 15:04:05"), message)
	return message
}

func (c *prodLoggingService) writeToFile(message string) {
	path := getLogPath(c.logsDirectory)
	f, err := os.OpenFile(path, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0644)
	if err != nil {
		message := message + "\n" + fmt.Sprintf("[panic] cannot open log file: %v", err)
		c.watchdog.NotifyMessage(message)
		c.consoleLogger.LogFatal(message)
		return
	}
	if _, err = f.WriteString(message + "\n"); err != nil {
		message := message + "\n" + fmt.Sprintf("[panic] cannot write to log file: %v", err)
		c.watchdog.NotifyMessage(message)
		c.consoleLogger.LogFatal(message)
		return
	}
}

func (c *prodLoggingService) fireWatchdog(message string) {
	file, err := os.CreateTemp("", "watchdogContext")
	if err != nil {
		c.watchdog.NotifyMessage(fmt.Sprintf("[panic] shutting down wd, reason: cannot create logs file err: %v", err))
		return
	}
	context := strings.Join(c.watchdogContext.Array(), "\n")
	if _, err = file.WriteString(context); err != nil {
		c.watchdog.NotifyMessage(fmt.Sprintf("[panic] shutting down wd, reason: cannot write logs to file err: %v", err))
		return
	}
	c.watchdog.NotifyMessage(fmt.Sprintf("internal error: %s", message))
	c.watchdog.NotifyFile(file.Name())
}

func getLogPath(directory string) string {
	return filepath.Join(directory, "./1.log")
}
