# Verni

[![Swift Version](https://img.shields.io/badge/swift-6.0-orange)](https://img.shields.io/badge/swift-6.0-orange)
[![Xcode - Build and Analyze](https://github.com/rzmn/Verni.App.iOS/actions/workflows/build.yml/badge.svg)](https://github.com/rzmn/Verni.App.iOS/actions/workflows/build.yml)
[![Xcode - Test](https://github.com/rzmn/Verni.App.iOS/actions/workflows/test.yml/badge.svg)](https://github.com/rzmn/Verni.App.iOS/actions/workflows/test.yml)
[![Code Coverage](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.jsonbin.io%2Fv3%2Fb%2F66e66909acd3cb34a884adb5%2Flatest&query=%24.record.coverage&label=Code%20Coverage)](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.jsonbin.io%2Fv3%2Fb%2F66e66909acd3cb34a884adb5%2Flatest&query=%24.record.coverage&label=Code%20Coverage)

---
# Verni
Open-source shared expenses tracker

**Project is under development.**
# Table of Contents
1. [👋 About](https://github.com/rzmn/swiftverni?tab=readme-ov-file#about)
2. [👀 What's Verni?](https://github.com/rzmn/swiftverni?tab=readme-ov-file#whats-verni)
3. [📋 Tech Stack](https://github.com/rzmn/swiftverni?tab=readme-ov-file#tech-stack)
4. [🚀 Features](https://github.com/rzmn/swiftverni?tab=readme-ov-file#features)
5. [💡 Architecture Overview](https://github.com/rzmn/swiftverni?tab=readme-ov-file#architecture-overview)
6. [⚙️ Implementation Overview](https://github.com/rzmn/swiftverni?tab=readme-ov-file#implementation-overview)
## About
This project started as a system design practice. Over time, it evolved into the idea of ​​a product whose core value would be the scalability and reliability of the components it was made of. Components mean all stages of the implementation: starting from the codebase and ending with the design system.

The main feature for final users is a complete absence of a desire to monetize user journeys. The user's needs should be met in the simplest possible way, forever free.

## What's Verni?
Verni is a mobile-first shared expenses tracker mostly inspired by [splitwise](https://www.splitwise.com/). The app keeps track of your shared expenses and balances with friends.

[Verni Server Side](https://github.com/rzmn/governi/)

## Tech stack

- swift testing
- strict concurrency
- swiftui
- SPM

## Features

- tbd

## Architecture/Implementation overview

The App's architecture can be considered as a set of _Layers_. Each layer knows only about the layer "below".

```mermaid
graph LR
    DataLayer(Data Layer) -- managing data for --> DomainLayer(Domain Layer)
    DomainLayer(Domain Layer)-. knows about .-> DataLayer(Data Layer)
    DomainLayer(Domain Layer) -- business logic --> PresentationLayer(App Layer)
    PresentationLayer(App Layer)-. knows about .-> DomainLayer(Domain Layer)
```

Each part of domain or data layer has its own *abstract* module containing a set of protocols/entities and at least one *implementation* module. If necessary, implementation modules can be dependent on the infrastructure layer.

<details>
  <summary>Dependency graph</summary>

```mermaid
graph LR
    Infrastructure(Infrastructure Layer) -- utility/analytics/logging --> DataLayer(Data Layer Implementations)
    Infrastructure(Infrastructure Layer) -- utility/analytics/logging --> DomainLayer(Domain Layer Implementations)
    Infrastructure(Infrastructure Layer) -- utility/analytics/logging --> PresentationLayer(App Layer Implementations)
```

</details>

No *abstract* module depends on any *implementation* module, which is strictly prohibited to ensure proper encapsulation. It can guarantee that touching implementations will not trigger recompilation of other implementation modules, only that of the final target, which in most cases can leverage incremental compilation.

It is highly recommended to keep *abstract* modules without any dependencies to provide better testability. There may be few exceptions: for example it would be redundant to keep presentation layer parts independent of domain entities.

Each *module* is provided as a *Swift Package*.

### Data Layer

The Data Layer is mostly about how to store, fetch and serialize data.

`DataTransferObjects` - Serializable Data Types

`Networking` - HTTP Networking Service

`ApiService` - Authorization and Data Serialization Service

`Api` - REST API Schema and Polling

`PersistentStorage` - Persistent Data Storage

Networking service implementation is URLSession-based, service is responsible to perform request retries (exponential backoff). Reachability retries are considered to be responsibility of the App Layer. 

Api Service is responsible for refreshing token (JWT) when a request fails due token expiration and then restarting it with a refreshed token. The Api Service can make N requests simultaneously keeping relevant refresh token for each one.

Serialization is Codable-based, the same object types are used both in Api Schema and Persistent Storage. Storage is sqlite3 database.

### Domain Layer

The Domain Layer contains three kind of objects describing business logic

- Entities - pure data representing core concepts of a problem domain

- Repositories - read-only data providers

- Use Cases - user scenarios

Repositories are designed to allow subscription to data updates. When repository has a subscription, it is listening for remote updates via api polling. Every data update is cached in persistent storage.

However, Domain Layer has mutable extensions for offline repositories. Is was made for convenient injection in the regular repositories to update caches, keeping proper encapsulation. Mutable extensions are supposed to be unavailable from App Layer, therefore they are not provided by DI, unlike the immutable ones.

Use cases have access to repositories. Use cases are able to provide a "data update hint" to repository to avoid unnecessary api calls. For example if we have a "Profile Repository" for profile that contains an e-mail, when the e-mail is updated by "E-mail Update Use Case", it would be OK for use case to provide just a closure that can update some profile's e-mail to repository, without making api call to get relevant profile info. That closure (one or more, sequential) will be removed on the next api call to get profile. See `ExternallyUpdatable` for implementation details.

### App (Presentation) Layer

The App Layer is a set of _Screens_. _Screen_ is a complete and reusable fragment of some user story. _Screen_ should be able to appear from anywhere. Navigation is being managed by screen coordinator

Each _Screen_ is provided as a _Swift Package_. Each *Screen* is not dependent on any other _Screen_. The screen itself is made up of redux-like components:

```mermaid
flowchart
    View(View) -- creating actions --> ActionHandler(Action Handler)
    subgraph Store
    ActionHandler(Action Handler) -- delivers actions --> Reducer(Reducer)
    end
    Reducer(Reducer) -. creates state .-> View(View)
    ActionHandler(Action Handler) -- interacting with --> SideEffects(Side Effects)
    SideEffects(Side Effects) -. creating actions .-> ActionHandler(Action Handler)
```

#### View

- View is a function of state

- Subscribed to state updates

- Sending user actions

<details>
  <summary>View Example Implementation</summary>

```swift
struct ExampleView: View {
    @ObservedObject private var store: Store<State, Action>

    var body: some View {
        Button {
            store.dispatch(.buttonTapped)
        } label: {
            Text(store.state.buttonTitle)    
        }
    }
}
```

</details>

#### Store

- Responding to user actions

- Holds screen state

<details>
  <summary>Store Example Implementation</summary>

```swift
class ExampleStore<State, Action>: Store {
    @Published var state: State
    private var handlers: [ActionHandler<Action>]
    private let reducer: (State, Action) -> State

    func dispatch(action: Action) {
        state = reducer(state, action)
        for handler in handlers {
            handler.handle(action)
        }
    }
}
```

</details>

#### Reducer

- Pure function returning a new state based on user action and the prevous state

#### Action Handler

- Handling user actions

- Dealing with side effects

- Producing new actions if necessary


<details>
  <summary>Action Handler Example Implementation</summary>

```swift
class ExampleActionHandler<Action>: ActionHandler {
    private unowned let store: Store<State, Action>
    private let api: Api

    func handle(action: Action) {
        switch action {
        case .onRefreshDataTap: refreshData()
        default: break
        }
    }

    private func refreshData() {
        store.dispatch(.dataIsLoading)
        Task {
            do {
                let data = try api.loadData()
                store.dispatch(.dataLoaded(data))
            } catch {
                store.dispatch(.loadDataFailed(error))
            }
        }
    }
}
```

</details>
