import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
internal import Base
internal import DesignSystem
internal import ProgressHUD

actor SignInModel {
    private let store: Store<SignInState, SignInAction>

    init(di: AnonymousDomainLayerSession) async {
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
        await store.append(
            handler: SignInSideEffects(
                store: store,
                saveCredentialsUseCase: di.appCommon.saveCredentialsUseCase,
                emailValidationUseCase: di.appCommon.localEmailValidationUseCase,
                authUseCase: di.authUseCase()
            ),
            keepingUnique: true
        )
    }
}

@MainActor extension SignInModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (SignInEvent) -> Void
    ) -> SignInView {
        SignInView(
            store: tap(store) { store in
                store.append(
                    handler: AnyActionHandler(
                        id: "\(SignInEvent.self)",
                        handleBlock: { action in
                            switch action {
                            case .close:
                                handler(.canceled)
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
