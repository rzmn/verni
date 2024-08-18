import AppBase
import UIKit
import Combine
internal import DesignSystem

class AccountView: View<AccountFlow> {
    private let updateAvatar = Button(
        config: Button.Config(
            style: .primary,
            title: "account_update_avatar".localized
        )
    )
    private let updateEmail = Button(
        config: Button.Config(
            style: .primary,
            title: "account_update_email".localized
        )
    )
    private let updateDisplayName = Button(
        config: Button.Config(
            style: .primary,
            title: "account_update_display_name".localized
        )
    )
    private let updatePassword = Button(
        config: Button.Config(
            style: .primary,
            title: "account_update_password".localized
        )
    )
    private let logout = Button(
        config: Button.Config(
            style: .destructive,
            title: "account_logout".localized
        )
    )
    private var subscriptions = Set<AnyCancellable>()

    override func setupView() {
        backgroundColor = .p.background
        [updateAvatar, updateEmail, updateDisplayName, updatePassword, logout].forEach(addSubview)
        logout.addAction({ [weak model] in
            await model?.logout()
        }, for: .touchUpInside)
        updateAvatar.addAction({ [weak model] in
            await model?.updateAvatar()
        }, for: .touchUpInside)
        updateEmail.addAction({ [weak model] in
            await model?.updateEmail()
        }, for: .touchUpInside)
        updatePassword.addAction({ [weak model] in
            await model?.updatePassword()
        }, for: .touchUpInside)
        updateDisplayName.addAction({ [weak model] in
            await model?.updateDisplayName()
        }, for: .touchUpInside)
        model.subject
            .sink(receiveValue: render)
            .store(in: &subscriptions)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateAvatar.frame = CGRect(
            x: .p.defaultHorizontal,
            y: safeAreaInsets.top + .p.defaultVertical,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        updateEmail.frame = CGRect(
            x: .p.defaultHorizontal,
            y: updateAvatar.frame.maxY + .p.vButtonSpacing,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        updateDisplayName.frame = CGRect(
            x: .p.defaultHorizontal,
            y: updateEmail.frame.maxY + .p.vButtonSpacing,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        updatePassword.frame = CGRect(
            x: .p.defaultHorizontal,
            y: updateDisplayName.frame.maxY + .p.vButtonSpacing,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        logout.frame = CGRect(
            x: .p.defaultHorizontal,
            y: bounds.maxY - safeAreaInsets.bottom - .p.buttonHeight - .p.defaultVertical,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
    }

    private func render(state: AccountState) {
        switch state.info {
        case .initial:
            break
        case .loading:
            break
        case .loaded(let t):
            sequence(first: self, next: \.next)
                .first {
                    $0 is UIViewController
                }
                .flatMap {
                    guard let controller = $0 as? UIViewController else {
                        return
                    }
                    controller.navigationItem.title = t.user.displayName
                }
        case .failed:
            break
        }
    }
}
