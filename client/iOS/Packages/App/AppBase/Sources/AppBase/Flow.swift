import Foundation
import Combine

public protocol Flow {
    associatedtype FlowResult
    func perform() async -> FlowResult
}

extension Flow {
    public typealias Continuation = CheckedContinuation<FlowResult, Never>
}

public protocol FlowEventHandler<FlowEvent>: Identifiable {
    associatedtype FlowEvent
    func handle(event: FlowEvent) async
}

public struct AnyFlowEventHandler<FlowEvent>: FlowEventHandler {
    public let id: AnyHashable
    private let handleImpl: (FlowEvent) async -> Void

    public init<Impl: FlowEventHandler>(_ impl: Impl) where Impl.FlowEvent == FlowEvent {
        id = impl.id
        handleImpl = impl.handle(event:)
    }

    public init(id: AnyHashable, handle: @escaping (FlowEvent) async -> Void) {
        self.id = id
        handleImpl = handle
    }

    public func handle(event: FlowEvent) async {
        await handleImpl(event)
    }
}

public protocol FlowEvents {
    associatedtype FlowEvent

    func addHandler<T: FlowEventHandler>(handler: T) async where T.FlowEvent == FlowEvent
    func removeHandler<T: FlowEventHandler>(handler: T) async where T.FlowEvent == FlowEvent
}

public protocol TabEmbedFlow: Flow {
    @MainActor func viewController() async -> Routable
}
