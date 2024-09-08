import AppBase
import UIKit
import Combine
internal import DesignSystem
internal import Base

class SignInHintView: View<SignInViewActions> {
    private let button = Button(
        config: Button.Config(
            style: .primary,
            title: "login_go_to_signin".localized
        )
    )
    private var subscriptions = Set<AnyCancellable>()

    override func setupView() {
        backgroundColor = .p.background
        [button].forEach(addSubview)
        button.tapPublisher
            .sink(receiveValue: curry(model.handle)(.onOpenSignInTap))
            .store(in: &subscriptions)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = CGRect(
            x: .p.defaultHorizontal,
            y: bounds.midY - .p.buttonHeight,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
    }
}
