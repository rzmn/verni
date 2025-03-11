import UIKit
import Entities
import AppBase
import Combine
import SpendingsRepository
import ProfileRepository
import UsersRepository
import AsyncExtensions
import SwiftUI
import Logging
import AddExpenseScreen
import QrInviteUseCase
internal import Convenience
internal import DesignSystem

actor AddExpenseModel {
    private let store: Store<AddExpenseState, AddExpenseAction>

    init(
        profileRepository: ProfileRepository,
        spendingsRepository: SpendingsRepository,
        usersRepository: UsersRepository,
        logger: Logger
    ) async {
        let hostId = await profileRepository.profile.userId
        let host: User
        if let anyHost = await usersRepository[hostId], case .regular(let user) = anyHost {
            host = user
        } else {
            logger.logE { "cannot get host info" }
            host = User(
                id: hostId,
                payload: UserPayload(
                    displayName: hostId,
                    avatar: nil
                )
            )
        }
        let groups = await spendingsRepository.groups
            .asyncCompactMap { group -> OneToOneSpendingsGroup? in
                guard let group = await spendingsRepository[group: group] else {
                    return nil
                }
                guard let participant = group.participants.first(where: { $0.userId != hostId }) else {
                    return nil
                }
                guard let anyUser = await usersRepository[participant.userId] else {
                    return nil
                }
                guard case .regular(let user) = anyUser else {
                    return nil
                }
                return OneToOneSpendingsGroup(
                    counterparty: user,
                    group: group.group
                )
            }
        store = await Store<AddExpenseState, AddExpenseAction>(
            state: AddExpenseState(
                currency: .russianRuble,
                amount: 0,
                splitRule: .equally,
                paidByHost: true,
                title: "",
                host: host,
                counterparty: nil,
                availableCounterparties: groups.map(\.counterparty)
                
            ),
            reducer: Self.reducer
        )
        await store.append(
            handler: AddExpenseSideEffects(
                store: store,
                groups: groups,
                hostId: hostId,
                spendingsRepository: spendingsRepository
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

@MainActor extension AddExpenseModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (AddExpenseEvent) -> Void
    ) -> (AddExpenseTransitions) -> AddExpenseView {
        return { transitions in
            AddExpenseView(
                store: modify(self.store) { store in
                    store.append(
                        handler: AnyActionHandler(
                            id: "\(AddExpenseEvent.self)",
                            handleBlock: { action in
                                switch action {
                                case .expenseAdded, .cancel:
                                    handler(.finished)
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
