import UIKit
import Domain

class QrPreviewViewController: UIViewController {
    private let _qrView: UIView
    private let user: User

    init(qrView: UIView, user: User) {
        _qrView = qrView
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func loadView() {
        view = QrPreviewView(qrView: _qrView, user: user)
    }
}
