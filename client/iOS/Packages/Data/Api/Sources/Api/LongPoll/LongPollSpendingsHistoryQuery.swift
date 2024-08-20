import DataTransferObjects

public struct SpendingsHistoryUpdate: LongPollQuery {
    public typealias Update = [IdentifiableDealDto]
    private let uid: UserDto.ID

    public init(uid: UserDto.ID) {
        self.uid = uid
    }

    public var eventId: String {
        "spendings_\(uid)"
    }
}
