import SyncEngine
import Api
import Logging
import PersistentStorage
import AsyncExtensions

actor RemoteSyncEngine {
    let logger: Logger
    private let updatesListener: UpdatesListener
    private let updatesSubject: AsyncSubject<[Components.Schemas.SomeOperation]>
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
        self.updatesListener = await ShortPoller(
            api: api,
            logger: logger
                .with(prefix: "🔄"),
            taskFactory: taskFactory
        )
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
    var updates: any AsyncBroadcast<[Components.Schemas.SomeOperation]> {
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
        let pulled: @Sendable ([Components.Schemas.SomeOperation]) async -> Void = { [weak self] operations in
            guard let self else { return }
            do {
                try await self.pulled(operations: operations)
            } catch {
                self.logger.logW { "pulled failed due \(error)" }
            }
        }
        taskFactory.detached {
            await self.updatesListener.start { [weak self] operations in
                guard let self else { return }
                taskFactory.detached {
                    await pulled(operations)
                }
            }
        }
    }
    
    private func stop() {
        taskFactory.detached {
            await self.updatesListener.stop()
        }
    }
    
    var operations: [Components.Schemas.SomeOperation] {
        get async {
            await storage.operations.map(\.payload)
        }
    }

    func push(operations: [Components.Schemas.SomeOperation]) async throws {
        
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
    
    func pulled(operations: [Components.Schemas.SomeOperation]) async throws {
        try await storage
            .update(
                operations: operations.map {
                    Operation(
                        kind: .pendingConfirm,
                        payload: $0
                    )
                }
            )
        await confirm()
    }
    
    private func sync() async {
        let operations: [Components.Schemas.SomeOperation] = await storage.operations
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
        let unconfirmed: [Components.Schemas.SomeOperation]
        do {
            let response = try await api.pushOperations(
                .init(
                    body: .json(
                        .init(
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
        let operations: [Components.Schemas.SomeOperation] = await storage.operations
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
