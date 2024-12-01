import Foundation

public protocol AvatarsOfflineRepository: Sendable {
    func get(for id: Avatar.Identifier) -> Data?
}
