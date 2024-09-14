import Domain
import AppBase
import Combine

struct FriendsState {
    class Item: Equatable {
        @Published var data: ItemData
        let id: User.ID

        init(item: ItemData) {
            data = item
            id = item.user.id
        }

        static func == (lhs: FriendsState.Item, rhs: FriendsState.Item) -> Bool {
            lhs.id == rhs.id
        }
    }
    struct ItemData: Equatable {
        let user: User
        let balance: [Currency: Cost]
    }

    struct Section: Equatable {
        let id: FriendshipKind
        let items: [Item]
    }

    struct Content: Equatable {
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
