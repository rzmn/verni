import Foundation
import Entities
import UIKit
import PhotosUI
import SwiftUI

public enum ProfileEditingAction: Sendable {
    case onDisplayNameChanged(String)
    case onDiscardName
    
    case onCloseImagePicker
    case onSelectImage
    case onDiscardImage
    case onSelectDefaultImage
    
    case onSelectedImageChanged(PhotosPickerItem?)
    case onSelectedImageLoaded(PhotosPickerItem?, UIImage)
    
    case onClose
    case onSaveChanges
}
