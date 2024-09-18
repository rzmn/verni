public protocol LongPollQuery: Sendable {
    associatedtype Update: Sendable & Decodable

    func updateIsRelevant(_ update: Update) -> Bool

    var eventId: String { get }
    var method: String { get }
}
