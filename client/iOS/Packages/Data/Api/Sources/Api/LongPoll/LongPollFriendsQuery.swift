import DataTransferObjects

public struct LongPollFriendsQuery: LongPollQuery {
    public struct Update: Decodable {
        public enum Category: String, Decodable {
            case friends
        }
        let category: Category
    }

    public init() {}

    public var method: String {
        "/friends/subscribe"
    }

    public func updateIsRelevant(_ update: Update) -> Bool {
        true
    }

    public var eventId: String {
        Update.Category.friends.rawValue
    }
}
