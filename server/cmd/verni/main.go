package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"time"

	"verni/internal/db"
	postgresDb "verni/internal/db/postgres"
	openapi "verni/internal/openapi/go"
	"verni/internal/openapi/openapiImplementation"
	authRepository "verni/internal/repositories/auth"
	defaultAuthRepository "verni/internal/repositories/auth/default"
	operationsRepository "verni/internal/repositories/operations"
	defaultOperationsRepository "verni/internal/repositories/operations/default"
	pushRegistryRepository "verni/internal/repositories/pushNotifications"
	defaultPushRegistryRepository "verni/internal/repositories/pushNotifications/default"
	verificationRepository "verni/internal/repositories/verification"
	defaultVerificationRepository "verni/internal/repositories/verification/default"
	defaultServer "verni/internal/server/default"

	"verni/internal/server"

	"verni/internal/services/emailSender"
	yandexEmailSender "verni/internal/services/emailSender/yandex"
	"verni/internal/services/formatValidation"
	defaultFormatValidation "verni/internal/services/formatValidation/default"
	"verni/internal/services/jwt"
	defaultJwtService "verni/internal/services/jwt/default"
	"verni/internal/services/logging"
	prodLoggingService "verni/internal/services/logging/prod"
	standartOutputLoggingService "verni/internal/services/logging/standartOutput"
	"verni/internal/services/pathProvider"
	envBasedPathProvider "verni/internal/services/pathProvider/env"
	"verni/internal/services/pushNotifications"
	applePushNotifications "verni/internal/services/pushNotifications/apns"
	"verni/internal/services/realtimeEvents"
	defaultRealtimeEvents "verni/internal/services/realtimeEvents/default"
	"verni/internal/services/watchdog"
	telegramWatchdog "verni/internal/services/watchdog/telegram"

	authController "verni/internal/controllers/auth"
	defaultAuthController "verni/internal/controllers/auth/default"
	imagesController "verni/internal/controllers/images"
	defaultImagesController "verni/internal/controllers/images/default"
	operationsController "verni/internal/controllers/operations"
	defaultOperationsController "verni/internal/controllers/operations/default"
	usersController "verni/internal/controllers/users"
	defaultUsersController "verni/internal/controllers/users/default"
	verificationController "verni/internal/controllers/verification"
	defaultVerificationController "verni/internal/controllers/verification/default"
)

type Repositories struct {
	auth         authRepository.Repository
	operations   operationsRepository.Repository
	pushRegistry pushRegistryRepository.Repository
	verification verificationRepository.Repository
}

type Services struct {
	push                    pushNotifications.Service
	jwt                     jwt.Service
	emailSender             emailSender.Service
	formatValidationService formatValidation.Service
	realtimeEventsService   realtimeEvents.Service
}

type Controllers struct {
	auth         authController.Controller
	images       imagesController.Controller
	operations   operationsController.Controller
	users        usersController.Controller
	verification verificationController.Controller
}

