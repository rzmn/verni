import DataTransferObjects

public protocol Persistency {
    func getRefreshToken() async -> String
    func update(refreshToken: String) async

    func getHostInfo() async -> UserDto?
    func user(id: UserDto.ID) async -> UserDto?
    func update(users: [UserDto]) async

    func invalidate() async
}
