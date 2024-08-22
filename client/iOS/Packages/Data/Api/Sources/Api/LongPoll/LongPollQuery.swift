public protocol LongPollQuery {
    associatedtype Update

    func updateIsRelevant(_ update: Update) -> Bool

    var eventId: String { get }
    var method: String { get }
}