func main() {
	type Module struct {
		Type   string                 `json:"type"`
		Config map[string]interface{} `json:"config"`
	}
	type Config struct {
		Storage           Module `json:"storage"`
		PushNotifications Module `json:"pushNotifications"`
		EmailSender       Module `json:"emailSender"`
		Jwt               Module `json:"jwt"`
		Server            Module `json:"server"`
		Watchdog          Module `json:"watchdog"`
	}
	logger, pathProvider, config := func() (logging.Service, pathProvider.Service, Config) {
		startupTime := time.Now()
		tmpLogger := standartOutputLoggingService.New()
		tmpPathProvider := envBasedPathProvider.New(tmpLogger)
		loggingDirectory := tmpPathProvider.AbsolutePath(
			fmt.Sprintf("./logs/session[%s].log", startupTime.Format("2006.01.02 15:04:05")),
		)
		if err := os.MkdirAll(loggingDirectory, os.ModePerm); err != nil {
			tmpLogger.LogFatal("failed to create logging directory %s", loggingDirectory)
		}
		configFile, err := os.Open(tmpPathProvider.AbsolutePath("./config/prod/verni.json"))
		if err != nil {
			tmpLogger.LogFatal("failed to open config file: %s", err)
		}
		defer configFile.Close()
		configData, err := io.ReadAll(configFile)
		if err != nil {
			tmpLogger.LogFatal("failed to read config file: %s", err)
		}
		var config Config
		json.Unmarshal([]byte(configData), &config)
		watchdog := func() watchdog.Service {
			switch config.Watchdog.Type {
			case "telegram":
				data, err := json.Marshal(config.Watchdog.Config)
				if err != nil {
					tmpLogger.LogFatal("failed to serialize telegram watchdog config err: %v", err)
				}
				var telegramConfig telegramWatchdog.TelegramConfig
				json.Unmarshal(data, &telegramConfig)
				tmpLogger.LogInfo("creating telegram watchdog with config %v", telegramConfig)
				watchdog, err := telegramWatchdog.New(telegramConfig)
				if err != nil {
					tmpLogger.LogFatal("failed to initialize telegram watchdog err: %v", err)
				}
				tmpLogger.LogInfo("initialized telegram watchdog")
				return watchdog
			default:
				tmpLogger.LogFatal("unknown storage type %s", config.Storage.Type)
				return nil
			}
		}()
		logger := prodLoggingService.New(prodLoggingService.ProdLoggerConfig{
			Watchdog:         watchdog,
			LoggingDirectory: loggingDirectory,
		})
		pathProvider := envBasedPathProvider.New(logger)
		return logger, pathProvider, config
	}()
	logger.LogInfo("initializing with config %v", config)

	database := func() db.DB {
		switch config.Storage.Type {
		case "postgres":
			data, err := json.Marshal(config.Storage.Config)
			if err != nil {
				logger.LogFatal("failed to serialize ydb config err: %v", err)
			}
			var postgresConfig postgresDb.PostgresConfig
			json.Unmarshal(data, &postgresConfig)
			logger.LogInfo("creating postgres with config %v", postgresConfig)
			db, err := postgresDb.Postgres(postgresConfig, logger)
			if err != nil {
				logger.LogFatal("failed to initialize postgres err: %v", err)
			}
			logger.LogInfo("initialized postgres")
			return db
		default:
			logger.LogFatal("unknown storage type %s", config.Storage.Type)
			return nil
		}
	}()
	defer database.Close()
	repositories := Repositories{
		auth:         defaultAuthRepository.New(database, logger),
		operations:   defaultOperationsRepository.New(database, logger),
		pushRegistry: defaultPushRegistryRepository.New(database, logger),
		verification: defaultVerificationRepository.New(database, logger),
	}
	services := Services{
		push: func() pushNotifications.Service {
			switch config.PushNotifications.Type {
			case "apns":
				data, err := json.Marshal(config.PushNotifications.Config)
				if err != nil {
					logger.LogFatal("failed to serialize apple apns config err: %v", err)
				}
				var apnsConfig applePushNotifications.ApnsConfig
				json.Unmarshal(data, &apnsConfig)
				logger.LogInfo("creating apple apns service with config %v", apnsConfig)
				service, err := applePushNotifications.New(apnsConfig, logger, pathProvider, repositories.pushRegistry)
				if err != nil {
					logger.LogFatal("failed to initialize apple apns service err: %v", err)
				}
				logger.LogInfo("initialized apple apns service")
				return service
			default:
				logger.LogFatal("unknown apns type %s", config.PushNotifications.Type)
				return nil
			}
		}(),
		jwt: func() jwt.Service {
			switch config.Jwt.Type {
			case "default":
				data, err := json.Marshal(config.Jwt.Config)
				if err != nil {
					logger.LogFatal("failed to serialize jwt config err: %v", err)
				}
				var defaultConfig defaultJwtService.DefaultConfig
				json.Unmarshal(data, &defaultConfig)
				logger.LogInfo("creating jwt token service with config %v", defaultConfig)
				return defaultJwtService.New(
					defaultConfig,
					logger,
					func() time.Time {
						return time.Now()
					},
				)
			default:
				logger.LogFatal("unknown jwt service type %s", config.Jwt.Type)
				return nil
			}
		}(),
		emailSender: func() emailSender.Service {
			switch config.EmailSender.Type {
			case "yandex":
				data, err := json.Marshal(config.EmailSender.Config)
				if err != nil {
					logger.LogFatal("failed to serialize yandex email sender config err: %v", err)
				}
				var yandexConfig yandexEmailSender.YandexConfig
				json.Unmarshal(data, &yandexConfig)
				logger.LogInfo("creating yandex email sender with config %v", yandexConfig)
				return yandexEmailSender.New(yandexConfig, logger)
			default:
				logger.LogFatal("unknown email sender type %s", config.EmailSender.Type)
				return nil
			}
		}(),
		formatValidationService: func() formatValidation.Service {
			return defaultFormatValidation.New(logger)
		}(),
		realtimeEventsService: func() realtimeEvents.Service {
			return defaultRealtimeEvents.NewUserUpdateService()
		}(),
	}
	controllers := Controllers{
		auth: defaultAuthController.New(
			repositories.auth,
			repositories.operations,
			repositories.pushRegistry,
			services.jwt,
			services.formatValidationService,
			logger,
		),
		images: defaultImagesController.New(
			repositories.operations,
			logger,
		),
		operations: defaultOperationsController.New(
			repositories.operations,
			services.realtimeEventsService,
			logger,
		),
		users: defaultUsersController.New(
			repositories.operations,
			logger,
		),
		verification: defaultVerificationController.New(
			repositories.verification,
			repositories.auth,
			services.emailSender,
			logger,
		),
	}
	api := func() openapi.DefaultAPIServicer {
		return openapiImplementation.New(
			controllers.auth,
			controllers.verification,
			controllers.users,
			controllers.images,
			controllers.operations,
			logger,
		)
	}()
	server := func() server.Server {
		switch config.Server.Type {
		case "gin":
			data, err := json.Marshal(config.Server.Config)
			if err != nil {
				logger.LogFatal("failed to serialize default server config err: %v", err)
			}
			var ginConfig defaultServer.ServerConfig
			json.Unmarshal(data, &ginConfig)
			logger.LogInfo("creating gin server with config %v", ginConfig)

			return defaultServer.New(
				ginConfig,
				openapiImplementation.NewSSEHandler(
					services.realtimeEventsService,
					controllers.auth,
					controllers.operations,
					logger,
				),
				api,
				logger,
			)
		default:
			logger.LogFatal("unknown server type %s", config.Server.Type)
			return nil
		}
	}()
	server.ListenAndServe()
}
