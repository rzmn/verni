import Foundation
import Entities
import SwiftUI
import PhotosUI
internal import DesignSystem

public struct ProfileEditingState: Equatable, Sendable {
    public struct ImageSelection: Equatable, Sendable {
        public let image: PhotosPickerItem?
        public let uiImage: UIImage?
        
        public init(image: PhotosPickerItem?, uiImage: UIImage?) {
            self.image = image
            self.uiImage = uiImage
        }
    }
    
    public var currentDisplayName: String
    public var displayName: String
    public var displayNameHint: String?
    
    public var showingImagePicker: Bool
    public var currentAvatar: Entities.Image.Identifier?
    public var imageSelection: ImageSelection?
    
    public var canSubmit: Bool
    
    public var sessionId: UUID
    
    var hasChanges: Bool {
        let displayNameDiffers = currentDisplayName != displayName && !displayName.isEmpty
        let avatarDiffers: Bool
        if let imageSelection {
            avatarDiffers = currentAvatar != nil || imageSelection.image != nil
        } else {
            avatarDiffers = false
        }
        return displayNameDiffers || avatarDiffers
    }
    
    public init(
        currentDisplayName: String,
        displayName: String,
        displayNameHint: String? = nil,
        currentAvatar: Entities.Image.Identifier? = nil,
        imageSelection: ImageSelection? = nil,
        canSubmit: Bool,
        showingImagePicker: Bool,
        sessionId: UUID
    ) {
        self.currentDisplayName = currentDisplayName
        self.displayName = displayName
        self.displayNameHint = displayNameHint
        self.currentAvatar = currentAvatar
        self.imageSelection = imageSelection
        self.canSubmit = canSubmit
        self.showingImagePicker = showingImagePicker
        self.sessionId = sessionId
    }
}
