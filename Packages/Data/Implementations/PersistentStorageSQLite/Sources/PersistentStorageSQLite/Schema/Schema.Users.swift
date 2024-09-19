import DataTransferObjects

extension Schema {
    enum UsersTableMetadata: SQLTableKeys {
        static let id = Expression<String>("id")
        static let payload = Expression<CodableBlob<UserDto>>("payload")

        static let tableNameKey = "users"
    }

    typealias Users = SQLTable<UsersTableMetadata>
}
