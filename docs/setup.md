# Detailed Setup Guide

This guide will help you set up both the server and iOS client development environments.

## Prerequisites

### Server Development
- Go 1.22 or later
- PostgreSQL 14 or later
- Git

### iOS Development
- macOS Sonoma or later
- Xcode 15.0 or later
- iOS 17.0 SDK
- Swift 6.0

## Server Setup

### 1. Database Setup

```bash
# Start PostgreSQL service
brew services start postgresql@14

# Create database and user
psql postgres

# In psql console:
CREATE USER verni_user WITH PASSWORD 'your_password';
CREATE DATABASE verni_db;
GRANT ALL PRIVILEGES ON DATABASE verni_db TO verni_user;
```

### 2. Configuration

Create a `config.json` file:

```json
{
  "storage": {
    "type": "postgres",
    "config": {
      "host": "123hjg.com",
      "port": 2145,
      "user": "213jhg123",
      "password": "312hg",
      "dbName": "2j1h3g"
    }
  },
  "pushNotifications": {
    "type": "apns",
    "config": {
      "certificatePath": "./some/path/certificate.p12",
      "credentialsPath": "./some/path/credentials.json"
    }
  },
  "emailSender": {
    "type": "yandex",
    "config": {
      "address": "dfsjh123@yyye.ru",
      "password": "gzzcmxyjpksxcxje",
      "host": "smtp.21hg3f123hgf.ru",
      "port": "213"
    }
  },
  "jwt": {
    "type": "default",
    "config": {
      "accessTokenLifetimeHours": 1,
      "refreshTokenLifetimeHours": 720,
      "refreshTokenSecret": "2hj1g3jh123g",
      "accessTokenSecret": "213hjg12jh123"
    }
  },
  "server": {
    "type": "default",
    "config": {
      "timeoutSec": 4,
      "idleTimeoutSec": 60,
      "runMode": "release",
      "port": "4321"
    }
  },
  "watchdog": {
    "type": "telegram",
    "config": {
      "token": "312jhg312j",
      "channelId": -1234
    }
  }
}
```

### 3. Initialize Database Schema

```bash
cd ./server/cmd/utilities
go build .
./utilities --command create-tables --config-path ./path/to/config.json
```

### 4. Run the Server

```bash
cd ./server
go build cmd/verni/main.go
./main --config-path ./path/to/config.json
```

## iOS Setup

### 1. Environment Setup

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Clone the repository
git clone https://github.com/rzmn/verni.git
cd verni
```

### 2. Project Configuration

1. Open `iosclient/Verni.xcodeproj` in Xcode
2. Select your development team in project settings
3. Configure app in `Packages/Assembly/Sources/Configuration.swift`:

```swift
struct Configuration {
    static let endpoint = "https://verni.app"
    static let appUrlSchema = "verni"
    static let webcredentials = "verni.com"
    static let appGroupId = "group.com.rzmn.dev.verni"
    static let dataVersionLabel = "v5"
}
```

### 3. Build and Run

1. Select `Verni` target
2. Build and run the project (⌘R)

## Next Steps

- Review [Architecture Overview](./architecture.md)
- Explore [API Documentation](https://verni.app/docs)