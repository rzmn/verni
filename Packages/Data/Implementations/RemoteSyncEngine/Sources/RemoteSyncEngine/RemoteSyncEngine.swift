import SyncEngine
import DataLayerDependencies
import Api
import Logging
import PersistentStorage
import AsyncExtensions

actor RemoteSyncEngine {
    let logger: Logger
    private let updatesSubject: AsyncSubject<[Components.Schemas.Operation]>
    private var updatesSubscribersCount: BlockAsyncSubscription<Int>?
    private let api: APIProtocol
    private let storage: UserStorage
    private let taskFactory: TaskFactory
    private var isActive = false
    
    init(
        api: APIProtocol,
        storage: UserStorage,
        logger: Logger,
        taskFactory: TaskFactory
    ) async {
        self.api = api
        self.storage = storage
        self.taskFactory = taskFactory
        self.logger = logger
        updatesSubject = AsyncSubject(
            taskFactory: taskFactory,
            logger: logger
        )
        updatesSubscribersCount = await updatesSubject.subscribersCount.countPublisher.subscribe { [weak self] subscribersCount in
            guard let self else { return }
            taskFactory.task {
                await self.handleSubscribersUpdated(count: subscribersCount)
            }
        }
    }
}

extension RemoteSyncEngine: Engine {
    var updates: any AsyncBroadcast<[Components.Schemas.Operation]> {
        updatesSubject
    }
    
    func handleSubscribersUpdated(count: Int) {
        logI { "subscribers: \(count)" }
        let wasActive = isActive
        let shouldBeActive = count > 0
        guard wasActive != shouldBeActive else {
            return
        }
        logI { "setting active = \(shouldBeActive)" }
        isActive = shouldBeActive
        if shouldBeActive {
            start()
        } else {
            stop()
        }
    }
    
    private func start() {
        /// call `pull` once
        /// then set up remote updates
        /// repeatedly (eg every 10 sec) check if the remote updates service is alive, if not - call `pull` and reschedule service and timer
        /// also repeatedly checking for pending push operations would be helpful too
        assertionFailure("not implemented")
    }
    
    private func stop() {
        assertionFailure("not implemented")
    }

    func push(operations: [Components.Schemas.Operation]) async throws {
        try await storage
            .update(
                operations: operations.map {
                    Operation(
                        kind: .pendingSync,
                        payload: $0
                    )
                }
            )
        await sync()
    }
    
    private func sync() async {
        let operations: [Components.Schemas.Operation] = await storage.operations
            .compactMap {
                guard case .pendingSync = $0.kind else {
                    return nil
                }
                return $0.payload
            }
        guard !operations.isEmpty else {
            return
        }
        logI { "found \(operations) pending operations, syncing..." }
        let unconfirmed: [Components.Schemas.Operation]
        do {
            let response = try await api.pushOperations(
                .init(
                    body: .json(
                        .init(
                            deviceId: storage.deviceId,
                            operations: operations
                        )
                    )
                )
            )
            switch response {
            case .ok(let payload):
                switch payload.body {
                case .json(let body):
                    unconfirmed = body.response
                }
            case .unauthorized(let response):
                return logE { "push is not allowed (unauthorized): \(response)" }
            case .conflict(let response):
                /// re-generate uuids for `create` operations and following operations on that ids, then re-push
                return assertionFailure("not implemented")
            case .internalServerError(let response):
                return logE { "internal error on push: \(response)" }
            case .undocumented(let statusCode, let body):
                return logE { "undocumented response on push: \(body)" }
            }
            try await storage.update(
                operations: operations.map {
                    Operation(
                        kind: .synced,
                        payload: $0
                    )
                }
            )
        } catch {
            return logE { "sync failed due error: \(error)" }
        }
        logI { "successfully pushed \(operations) pending operations" }
        guard !unconfirmed.isEmpty else {
            return
        }
        logI { "received \(unconfirmed.count) unconfirmed operations as a push response, storing..." }
        do {
            try await storage
                .update(
                    operations: operations.map {
                        Operation(
                            kind: .pendingConfirm,
                            payload: $0
                        )
                    }
                )
        } catch {
            return logE { "store unconfirmed operations failed due error: \(error)" }
        }
        logI { "successfully stored \(unconfirmed.count) unconfirmed operations" }
        await confirm()
    }
    
    private func confirm() async {
        let operations: [Components.Schemas.Operation] = await storage.operations
            .compactMap {
                guard case .pendingConfirm = $0.kind else {
                    return nil
                }
                return $0.payload
            }
        guard !operations.isEmpty else {
            return
        }
        logI { "found \(operations) unconfirmed operations, syncing..." }
        do {
            let response = try await api.confirmOperations(
                .init(
                    query: .init(
                        deviceId: storage.deviceId,
                        ids: operations.map(\.value1.operationId)
                    )
                )
            )
            switch response {
            case .ok:
                try await storage
                    .update(
                        operations: operations.map {
                            Operation(
                                kind: .synced,
                                payload: $0
                            )
                        }
                    )
            case .unauthorized(let response):
                return logE { "confirm is not allowed (unauthorized): \(response)" }
            case .internalServerError(let response):
                return logE { "internal error on confirm: \(response)" }
            case .undocumented(let statusCode, let body):
                return logE { "undocumented response on confirm: \(body)" }
            }
        } catch {
            return logE { "confirm failed due error: \(error)" }
        }
        logE { "confirm succeeded" }
    }
    
}

extension RemoteSyncEngine: Loggable {}
