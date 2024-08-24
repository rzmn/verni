import Foundation

struct AuthenticatedState: Equatable {
    enum Tab: Equatable {
        case friends
        case account
    }
    let tabs: [Tab]
    let activeTab: Tab
}
