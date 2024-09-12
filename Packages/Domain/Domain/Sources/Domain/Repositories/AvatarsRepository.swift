import Foundation

public protocol AvatarsRepository: Sendable {
    func get(ids: [Avatar.ID]) async -> [Avatar.ID: Data]
}

public enum AvatarsRepositoryError: Error, Sendable {
    case idDoesNotExist
    case hasNoData
}

public extension AvatarsRepository {
    func get(id: Avatar.ID) async -> Data? {
        await get(ids: [id])[id]
    }
}
