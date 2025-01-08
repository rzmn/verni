public protocol UsersRemoteDataSource: Sendable {
    func searchUsers(
        query: String
    ) async throws(GeneralError) -> [User]
}
