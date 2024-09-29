import Foundation

struct UpdateDisplayNameState {
    let displayName: String
    let displayNameHint: String?

    var canConfirm: Bool {
        if displayName.isEmpty {
            return false
        }
        if displayNameHint != nil {
            return false
        }
        return true
    }
}
