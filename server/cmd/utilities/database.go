package main

import (
	"encoding/json"

	"verni/internal/db"
	postgresDb "verni/internal/db/postgres"
	"verni/internal/services/logging"
)

type databaseActions struct {
	setup func()
	drop  func()
}

func createDatabaseActions(configData []byte, logger logging.Service) (databaseActions, error) {
	var postgresConfig postgresDb.PostgresConfig
	json.Unmarshal(configData, &postgresConfig)
	logger.LogInfo("creating postgres with config %v", postgresConfig)
	database, err := postgresDb.Postgres(postgresConfig, logger)
	if err != nil {
		logger.LogFatal("failed to initialize postgres err: %v", err)
	}
	logger.LogInfo("initialized postgres")
	return databaseActions{
		setup: func() {
			for _, table := range tables() {
				if err := table.create(database); err != nil {
					logger.LogInfo("failed to create table %s err: %v", err, table.name)
				}
				logger.LogInfo("created table %s", table.name)
			}
		},
		drop: func() {
			for _, table := range tables() {
				if err := table.delete(database); err != nil {
					logger.LogInfo("failed to drop table %s err: %v", err, table.name)
				}
				logger.LogInfo("droped table %s", table.name)
			}
		},
	}, nil
}

type table struct {
	name   string
	create func(db db.DB) error
	delete func(db db.DB) error
}

func tables() []table {
	return []table{
		{
			name: "credentials",
			create: func(db db.DB) error {
				_, err := db.Exec(`
				CREATE TABLE credentials(
					userId text NOT NULL PRIMARY KEY,
					email text NOT NULL,
					password text NOT NULL,
					emailVerified bool NOT NULL
				);`)
				return err
			},
			delete: func(db db.DB) error {
				_, err := db.Exec(`DROP TABLE credentials;`)
				return err
			},
		},
		{
			name: "refreshTokens",
			create: func(db db.DB) error {
				_, err := db.Exec(`
				CREATE TABLE refreshTokens(
					userId text NOT NULL,
					deviceId text NOT NULL,
					refreshToken text NOT NULL,
					PRIMARY KEY(userId, deviceId)
				);`)
				return err
			},
			delete: func(db db.DB) error {
				_, err := db.Exec(`DROP TABLE refreshTokens;`)
				return err
			},
		},
		{
			name: "operations",
			create: func(db db.DB) error {
				_, err := db.Exec(`
				CREATE TABLE operations(
					operationId text NOT NULL PRIMARY KEY,
					createdAt bigint NOT NULL,
					authorId text NOT NULL,
					operationType text NOT NULL,
					isLarge text NOT NULL,
					data BYTEA NOT NULL,
					searchHint text
				);`)
				return err
			},
			delete: func(db db.DB) error {
				_, err := db.Exec(`DROP TABLE operations;`)
				return err
			},
		},
		{
			name: "confirmedOperations",
			create: func(db db.DB) error {
				_, err := db.Exec(`
				CREATE TABLE confirmedOperations(
					userId text NOT NULL,
					deviceId text NOT NULL,
					operationId text NOT NULL,
					PRIMARY KEY(userId, deviceId, operationId)
				);`)
				return err
			},
			delete: func(db db.DB) error {
				_, err := db.Exec(`DROP TABLE confirmedOperations;`)
				return err
			},
		},
		{
			name: "trackedEntities",
			create: func(db db.DB) error {
				_, err := db.Exec(`
				CREATE TABLE trackedEntities(
					userId text NOT NULL,
					entityId text NOT NULL,
					entityType text NOT NULL,
					PRIMARY KEY(userId, entityId, entityType)
				);`)
				return err
			},
			delete: func(db db.DB) error {
				_, err := db.Exec(`DROP TABLE trackedEntities;`)
				return err
			},
		},
		{
			name: "operationsAffectingEntity",
			create: func(db db.DB) error {
				_, err := db.Exec(`
				CREATE TABLE operationsAffectingEntity(
					operationId text NOT NULL,
					entityId text NOT NULL,
					entityType text NOT NULL,
					PRIMARY KEY(operationId, entityId, entityType)
				);`)
				return err
			},
			delete: func(db db.DB) error {
				_, err := db.Exec(`DROP TABLE operationsAffectingEntity;`)
				return err
			},
		},
		{
			name: "images",
			create: func(db db.DB) error {
				_, err := db.Exec(`
				CREATE TABLE images(
					id text NOT NULL PRIMARY KEY,
					base64 text NOT NULL
				);`)
				return err
			},
			delete: func(db db.DB) error {
				_, err := db.Exec(`DROP TABLE images;`)
				return err
			},
		},
		{
			name: "pushTokens",
			create: func(db db.DB) error {
				_, err := db.Exec(`
				CREATE TABLE pushTokens(
					userId text NOT NULL,
					deviceId text NOT NULL,
					token text NOT NULL,
					PRIMARY KEY(userId, deviceId)
				);`)
				return err
			},
			delete: func(db db.DB) error {
				_, err := db.Exec(`DROP TABLE pushTokens;`)
				return err
			},
		},
		{
			name: "emailVerification",
			create: func(db db.DB) error {
				_, err := db.Exec(`
				CREATE TABLE emailVerification(
					email text NOT NULL PRIMARY KEY,
					code text
				);`)
				return err
			},
			delete: func(db db.DB) error {
				_, err := db.Exec(`DROP TABLE emailVerification;`)
				return err
			},
		},
	}
}
