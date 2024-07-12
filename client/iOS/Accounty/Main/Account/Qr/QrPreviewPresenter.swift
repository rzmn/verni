import UIKit
import Domain

class QrPreviewPresenter {
    private weak var model: QrPreviewModel?
    private let router: AppRouter

    init(router: AppRouter, model: QrPreviewModel) {
        self.router = router
        self.model = model
    }

    @MainActor
    func start(qrView: UIView, user: User) async {
        let controller = QrPreviewViewController(qrView: qrView, user: user)
        await router.present(controller)
    }

    @MainActor
    func error() {
        
    }
}
