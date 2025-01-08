import Foundation

public protocol AvatarsRemoteDataSource {
    func fetch(
        ids: [Avatar.Identifier]
    ) async -> [Avatar.Identifier: Data]
}

extension AvatarsRemoteDataSource {
    public func fetch(
        id: Avatar.Identifier
    ) async -> Data? {
        await fetch(ids: [id])[id]
    }
}
