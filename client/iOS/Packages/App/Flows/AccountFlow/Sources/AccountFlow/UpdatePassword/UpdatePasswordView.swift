import AppBase
import UIKit
import Combine
internal import DesignSystem

class UpdatePasswordView: View<UpdatePasswordFlow> {
    private let oldPassword = TextField(
        config: TextField.Config(
            placeholder: "enter_old_pwd_placeholder".localized,
            content: .unspecifiedSecure
        )
    )
    private let newPassword = TextField(
        config: TextField.Config(
            placeholder: "enter_new_pwd_placeholder".localized,
            content: .newPassword
        )
    )
    private let newPasswordRepeat = TextField(
        config: TextField.Config(
            placeholder: "enter_old_pwd_placeholder_again".localized,
            content: .newPassword
        )
    )
    private let confirm = Button(
        config: Button.Config(
            style: .primary,
            title: "common_confirm".localized
        )
    )
    private var subscriptions = Set<AnyCancellable>()

    override func setupView() {
        backgroundColor = .p.background
        [oldPassword, newPassword, newPasswordRepeat, confirm].forEach(addSubview)
        [oldPassword, newPassword, newPasswordRepeat].forEach {
            $0.delegate = self
        }
        oldPassword.addAction({ [weak model, weak oldPassword] in
            model?.update(oldPassword: oldPassword?.text ?? "")
        }, for: .editingChanged)
        newPassword.addAction({ [weak model, weak newPassword] in
            model?.update(newPassword: newPassword?.text ?? "")
        }, for: .editingChanged)
        newPasswordRepeat.addAction({ [weak model, weak newPasswordRepeat] in
            model?.update(repeatNewPassword: newPasswordRepeat?.text ?? "")
        }, for: .editingChanged)
        confirm.addAction({ [weak model] in
            await model?.updatePassword()
        }, for: .touchUpInside)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        render(state: model.subject.value)
        model.subject
            .receive(on: RunLoop.main)
            .sink(receiveValue: render)
            .store(in: &subscriptions)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        oldPassword.frame = CGRect(
            x: .p.defaultHorizontal,
            y: safeAreaInsets.top + .p.defaultVertical,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        newPassword.frame = CGRect(
            x: .p.defaultHorizontal,
            y: oldPassword.frame.maxY + .p.vButtonSpacing,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        newPasswordRepeat.frame = CGRect(
            x: .p.defaultHorizontal,
            y: newPassword.frame.maxY + .p.vButtonSpacing,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        confirm.frame = CGRect(
            x: .p.defaultHorizontal,
            y: bounds.maxY - safeAreaInsets.bottom - .p.buttonHeight - .p.defaultVertical,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
    }

    @objc private func onTap() {
        endEditing(true)
    }

    private func render(state: UpdatePasswordState) {
        oldPassword.render(
            TextField.Config(
                placeholder: "enter_old_pwd_placeholder".localized,
                content: .unspecifiedSecure
            )
        )
        newPassword.render(
            TextField.Config(
                placeholder: "enter_new_pwd_placeholder".localized,
                content: .newPassword,
                formatHint: state.newPasswordHint
            )
        )
        newPasswordRepeat.render(
            TextField.Config(
                placeholder: "enter_old_pwd_placeholder_again".localized,
                content: .newPassword,
                formatHint: state.repeatNewPasswordHint
            )
        )
    }
}

extension UpdatePasswordView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case newPasswordRepeat:
            Task.detached {
                await self.model.updatePassword()
            }
        case oldPassword:
            newPassword.becomeFirstResponder()
        case newPassword:
            newPasswordRepeat.becomeFirstResponder()
        default:
            break
        }
        return true
    }
}
