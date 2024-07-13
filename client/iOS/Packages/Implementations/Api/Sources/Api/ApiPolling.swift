import Combine
import Foundation

public protocol ApiPolling {
    var friends: AnyPublisher<Void, Never> { get }
}

public class TimerBasedPolling: ApiPolling {
    private let timer = Timer
        .publish(every: 5, on: .main, in: .common)
        .autoconnect()

    public var friends: AnyPublisher<Void, Never> {
        timer
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    public init() {}
}
