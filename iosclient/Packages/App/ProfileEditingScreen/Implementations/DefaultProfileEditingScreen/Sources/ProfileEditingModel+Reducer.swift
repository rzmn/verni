import ProfileEditingScreen
internal import Convenience

extension String {
    var isValidDisplayName: Bool {
        count >= 4
    }
}

extension ProfileEditingModel {
    static var reducer: @MainActor (ProfileEditingState, ProfileEditingAction) -> ProfileEditingState {
        return { state, action in
            switch action {
            case .onDisplayNameChanged(let name):
                return modify(state) {
                    $0.displayName = name
                    if !name.isEmpty && !name.isValidDisplayName {
                        $0.canSubmit = false
                        $0.displayNameHint = .profileEditDisplayNameTooShort
                    } else {
                        $0.canSubmit = true
                        $0.displayNameHint = nil
                    }
                }
            case .onDiscardName:
                return modify(state) {
                    $0.displayName = ""
                    $0.canSubmit = true
                }
            case .onCloseImagePicker:
                return modify(state) {
                    $0.showingImagePicker = false
                }
            case .onSelectImage:
                return modify(state) {
                    $0.showingImagePicker = true
                }
            case .onDiscardImage:
                return modify(state) {
                    $0.imageSelection = nil
                    $0.canSubmit = true
                }
            case .onSelectDefaultImage:
                return modify(state) {
                    $0.imageSelection = .init(image: nil, uiImage: nil)
                    $0.canSubmit = true
                }
            case .onSelectedImageChanged(let image):
                return modify(state) {
                    $0.imageSelection = .init(image: image, uiImage: nil)
                    $0.canSubmit = false
                }
            case .onSelectedImageLoaded(let image, let uiImage):
                return modify(state) {
                    $0.imageSelection = .init(image: image, uiImage: uiImage)
                    $0.canSubmit = true
                }
            case .onClose:
                return modify(state) {
                    $0.canSubmit = true
                }
            case .onSaveChanges:
                return modify(state) {
                    $0.canSubmit = false
                }
            }
        }
    }
}
