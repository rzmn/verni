import Foundation

public protocol AvatarsRepository: Sendable {
    func get(ids: [Avatar.Identifier]) async -> [Avatar.Identifier: Data]
    func getIfCached(id: Avatar.Identifier) -> Data?
}

public enum AvatarsRepositoryError: Error, Sendable {
    case idDoesNotExist
    case hasNoData
}

public extension AvatarsRepository {
    func get(id: Avatar.Identifier) async -> Data? {
        await get(ids: [id])[id]
    }
}
