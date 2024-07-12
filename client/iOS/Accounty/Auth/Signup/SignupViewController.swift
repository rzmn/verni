import UIKit

class SignupViewController: UIViewController {
    private let model: SignupModel
    private var signupView: SignupView {
        view as! SignupView
    }

    init(model: SignupModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func loadView() {
        view = SignupView(model: model)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        signupView.startEditing()
    }
}
