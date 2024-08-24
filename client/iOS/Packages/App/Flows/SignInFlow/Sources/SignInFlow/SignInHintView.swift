import AppBase
import UIKit
internal import DesignSystem
internal import Base

class SignInHintView: View<SignInFlow> {
    private let button = Button(
        config: Button.Config(
            style: .primary,
            title: "login_go_to_signin".localized
        )
    )

    override func setupView() {
        backgroundColor = .p.background
        [button].forEach(addSubview)
        button.addAction({ [weak model] in
            model?.openSignIn()
        }, for: .touchUpInside)
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
