import Domain

public protocol Persistency {
    func getRefreshToken() async -> String
    func update(refreshToken: String) async

    func getHostInfo() async -> User?
    func user(id: User.ID) async -> User?
    func update(users: [User]) async

    func invalidate() async
}
