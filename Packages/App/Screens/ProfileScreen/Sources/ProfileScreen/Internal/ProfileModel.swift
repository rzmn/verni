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

    init(di: AuthenticatedDomainLayerSession, haptic: HapticManager) async {
        let profile = await di.profileOfflineRepository.getProfile()
        store = await Store(
            state: modify(Self.initialState) {
                if let profile {
                    $0.profile = .loaded(profile)
                }
            },
            reducer: Self.reducer
        )
    }
}

@MainActor extension ProfileModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (ProfileEvent) -> Void
    ) -> ProfileView {
        ProfileView(
            store: modify(store) { store in
                store.append(
                    handler: AnyActionHandler(
                        id: "\(ProfileEvent.self)",
                        handleBlock: { action in
                            switch action {
                            case .onLogoutConfirmTap:
                                handler(.logout)
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
