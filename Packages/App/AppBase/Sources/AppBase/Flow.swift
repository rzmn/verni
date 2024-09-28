import Foundation
import Combine
import SwiftUI

public protocol Flow: Sendable {
    associatedtype FlowResult
    func perform() async -> FlowResult
}

public protocol SUIFlow<FlowResult, BodyBuilder>: Sendable {
    associatedtype FlowResult: Sendable
    associatedtype BodyBuilder

    @MainActor func instantiate(handler: @MainActor @escaping (FlowResult) -> Void) -> BodyBuilder
}

extension Flow {
    public typealias Continuation = CheckedContinuation<FlowResult, Never>
}

public protocol TabEmbedFlow: Flow {
    @MainActor func viewController() async -> Routable
}
