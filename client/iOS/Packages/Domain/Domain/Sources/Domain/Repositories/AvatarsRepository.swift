import Foundation

public protocol AvatarsRepository {
    func get(ids: [Avatar.ID]) async throws(GeneralError) -> [Avatar.ID: Data]
}

public enum AvatarsRepositoryError: Error {
    case idDoesNotExist
    case hasNoData
}

public extension AvatarsRepository {
    func get(id: Avatar.ID) async throws(GeneralError) -> Data {
        let data = try await get(ids: [id])
        guard let data = data.first?.value else {
            throw .other(AvatarsRepositoryError.idDoesNotExist)
        }
        return data
    }
}
