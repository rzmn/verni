import Domain
import AppBase

struct FriendsState {
    struct Item: Equatable, Identifiable {
        let user: User
        let balance: [Currency: Cost]

        var id: User.ID {
            user.id
        }
    }
    struct Section: Equatable {
        let id: FriendshipKind
        let items: [Item]

        static var order: [FriendshipKind] {
            [.incoming, .pending, .friends]
        }
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

    static var initial: Self {
        FriendsState(content: .initial)
    }
}
