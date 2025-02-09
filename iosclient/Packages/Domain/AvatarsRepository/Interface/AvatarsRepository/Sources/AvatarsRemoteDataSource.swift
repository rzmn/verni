import Entities

public protocol AvatarsRemoteDataSource: Sendable {
    func fetch(
        ids: [Image.Identifier]
    ) async -> [Image.Identifier: Image]
}

extension AvatarsRemoteDataSource {
    public func fetch(
        id: Image.Identifier
    ) async -> Image? {
        await fetch(ids: [id])[id]
    }
}
