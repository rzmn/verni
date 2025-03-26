import Api
import AsyncExtensions
import Entities
import InfrastructureLayer
import Logging
import PersistentStorage
import SyncEngine
import SpendingsRepository
import UsersRepository
import Foundation
import OperationsRepository
internal import Convenience

public typealias Operation = Entities.Operation

public actor DefaultOperationsRepository: Sendable {
    public let logger: Logger
    private let storage: UserStorage
    private let infrastructure: InfrastructureLayer
    private let spendingsRepository: SpendingsRepository
    private let usersRepository: UsersRepository
    
    public private(set) var operations: [Operation]
    private var operationsDict: [Operation.Identifier: Operation]
    private let eventPublisher = EventPublisher<Void>()
    
    public init(
        storage: UserStorage,
        infrastructure: InfrastructureLayer,
        spendingsRepository: SpendingsRepository,
        usersRepository: UsersRepository,
        logger: Logger
    ) async {
        self.storage = storage
        self.infrastructure = infrastructure
        self.logger = logger
        self.spendingsRepository = spendingsRepository
        self.usersRepository = usersRepository
        let (operations, operationsDict) = await Self.getOperations(
            storage: storage,
            spendingsRepository: spendingsRepository,
            usersRepository: usersRepository
        )
        self.operationsDict = operationsDict
        self.operations = operations
        
        await storage.onOperationsUpdated
            .subscribeWeak(self) { [weak self] _ in
                guard let self else { return }
                Task {
                    await operationsDidUpdate()
                }
            }
    }
}

extension DefaultOperationsRepository: OperationsRepository {
    public nonisolated var updates: any EventSource<Void> {
        eventPublisher
    }
    
    public subscript(id: Entities.Operation.Identifier) -> Entities.Operation? {
        get async {
            operationsDict[id]
        }
    }
}

extension DefaultOperationsRepository {
    private func operationsDidUpdate() async {
        let (operations, operationsDict) = await Self.getOperations(
            storage: storage,
            spendingsRepository: spendingsRepository,
            usersRepository: usersRepository
        )
        self.operationsDict = operationsDict
        self.operations = operations
        
    }
    
