import UIKit
import Domain
import DI
internal import DesignSystem

actor QrPreviewModel {
    private let useCase: QRInviteUseCase
    private let router: AppRouter
    private lazy var presenter = QrPreviewPresenter(router: router, model: self)

    init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
        useCase = di.qrInviteUseCase()
    }

    func start(user: User) async {
        await router.showHud(graceTime: 0.15)
        let qrView: UIView
        do {
            qrView = try await useCase.createView(
                background: .p.backgroundContent,
                tint: .p.primary,
                url: "\(InternalUrl.scheme)://u/\(user.id)",
                extraBottomPadding: 36
            )
        } catch {
            return await presenter.error()
        }
        await router.hideHud()
        await presenter.start(qrView: qrView, user: user)
    }
}
