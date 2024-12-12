import AsyncExtensions
import Logging

public actor ExternallyUpdatable<T: Sendable> {
    private var object: T?
    private var actions: [@Sendable (T) -> T] = []
    private let broadcast: AsyncSubject<T>

    public init(taskFactory: TaskFactory, logger: Logger) {
        broadcast = AsyncSubject(taskFactory: taskFactory, logger: logger)
    }
}

extension ExternallyUpdatable {
    public var relevant: AsyncSubject<T> {
        broadcast
    }

    public func update(_ object: T) async {
        self.object = object
        self.actions = []
        await publish()
    }

    public func add(action: @Sendable @escaping (T) -> T) async {
        actions.append(action)
        await publish()
    }

    private func publish() async {
        guard let object else {
            return
        }
        await broadcast.yield(
            actions.reduce(object) { current, action in
                action(current)
            }
        )
    }
}
