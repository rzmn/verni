import Domain
import Combine

@MainActor class UpdateDisplayNameViewModel {
    @Published var state: UpdateDisplayNameState

    @Published var displayName: String

    init() {
        let initial = UpdateDisplayNameState(displayName: "", displayNameHint: nil)
        state = initial
        displayName = initial.displayName
        setupStateBuilder()
    }

    private func setupStateBuilder() {
        $displayName
            .map {
                let displayNameHint: String?
                if $0.isEmpty {
                    displayNameHint = nil
                } else if $0.count < 4 {
                    displayNameHint = "display_name_invalid_lehght".localized
                } else if !$0.allSatisfy({ $0.isNumber || $0.isLetter }) {
                    displayNameHint = "display_name_invalid_format".localized
                } else {
                    displayNameHint = nil
                }
                return UpdateDisplayNameState(displayName: $0, displayNameHint: displayNameHint)
            }
            .assign(to: &$state)
    }
}
