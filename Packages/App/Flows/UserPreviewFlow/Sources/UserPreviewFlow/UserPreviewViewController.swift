import AppBase
import UIKit
import Combine
internal import Base

@MainActor class UserPreviewViewController: ViewController<UserPreviewView, UserPreviewViewActions> {
    private var subscriptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        model.state
            .sink(receiveValue: render)
            .store(in: &subscriptions)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.handle(.onViewAppeared)
    }

    private func render(state: UserPreviewState) {
        let actions = menuActions(by: state)
        if actions.isEmpty {
            navigationItem.rightBarButtonItem = nil
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: nil,
                image: UIImage(systemName: "gearshape"),
                menu: UIMenu(
                    children: actions
                )
            )
        }
    }

    private func menuActions(by state: UserPreviewState) -> [UIAction] {
        switch state.user.status {
        case .me:
            return []
        case .outgoing:
            return [
                UIAction(
                    title: "friend_req_rollback".localized,
                    handler: curry(model.handle)(.onRollbackFriendRequestTap) • nop
                )
            ]
        case .incoming:
            return [
                UIAction(
                    title: "friend_req_accept".localized,
                    handler: curry(model.handle)(.onAcceptFriendRequestTap) • nop
                ),
                UIAction(
                    title: "friend_req_reject".localized,
                    attributes: [.destructive],
                    handler: curry(model.handle)(.onRejectFriendRequestTap) • nop
                )
            ]
        case .friend:
            return [
                UIAction(
                    title: "friend_unfriend".localized,
                    attributes: [.destructive],
                    handler: curry(model.handle)(.onUnfriendTap) • nop
                )
            ]
        case .no:
            return [
                UIAction(
                    title: "friend_req_send".localized,
                    handler: curry(model.handle)(.onSendFriendRequestTap) • nop
                )
            ]
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
