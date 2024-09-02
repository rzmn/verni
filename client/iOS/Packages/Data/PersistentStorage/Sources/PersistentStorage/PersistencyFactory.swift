import DataTransferObjects

public protocol PersistencyFactory: Sendable {
    func awake() async -> Persistency?
    func create(hostId: UserDto.ID, refreshToken: String) async throws -> Persistency
}
