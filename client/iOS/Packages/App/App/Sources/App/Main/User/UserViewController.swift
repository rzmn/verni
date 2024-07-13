import UIKit

class UserViewController: UIViewController {
    private let model: UserModel

    init(model: UserModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func loadView() {
        view = UserView(model: model)
    }
}
