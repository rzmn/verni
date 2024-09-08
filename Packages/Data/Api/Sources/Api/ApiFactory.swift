public protocol ApiFactory: Sendable {
    func create() -> ApiProtocol
    func longPoll() -> LongPoll
}
