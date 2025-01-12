internal import Convenience

struct LastWriteWinsCRDT<Entity> {
    struct Operation: TimeOrderedOperation {
        enum Kind {
            case mutate((Entity) -> Entity)
            case create(Entity)
            case delete
        }
        let kind: Kind
        let id: String
        let timestamp: MsSince1970
    }
    private let initial: Entity?
    private let history: [(entity: Entity?, operation: Operation)]

    init(initial: Entity?, history: [(entity: Entity?, operation: Operation)] = []) {
        self.initial = initial
        self.history = history
    }
}

extension LastWriteWinsCRDT {
    var value: Entity? {
        history.last?.entity ?? initial
    }

    func byInserting(operation: Operation) -> Self {
        byInserting(operations: [operation])
    }

    func byInserting(operations: [Operation]) -> Self {
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
