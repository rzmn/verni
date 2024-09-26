import Combine

@MainActor public final class Store<State: Sendable & Equatable, Action: Sendable>: ObservableObject {
    @Published public private(set) var state: State
    public let handle: @MainActor (Action) -> Void

    public init(
        current: State,
        publisher: Published<State>.Publisher? = nil,
        handle: @MainActor @escaping (Action) -> Void
    ) {
        self.state = current
        self.handle = handle
        publisher?.assign(to: &$state)
    }
}
