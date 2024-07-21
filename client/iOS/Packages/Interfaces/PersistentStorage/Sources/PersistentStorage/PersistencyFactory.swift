import Foundation
import DataTransferObjects

public protocol PersistencyFactory {
    func awake() -> Persistency?
    func create(hostId: UserDto.ID, refreshToken: String) throws -> Persistency
}
