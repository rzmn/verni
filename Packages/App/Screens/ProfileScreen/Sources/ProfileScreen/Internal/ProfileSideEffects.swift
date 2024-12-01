import Domain
import AppBase

@MainActor final class ProfileSideEffects: Sendable {
    private unowned let store: Store<ProfileState, ProfileAction>
    private let qrUseCase: QRInviteUseCase
    private let repository: ProfileRepository
    private let userId: User.Identifier
    private var shouldUseAlreadyLoadedProfile = false
    
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
        case .onRefreshProfile:
            onRefreshProfile()
        case .onRequestQrImage(let size):
            requestQrImage(size: size)
        default:
            break
        }
    }
    
    private func requestQrImage(size: Int) {
        Task.detached {
            let data = try? await self.qrUseCase.generate(
                background: .white,
                tint: .black,
                size: size,
                userId: self.userId
            )
            guard let data else {
                return
            }
            await self.store.dispatch(.onQrImageReady(data))
        }
    }
    
    private func onRefreshProfile() {
        Task.detached {
            await self.refreshProfile()
        }
    }
    
    private func refreshProfile() async {
        guard !shouldUseAlreadyLoadedProfile else {
            return
        }
        let profile: Profile
        do {
            profile = try await repository.refreshProfile()
            shouldUseAlreadyLoadedProfile = true
            store.dispatch(.profileUpdated(profile))
        } catch {
            switch error {
            default:
                store.dispatch(.unauthorized(reason: "refresh profile failed: \(error)"))
            }
        }
    }
}
