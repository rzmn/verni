import Combine

@MainActor public struct ActionExecutor<Action: Sendable>: Sendable {
    let action: Action
    private let executor: (@MainActor () -> Void)?

    public static func make(action: Action, executor: (@MainActor () -> Void)? = nil) -> Self {
        Self(action: action, executor: executor)
    }

    func execute() {
        executor?()
    }
}

public protocol ActionExecutorFactory<Action> {
    associatedtype Action: Sendable

    @MainActor func executor(for action: Action) -> ActionExecutor<Action>
}

public struct FakeActionExecutorFactory<Action: Sendable>: ActionExecutorFactory {
    public init() {}

    public func executor(for action: Action) -> ActionExecutor<Action> {
        .make(action: action)
    }
}

@MainActor public final class Store<State: Sendable & Equatable, Action: Sendable>: ObservableObject {
    @Published public private(set) var state: State
    let reducer: @MainActor (State, Action) -> State

    public init(
        state: State,
        reducer: @MainActor @escaping (State, Action) -> State
    ) {
        self.state = state
        self.reducer = reducer
    }

    public func dispatch(_ executor: ActionExecutor<Action>) {
        state = reducer(state, executor.action)
        executor.execute()
    }
}

extension Store {
    @MainActor public struct StoreWithFactory {
        let store: Store
        let factory: any ActionExecutorFactory<Action>

        public func dispatch(_ action: Action) {
            store.dispatch(factory.executor(for: action))
        }
    }

    public func with(
        _ factory: any ActionExecutorFactory<Action>
    ) -> StoreWithFactory {
        StoreWithFactory(store: self, factory: factory)
    }
}
