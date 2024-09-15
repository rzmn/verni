import AppBase
import UIKit
import Combine
internal import Base
internal import DesignSystem

class AccountView: View<AccountViewActions> {
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
        for view in [updateAvatar, updateEmail, updateDisplayName, updatePassword, logout] {
            addSubview(view)
        }
        logout.tapPublisher
            .sink(receiveValue: curry(model.handle)(.onLogoutTap))
            .store(in: &subscriptions)
        updateAvatar.tapPublisher
            .sink(receiveValue: curry(model.handle)(.onUpdateAvatarTap))
            .store(in: &subscriptions)
        updateEmail.tapPublisher
            .sink(receiveValue: curry(model.handle)(.onUpdateEmailTap))
            .store(in: &subscriptions)
        updatePassword.tapPublisher
            .sink(receiveValue: curry(model.handle)(.onUpdatePasswordTap))
            .store(in: &subscriptions)
        updateDisplayName.tapPublisher
            .sink(receiveValue: curry(model.handle)(.onUpdateDisplayNameTap))
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
}
