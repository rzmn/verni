import Foundation
import Domain

fileprivate extension FriendsState.Content {
    init(friends: [FriendshipKind: [User]], spendings: [SpendingsPreview], items: inout [User.ID: FriendsState.Item]) {
        let users = friends.values.flatMap { $0 }
        let ids = Set(users.map(\.id))
        let idToBalance = spendings.reduce(into: [:]) { dict, preview in
            dict[preview.counterparty] = preview.balance
        }
        items = items.filter { ids.contains($0.key) }
        users.forEach { user in
            let balance = idToBalance[user.id, default: [:]]
            items[user.id]?.data = FriendsState.ItemData(
                user: user,
                balance: balance
            )
        }
        let sectionsOrder: [FriendshipKind] = [.incoming, .pending, .friends]
        self = FriendsState.Content(
            sections: sectionsOrder.compactMap { friendshipKind -> FriendsState.Section? in
                guard let users = friends[friendshipKind], !users.isEmpty else {
                    return nil
                }
                return FriendsState.Section(
                    id: friendshipKind,
                    items: users.map { user in
                        if let item = items[user.id] {
                            return item
                        } else {
                            let item = FriendsState.Item(
                                item: FriendsState.ItemData(
                                    user: user,
                                    balance: idToBalance[user.id, default: [:]]
                                )
                            )
                            items[user.id] = item
                            return item
                        }
                    }
                )
            }
        )
    }
}

@MainActor class FriendsViewModel {
    @Published var state: FriendsState

    @Published var content: Loadable<FriendsState.Content, FriendsState.Failure>
    private var items: [User.ID: FriendsState.Item]

    convenience init(friends: [FriendshipKind: [User]], spendings: [SpendingsPreview]) {
        var items = [User.ID: FriendsState.Item]()
        let content = FriendsState.Content(friends: friends, spendings: spendings, items: &items)
        self.init(initial: FriendsState(content: .loaded(content)), items: items)
    }

    convenience init() {
        self.init(initial: FriendsState(content: .initial), items: [:])
    }

    private init(initial: FriendsState, items: [User.ID: FriendsState.Item]) {
        self.items = items
        state = initial
        content = initial.content
        setupStateBuilder()
    }

    private func setupStateBuilder() {
        $content.map { content in
            FriendsState(content: content)
        }
        .assign(to: &$state)
    }

    func reload(friends: [FriendshipKind: [User]], spendings: [SpendingsPreview]) {
        content = .loaded(FriendsState.Content(friends: friends, spendings: spendings, items: &items))
    }
}
