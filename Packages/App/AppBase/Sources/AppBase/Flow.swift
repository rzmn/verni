import SwiftUI

public protocol SUIFlow<FlowResult, BodyBuilder>: Sendable {
    associatedtype FlowResult: Sendable
    associatedtype BodyBuilder

    @MainActor func instantiate(handler: @MainActor @escaping (FlowResult) -> Void) -> BodyBuilder
}
