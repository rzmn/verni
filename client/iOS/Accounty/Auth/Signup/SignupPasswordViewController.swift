import UIKit

class SignupPasswordViewController: UIViewController {
    private let model: SignupModel
    private var passwordView: SignupPasswordView {
        view as! SignupPasswordView
    }

    init(model: SignupModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func loadView() {
        view = SignupPasswordView(model: model)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        passwordView.startEditing()
    }
}
