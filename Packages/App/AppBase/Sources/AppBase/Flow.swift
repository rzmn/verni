import Foundation
import Combine
import SwiftUI

public protocol Flow: Sendable {
    associatedtype FlowResult
    func perform() async -> FlowResult
}

public protocol SUIFlow<FlowResult, Body>: Sendable {
    associatedtype FlowResult: Sendable
    associatedtype Body: View

    @ViewBuilder @MainActor
    func instantiate(handler: @MainActor @escaping (FlowResult) -> Void) -> Body
}

extension Flow {
    public typealias Continuation = CheckedContinuation<FlowResult, Never>
}

public protocol TabEmbedFlow: Flow {
    @MainActor func viewController() async -> Routable
}
