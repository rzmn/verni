import Foundation

public protocol AvatarsRepository {
    func get(ids: [Avatar.ID]) async -> Result<[Avatar.ID: Data], GeneralError>
}

public enum AvatarsRepositoryError: Error {
    case idDoesNotExist
    case hasNoData
}

public extension AvatarsRepository {
    func get(id: Avatar.ID) async -> Result<Data, GeneralError> {
        switch await get(ids: [id]) {
        case .success(let data):
            guard let data = data.first?.value else {
                return .failure(.other(AvatarsRepositoryError.idDoesNotExist))
            }
            return .success(data)
        case .failure(let error):
            return .failure(error)
        }
    }
}
