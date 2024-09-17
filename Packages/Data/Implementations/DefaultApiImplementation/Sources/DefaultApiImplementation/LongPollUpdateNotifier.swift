import Api
import Base
import AsyncExtensions
internal import Logging

actor LongPollUpdateNotifier<Query: LongPollQuery> where Query.Update: Decodable & Sendable {
    var publisher: any AsyncPublisher<Query.Update> {
        broadcast
    }
    private let broadcast: AsyncBroadcast<Query.Update>
    private var hasSubscribersSubscription: BlockAsyncSubscription<Int>?

    let logger: Logger = .shared.with(prefix: "[lp] ")
    private let poller: Poller<Query>
    private let taskFactory: TaskFactory
    private var isListening = false

    init(query: Query, api: DefaultApi, taskFactory: TaskFactory) async where Query.Update: Decodable & Sendable {
        self.poller = await Poller(query: query, api: api)
        self.taskFactory = taskFactory
        self.broadcast = AsyncBroadcast(taskFactory: taskFactory)
        hasSubscribersSubscription = await broadcast.subscribersCount.countPublisher.subscribe { [weak self, taskFactory] subscribersCount in
            taskFactory.task { [weak self] in
                guard let self else { return }
                if subscribersCount > 0 {
                    await self.startListening()
                } else {
                    await self.cancelListening()
                }
            }
        }
    }

    private func startListening() {
        logI { "startListening: starting" }
        guard !isListening else {
            logI { "startListening: already running" }
            return
        }
        isListening = true
        logI { "startListening: started" }
        taskFactory.task {
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
            for update in updates {
                await broadcast.yield(update)
            }
        } while true
    }
}

extension LongPollUpdateNotifier: Loggable {}
