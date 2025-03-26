import AsyncExtensions
import Entities

public protocol OperationsRepository: Sendable {
    var updates: any EventSource<Void> { get }

    subscript(id: Operation.Identifier) -> Operation? { get async }
    var operations: [Operation] { get async }
}
