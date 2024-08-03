import Foundation

public protocol ThrowingFlow {
    associatedtype Success
    associatedtype Failure: Error

    func perform() async -> Result<Success, Failure>
}

public protocol Flow {
    associatedtype Success

    func perform() async -> Success
}
