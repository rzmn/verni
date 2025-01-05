import Api
import Base
import AsyncExtensions
import Logging

actor WebSocketRemoteUpdatesService {
    var publisher: any AsyncBroadcast<RemoteUpdate> {
        broadcast
    }
    private let broadcast: AsyncSubject<RemoteUpdate>
    private var hasSubscribersSubscription: BlockAsyncSubscription<Int>?

    let logger: Logger
    private let taskFactory: TaskFactory
    private var isListening = false

    init(taskFactory: TaskFactory, logger: Logger) async {
        self.logger = logger.with(prefix: "[ws] ")
        self.taskFactory = taskFactory
        self.broadcast = AsyncSubject(taskFactory: taskFactory, logger: logger)
        hasSubscribersSubscription = await broadcast.subscribersCount.countPublisher
            .subscribe { [weak self, taskFactory] subscribersCount in
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
//            let updates: [Query.Update]
//            do {
//                updates = try await poller.poll().get()
//            } catch {
//                logI { "startListening: got failure \(error), terminating" }
//                return
//            }
//            guard isListening else {
//                logI { "startListening: was canceled, terminating" }
//                return
//            }
//            logI { "startListening: publishind update..." }
//            for update in updates {
//                await broadcast.yield(update)
//            }
        } while true
    }
}

extension WebSocketRemoteUpdatesService: Loggable {}
