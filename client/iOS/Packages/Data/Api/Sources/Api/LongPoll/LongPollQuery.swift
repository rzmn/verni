public protocol LongPollQuery {
    associatedtype Update

    var eventId: String { get }
}
