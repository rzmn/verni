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

struct SpendingsDataSource {
    let spendingsRepository: SpendingsRepository
    let usersRepository: UsersRepository
    let logger: Logger
    let hostId: User.Identifier
    
    var spendings: [SpendingsState.Item] {
        get async {
            await spendingsRepository.groups
                .asyncCompactMap {
                    await spendingsRepository[group: $0]
                }
                .asyncCompactMap { (group, participants) -> SpendingsState.Item? in
                    let name: String
                    let image: Entities.Image.Identifier?
                    if let groupName = group.name {
                        name = groupName
                    } else {
                        name = await participants
                            .map(\.userId)
                            .filter { $0 != hostId }
                            .asyncCompactMap {
                                await usersRepository[$0]?.payload.displayName
                            }
                            .joined(separator: ", ")
                    }
                    image = await participants
                        .map(\.userId)
                        .filter { $0 != hostId }
                        .lazy
                        .asyncCompactMap {
                            await usersRepository[$0]?.payload.avatar
                        }
                        .first
                    let spendings = await spendingsRepository[spendingsIn: group.id] ?? []
                    return SpendingsState.Item(
                        id: group.id,
                        image: image,
                        name: name,
                        balance: spendings
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
        }
    }
}

actor SpendingsModel {
    private let store: Store<SpendingsState, SpendingsAction>
    private let spendingsRepository: SpendingsRepository
    private let usersRepository: UsersRepository
    
    init(
        spendingsRepository: SpendingsRepository,
        usersRepository: UsersRepository,
        hostId: User.Identifier,
        logger: Logger
    ) async {
        self.spendingsRepository = spendingsRepository
        self.usersRepository = usersRepository
        let dataSource = SpendingsDataSource(
            spendingsRepository: spendingsRepository,
            usersRepository: usersRepository,
            logger: logger,
            hostId: hostId
        )
        let items = await dataSource.spendings
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
                dataSource: dataSource,
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
                                case .onGroupTap(let id):
                                    handler(.onGroupTap(id))
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
