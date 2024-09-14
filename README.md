# The App
[![Xcode - Build and Analyze](https://github.com/rzmn/Accounty-iOS/actions/workflows/build.yml/badge.svg)](https://github.com/rzmn/Accounty-iOS/actions/workflows/build.yml)
[![Xcode - Test](https://github.com/rzmn/Accounty-iOS/actions/workflows/test.yml/badge.svg)](https://github.com/rzmn/Accounty-iOS/actions/workflows/test.yml)

Shared Expenses Tracker App iOS Client.

---

I dreamed of working on a product that wouldn't have boring commercial stuff like supporting 4yr old iOS deployment target or demands to test some random idea ASAP just to measure its impact on user's timestamp or reabstracting awful api designed by incapable of negotiation backend team or whatever. So I made one. 

Let's try to realize the desire to implement the application the way I'd like it to be, keeping focus on scalability, testability and maintainability.

## Tech stack

- swift 6

- strict concurrency

- combine

- UIKit

- SPM

## Features

- tbd

## Architecture/Implementation overview

The App's architecture can be considered as a set of _Layers_. Each layer knows only about the "previous" one. 

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

`Api` - REST API Schema + Polling

`PersistentStorage` - Persistent Data Storage

Networking service is URLSession-based, service is responsible to perform request retries (exponential backoff). Reachability retries are considered to be responsibility of the App Layer. 

Api Service is responsible for refreshing token (JWT) when a request fails due token expiration and then restarting it with a refreshed token. The Api Service can make N requests simultaneously keeping relevant refresh token for each one.

Serialization is Codable-based, the same object types are used both in Api Schema and Persistent Storage. Storage is sqlite3 database.

### Domain Layer

The Domain Layer contains three kind of objects describing business logic

- Entities - pure data representing core concepts of problem domain

- Repositories - read-only data providers

- Use Cases - user scenarios

Repositories are designed to allow subscription to data updates. When repository has a subscription, it is listening for remote updates via api polling. Every data update is cached in persistent storage.

However, Domain Layer has mutable extensions for offline repositories. Is was made for convenient injection in the regular repositories to update caches, keeping proper encapsulation. Mutable extensions are supposed to be unavailable from App Layer, therefore they are not provided by DI, unlike the immutable ones.

Use cases have access to repositories. Use cases are able to provide a "data update hint" to repository to avoid unnecessary api calls. For example if we have a "Profile Repository" for profile that contains an e-mail, when the e-mail is updated by "E-mail Update Use Case", it would be OK for use case to provide just a closure that can update some profile's e-mail to repository, without making api call to get relevant profile info. That closure (one or more, sequential) will be removed on the next api call to get profile. See `ExternallyUpdatable` for implementation details.

### App (Presentation) Layer

The App Layer is a set of _Flows_. _Flow_ is a complete and reusable fragment of some user path.

_Flow_ is presenting and dismissing itself on its own. _Flow_ should be able to start from anywhere.

It's convenient to consider _Flow_ as a single async function:

```swift
public protocol Flow {
    associatedtype FlowResult
    func perform() async -> FlowResult
}
```

<details>
  <summary>Example (Flow for asking for push notification permission)</summary>

```swift
actor AskForPushNotificationPermissionFlow: Flow {
    enum Verdict {
        case allowed, denied
    }
    func perform() async -> Verdict {
        let allowed = await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
        return allowed ? .allowed : .denied
    }
}
```

</details>

Each _Flow_ is provided as a _Swift Package_.

### Flow Components

#### Flow

- Entry point for some user path as described above

- The only public entity in a corresponding swift package

- Interacts with domain layer. (Use Cases, Repositories, Entities)

- _Presenter_ and _ViewModel_ are created by a _Flow_

- Listening for _User Actions_

- Sending updates to _ViewModel_
  
  #### Presenter

- Responsible for UI presentation (view controllers, HUDs, popups etc)

- Interacts with _AppRouter_. _AppRouter_ provides an information about current navigation state.

- _View_ is created by a _Presenter_
  
  #### ViewModel

- Responsible for creating and publishing a _ViewState_ to _ViewActions_

- _ViewModel_ is istening for updates from _Flow_. _ViewState_ is being created based on that updates
  
  #### ViewActions

- Publishing _ViewState_ to _View_

- Listening for user actions from _View_
  
  #### View

- Passive

- Listening for _ViewState_ from _ViewActions_ and renders it

```mermaid
graph LR
    View(View) -- creating and publishing user actions --> ViewActions(View Actions)
    ViewActions(ViewActions) -- publishing user actions --> Flow(Flow)
    ViewModel(View Model) -- creating and publishing view state --> ViewActions(View Actions)
    ViewActions(View Actions) -- publishing view state --> View(View)
    Flow(Flow) -- creating and mutating --> ViewModel(View Model)
    Flow(Flow) -- creating and configuring --> Presenter(Presenter)
    Presenter(Presenter) -- creating and presenting --> View(View)
```

Each flow knows about its direct children only

<details>
  <summary>Flow hierarchy</summary>

```mermaid
graph LR
    App(App) -- if has stored session --> AuthenticatedFlow(AuthenticatedFlow)
    AuthenticatedFlow(AuthenticatedFlow) -- as tab --> AccountFlow(AccountFlow)
    AccountFlow(AccountFlow) -- starts --> UpdateAvatarFlow(UpdateAvatarFlow)
    AccountFlow(AccountFlow) -- starts --> QrPreviewFlow(QrPreviewFlow)
    AccountFlow(AccountFlow) -- starts --> UpdatePasswordFlow(UpdatePasswordFlow)
    AccountFlow(AccountFlow) -- starts --> UpdateDisplayNameFlow(UpdateDisplayNameFlow)
    AccountFlow(AccountFlow) -- starts --> UpdateEmailFlow(UpdateEmailFlow)
    AuthenticatedFlow(AuthenticatedFlow) -- as tab --> FriendsFlow(FriendsFlow)
    FriendsFlow(FriendsFlow) -- starts --> UserPreviewFlow(UserPreviewFlow)
    AuthenticatedFlow(AuthenticatedFlow) -- starts --> AddExpenseFlow(AddExpenseFlow)
    AddExpenseFlow(AddExpenseFlow) -- starts --> PickCounterpartyFlow(PickCounterpartyFlow)
    App(App) -- if does not have stored session --> UnauthenticatedFlow(UnauthenticatedFlow)
    UnauthenticatedFlow(UnauthenticatedFlow) -- as tab --> SignInFlow(SignInFlow)
    SignInFlow(SignInFlow) -- starts --> SignUpFlow(SignUpFlow)
```

</details>