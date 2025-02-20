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
    private let eventPublisher: EventPublisher<[Image.Identifier: Image]>
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
        eventPublisher = EventPublisher()
        for operation in await sync.operations {
            state = reducer(operation, state)
        }
        await sync.updates.subscribeWeak(self) { [weak self] operations in
            guard let self else { return }
            infrastructure.taskFactory.task { [weak self] in
                guard let self else { return }
                await received(operations: operations)
            }
        }
    }
    
    private func received(operation: Components.Schemas.SomeOperation) {
        received(operations: [operation])
    }
    
    private func received(operations: [Components.Schemas.SomeOperation]) {
        let oldState = state
        for operation in operations {
            state = reducer(operation, state)
        }
        let updates = state.images.reduce(into: [:] as [Image.Identifier: Image]) { dict, kv in
            let (id, image) = kv
            guard oldState.images[id] != image else {
                return
            }
            dict[id] = image
        }
        guard !updates.isEmpty else {
            return
        }
        infrastructure.taskFactory.detached { [weak self] in
            guard let self else { return }
            await eventPublisher.notify(updates)
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
    
    public nonisolated var updates: any EventSource<[Image.Identifier: Image]> {
        eventPublisher
    }
    
    public subscript(id: Image.Identifier) -> Image? {
        get async {
            state.images[id]
        }
    }
    
    public func upload(image data: Image.Base64Data) async throws(UploadImageError) -> Image.Identifier {
        let imageId = infrastructure.nextId(
            isBlacklisted: isImageIdReserved
        )
        let operation = await Components.Schemas.SomeOperation(
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
            logE { "uploadImage: push failed error: \(error)" }
            throw .internal(error)
        }
        received(operation: operation)
        return imageId
    }
}

extension DefaultAvatarsRepository: Loggable {}
