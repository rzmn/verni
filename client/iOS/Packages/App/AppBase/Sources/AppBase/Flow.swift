import Foundation
import Combine

public struct FlowContinuation<T> {
    public let continuation: CheckedContinuation<T, Never>
    public let willFinishHandler: ((T) async -> Void)?

    public init(continuation: CheckedContinuation<T, Never>, willFinishHandler: ((T) async -> Void)?) {
        self.continuation = continuation
        self.willFinishHandler = willFinishHandler
    }
}

public protocol Flow {
    associatedtype FlowResult
    typealias Continuation = FlowContinuation<FlowResult>

    func perform(
        willFinish: ((FlowResult) async -> Void)?
    ) async -> FlowResult
}

public extension Flow {
    func perform() async -> FlowResult {
        await perform(willFinish: nil)
    }
}

public protocol TabEmbedFlow: Flow {
    @MainActor func viewController() async -> Routable
}
