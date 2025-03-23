import UIKit
import Entities
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
import Logging
import SpendingsRepository
import UsersRepository
import SpendingsGroupScreen
internal import Convenience
internal import DesignSystem

struct SpendingsDataSource {
    let spendingsRepository: SpendingsRepository
    let usersRepository: UsersRepository
    let logger: Logger
    let groupId: SpendingGroup.Identifier
    let hostId: User.Identifier
    let dateFormatter: DateFormatter
    
    var groupPreview: SpendingsGroupState.GroupPreview {
        get async {
            guard let (group, participants) = await spendingsRepository[group: groupId] else {
                return SpendingsGroupState.GroupPreview(
                    name: .notFound,
                    balance: [:]
                )
            }
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
            image = await participants.map(\.userId)
                .lazy
                .filter { $0 != hostId }
                .asyncCompactMap {
                    await usersRepository[$0]?.payload.avatar
                }
                .first
            let spendings = await spendingsRepository[spendingsIn: group.id] ?? []
            return SpendingsGroupState.GroupPreview(
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
    
    var spendings: [SpendingsGroupState.Item] {
        get async {
            guard let spendings = await spendingsRepository[spendingsIn: groupId] else {
                logger.logW { "no spendings found for group \(groupId)" }
                return []
            }
            return spendings
                .sorted {
                    $0.payload.createdAt > $1.payload.createdAt
                }
                .compactMap { spending -> SpendingsGroupState.Item? in
                    guard let share = spending.payload.shares.first(where: { $0.userId == hostId }) else {
                        return nil
                    }
                    return SpendingsGroupState.Item(
                        id: spending.id,
                        name: spending.payload.name,
                        currency: spending.payload.currency,
                        createdAt: dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(spending.payload.createdAt) / 1000)),
                        amount: spending.payload.amount,
                        diff: share.amount
                    )
                }
        }
    }
}

actor SpendingsGroupModel {
    private let store: Store<SpendingsGroupState, SpendingsGroupAction>
    private let spendingsRepository: SpendingsRepository
    private let usersRepository: UsersRepository

    init(
        spendingsRepository: SpendingsRepository,
        usersRepository: UsersRepository,
        hostId: User.Identifier,
        groupId: SpendingGroup.Identifier,
        logger: Logger
    ) async {
        self.spendingsRepository = spendingsRepository
        self.usersRepository = usersRepository
        let dataSource = SpendingsDataSource(
            spendingsRepository: spendingsRepository,
            usersRepository: usersRepository,
            logger: logger,
            groupId: groupId,
            hostId: hostId,
            dateFormatter: modify(DateFormatter()) {
                $0.dateFormat = "MMM d, h:mm a"
            }
        )
        let items = await dataSource.spendings
        let groupPreview = await dataSource.groupPreview
        store = await Store(
            state: SpendingsGroupState(
                preview: groupPreview,
                items: items
            ),
            reducer: Self.reducer
        )
        await store.append(
            handler: SpendingsGroupSideEffects(
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

@MainActor extension SpendingsGroupModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (SpendingsGroupEvent) -> Void
    ) -> (SpendingsGroupTransitions) -> SpendingsGroupView {
        return { transitions in
            SpendingsGroupView(
                store: modify(self.store) { store in
                    store.append(
                        handler: AnyActionHandler(
                            id: "\(SpendingsGroupEvent.self)",
                            handleBlock: { action in
                                switch action {
                                case .onTapBack:
                                    handler(.onClose)
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
