import Foundation
import Domain

fileprivate extension FriendsState.Content {
    init(
        friends: [FriendshipKind: [User]],
        spendings: [SpendingsPreview],
        items: inout [User.ID: FriendsState.Item]
    ) {
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
        let sectionsOrder: [FriendshipKind] = [.subscriber, .subscription, .friends]
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

    private var currentFriends: [FriendshipKind: [User]]?
    private var currentSpendings: [SpendingsPreview]?

    convenience init(friends: [FriendshipKind: [User]], spendings: [SpendingsPreview]) {
        self.init(
            currentFriends: friends,
            currentSpendings: spendings
        )
    }

    convenience init() {
        self.init(currentFriends: nil, currentSpendings: nil)
    }

    private init(
        currentFriends: [FriendshipKind: [User]]?,
        currentSpendings: [SpendingsPreview]?
    ) {
        self.currentFriends = currentFriends
        self.currentSpendings = currentSpendings
        if let currentFriends, let currentSpendings {
            var items = [User.ID: FriendsState.Item]()
            let content = FriendsState.Content(friends: currentFriends, spendings: currentSpendings, items: &items)
            self.items = items
            self.content = .loaded(content)
            self.state = FriendsState(content: .loaded(content))
        } else {
            self.items = [:]
            let content: Loadable<FriendsState.Content, FriendsState.Failure> = .initial
            self.content = content
            self.state = FriendsState(content: content)
        }
        setupStateBuilder()
    }

    private func setupStateBuilder() {
        $content.map { content in
            FriendsState(content: content)
        }
        .receive(on: RunLoop.main)
        .assign(to: &$state)
    }

    func reload(friends: [FriendshipKind: [User]], spendings: [SpendingsPreview]) {
        content = .loaded(FriendsState.Content(friends: friends, spendings: spendings, items: &items))
    }

    func reload(friends: [FriendshipKind: [User]]) {
        self.currentFriends = friends
        guard let currentSpendings else {
            return
        }
        reload(friends: friends, spendings: currentSpendings)
    }

    func reload(spendings: [SpendingsPreview]) {
        self.currentSpendings = spendings
        guard let currentFriends else {
            return
        }
        reload(friends: currentFriends, spendings: spendings)
    }

    func reload(error: GeneralError) {
        switch error {
        case .noConnection:
            content = .failed(
                previous: content,
                FriendsState.Failure(
                    hint: "no_connection_hint".localized,
                    iconName: "network.slash"
                )
            )
        case .notAuthorized:
            content = .failed(
                previous: content,
                FriendsState.Failure(
                    hint: "alert_title_unauthorized".localized,
                    iconName: "network.slash"
                )
            )
        case .other:
            content = .failed(
                previous: content,
                FriendsState.Failure(
                    hint: "unknown_error_hint".localized,
                    iconName: "exclamationmark.triangle"
                )
            )
        }
    }
}
