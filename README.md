![Go Report Card](https://goreportcard.com/badge/github.com/rzmn/governi)
![Server Build](https://github.com/rzmn/verni/actions/workflows/build_server.yml/badge.svg)
![Server Test](https://github.com/rzmn/verni/actions/workflows/test_server.yml/badge.svg)
![Swift Version](https://img.shields.io/badge/swift-6.0-orange)
![iOS Build](https://github.com/rzmn/verni/actions/workflows/build_ios.yml/badge.svg)
![iOS Test](https://github.com/rzmn/verni/actions/workflows/test_ios.yml/badge.svg)

![iOS Test Coverage](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.jsonbin.io%2Fv3%2Fb%2F66e66909acd3cb34a884adb5%2Flatest&query=record.coverage&label=iOS%20Code%20Coverage)
![Go Test Coverage](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.jsonbin.io%2Fv3%2Fb%2F67dd1f9c8960c979a575ac87%2Flatest&query=record.coverage&label=Go%20Code%20Coverage)

# Verni - A Modern Expense Sharing App

Verni is an open-source expense sharing app that prioritizes simplicity, privacy, and reliability. Built with modern technologies and a focus on offline-first functionality, Verni helps you manage shared expenses without compromising on user experience or data privacy.

## ✨ Key Features

- 🔒 **Privacy First**: Your financial data stays on your device. No tracking, no ads, no data mining.
- 🌐 **Works Offline**: Full functionality without internet - sync when you're back online
- 🚀 **Modern Stack**: Go 1.22 backend + Swift 6.0 iOS client with clean architecture
- 💯 **Free Forever**: No premium features, no paywalls - just pure functionality
- 🔄 **Real-time Sync**: Server-Sent Events (SSE) for instant updates across devices
- 🎯 **Local-First**: Start using without an account, sync data when you're ready

## 🎯 Perfect for Contributors Who Want To:

- Learn modern Go/Swift development with clean architecture
- Gain experience with offline-first and real-time sync implementations
- Get involved in the very early stages of development
- Contribute to a production-ready mobile application
- Implement and improve test coverage across different layers

## 🚀 Quick Start

### iOS Development
```sh
# Clone the repository
git clone https://github.com/rzmn/verni.git
cd verni

# Open the Xcode project
open iosclient/Verni.xcodeproj
# Run the 'Verni' scheme
```

### Server Development
```sh
# Install PostgreSQL
# Create database and user (see detailed setup in docs)

# Create tables
cd ./server/cmd/utilities
go build .
./utilities --command create-tables --config-path ./config.json

# Run the server
cd ../
go build cmd/verni/main.go
./main --config-path ./config.json
```

## 🌟 Current Focus Areas

We're actively working on these areas and welcome contributions:

- 📱 UI/UX Implementation
  - Login and registration flows
  - Profile management
  - Expense creation and listing
  - Group management interfaces

- 🎨 Design System
  - Building a comprehensive design system
  - Component library development
  - Accessibility guidelines
  - Dark/Light mode support

- 🔧 Core Features
  - Friend system implementation
  - Balance calculations
  - Transaction history
  - Push/Email notifications

- 🧪 Testing & Quality
  - Unit tests for business logic

> 🎯 **Design Status**: We're currently working on a complete UI/UX in Figma. The current implementation serves as a proof of concept while we develop a more polished and user-friendly interface. Figma file will be published soon.

## 🏗 Architecture Overview

Both server and client follow clean architecture principles with clear separation of concerns:

### Server (Go)
- **Repositories**: Data storage with rollback support
- **Controllers**: Business logic coordination
- **Request Handlers**: HTTP endpoint management
- **Services**: Third-party integrations

### iOS (Swift)
- **Data Layer**: Networking, persistence, serialization
- **Domain Layer**: Business logic and use cases
- **Presentation Layer**: Redux-pattern UI implementation
- **Infrastructure**: System-wide utilities

## 📚 Documentation

- [Detailed Setup Guide](./docs/setup.md)
- [Architecture Overview](./docs/architecture.md)
- [API Documentation](https://verni.app/docs)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">❤️</p>
