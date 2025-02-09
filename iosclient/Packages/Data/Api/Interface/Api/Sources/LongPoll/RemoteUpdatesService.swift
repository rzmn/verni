import AsyncExtensions

public protocol RemoteUpdatesService: Sendable {
    func subscribe() async -> any EventSource<RemoteUpdate>
}
