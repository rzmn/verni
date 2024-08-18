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
    private var keyboardBottomInset: CGFloat = 0
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
            .sink(receiveValue: render)
            .store(in: &subscriptions)
        KeyboardObserver.shared.notifier
            .sink { [weak self] event in
                guard let self, !isInInteractiveTransition else { return }
                switch event.kind {
                case .willChangeFrame(let frame):
                    keyboardBottomInset = max(0, bounds.maxY - convert(frame, to: window).minY)
                case .willHide:
                    keyboardBottomInset = 0
                }
                setNeedsLayout()
                UIView.animate(
                    withDuration: event.animationDuration,
                    delay: 0,
                    options: event.options,
                    animations: layoutIfNeeded
                )
            }
            .store(in: &subscriptions)
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
        let bottomInset = keyboardBottomInset == 0 ? safeAreaInsets.bottom : keyboardBottomInset
        confirm.frame = CGRect(
            x: .p.defaultHorizontal,
            y: bounds.maxY - bottomInset - .p.buttonHeight - .p.defaultVertical,
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
        confirm.render(
            config: Button.Config(
                style: .primary,
                title: "login_go_to_signup".localized,
                enabled: state.canConfirm
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
            confirm.sendActions(for: .touchUpInside)
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
