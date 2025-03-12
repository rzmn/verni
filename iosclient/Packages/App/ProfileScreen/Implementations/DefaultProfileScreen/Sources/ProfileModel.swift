import UIKit
import Entities
import AppBase
import Combine
import ProfileRepository
import UsersRepository
import AsyncExtensions
import SwiftUI
import Logging
import ProfileScreen
import QrInviteUseCase
internal import Convenience
internal import DesignSystem

actor ProfileModel {
    private let store: Store<ProfileState, ProfileAction>

    init(
        profileRepository: ProfileRepository,
        usersRepository: UsersRepository,
        qrInviteUseCase: QRInviteUseCase,
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
            state: ProfileState(
                profile: profile,
                profileInfo: user,
                avatarCardFlipCount: 0,
                qrCodeData: nil
            ),
            reducer: Self.reducer
        )
        await store.append(
            handler: ProfileSideEffects(
                store: store,
                profileRepository: profileRepository,
                usersRepository: usersRepository,
                qrUseCase: qrInviteUseCase
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

@MainActor extension ProfileModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (ProfileEvent) -> Void
    ) -> (ProfileTransitions) -> ProfileView {
        return { transitions in
            ProfileView(
                store: modify(self.store) { store in
                    store.append(
                        handler: AnyActionHandler(
                            id: "\(ProfileEvent.self)",
                            handleBlock: { action in
                                switch action {
                                case .onLogoutTap:
                                    handler(.logout)
                                case .unauthorized(let reason):
                                    handler(.unauthorized(reason: reason))
                                case .onShowQrHintTap:
                                    handler(.showQrHint)
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
