import Foundation

public protocol AvatarsOfflineRepository: Sendable {
    func get(for id: Avatar.ID) async -> Data?
}
