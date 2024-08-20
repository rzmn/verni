import Api
import Combine

actor LongPollUpdateNotifier<Query: LongPollQuery> {
    lazy var publisher: AnyPublisher<Query.Update, Never> = {
        PassthroughSubject<Query.Update, Never>()
            .handleEvents(
                receiveSubscription: { _ in
                    Task.detached { [weak self] in
                        await self?.subscribe()
                    }
                },
                receiveCompletion: { [weak self] _ in
                    Task.detached { [weak self] in
                        await self?.unsubscribe()
                    }
                },
                receiveCancel: { [weak self] in
                    Task.detached { [weak self] in
                        await self?.unsubscribe()
                    }
                }
            )
            .eraseToAnyPublisher()
    }()
    private let query: Query
    private var subscribersCount = 0

    init(query: Query) {
        self.query = query
    }

    func subscribe() {
        subscribersCount += 1
        if subscribersCount == 1 {
            startListening()
        }
    }

    func unsubscribe() {
        subscribersCount -= 1
        assert(subscribersCount >= 0)
        if subscribersCount == 0 {
            cancelListening()
        }
    }

    private func startListening() {

    }

    private func cancelListening() {

    }
}
