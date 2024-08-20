import DataTransferObjects

public struct LongPollFriendsQuery: LongPollQuery {
    public typealias Update = LongPollEmptyUpdate

    public init() {}

    public var eventId: String {
        "friends"
    }
}
