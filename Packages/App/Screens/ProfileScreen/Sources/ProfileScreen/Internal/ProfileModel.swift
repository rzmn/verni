import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
internal import Base
internal import DesignSystem

actor ProfileModel {
    private let store: Store<ProfileState, ProfileAction>

    init(di: AuthenticatedDomainLayerSession) async {
        let profile = await di.profileOfflineRepository.getProfile()
        store = await Store(
            state: modify(Self.initialState) {
                if let profile {
                    $0.profile = .loaded(profile)
                }
            },
            reducer: Self.reducer
        )
        await store.append(
            handler: ProfileSideEffects(
                store: store,
                repository: di.profileRepository,
                qrUseCase: di.qrInviteUseCase(),
                userId: di.userId
            ),
            keepingUnique: true
        )
    }
}

@MainActor extension ProfileModel: ScreenProvider {
    typealias Args = Void
    
    func instantiate(
        handler: @escaping @MainActor (ProfileEvent) -> Void
    ) -> (Args) -> ProfileView {
        return { _ in
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
                }
            )
        }
    }
}
