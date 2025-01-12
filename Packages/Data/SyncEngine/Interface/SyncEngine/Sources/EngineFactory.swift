public protocol EngineFactory {
    func create() async -> Engine
}
