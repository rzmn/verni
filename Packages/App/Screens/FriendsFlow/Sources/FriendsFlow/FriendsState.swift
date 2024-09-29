import Domain
import AppBase
import Combine
internal import Base

struct FriendsState {
    @MainActor class Item: Equatable, Sendable {
        @Published var data: ItemData
        let id: User.Identifier

        init(item: ItemData) {
            data = item
            id = item.user.id
        }

        nonisolated static func == (lhs: FriendsState.Item, rhs: FriendsState.Item) -> Bool {
            lhs.id == rhs.id
        }
    }
    struct ItemData: Equatable, Sendable {
        let user: User
        let balance: [Currency: Cost]
    }

    struct Section: Equatable, Sendable {
        let id: FriendshipKind
        let items: [Item]
    }

    struct Content: Equatable, Sendable {
        let sections: [Section]
    }

    struct Failure: Error, Equatable {
        let hint: String
        let iconName: String?
    }

    let content: Loadable<Content, Failure>

    init(content: Loadable<Content, Failure>) {
        self.content = content
    }

    init(
        _ state: Self,
        content: Loadable<Content, Failure>? = nil
    ) {
        self.content = content ?? state.content
    }
}
