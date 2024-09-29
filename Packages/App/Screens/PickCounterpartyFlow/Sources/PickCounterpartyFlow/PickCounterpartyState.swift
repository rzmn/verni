import Domain
import AppBase

struct PickCounterpartyState {
    struct Section: Equatable {
        enum Kind: Hashable {
            case existing
        }
        let kind: Kind
        let items: [User]
    }
    struct Failure: Error, Equatable {
        let hint: String
        let iconName: String?
    }
    let content: Loadable<[Section], Failure>
}
