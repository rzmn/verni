import DataTransferObjects

public struct LongPollCounterpartiesQuery: LongPollQuery {
    public typealias Update = LongPollEmptyUpdate

    public init() {}

    public var eventId: String {
        "counterparties"
    }
}
