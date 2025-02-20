import AsyncExtensions

public protocol RemoteUpdatesService: Sendable {
    var eventSource: any EventSource<RemoteUpdate> { get async }
    
    func start() async
    func stop() async
}
