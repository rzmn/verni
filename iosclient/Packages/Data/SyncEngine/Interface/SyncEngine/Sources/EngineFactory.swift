public protocol EngineFactory: Sendable {
    func create() async -> Engine
}
