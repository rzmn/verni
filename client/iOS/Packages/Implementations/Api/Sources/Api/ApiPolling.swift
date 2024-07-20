import Combine
import Foundation

public protocol ApiPolling {
    var friends: AnyPublisher<Void, Never> { get }
    var spendings: AnyPublisher<Void, Never> { get }
}

public class TimerBasedPolling: ApiPolling {
    private let timer = Timer
        .publish(every: 7, on: .main, in: .common)
        .autoconnect()

    public var friends: AnyPublisher<Void, Never> {
        timer
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    public var spendings: AnyPublisher<Void, Never> {
        timer
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    public init() {}
}
