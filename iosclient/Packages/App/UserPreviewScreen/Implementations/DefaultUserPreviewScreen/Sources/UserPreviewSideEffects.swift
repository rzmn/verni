import Entities
import UserPreviewScreen
import UsersRepository
import SpendingsRepository
import AppBase
import UIKit
import Logging

@MainActor final class UserPreviewSideEffects: Sendable {
    let logger: Logger
    
    private unowned let store: Store<UserPreviewState, UserPreviewAction>
    private let usersRepository: UsersRepository
    private let spendingsRepository: SpendingsRepository
    private let usersRemoteDataSource: UsersRemoteDataSource
    private let dataSource: StatusDataSource
    private let userId: User.Identifier
    private let hostId: User.Identifier

    init(
        store: Store<UserPreviewState, UserPreviewAction>,
        logger: Logger,
        usersRepository: UsersRepository,
        spendingsRepository: SpendingsRepository,
        usersRemoteDataSource: UsersRemoteDataSource,
        dataSource: StatusDataSource,
        hostId: User.Identifier,
        userId: User.Identifier
    ) {
        self.store = store
        self.usersRepository = usersRepository
        self.spendingsRepository = spendingsRepository
        self.logger = logger
        self.usersRemoteDataSource = usersRemoteDataSource
        self.dataSource = dataSource
        self.userId = userId
        self.hostId = hostId
    }
}

extension UserPreviewSideEffects: ActionHandler {
    var id: String {
        "\(UserPreviewSideEffects.self)"
    }

    func handle(_ action: UserPreviewAction) {
        switch action {
        case .appeared:
            appeared()
        case .createSpendingGroup:
            createSpendingGroup()
        default:
            break
        }
    }
    
    private func appeared() {
        Task {
            await usersRepository.storeUserData(user: store.state.user)
            if let info = await usersRepository[userId], case .regular(let user) = info {
                store.dispatch(.infoUpdated(user))
            }
            let reload: @Sendable () -> Void = { [weak self] in
                guard let self else { return }
                Task {
                    if let info = await usersRepository[userId], case .regular(let user) = info {
                        await store.dispatch(.infoUpdated(user))
                    }
                    await store.dispatch(.statusUpdated(await dataSource.status))
                }
            }
            await spendingsRepository.updates.subscribeWeak(self) { _ in
                reload()
            }
            await usersRepository.updates.subscribeWeak(self) { _ in
                reload()
            }
        }
    }
    
    private func createSpendingGroup() {
        Task {
            do {
                let groupId = try await spendingsRepository.createGroup(
                    participants: [userId, hostId],
                    displayName: nil
                )
                store.dispatch(.spendingGroupCreated(groupId))
            } catch {
                logE { "error creating spending group \(error)" }
            }
        }
    }
}

extension UserPreviewSideEffects: Loggable {}
