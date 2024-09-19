extension Schema {
    enum TokensTableMetadata: SQLTableKeys {
        static let id = Expression<String>("id")
        static let token = Expression<String>("token")

        static let tableNameKey: String = "tokens"
    }

    typealias Tokens = SQLTable<TokensTableMetadata>
}
