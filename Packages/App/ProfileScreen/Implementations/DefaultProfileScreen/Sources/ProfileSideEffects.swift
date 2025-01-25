import Entities
import ProfileScreen
import QrInviteUseCase
import ProfileRepository
import AppBase
import UIKit

@MainActor final class ProfileSideEffects: Sendable {
    private unowned let store: Store<ProfileState, ProfileAction>
    private let qrUseCase: QRInviteUseCase
    private let repository: ProfileRepository
    private let userId: User.Identifier

    init(
        store: Store<ProfileState, ProfileAction>,
        repository: ProfileRepository,
        qrUseCase: QRInviteUseCase,
        userId: User.Identifier
    ) {
        self.store = store
        self.repository = repository
        self.qrUseCase = qrUseCase
        self.userId = userId
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
        default:
            break
        }
    }

    private func requestQrImage(size: Int) {
        Task.detached {
            let data = try? await self.qrUseCase.generate(
                background: .clear,
                tint: .black,
                size: size,
                userId: self.userId
            )
            guard let data, let image = UIImage(data: data)?.withRenderingMode(.alwaysTemplate) else {
                return
            }
            await self.store.dispatch(.onQrImageReady(image))
        }
    }
}
