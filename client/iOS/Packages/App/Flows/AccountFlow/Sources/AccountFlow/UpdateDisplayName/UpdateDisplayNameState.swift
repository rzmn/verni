import Foundation

struct UpdateDisplayNameState {
    let displayName: String
    let displayNameHint: String?

    static var initial: Self {
        UpdateDisplayNameState(displayName: "", displayNameHint: nil)
    }
}
