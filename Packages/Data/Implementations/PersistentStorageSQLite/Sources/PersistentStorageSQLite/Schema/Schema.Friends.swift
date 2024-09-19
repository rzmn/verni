import DataTransferObjects

extension Schema {
    enum FriendsTableMetadata: SQLTableKeys {
        static let id = Expression<Int64>("id")
        static let payload = Expression<CodableBlob<[FriendshipKindDto: [UserDto]]>>("payload")

        static let tableNameKey = "friends"
    }

    typealias Friends = SQLTable<FriendsTableMetadata>
}
