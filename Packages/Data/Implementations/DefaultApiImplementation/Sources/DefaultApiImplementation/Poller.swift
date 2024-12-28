import Api
import Logging

actor Poller<Query: LongPollQuery> {
    enum PollingTerminationEvent: Error, Sendable {
        case offline
        case canceled
        case internalError
    }
    let logger: Logger
    private let query: Query
    private let api: DefaultApi

    init(query: Query, api: DefaultApi, logger: Logger) async {
        self.query = query
        self.api = api
        self.logger = logger
    }

    func poll() async -> Result<[Query.Update], PollingTerminationEvent> {
        let updates: [Query.Update]
        do {
            updates = try await api.longPoll(query: query)
        } catch {
            switch error {
            case .noUpdates:
                logE { "still working, reschedule..." }
                return await poll()
            case .noConnection:
                logI { "listenForUpdates canceled: no network. waiting for network" }
                return .failure(.offline)
            case .internalError(let error):
                logI { "listenForUpdates canceled: internal error \(error)." }
                return .failure(.canceled)
            }
        }
        return .success(updates.filter(query.updateIsRelevant))
    }
}

extension Poller: Loggable {}
