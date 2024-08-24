import AppBase
import UIKit

class PickCounterpartyViewController: ViewController<PickCounterpartyView, PickCounterpartyFlow> {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "common_cancel".localized,
            style: .plain,
            target: self,
            action: #selector(cancel)
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.appeared()
    }

    @objc private func cancel() {
        model.cancel()
    }
}

extension PickCounterpartyViewController: Routable {
    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return self
    }

    var name: String {
        "pick counterparty"
    }
}
