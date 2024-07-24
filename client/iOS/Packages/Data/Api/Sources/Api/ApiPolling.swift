import Foundation

public protocol ApiPolling {
    var friends: AsyncStream<Void> { get }
    var spendings: AsyncStream<Void> { get }
}

public class TimerBasedPolling: ApiPolling {
    private let timerStream: AsyncStream<Void>
    private let timer: Timer

    public init() {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        timerStream = stream
        timer = Timer.scheduledTimer(withTimeInterval: 7, repeats: true) { _ in
            continuation.yield()
        }
    }

    public var friends: AsyncStream<Void> {
        timerStream
    }

    public var spendings: AsyncStream<Void> {
        timerStream
    }
}
