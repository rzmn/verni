import DataTransferObjects

public protocol PersistencyFactory: Sendable {
    func awake(host: UserDto.Identifier) async -> Persistency?
    func create(host: UserDto.Identifier, refreshToken: String) async throws -> Persistency
}
