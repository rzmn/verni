import Combine

public class OnDemandPublisher<Output>: @unchecked Sendable {
    public private(set) var upstream: PassthroughSubject<Output, Never>!
    public let hasSubscribers = CurrentValueSubject<Bool, Never>(false)
    private var subscribersCount = 0

    public init() {
        upstream = PassthroughSubject<Output, Never>()
            .handleEvents(
                receiveSubscription: weak(self, type(of: self).subscribe) • nop,
                receiveCompletion: weak(self, type(of: self).unsubscribe) • nop,
                receiveCancel: weak(self, type(of: self).unsubscribe)
            ).upstream
    }

    private func subscribe() {
        subscribersCount += 1
        if subscribersCount == 1 {
            hasSubscribers.send(true)
        }
    }

    private func unsubscribe() {
        subscribersCount -= 1
        assert(subscribersCount >= 0)
        if subscribersCount == 0 {
            hasSubscribers.send(false)
        }
    }
}
