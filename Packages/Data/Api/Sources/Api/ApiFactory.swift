import OpenAPIRuntime

public protocol ApiFactory: Sendable {
    func create() -> APIProtocol
    func longPoll() -> LongPoll
}
