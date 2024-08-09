import UIKit
import AppBase
import Combine
internal import Base
internal import DesignSystem

class SignUpView: View<SignUpFlow> {
    private let email = TextField(
        config: TextField.Config(
            placeholder: "email_placeholder".localized,
            content: .email
        )
    )
    private let password = TextField(
        config: TextField.Config(
            placeholder: "login_pwd_placeholder".localized,
            content: .newPassword
        )
    )
    private let passwordRepeat = TextField(
        config: TextField.Config(
            placeholder: "login_pwd_repeat_placeholder".localized,
            content: .newPassword
        )
    )
    private let confirm = Button(
        config: Button.Config(
            style: .primary,
            title: "login_go_to_signup".localized
        )
    )

    private var subscriptions = Set<AnyCancellable>()

    override func setupView() {
        backgroundColor = .p.background
        [email, password, passwordRepeat, confirm].forEach(addSubview)
        email.delegate = self
        password.delegate = self
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        email.addAction({ [weak model, weak email] in
            guard let model, let email else { return }
            model.update(email: email.text ?? "")
        }, for: .editingChanged)
        password.addAction({ [weak model, weak password] in
            guard let model, let password else { return }
            model.update(password: password.text ?? "")
        }, for: .editingChanged)
        passwordRepeat.addAction({ [weak model, weak passwordRepeat] in
            guard let model, let passwordRepeat else { return }
            model.update(passwordRepeat: passwordRepeat.text ?? "")
        }, for: .editingChanged)
        confirm.addAction({ [weak model] in
            await model?.signIn()
        }, for: .touchUpInside)
        model.subject
            .receive(on: RunLoop.main)
            .sink(receiveValue: render)
            .store(in: &subscriptions)
        render(state: model.subject.value)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        email.frame = CGRect(
            x: .p.defaultHorizontal,
            y: safeAreaInsets.top + .p.defaultVertical,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        password.frame = CGRect(
            x: .p.defaultHorizontal,
            y: email.frame.maxY + .p.vButtonSpacing,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        passwordRepeat.frame = CGRect(
            x: .p.defaultHorizontal,
            y: password.frame.maxY + .p.vButtonSpacing,
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

    private func render(state: SignUpState) {
        email.render(
            TextField.Config(
                placeholder: "email_placeholder".localized,
                content: .email,
                formatHint: state.emailHint
            )
        )
        password.render(
            TextField.Config(
                placeholder: "login_pwd_placeholder".localized,
                content: .newPassword,
                formatHint: state.passwordHint
            )
        )
        passwordRepeat.render(
            TextField.Config(
                placeholder: "login_pwd_repeat_placeholder".localized,
                content: .newPassword,
                formatHint: state.passwordConfirmationHint
            )
        )
    }

    @objc private func onTap() {
        endEditing(true)
    }
}

extension SignUpView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case passwordRepeat:
            Task.detached {
                await self.model.signIn()
            }
        case email:
            password.becomeFirstResponder()
        case password:
            passwordRepeat.becomeFirstResponder()
        default:
            break
        }
        return true
    }
}
