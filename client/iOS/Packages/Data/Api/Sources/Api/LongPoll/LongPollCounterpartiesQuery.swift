import DataTransferObjects

public struct LongPollCounterpartiesQuery: LongPollQuery {
    public struct Update: Decodable {
        public enum Category: String, Decodable {
            case counterparties
        }
        let category: Category
    }

    public init() {}

    public var method: String {
        "/spendings/subscribe"
    }

    public func updateIsRelevant(_ update: Update) -> Bool {
        true
    }

    public var eventId: String {
        Update.Category.counterparties.rawValue
    }
}
