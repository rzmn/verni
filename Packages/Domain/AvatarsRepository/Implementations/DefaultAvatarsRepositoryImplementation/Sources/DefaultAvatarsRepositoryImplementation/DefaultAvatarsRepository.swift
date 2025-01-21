import Entities
import Api
import AvatarsRepository
import Foundation
import Logging
import AsyncExtensions
import SyncEngine
import InfrastructureLayer
internal import Convenience

public actor DefaultAvatarsRepository: Sendable {
    public let logger: Logger
    private let updatesSubject: AsyncSubject<[Image.Identifier: Image]>
    private var remoteUpdatesSubscription: BlockAsyncSubscription<[Components.Schemas.Operation]>?
    private let infrastructure: InfrastructureLayer
    private let sync: Engine
    private let reducer: Reducer
    private let userId: User.Identifier
    private var state: State
    
    public init(
        userId: User.Identifier,
        sync: Engine,
        infrastructure: InfrastructureLayer,
        logger: Logger
    ) async {
        await self.init(
            reducer: DefaultReducer(
                uploadImageReducer: UploadImageReducer
            ),
            userId: userId,
            sync: sync,
            infrastructure: infrastructure,
            logger: logger
        )
    }
    
    init(
        reducer: @escaping Reducer,
        userId: User.Identifier,
        sync: Engine,
        infrastructure: InfrastructureLayer,
        logger: Logger
    ) async {
        self.logger = logger
        self.state = State(images: [:])
        self.reducer = reducer
        self.infrastructure = infrastructure
        self.sync = sync
        self.userId = userId
        updatesSubject = AsyncSubject(
            taskFactory: infrastructure.taskFactory,
            logger: logger.with(
                prefix: "🆕"
            )
        )
        for operation in await sync.operations {
            state = reducer(operation, state)
        }
        remoteUpdatesSubscription = await sync.updates.subscribe { [weak self] operations in
            Task { [weak self] in
                await self?.received(operations: operations)
            }
        }
    }
    
    private func received(operation: Components.Schemas.Operation) {
        received(operations: [operation])
    }
    
    private func received(operations: [Components.Schemas.Operation]) {
        let oldState = state
        for operation in operations {
            state = reducer(operation, state)
        }
        let updates = state.images.reduce(into: [:] as [Image.Identifier: Image]) { dict, kv in
            let (userId, user) = kv
            guard let value = user.value else {
                return
            }
            guard oldState.images[userId]?.value != value else {
                return
            }
            dict[userId] = value
        }
        guard !updates.isEmpty else {
            return
        }
        infrastructure.taskFactory.detached { [weak self] in
            await self?.updatesSubject.yield(updates)
        }
    }
}

extension DefaultAvatarsRepository: AvatarsRepository {
    private var isImageIdReserved: (Image.Identifier) -> Bool {
        state.images.keys.contains
    }
    
    private var isOperationIdReserved: (SpendingGroup.Identifier) -> Bool {
        get async {
            Set(await sync.operations.map(\.value1.operationId)).contains
        }
    }
    
    public nonisolated var updates: any AsyncBroadcast<[Image.Identifier: Image]> {
        updatesSubject
    }
    
    public subscript(id: Image.Identifier) -> Image? {
        get async {
            state.images[id]?.value
        }
    }
    
    public func upload(image data: Image.Base64Data) async throws(UploadImageError) -> Image.Identifier {
        let imageId = infrastructure.nextId(
            isBlacklisted: isImageIdReserved
        )
        let operation = await Components.Schemas.Operation(
            value1: Components.Schemas.BaseOperation(
                operationId: infrastructure.nextId(
                    isBlacklisted: isOperationIdReserved
                ),
                createdAt: infrastructure.timeMs,
                authorId: userId
            ),
            value2: .UploadImageOperation(
                .init(
                    uploadImage: .init(
                        imageId: imageId,
                        base64: data
                    )
                )
            )
        )
        do {
            try await sync.push(operation: operation)
        } catch {
            logE { "createUser: push failed error: \(error)" }
            throw .internal(error)
        }
        received(operation: operation)
        return imageId
    }
}

extension DefaultAvatarsRepository: Loggable {}
