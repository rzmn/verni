import AppBase
import UIKit
import Combine

class UserPreviewViewController: ViewController<UserPreviewView, UserPreviewFlow> {
    private var subscriptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        model.subject
            .sink(receiveValue: render)
            .store(in: &subscriptions)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.refresh()
    }

    private func render(state: UserPreviewState) {
        let menuActions: [UIAction] = {
            switch state.user.status {
            case .me:
                return []
            case .outgoing:
                return [
                    UIAction(
                        title: "friend_req_rollback".localized
                    ) { [unowned self] _ in
                        model.rollbackRequest()
                    }
                ]
            case .incoming:
                return [
                    UIAction(
                        title: "friend_req_accept".localized
                    ) { [unowned self] _ in
                        model.acceptRequest()
                    },
                    UIAction(
                        title: "friend_req_reject".localized,
                        attributes: [.destructive]
                    ) { [unowned self] _ in
                        model.rejectRequest()
                    }
                ]
            case .friend:
                return [
                    UIAction(
                        title: "friend_unfriend".localized,
                        attributes: [.destructive]
                    ) { [unowned self] _ in
                        model.unfriend()
                    }
                ]
            case .no:
                return [
                    UIAction(
                        title: "friend_req_send".localized
                    ) { [unowned self] _ in
                        model.sendRequest()
                    }
                ]
            }
        }()
        if menuActions.isEmpty {
            navigationItem.rightBarButtonItem = nil
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: nil,
                image: UIImage(systemName: "gearshape"),
                menu: UIMenu(
                    children: menuActions
                )
            )
        }
    }
}

extension UserPreviewViewController: Routable {
    var name: String {
        "user preview"
    }

    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return self
    }
}
