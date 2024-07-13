import UIKit

class LoginViewController: UIViewController {
    private let model: LoginModel

    init(model: LoginModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func loadView() {
        view = LoginView(model: model)
    }
}
