internal import Convenience

public struct LastWriteWinsCRDT<Entity: Sendable>: Sendable {
    public struct Operation: TimeOrderedOperation {
        public enum Kind: Sendable {
            case mutate(@Sendable (Entity) -> Entity)
            case create(Entity)
            case delete
        }
        public let kind: Kind
        public let id: String
        public let timestamp: Int64
        
        public init(kind: Kind, id: String, timestamp: Int64) {
            self.kind = kind
            self.id = id
            self.timestamp = timestamp
        }
    }
    private let initial: Entity?
    private let history: [(entity: Entity?, operation: Operation)]

    public init(
        initial: Entity?,
        history: [(entity: Entity?, operation: Operation)] = []
    ) {
        self.initial = initial
        self.history = history
    }
}

extension LastWriteWinsCRDT {
    public var value: Entity? {
        history.last?.entity ?? initial
    }

    public func byInserting(operation: Operation) -> Self {
        byInserting(operations: [operation])
    }

    public func byInserting(operations: [Operation]) -> Self {
        let operations = (history.map(\.operation) + operations)
            .reduce(
                into: [:]
            ) { dict, operation in
                dict[operation.id] = operation
            }
            .values
            .ordered()
        var current = initial
        return Self(
            initial: initial,
            history: operations.map { operation in
                switch operation.kind {
                case .create(let value):
                    current = value
                case .mutate(let action):
                    current = current.flatMap(action)
                case .delete:
                    current = nil
                }
                return (entity: current, operation: operation)
            }
        )
    }
}
