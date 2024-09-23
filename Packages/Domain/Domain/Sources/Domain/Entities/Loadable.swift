public indirect enum Loadable<T: Equatable & Sendable, E: Equatable & Sendable>: Equatable, Sendable {
    case initial
    case loading(previous: Loadable<T, E>)
    case loaded(T)
    case failed(previous: Loadable<T, E>, E)

    public var value: T? {
        switch self {
        case .initial:
            return nil
        case .loading(let previous), .failed(let previous, _):
            return previous.value
        case .loaded(let value):
            return value
        }
    }

    public var error: E? {
        switch self {
        case .initial, .loaded:
            return nil
        case .loading(let previous):
            return previous.error
        case .failed(_, let error):
            return error
        }
    }

    public func mapValue<V>(_ block: (T) -> V) -> Loadable<V, E> {
        switch self {
        case .initial:
            return .initial
        case .loading(let previous):
            return .loading(previous: previous.mapValue(block))
        case .loaded(let value):
            return .loaded(block(value))
        case .failed(let previous, let error):
            return .failed(previous: previous.mapValue(block), error)
        }
    }
}
