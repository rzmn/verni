import Combine

@MainActor public protocol ActionHandler<Action> {
    associatedtype Action: Sendable
    func handle(_ action: Action)
    var id: String { get }
}

@MainActor public struct AnyActionHandler<Action: Sendable>: ActionHandler {
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
    private var handlers = [any ActionHandler<Action>]()

    public init(
        state: State,
        reducer: @MainActor @escaping (State, Action) -> State
    ) {
        self.state = state
        self.reducer = reducer
    }

    public func append(handler: some ActionHandler<Action>, keepingUnique: Bool) {
        if keepingUnique {
            removeHandler(handler.id)
        }
        handlers.append(handler)
    }

    public func update(handler: some ActionHandler<Action>) {
        handlers = handlers.map {
            $0.id == handler.id ? handler : $0
        }
    }

    public func removeHandler(_ id: String) {
        handlers.removeAll(where: { $0.id == id })
    }

    public func dispatch(_ action: Action) {
        state = reducer(state, action)
        for handler in handlers {
            handler.handle(action)
        }
    }
}
