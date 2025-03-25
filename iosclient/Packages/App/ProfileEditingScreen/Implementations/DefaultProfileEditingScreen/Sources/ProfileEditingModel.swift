import UIKit
import Entities
import AppBase
import Combine
import ProfileRepository
import UsersRepository
import AsyncExtensions
import AvatarsRepository
import SwiftUI
import Logging
import ProfileEditingScreen
import QrInviteUseCase
internal import Convenience
internal import DesignSystem

actor ProfileEditingModel {
    private let store: Store<ProfileEditingState, ProfileEditingAction>

    init(
        profileRepository: ProfileRepository,
        usersRepository: UsersRepository,
        avatarsRepository: AvatarsRepository,
        logger: Logger
    ) async {
        let profile = await profileRepository.profile
        let user: User
        if let anyUser = await usersRepository[profile.userId], case .regular(let data) = anyUser {
            user = data
        } else {
            user = User(
                id: profile.userId,
                payload: UserPayload(
                    displayName: profile.userId,
                    avatar: nil
                )
            )
        }
        store = await Store(
            state: Self.initialState(
                displayName: user.payload.displayName,
                currentAvatar: user.payload.avatar
            ),
            reducer: Self.reducer
        )
        await store.append(
            handler: ProfileEditingSideEffects(
                store: store,
                profileRepository: profileRepository,
                usersRepository: usersRepository,
                avatarsRepository: avatarsRepository,
                logger: logger
            ),
            keepingUnique: true
        )
        await store.append(
            handler: AnyActionHandler(
                id: "\(Logger.self)",
                handleBlock: { action in
                    logger.logI { "received action \(action)" }
                }
            ),
            keepingUnique: true
        )
    }
}

@MainActor extension ProfileEditingModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (ProfileEditingEvent) -> Void
    ) -> (ProfileEditingTransitions) -> ProfileEditingView {
        return { transitions in
            ProfileEditingView(
                store: modify(self.store) { store in
                    store.append(
                        handler: AnyActionHandler(
                            id: "\(ProfileEditingEvent.self)",
                            handleBlock: { action in
                                switch action {
                                case .onClose, .onChangesSaved:
                                    handler(.onClose)
                                default:
                                    break
                                }
                            }
                        ),
                        keepingUnique: true
                    )
                },
                transitions: transitions
            )
        }
    }
}
