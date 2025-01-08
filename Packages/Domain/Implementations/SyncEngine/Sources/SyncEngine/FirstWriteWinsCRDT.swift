import Domain
import Foundation
import Base

struct FirstWriteWinsCRDT<Entity> {
    struct Operation {
        let perform: (Entity) -> Entity
        var performInPlace: (inout Entity) -> Void {
            return { entity in
                entity = perform(entity)
            }
        }
        let id: String
        let timestamp: TimeInterval

        init<T>(
            id: String,
            timestamp: TimeInterval,
            keyPath: WritableKeyPath<Entity, T>,
            value: T
        ) {
            self.id = id
            self.timestamp = timestamp
            perform = { entity in
                modify(entity) {
                    $0[keyPath: keyPath] = value
                }
            }
        }
    }
    private let initial: Entity
    private let history: [(entity: Entity, operation: Operation)]

    init(entity: Entity) {
        self = Self(initial: entity, history: [])
    }

    private init(initial: Entity, history: [(entity: Entity, operation: Operation)]) {
        self.initial = initial
        self.history = history
    }
}

extension FirstWriteWinsCRDT {
    var value: Entity {
        history.last?.entity ?? initial
    }

    func byInserting(operation: Operation) -> FirstWriteWinsCRDT {
        byInserting(operations: [operation])
    }

    func byInserting(operations: [Operation]) -> FirstWriteWinsCRDT {
        let operations = (history.map(\.operation) + operations)
            .reduce(
                into: [:]
            ) { dict, operation in
                dict[operation.id] = operation
            }
            .values
            .sorted { lhs, rhs in
                lhs.timestamp < rhs.timestamp
            }
        var current = initial
        return FirstWriteWinsCRDT(
            initial: initial,
            history: operations.map { operation in
                operation.performInPlace(&current)
                return (entity: current, operation: operation)
            }
        )
    }
}
