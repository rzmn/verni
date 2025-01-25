import UIKit
import Entities
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
import Logging
import SpendingsRepository
import UsersRepository
import SpendingsScreen
internal import Convenience
internal import DesignSystem

actor SpendingsModel {
    private let store: Store<SpendingsState, SpendingsAction>
    private let spendingsRepository: SpendingsRepository
    private let usersRepository: UsersRepository

    init(
        spendingsRepository: SpendingsRepository,
        usersRepository: UsersRepository,
        logger: Logger
    ) async {
        self.spendingsRepository = spendingsRepository
        self.usersRepository = usersRepository
        let items = await spendingsRepository.groups
            .asyncCompactMap {
                await spendingsRepository[group: $0]
            }
            .asyncCompactMap { (group, participants) -> SpendingsState.Item? in
                let users = await participants.asyncCompactMap { participant -> (participant: SpendingGroup.Participant, user: AnyUser)? in
                    guard let user = await usersRepository[participant.userId] else {
                        return nil
                    }
                    return (participant, user)
                }
                guard users.count == 2 else {
                    logger.logW { "skipping group \(group) due to wrong participants count \(participants)" }
                    return nil
                }
                guard let counterparty = users.first(where: { $0.user.id == "" }) else {
                    logger.logW { "counterparty not found in \(users.map(\.user))" }
                    return nil
                }
                return SpendingsState.Item(
                    user: counterparty.user,
                    balance: [:]
                )
            }
        store = await Store(
            state: modify(Self.initialState) {
                $0.previews = items
            },
            reducer: Self.reducer
        )
        await store.append(
            handler: SpendingsSideEffects(
                store: store,
                spendingsRepository: spendingsRepository,
                usersRepository: usersRepository
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

@MainActor extension SpendingsModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (SpendingsEvent) -> Void
    ) -> (SpendingsTransitions) -> SpendingsView {
        return { transitions in
            SpendingsView(
                store: modify(self.store) { store in
                    store.append(
                        handler: AnyActionHandler(
                            id: "\(SpendingsEvent.self)",
                            handleBlock: { action in
                                switch action {
                                case .onUserTap(let user):
                                    handler(.onUserTap(user))
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
