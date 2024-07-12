import UIKit
import DesignSystem
import Domain
import QR

actor QrPreviewModel {
    private let factory = QrCodeViewFactory()
    private let router: AppRouter
    private lazy var presenter = QrPreviewPresenter(router: router, model: self)

    init(router: AppRouter) async {
        self.router = router
    }

    func start(user: User) async {
        let qrView: UIView
        do {
            qrView = try await factory.createView(
                background: .p.backgroundContent,
                tint: .p.primary,
                url: "\(InternalUrl.scheme)://u/\(user.id)",
                extraBottomPadding: 36
            )
        } catch {
            return await presenter.error()
        }
        await presenter.start(qrView: qrView, user: user)
    }
}
