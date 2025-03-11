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
        store = await Store(
            state: UserPreviewState(
                user: user
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
