import Foundation
import Combine

public protocol Flow {
    associatedtype FlowResult
    func perform() async -> FlowResult
}

extension Flow {
    public typealias Continuation = CheckedContinuation<FlowResult, Never>
}

public protocol TabEmbedFlow: Flow {
    @MainActor func viewController() async -> Routable
}
