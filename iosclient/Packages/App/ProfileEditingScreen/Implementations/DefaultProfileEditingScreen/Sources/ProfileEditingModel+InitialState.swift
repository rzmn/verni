import ProfileEditingScreen
import Entities
import Foundation

extension ProfileEditingModel {
    static func initialState(
        displayName: String,
        currentAvatar: Entities.Image.Identifier?
    ) -> ProfileEditingState {
        ProfileEditingState(
            currentDisplayName: displayName,
            displayName: "",
            currentAvatar: currentAvatar,
            canSubmit: true,
            showingImagePicker: false,
            sessionId: UUID()
        )
    }
}
