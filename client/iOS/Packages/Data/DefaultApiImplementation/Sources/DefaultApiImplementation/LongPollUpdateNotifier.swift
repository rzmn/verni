import Api
import Combine
internal import Logging

actor LongPollUpdateNotifier<Query: LongPollQuery> where Query.Update: Decodable {
    var publisher: AnyPublisher<Query.Update, Never> {
        subject.eraseToAnyPublisher()
    }

    private lazy var subject = PassthroughSubject<Query.Update, Never>()
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

    let logger: Logger = .shared.with(prefix: "[lp] ")
    private let query: Query
    private let api: DefaultApi
    private var subscribersCount = 0 {
        didSet {
            logI { "subscribersCount=\(subscribersCount)" }
        }
    }

    init(query: Query, api: DefaultApi) where Query.Update: Decodable {
        self.query = query
        self.api = api
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

    private var routine: Task<Void, Never>?
    private func startListening() {
        logI { "startListening: starting" }
        if let routine, !routine.isCancelled {
            logI { "startListening: already running" }
            return
        }
        logI { "startListening: started" }
        routine = Task {
            repeat {
                logI { "startListening: listenForUpdates..." }
                let result = await listenForUpdates()
                if Task.isCancelled {
                    logI { "startListening: was canceled, terminating" }
                    return
                }
                guard case .success(let updates) = result else {
                    logI { "startListening: got failure \(result), terminating" }
                    return
                }
                logI { "startListening: publishind update..." }
                for update in updates where query.updateIsRelevant(update) {
                    self.subject.upstream.send(update)
                }
            } while true
        }
    }

    private func cancelListening() {
        guard let routine else {
            logI { "cancelListening: no routine, skip" }
            return
        }
        if !routine.isCancelled {
            logI { "cancelListening: canceled" }
            routine.cancel()
        }
        self.routine = nil
    }

    enum ListenForUpdatesTerminationEvent: Error {
        case offline
        case canceled
        case internalError
    }
    private func listenForUpdates() async -> Result<[Query.Update], ListenForUpdatesTerminationEvent> {
        let result = await api.longPoll(query: self.query)
        if Task.isCancelled {
            logI { "listenForUpdates canceled" }
            return .failure(.canceled)
        }
        switch result {
        case .success(let result):

            return .success(result)
        case .failure(let error):
            switch error {
            case .noUpdates:
                logE { "still working, reschedule..." }
                return await listenForUpdates()
            case .noConnection:
                logI { "listenForUpdates canceled: no network. waiting for network" }
                return .failure(.offline)
            case .internalError(let error):
                logI { "listenForUpdates canceled: internal error \(error)." }
                return .failure(.canceled)
            }
        }
    }
}

extension LongPollUpdateNotifier: Loggable {}

