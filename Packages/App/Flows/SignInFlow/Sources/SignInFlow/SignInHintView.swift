import AppBase
import UIKit
import Combine
internal import DesignSystem
internal import Base

class SignInHintView: UIKitBasedView<SignInViewActions> {
    private let button = Button(
        config: Button.Config(
            style: .primary,
            title: "login_go_to_signin".localized
        )
    )
    private var subscriptions = Set<AnyCancellable>()

    override func setupView() {
        backgroundColor = .palette.background
        for view in [button] {
            addSubview(view)
        }
        button.tapPublisher
            .sink(receiveValue: curry(model.handle)(.onOpenSignInTap))
            .store(in: &subscriptions)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: bounds.midY - .palette.buttonHeight,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
    }
}
