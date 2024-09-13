import Combine

public actor ExternallyUpdatable<T: Sendable> {
    private var object: T?
    private var actions: [@Sendable (T) -> T] = []
    private let subject = PassthroughSubject<T, Never>()

    public init() {}
}

extension ExternallyUpdatable {
    public var relevant: AnyPublisher<T, Never> {
        subject.eraseToAnyPublisher()
    }

    public func update(_ object: T) {
        self.object = object
        self.actions = []
        subject.send(object)
    }

    public func add(action: @Sendable @escaping (T) -> T) {
        guard let object else {
            return
        }
        actions.append(action)
        subject.send(
            actions.reduce(object) { current, action in
                action(current)
            }
        )
    }
}
