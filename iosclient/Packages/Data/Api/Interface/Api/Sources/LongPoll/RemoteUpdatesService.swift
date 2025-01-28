import AsyncExtensions

public protocol RemoteUpdatesService: Sendable {
    func subscribe() async -> any AsyncBroadcast<RemoteUpdate>
}
