import Combine

@MainActor public protocol Middleware<Action> {
    associatedtype Action: Sendable
    func handle(_ action: Action)
    var id: String { get }
}

@MainActor public struct AnyMiddleware<Action: Sendable>: Middleware {
    public let id: String
    private let handleBlock: @MainActor (Action) -> Void

    public init(id: String, handleBlock: @MainActor @escaping (Action) -> Void) {
        self.id = id
        self.handleBlock = handleBlock
    }

    public func handle(_ action: Action) {
        handleBlock(action)
    }
}

@MainActor public final class Store<State: Sendable & Equatable, Action: Sendable>: ObservableObject {
    @Published public private(set) var state: State
    let reducer: @MainActor (State, Action) -> State
    private var middlewares = [any Middleware<Action>]()

    public init(
        state: State,
        reducer: @MainActor @escaping (State, Action) -> State
    ) {
        self.state = state
        self.reducer = reducer
    }

    public func append(middleware: some Middleware<Action>, keepingUnique: Bool) {
        if keepingUnique {
            removeMiddleware(middleware.id)
        }
        middlewares.append(middleware)
    }

    public func update(middleware: some Middleware<Action>) {
        middlewares = middlewares.map {
            $0.id == middleware.id ? middleware : $0
        }
    }

    public func removeMiddleware(_ id: String) {
        middlewares.removeAll(where: { $0.id == id })
    }

    public func dispatch(_ action: Action) {
        state = reducer(state, action)
        for middleware in middlewares {
            middleware.handle(action)
        }
    }
}
