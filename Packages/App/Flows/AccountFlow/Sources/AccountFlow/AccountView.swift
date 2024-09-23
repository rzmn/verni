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
        backgroundColor = .palette.background
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
            x: .palette.defaultHorizontal,
            y: safeAreaInsets.top + .palette.defaultVertical,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
        updateEmail.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: updateAvatar.frame.maxY + .palette.vButtonSpacing,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
        updateDisplayName.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: updateEmail.frame.maxY + .palette.vButtonSpacing,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
        updatePassword.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: updateDisplayName.frame.maxY + .palette.vButtonSpacing,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
        logout.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: bounds.maxY - safeAreaInsets.bottom - .palette.buttonHeight - .palette.defaultVertical,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
    }
}
