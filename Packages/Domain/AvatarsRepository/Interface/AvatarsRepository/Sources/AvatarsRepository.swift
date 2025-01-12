import Foundation
import Entities

protocol AvatarsRepository {
    var remote: AvatarsRemoteDataSource { get async }

    subscript(
        id: Avatar.Identifier
    ) -> Data? { get async }
}
