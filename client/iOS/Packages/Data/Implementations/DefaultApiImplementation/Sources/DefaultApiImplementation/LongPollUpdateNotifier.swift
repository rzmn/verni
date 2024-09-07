import Api
import Combine
internal import Base
internal import Logging

actor LongPollUpdateNotifier<Query: LongPollQuery> where Query.Update: Decodable & Sendable {
    var publisher: AnyPublisher<Query.Update, Never> {
        subject.upstream.eraseToAnyPublisher()
    }
    private let subject = OnDemandPublisher<Query.Update>()

    let logger: Logger = .shared.with(prefix: "[lp] ")
    private var subscriptions = Set<AnyCancellable>()
    private let poller: Poller<Query>
    private var isListening = false

    init(query: Query, api: DefaultApi) async where Query.Update: Decodable & Sendable {
        self.poller = await Poller(query: query, api: api)
        subject.hasSubscribers
            .sink { hasSubscribers in
                Task {
                    if hasSubscribers {
                        self.startListening()
                    } else {
                        self.cancelListening()
                    }
                }
            }.store(in: &subscriptions)
    }

    private func startListening() {
        logI { "startListening: starting" }
        guard !isListening else {
            logI { "startListening: already running" }
            return
        }
        isListening = true
        logI { "startListening: started" }
        Task.detached {
            await self.pollLoop()
        }
    }

    private func cancelListening() {
        guard isListening else {
            logI { "cancelListening: isListening, skip" }
            return
        }
        isListening = false
    }

    func pollLoop() async {
        repeat {
            logI { "startListening: listenForUpdates..." }
            let updates: [Query.Update]
            do {
                updates = try await poller.poll().get()
            } catch {
                logI { "startListening: got failure \(error), terminating" }
                return
            }
            guard isListening else {
                logI { "startListening: was canceled, terminating" }
                return
            }
            logI { "startListening: publishind update..." }
            updates.forEach(subject.upstream.send)
        } while true
    }
}

extension LongPollUpdateNotifier: Loggable {}
