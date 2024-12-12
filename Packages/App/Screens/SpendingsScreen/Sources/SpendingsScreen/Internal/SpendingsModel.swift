import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
import Logging
internal import Base
internal import DesignSystem

actor SpendingsModel {
    private let store: Store<SpendingsState, SpendingsAction>

    init(di: AuthenticatedDomainLayerSession, logger: Logger) async {
        let spendings = await di.spendingsOfflineRepository.getSpendingCounterparties()
        let items = await withTaskGroup(of: Optional<SpendingsState.Item>.self, returning: [SpendingsState.Item].self) { group in
            spendings.flatMap { spendings in
                for spending in spendings {
                    group.addTask {
                        let user = try? await di.usersRepository.getUser(id: spending.counterparty)
                        return user.flatMap {
                            SpendingsState.Item(
                                user: $0,
                                balance: spending.balance
                            )
                        }
                    }
                }
            }
            return await group.reduce(into: [SpendingsState.Item]()) { result, spending in
                guard let spending else {
                    return
                }
                result.append(spending)
            }
        }
        store = await Store(
            state: modify(Self.initialState) {
                if spendings != nil {
                    $0.previews = .loaded(items)
                }
            },
            reducer: Self.reducer
        )
        await store.append(
            handler: SpendingsSideEffects(
                store: store,
                spendingsRepository: di.spendingsRepository,
                usersRepository: di.usersRepository
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
