import DataTransferObjects

extension Schema {
    enum ProfileTableMetadata: SQLTableKeys {
        static let id = Expression<String>("id")
        static let payload = Expression<CodableBlob<ProfileDto>>("payload")

        static let tableNameKey: String = "profiles"
    }

    typealias Profile = SQLTable<ProfileTableMetadata>
}
