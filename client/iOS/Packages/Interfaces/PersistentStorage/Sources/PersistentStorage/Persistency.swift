import DataTransferObjects

public protocol Persistency {
    var refreshToken: String { get set }

    func getHostInfo() async -> UserDto?
    func user(id: UserDto.ID) async -> UserDto?
    func update(users: [UserDto])

    func invalidate()
}
