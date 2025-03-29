import Entities
import ProfileScreen
import QrInviteUseCase
import ProfileRepository
import UsersRepository
import AppBase
import UIKit

@MainActor final class ProfileSideEffects: Sendable {
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
        urlProvider: UrlProvider
    ) {
        self.store = store
        self.profileRepository = profileRepository
        self.usersRepository = usersRepository
        self.qrUseCase = qrUseCase
        self.urlProvider = urlProvider
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
        default:
            break
        }
    }

    private func requestQrImage(size: Int) {
        Task {
            guard
                let anyUser = await usersRepository[profileRepository.profile.userId],
                case .regular(let user) = anyUser,
                let url = urlProvider.url(for: .users(.show(user)))
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
}
