import Combine

@MainActor public protocol Action<Kind>: Sendable {
    associatedtype Kind: Sendable

    var kind: Kind { get }
    func run()
}

public extension Action {
    func run() {}
}

public protocol ActionsFactory<ActionKind, ActionType> {
    associatedtype ActionKind
    associatedtype ActionType: Action where ActionType.Kind == ActionKind

    @MainActor func action(_ kind: ActionKind) -> ActionType
}

@MainActor public final class Store<State: Sendable & Equatable, ActionType: Action>: ObservableObject {
    @Published public private(set) var state: State
    let reducer: @MainActor (State, ActionType.Kind) -> State

    public init(
        current: State,
        reducer: @MainActor @escaping (State, ActionType.Kind) -> State
    ) {
        self.state = current
        self.reducer = reducer
    }

    public func dispatch(_ action: ActionType) {
        state = reducer(state, action.kind)
        action.run()
    }
}
