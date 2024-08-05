import AppBase
import UIKit
internal import DesignSystem

class AccountView: View<AccountFlow> {
    private let logout = Button(
        config: Button.Config(
            style: .destructive,
            title: "account_logout".localized
        )
    )

    override func setupView() {
        backgroundColor = .p.background
        [logout].forEach(addSubview)
        logout.addAction({ [weak model] in
            await model?.logout()
        }, for: .touchUpInside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        logout.frame = CGRect(
            x: .p.defaultHorizontal,
            y: bounds.maxY - safeAreaInsets.bottom - .p.buttonHeight - .p.defaultVertical,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
    }
}
