import Domain
import Foundation

struct UserPreviewState {
    struct SpendingPreview: Equatable {
        let id: Spending.Identifier
        let date: Date
        let title: String
        let iOwe: Bool
        let currency: Currency
        let personalAmount: Cost
    }

    struct Failure: Error, Equatable {
        let hint: String
        let iconName: String?
    }

    let user: User
    let spenginds: Loadable<[SpendingPreview], Failure>

    var userNameText: String {
        if case .currentUser = user.status {
            return String(format: "login_your_format".localized, user.displayName)
        } else {
            return user.displayName
        }
    }
}
