import DataTransferObjects

public protocol PersistencyFactory: Sendable {
    func awake(host: UserDto.ID) async -> Persistency?
    func create(host: UserDto.ID, refreshToken: String) async throws -> Persistency
}
