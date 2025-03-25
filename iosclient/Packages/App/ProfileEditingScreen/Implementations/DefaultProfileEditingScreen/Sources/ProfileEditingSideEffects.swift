import Entities
import ProfileEditingScreen
import QrInviteUseCase
import ProfileRepository
import UsersRepository
import AvatarsRepository
import AppBase
import UIKit
import PhotosUI
import SwiftUI
import Logging
internal import Convenience

extension PhotosPickerItem {
    func loadThumbnail(size: CGSize) async throws -> Data? {
        let thumbnail = try await loadTransferable(type: Data.self)
        guard let thumbnail else {
            return nil
        }
        guard let image = UIImage(data: thumbnail) else {
            return nil
        }
        let targetSize = CGSize(
            width: size.width,
            height: size.height
        )
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let croppedImage = renderer.image { context in
            let scale = max(
                targetSize.width / image.size.width,
                targetSize.height / image.size.height
            )
            let scaledWidth = image.size.width * scale
            let scaledHeight = image.size.height * scale
            let x = (targetSize.width - scaledWidth) / 2
            let y = (targetSize.height - scaledHeight) / 2
            
            image.draw(in: CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight))
        }
        return croppedImage.jpegData(compressionQuality: 0.8)
    }
}

@MainActor final class ProfileEditingSideEffects: Sendable {
    let logger: Logger
    
    private unowned let store: Store<ProfileEditingState, ProfileEditingAction>
    private let profileRepository: ProfileRepository
    private let avatarsRepository: AvatarsRepository
    private let usersRepository: UsersRepository
    private var photoItemTask: (item: PhotosPickerItem, task: Task<Data, Never>)?

    init(
        store: Store<ProfileEditingState, ProfileEditingAction>,
        profileRepository: ProfileRepository,
        usersRepository: UsersRepository,
        avatarsRepository: AvatarsRepository,
        logger: Logger
    ) {
        self.store = store
        self.profileRepository = profileRepository
        self.usersRepository = usersRepository
        self.avatarsRepository = avatarsRepository
        self.logger = logger
    }
}

extension ProfileEditingSideEffects: ActionHandler {
    var id: String {
        "\(ProfileEditingSideEffects.self)"
    }

    func handle(_ action: ProfileEditingAction) {
        switch action {
        case .onSelectedImageChanged(let item):
            onSelectedImageChanged(item: item)
        case .onDiscardImage:
            resetSelectedAsset()
        case .onSelectDefaultImage:
            resetSelectedAsset()
        case .onSaveChanges:
            editProfile()
        default:
            break
        }
    }
    
    private func onSelectedImageChanged(item: PhotosPickerItem?) {
        resetSelectedAsset()
        guard let item else {
            return
        }
        photoItemTask = (item, Task {
            do {
                guard
                    let data = try await item.loadThumbnail(size: CGSize(width: 400, height: 400)),
                    let image = UIImage(data: data)
                else {
                    throw InternalError.error("unexpected nil unpacking PhotosPickerItem")
                }
                guard !Task.isCancelled else {
                    return Data()
                }
                store.dispatch(.onSelectedImageLoaded(item, image))
                return data
            } catch {
                guard !Task.isCancelled else {
                    return Data()
                }
                logE { " failed to load PhotosPickerItem error: \(error)" }
                store.dispatch(.onDiscardImage)
                return Data()
            }
        })
    }
    
    private func resetSelectedAsset() {
        photoItemTask?.task.cancel()
        photoItemTask = nil
    }
    
    private func editProfile() {
        let state = store.state
        Task {
            let newDisplayName: String
            let newAvatarId: Entities.Image.Identifier?
            if let selection = state.imageSelection {
                if let item = selection.image {
                    if let photoItemTask {
                        if photoItemTask.item != item {
                            logW { "task item did not match picked PhotosPickerItem: task: \(photoItemTask.item), picked: \(item)" }
                            newAvatarId = state.currentAvatar
                        } else {
                            let data = await photoItemTask.task.value
                            do {
                                let id = try await avatarsRepository.upload(
                                    image: data.base64EncodedString()
                                )
                                try await usersRepository.updateAvatar(
                                    userId: profileRepository.profile.userId,
                                    imageId: id
                                )
                                newAvatarId = id
                            } catch {
                                logE { "failed to upload image error: \(error)" }
                                newAvatarId = state.currentAvatar
                            }
                        }
                    } else {
                        logW { "task not found for PhotosPickerItem \(item)" }
                        newAvatarId = state.currentAvatar
                    }
                } else {
                    try await usersRepository.updateAvatar(
                        userId: profileRepository.profile.userId,
                        imageId: nil
                    )
                    newAvatarId = nil
                }
            } else {
                newAvatarId = state.currentAvatar
            }
            if !state.displayName.isEmpty && state.displayName.isValidDisplayName {
                do {
                    try await usersRepository.updateDisplayName(
                        userId: profileRepository.profile.userId,
                        displayName: state.displayName
                    )
                    newDisplayName = state.displayName
                } catch {
                    logE { "failed to upload image error: \(error)" }
                    newDisplayName = state.currentDisplayName
                }
            } else {
                newDisplayName = state.currentDisplayName
            }
            store.dispatch(.onChangesSaved(displayName: newDisplayName, avatarId: newAvatarId))
        }
    }
}

extension ProfileEditingSideEffects: Loggable {}
