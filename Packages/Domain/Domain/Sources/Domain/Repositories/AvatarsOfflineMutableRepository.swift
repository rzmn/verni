import Foundation

public protocol AvatarsOfflineMutableRepository: Sendable {
    func store(data: Data, for id: Avatar.ID) async
}
