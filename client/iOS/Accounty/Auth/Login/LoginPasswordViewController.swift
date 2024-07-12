import UIKit

class LoginPasswordViewController: UIViewController {
    private let model: LoginModel
    private var passwordView: LoginPasswordView {
        view as! LoginPasswordView
    }

    init(model: LoginModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func loadView() {
        view = LoginPasswordView(model: model)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        passwordView.startEditing()
    }
}
