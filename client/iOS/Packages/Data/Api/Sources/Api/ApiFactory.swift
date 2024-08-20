public protocol ApiFactory {
    func create() -> ApiProtocol
    func longPoll() -> LongPoll
}
