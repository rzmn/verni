import Foundation
import Domain

public protocol PersistencyFactory {
    func awake() -> Persistency?
    func create(hostId: User.ID, refreshToken: String) throws -> Persistency
}