    private static func getOperations(
        storage: UserStorage,
        spendingsRepository: SpendingsRepository,
        usersRepository: UsersRepository
    ) async -> ([Operation], [Operation.Identifier: Operation]) {
        let array = await storage.operations.asyncMap { @Sendable operationFromStorage in
            let status: Operation.Status = {
                switch operationFromStorage.kind {
                case .pendingSync:
                    return .pendingSync
                case .pendingConfirm:
                    return .pendingConfirm
                case .synced:
                    return .synced
                }
            }()
            let getUser: @Sendable (User.Identifier) async -> AnyUser = {
                await usersRepository[$0] ?? .regular(
                    .init(
                        id: $0,
                        payload: .init(displayName: "<not found>", avatar: nil)
                    )
                )
            }
            let author = await getUser(operationFromStorage.base.authorId)
            switch operationFromStorage.payload.value2 {
            case .CreateUserOperation(let operation):
                return Operation(
                    id: operationFromStorage.base.operationId,
                    operationType: "CreateUser",
                    operationStatus: status,
                    author: author,
                    entityType: .user(await getUser(operation.createUser.userId)),
                    createdAt: operationFromStorage.base.createdAt,
                    details: "id: \(operation.createUser.userId), dn: \(operation.createUser.displayName)"
                )
            case .BindUserOperation(let operation):
                return Operation(
                    id: operationFromStorage.base.operationId,
                    operationType: "BindUser",
                    operationStatus: status,
                    author: author,
                    entityType: .userRelation(
                        from: await getUser(operation.bindUser.oldId),
                        to: await getUser(operation.bindUser.newId)
                    ),
                    createdAt: operationFromStorage.base.createdAt,
                    details: "oldId: \(operation.bindUser.oldId), newId: \(operation.bindUser.newId)"
                )
            case .UpdateAvatarOperation(let operation):
                return Operation(
                    id: operationFromStorage.base.operationId,
                    operationType: "UpdateAvatar",
                    operationStatus: status,
                    author: author,
                    entityType: .user(await getUser(operation.updateAvatar.userId)),
                    createdAt: operationFromStorage.base.createdAt,
                    details: "iid: \(operation.updateAvatar.imageId ?? "<nil>")"
                )
            case .UpdateDisplayNameOperation(let operation):
                return Operation(
                    id: operationFromStorage.base.operationId,
                    operationType: "UpdateDisplayName",
                    operationStatus: status,
                    author: author,
                    entityType: .user(await getUser(operation.updateDisplayName.userId)),
                    createdAt: operationFromStorage.base.createdAt,
                    details: "dn: \(operation.updateDisplayName.displayName)"
                )
            case .CreateSpendingGroupOperation(let operation):
                let group = SpendingGroup(
                    id: operation.createSpendingGroup.groupId,
                    name: operation.createSpendingGroup.displayName,
                    createdAt: operationFromStorage.base.createdAt
                )
                return await Operation(
                    id: operationFromStorage.base.operationId,
                    operationType: "CreateSpendingGroup",
                    operationStatus: status,
                    author: author,
                    entityType: .spenginsGroup(group, operation.createSpendingGroup.participants.asyncMap(getUser)),
                    createdAt: operationFromStorage.base.createdAt,
                    details: "id: \(group.id), name: \(group.name ?? "<nil>")"
                )
            case .DeleteSpendingGroupOperation(let operation):
                let group = SpendingGroup(
                    id: operation.deleteSpendingGroup.groupId,
                    name: nil,
                    createdAt: operationFromStorage.base.createdAt
                )
                return await Operation(
                    id: operationFromStorage.base.operationId,
                    operationType: "DeleteSpendingGroup",
                    operationStatus: status,
                    author: author,
                    entityType: .spenginsGroup(
                        group, spendingsRepository[group: group.id]?
                            .participants
                            .map(\.userId)
                            .asyncMap(getUser) ?? []
                    ),
                    createdAt: operationFromStorage.base.createdAt,
                    details: "id: \(group.id)"
                )
            case .CreateSpendingOperation(let operation):
                let spending = Spending(
                    id: operation.createSpending.spendingId,
                    payload: .init(
                        name: operation.createSpending.name,
                        currency: Currency(dto: operation.createSpending.currency),
                        createdAt: operationFromStorage.base.createdAt,
                        amount: Amount(dto: operation.createSpending.amount),
                        shares: operation.createSpending.shares
                            .map {
                                Spending.Share(
                                    userId: $0.userId,
                                    amount: Amount(dto: $0.amount)
                                )
                            }
                    )
                )
                return Operation(
                    id: operationFromStorage.base.operationId,
                    operationType: "CreateSpending",
                    operationStatus: status,
                    author: author,
                    entityType: .spending(spending, operation.createSpending.groupId),
                    createdAt: operationFromStorage.base.createdAt,
                    details: "id: \(spending.id), amount: \(spending.payload.currency.formatted(amount: spending.payload.amount))"
                )
            case .DeleteSpendingOperation(let operation):
                return Operation(
                    id: operationFromStorage.base.operationId,
                    operationType: "DeleteSpending",
                    operationStatus: status,
                    author: author,
                    entityType: .spending(
                        Spending(
                            id: operation.deleteSpending.spendingId,
                            payload: .init(name: "", currency: .unknown(""), createdAt: operationFromStorage.base.createdAt, amount: 0, shares: [])
                        ),
                        operation.deleteSpending.groupId
                    ),
                    createdAt: operationFromStorage.base.createdAt,
                    details: "id: \(operation.deleteSpending.spendingId)"
                )
            case .UpdateEmailOperation(let operation):
                return Operation(
                    id: operationFromStorage.base.operationId,
                    operationType: "UpdateEmail",
                    operationStatus: status,
                    author: author,
                    entityType: .user(await getUser(operationFromStorage.base.authorId)),
                    createdAt: operationFromStorage.base.createdAt,
                    details: "email: \(operation.updateEmail.email)"
                )
            case .VerifyEmailOperation(let operation):
                return Operation(
                    id: operationFromStorage.base.operationId,
                    operationType: "VerifyEmail",
                    operationStatus: status,
                    author: author,
                    entityType: .user(await getUser(operationFromStorage.base.authorId)),
                    createdAt: operationFromStorage.base.createdAt,
                    details: "verified: \(operation.verifyEmail.verified)"
                )
            case .UploadImageOperation(let operation):
                return Operation(
                    id: operationFromStorage.base.operationId,
                    operationType: "UploadImage",
                    operationStatus: status,
                    author: author,
                    entityType: .image(operation.uploadImage.imageId),
                    createdAt: operationFromStorage.base.createdAt,
                    details: "id: \(operation.uploadImage.imageId)"
                )
            }
        }
        let dict = array.reduce(into: [:]) { dict, operation in
            dict[operation.id] = operation
        }
        return (array, dict)
    }
}

extension DefaultOperationsRepository: Loggable {}
