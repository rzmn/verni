import Foundation

protocol AvatarsRepository {
    var remote: AvatarsRemoteDataSource { get async }

    subscript(
        id: Avatar.Identifier
    ) -> Data? { get async }
}
