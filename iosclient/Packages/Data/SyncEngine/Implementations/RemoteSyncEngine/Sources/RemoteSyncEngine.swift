import SyncEngine
import Api
import Logging
import PersistentStorage
import AsyncExtensions

actor RemoteSyncEngine {
    let logger: Logger
    private let remoteUpdatesService: RemoteUpdatesService
    private let eventPublisher = EventPublisher<[Components.Schemas.SomeOperation]>()
    private let api: APIProtocol
    private let storage: UserStorage
    private let taskFactory: TaskFactory
    private var isActive = false
    
    init(
        api: APIProtocol,
        remoteUpdatesService: RemoteUpdatesService,
        storage: UserStorage,
        logger: Logger,
        taskFactory: TaskFactory
    ) async {
        self.api = api
        self.storage = storage
        self.taskFactory = taskFactory
        self.logger = logger
        self.remoteUpdatesService = remoteUpdatesService
        await remoteUpdatesService.eventSource.subscribeWeak(self) { [weak self] event in
            guard let self else { return }
            taskFactory.task { [weak self] in
                guard let self else { return }
                switch event {
                case .newOperationsAvailable(let operations):
                    do {
                        try await pulled(operations: operations)
                    } catch {
                        logE { "failed to pull operations error: \(error)" }
                    }
                }
            }
        }
        await remoteUpdatesService.start()
    }
}

extension RemoteSyncEngine: Engine {
    var updates: any EventSource<[Components.Schemas.SomeOperation]> {
        eventPublisher
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
        await eventPublisher.notify(operations)
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
        await eventPublisher.notify(operations)
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
        let synced: [Components.Schemas.SomeOperation]
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
                    synced = body.response
                }
            case .unauthorized(let response):
                return logE { "push is not allowed (unauthorized): \(response)" }
            case .conflict:
                /// re-generate uuids for `create` operations and following operations on that ids, then re-push
                return assertionFailure("not implemented")
            case .internalServerError(let response):
                return logE { "internal error on push: \(response)" }
            case .undocumented(let statusCode, let payload):
                do {
                    let description = try await payload.logDescription
                    return logE { "undocumented response on push: code \(statusCode) body: \(description ?? "nil")" }
                } catch {
                    return logE { "undocumented response on push: code \(statusCode) body: \(payload) decodingFailure: \(error)" }
                }
                
            }
            try await storage.update(
                operations: synced.map {
                    Operation(
                        kind: .synced,
                        payload: $0
                    )
                }
            )
            await eventPublisher.notify(synced)
        } catch {
            return logE { "sync failed due error: \(error)" }
        }
        logI { "successfully pushed \(synced) pending operations" }
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
        let input = Operations.ConfirmOperations.Input.init(
            body: .json(
                .init(
                    ids: operations.map(\.value1.operationId)
                )
            )
        )
        do {
            let response = try await api.confirmOperations(input)
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
            case .undocumented(let statusCode, let payload):
                do {
                    let description = try await payload.logDescription
                    return logE { "undocumented response on confirm: code \(statusCode) body: \(description ?? "nil")" }
                } catch {
                    return logE { "undocumented response on confirm: code \(statusCode) body: \(payload) decodingFailure: \(error)" }
                }
            }
        } catch {
            return logE { "confirm failed due error: \(error)" }
        }
        logI { "confirm succeeded" }
    }
}

extension RemoteSyncEngine: Loggable {}
