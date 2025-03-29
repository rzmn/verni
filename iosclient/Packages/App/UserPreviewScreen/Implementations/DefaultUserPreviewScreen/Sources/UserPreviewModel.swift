import UIKit
import Entities
import AppBase
import Combine
import UsersRepository
import SpendingsRepository
import AsyncExtensions
import SwiftUI
import Logging
import UserPreviewScreen
internal import Convenience
internal import DesignSystem

struct StatusDataSource {
    private let spendingsRepository: SpendingsRepository
    private let hostId: User.Identifier
    private let user: User
    
    init(spendingsRepository: SpendingsRepository, hostId: User.Identifier, user: User) {
        self.spendingsRepository = spendingsRepository
        self.hostId = hostId
        self.user = user
    }
    
    var status: UserPreviewState.Status {
        get async {
            if user.id == hostId {
                return .me
            } else {
                return await spendingsRepository.groups
                    .asyncCompactMap {
                        await spendingsRepository[group: $0]
                    }
                    .lazy
                    .asyncCompactMap { (group, participants) -> UserPreviewState.Status? in
                        guard participants.map(\.userId).contains(user.id) else {
                            return nil
                        }
                        let spendings = await spendingsRepository[spendingsIn: group.id] ?? []
                        return .haveGroupInCommon(group.id, balance: spendings
                            .reduce(into: [Currency: Amount]()) { dict, element in
                                let hostsShare = element.payload.shares
                                    .first { $0.userId == hostId }
                                guard let hostsShare else {
                                    return
                                }
                                dict[element.payload.currency] = dict[element.payload.currency, default: 0] + hostsShare.amount
                            }
                        )
                    }
                    .first ?? .noStatus
            }
        }
    }
}

actor UserPreviewModel {
    private let store: Store<UserPreviewState, UserPreviewAction>

    init(
        user: User,
        logger: Logger,
        usersRepository: UsersRepository,
        spendingsRepository: SpendingsRepository,
        usersRemoteDataSource: UsersRemoteDataSource,
        hostId: User.Identifier
    ) async {
        let dataSource = StatusDataSource(
            spendingsRepository: spendingsRepository,
            hostId: hostId,
            user: user
        )
        store = await Store(
            state: UserPreviewState(
                user: user,
                status: dataSource.status
            ),
            reducer: Self.reducer
        )
        await store.append(
            handler: UserPreviewSideEffects(
                store: store,
                logger: logger,
                usersRepository: usersRepository,
                spendingsRepository: spendingsRepository,
                usersRemoteDataSource: usersRemoteDataSource,
                dataSource: dataSource,
                hostId: hostId,
                userId: user.id
            ),
            keepingUnique: true
        )
        await store.append(
            handler: AnyActionHandler(
                id: "\(Logger.self)",
                handleBlock: { action in
                    logger.logI { "received action \(action)" }
                }
            ),
            keepingUnique: true
        )
    }
}

@MainActor extension UserPreviewModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (UserPreviewEvent) -> Void
    ) -> (UserPreviewTransitions) -> UserPreviewView {
        return { transitions in
            UserPreviewView(
                store: modify(self.store) { store in
                    store.append(
                        handler: AnyActionHandler(
                            id: "\(UserPreviewEvent.self)",
                            handleBlock: { action in
                                switch action {
                                case .spendingGroupCreated(let id):
                                    handler(.spendingGroupCreated(id))
                                case .close:
                                    handler(.closed)
                                default:
                                    break
                                }
                            }
                        ),
                        keepingUnique: true
                    )
                },
                transitions: transitions
            )
        }
    }
}
