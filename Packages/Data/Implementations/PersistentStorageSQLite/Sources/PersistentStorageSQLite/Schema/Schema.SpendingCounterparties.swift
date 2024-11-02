import DataTransferObjects

extension Schema {
    enum SpendingCounterpartiesTableMetadata: SQLTableKeys {
        static let id = Expression<String>("id")
        static let payload = Expression<CodableBlob<[BalanceDto]>>("payload")

        static let tableNameKey = "spendingCounterparties"
    }

    typealias SpendingCounterparties = SQLTable<SpendingCounterpartiesTableMetadata>
}
