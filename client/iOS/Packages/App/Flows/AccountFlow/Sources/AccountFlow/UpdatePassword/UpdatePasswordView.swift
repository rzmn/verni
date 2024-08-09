import AppBase
import UIKit
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

    override func setupView() {
        backgroundColor = .p.background
        [oldPassword, newPassword, newPasswordRepeat, confirm].forEach(addSubview)
        [oldPassword, newPassword, newPasswordRepeat].forEach {
            $0.delegate = self
        }
        confirm.addAction({ [weak model] in
            await model?.updatePassword()
        }, for: .touchUpInside)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
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
