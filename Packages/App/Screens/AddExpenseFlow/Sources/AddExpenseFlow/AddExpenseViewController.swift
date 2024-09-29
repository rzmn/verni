import AppBase
import UIKit

class AddExpenseViewController: ViewController<AddExpenseView.Adapter, Store<AddExpenseState, AddExpenseUserAction>> {
    override func viewDidLoad() {
        super.viewDidLoad()
        isModalInPresentation = true
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "common_cancel".localized,
            style: .plain,
            target: self,
            action: #selector(cancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "common_save".localized,
            style: .done,
            target: self,
            action: #selector(save)
        )
    }

    @objc private func save() {
        model.handle(.onDoneTap)
    }

    @objc private func cancel() {
        model.handle(.onCancelTap)
    }
}

extension AddExpenseViewController: Routable {
    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return self
    }

    var name: String {
        "add expense"
    }
}
