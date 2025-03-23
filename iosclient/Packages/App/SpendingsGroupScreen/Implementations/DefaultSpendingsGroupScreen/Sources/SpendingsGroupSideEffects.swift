import Entities
import SpendingsGroupScreen
import SpendingsRepository
import UsersRepository
import AppBase
import SwiftUI

@MainActor final class SpendingsGroupSideEffects: Sendable {
    private unowned let store: Store<SpendingsGroupState, SpendingsGroupAction>
    private let spendingsRepository: SpendingsRepository
    private let usersRepository: UsersRepository
    private let dataSource: SpendingsDataSource

    init(
        store: Store<SpendingsGroupState, SpendingsGroupAction>,
        spendingsRepository: SpendingsRepository,
        dataSource: SpendingsDataSource,
        usersRepository: UsersRepository
    ) {
        self.store = store
        self.spendingsRepository = spendingsRepository
        self.usersRepository = usersRepository
        self.dataSource = dataSource
    }
}

extension SpendingsGroupSideEffects: ActionHandler {
    var id: String {
        "\(SpendingsGroupSideEffects.self)"
    }

    func handle(_ action: SpendingsGroupAction) {
        switch action {
        case .onAppear:
            subscribeToUpdates()
        default:
            break
        }
    }
    
    private func subscribeToUpdates() {
        Task {
            await spendingsRepository
                .updates
                .subscribeWeak(self) { [weak self] events in
                    guard let self else { return }
                    Task { @MainActor in
                        let spendings = await dataSource.spendings
                        let preview = await dataSource.groupPreview
                        withAnimation {
                            store.dispatch(
                                .onSpendingsUpdated(
                                    SpendingsGroupState(
                                        preview: preview,
                                        items: spendings
                                    )
                                )
                            )
                        }
                    }
                }
        }
    }
}
