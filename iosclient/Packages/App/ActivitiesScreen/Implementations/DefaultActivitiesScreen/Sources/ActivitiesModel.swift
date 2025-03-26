import UIKit
import Entities
import AppBase
import Combine
import SpendingsRepository
import OperationsRepository
import UsersRepository
import AsyncExtensions
import SwiftUI
import Logging
import ActivitiesScreen
internal import Convenience
internal import DesignSystem

actor ActivitiesModel {
    private let store: Store<ActivitiesState, ActivitiesAction>
    private let dateFormatter =  modify(DateFormatter()) {
        $0.dateFormat = "MMM d, h:mm a"
    }

    init(
        operationsRepository: OperationsRepository,
        usersRepository: UsersRepository,
        spendingsRepository: SpendingsRepository,
        logger: Logger
    ) async {
        let operations = await operationsRepository.operations
        store = await Store<ActivitiesState, ActivitiesAction>(
            state: modify(ActivitiesModel.initialState) {
                $0.operations = operations
            },
            reducer: Self.reducer
        )
        await store.append(
            handler: AddExpenseSideEffects(
                store: store,
                operationsRepository: operationsRepository,
                usersRepository: usersRepository,
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

@MainActor extension ActivitiesModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (ActivitiesEvent) -> Void
    ) -> (ActivitiesTransitions) -> ActivitiesView {
        return { [dateFormatter] transitions in
            ActivitiesView(
                store: modify(self.store) { store in
                    store.append(
                        handler: AnyActionHandler(
                            id: "\(ActivitiesEvent.self)",
                            handleBlock: { action in
                                switch action {
                                case .cancel:
                                    handler(.closed)
                                default:
                                    break
                                }
                            }
                        ),
                        keepingUnique: true
                    )
                },
                dateFormatter: dateFormatter,
                transitions: transitions
            )
        }
    }
}
