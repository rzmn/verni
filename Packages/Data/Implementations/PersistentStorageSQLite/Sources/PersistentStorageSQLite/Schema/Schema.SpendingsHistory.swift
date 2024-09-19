import DataTransferObjects

extension Schema {
    enum SpendingsHistoryTableMetadata: SQLTableKeys {
        static let id = Expression<String>("id")
        static let payload = Expression<CodableBlob<[IdentifiableDealDto]>>("payload")

        static let tableNameKey = "spendingHistory"
    }

    typealias SpendingsHistory = SQLTable<SpendingsHistoryTableMetadata>
}
