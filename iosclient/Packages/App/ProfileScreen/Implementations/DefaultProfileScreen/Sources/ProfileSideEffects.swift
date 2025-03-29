import Entities
import ProfileScreen
import QrInviteUseCase
import ProfileRepository
import UsersRepository
import AppBase
import UIKit
import Logging

@MainActor final class ProfileSideEffects: Sendable {
    let logger: Logger
    
    private unowned let store: Store<ProfileState, ProfileAction>
    private let qrUseCase: QRInviteUseCase
    private let profileRepository: ProfileRepository
    private let usersRepository: UsersRepository
    private let urlProvider: UrlProvider

    init(
        store: Store<ProfileState, ProfileAction>,
        profileRepository: ProfileRepository,
        usersRepository: UsersRepository,
        qrUseCase: QRInviteUseCase,
        logger: Logger,
        urlProvider: UrlProvider
    ) {
        self.store = store
        self.profileRepository = profileRepository
        self.usersRepository = usersRepository
        self.qrUseCase = qrUseCase
        self.urlProvider = urlProvider
        self.logger = logger
    }
}

extension ProfileSideEffects: ActionHandler {
    var id: String {
        "\(ProfileSideEffects.self)"
    }

    func handle(_ action: ProfileAction) {
        switch action {
        case .onRequestQrImage(let size):
            requestQrImage(size: size)
        case .onAppear:
            subscribeToUpdates()
        case .onShareTap:
            shareProfile()
        default:
            break
        }
    }

    private func requestQrImage(size: Int) {
        Task {
            guard
                let anyUser = await usersRepository[profileRepository.profile.userId],
                case .regular(let user) = anyUser,
                let url = urlProvider.internalUrl(for: .users(.show(user)))
            else {
                return
            }
            let data = try? await self.qrUseCase.generate(
                background: .clear,
                tint: .black,
                size: size,
                text: url.absoluteString
            )
            guard let data, let image = UIImage(data: data)?.withRenderingMode(.alwaysTemplate) else {
                return
            }
            await self.store.dispatch(.onQrImageReady(image))
        }
    }
    
    private func subscribeToUpdates() {
        Task {
            await usersRepository.updates.subscribeWeak(self) { event in
                Task {
                    guard let user = event[await self.profileRepository.profile.userId] else {
                        return
                    }
                    await self.store.dispatch(.profileInfoUpdated(user.payload))
                }
            }
        }
    }
    
    private func shareProfile() {
        let state = store.state
        guard let url = urlProvider.externalUrl(
            for: .users(.show(.init(id: state.profile.userId, payload: state.profileInfo)))
        ) else {
            return logE { "failed to build profile external url" }
        }
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first,
            let rootViewController = window.rootViewController
        else {
            return logE { "failed to present activity controller - unexpected nil in view hierarchy" }
        }
        activityVC.popoverPresentationController?.sourceView = window
        rootViewController.present(activityVC, animated: true)
    }
}

extension ProfileSideEffects: Loggable {}
