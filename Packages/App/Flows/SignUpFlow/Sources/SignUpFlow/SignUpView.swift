import UIKit
import AppBase
import Combine
internal import Base
internal import DesignSystem

class SignUpView: View<SignUpViewActions> {
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
        backgroundColor = .palette.background
        for view in [email, password, passwordRepeat, confirm] {
            addSubview(view)
        }
        email.delegate = self
        password.delegate = self
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        email.textPublisher
            .map { $0 ?? "" }
            .sink(receiveValue: model.handle • SignUpViewActionType.onEmailTextUpdated)
            .store(in: &subscriptions)
        password.textPublisher
            .map { $0 ?? "" }
            .sink(receiveValue: model.handle • SignUpViewActionType.onPasswordTextUpdated)
            .store(in: &subscriptions)
        passwordRepeat.textPublisher
            .map { $0 ?? "" }
            .sink(receiveValue: model.handle • SignUpViewActionType.onRepeatPasswordTextUpdated)
            .store(in: &subscriptions)
        confirm.tapPublisher
            .sink(receiveValue: curry(model.handle)(.onSignInTap))
            .store(in: &subscriptions)
        model.state
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
            x: .palette.defaultHorizontal,
            y: safeAreaInsets.top + .palette.defaultVertical,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
        password.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: email.frame.maxY + .palette.vButtonSpacing,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
        passwordRepeat.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: password.frame.maxY + .palette.vButtonSpacing,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
        let bottomInset = keyboardBottomInset == 0 ? safeAreaInsets.bottom : keyboardBottomInset
        confirm.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: bounds.maxY - bottomInset - .palette.buttonHeight - .palette.defaultVertical,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
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
