import UIKit
import AppBase
import Combine
internal import Base
internal import DesignSystem

private let appIconSize: CGFloat = 158
private let appIconBottomPadding: CGFloat = 48
class SignInView: View<SignInFlow> {
    private let appIcon = {
        let view = UIImageView()
        view.image = UIImage(named: "logo")
        view.layer.masksToBounds = true
        view.layer.cornerRadius = appIconSize / 2
        return view
    }()
    private let email = TextField(
        config: TextField.Config(
            placeholder: "email_placeholder".localized,
            content: .email
        )
    )
    private let password = TextField(
        config: TextField.Config(
            placeholder: "login_pwd_placeholder".localized,
            content: .password
        )
    )
    private let confirm = Button(
        config: Button.Config(
            style: .primary,
            title: "login_go_to_signin".localized
        )
    )
    private let createAccount = Button(
        config: Button.Config(
            style: .secondary,
            title: "login_go_to_signup".localized
        )
    )
    private let close = IconButton(
        config: IconButton.Config(
            icon: UIImage(systemName: "xmark.circle.fill")
        )
    )
    private var subscriptions = Set<AnyCancellable>()

    override func setupView() {
        backgroundColor = .p.background
        [email, password, close, confirm, createAccount, appIcon].forEach(addSubview)
        close.addAction({ [weak model] in
            await model?.closeSignIn()
        }, for: .touchUpInside)
        email.addAction({ [weak model, weak email] in
            guard let model, let email else { return }
            model.update(email: email.text ?? "")
        }, for: .editingChanged)
        password.addAction({ [weak model, weak password] in
            guard let model, let password else { return }
            model.update(password: password.text ?? "")
        }, for: .editingChanged)
        confirm.addAction({ [weak model] in
            await model?.signIn()
        }, for: .touchUpInside)
        createAccount.addAction({ [weak model] in
            await model?.createAccount()
        }, for: .touchUpInside)
        email.delegate = self
        password.delegate = self
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        model.subject
            .receive(on: RunLoop.main)
            .sink(receiveValue: weak(self, type(of: self).render))
            .store(in: &subscriptions)
        render(state: model.subject.value)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let closeFitSize = close.sizeThatFits(bounds.size)
        close.frame = CGRect(
            x: bounds.maxX - .p.defaultHorizontal - closeFitSize.width,
            y: safeAreaInsets.top + .p.defaultVertical,
            width: closeFitSize.width,
            height: closeFitSize.height
        )
        appIcon.frame = CGRect(
            x: bounds.midX - appIconSize / 2,
            y: close.frame.maxY + .p.defaultVertical,
            width: appIconSize,
            height: appIconSize
        )
        email.frame = CGRect(
            x: .p.defaultHorizontal,
            y: appIcon.frame.maxY + appIconBottomPadding,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        password.frame = CGRect(
            x: .p.defaultHorizontal,
            y: email.frame.maxY + .p.vButtonSpacing,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        createAccount.frame = CGRect(
            x: .p.defaultHorizontal,
            y: bounds.maxY - safeAreaInsets.bottom - .p.buttonHeight - .p.defaultVertical,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        confirm.frame = CGRect(
            x: .p.defaultHorizontal,
            y: createAccount.frame.minY - .p.vButtonSpacing - .p.buttonHeight,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
    }

    private func render(state: SignInState) {
        email.render(
            TextField.Config(
                placeholder: "email_placeholder".localized,
                content: .email,
                formatHint: state.emailHint
            )
        )
    }

    @objc private func onTap() {
        endEditing(true)
    }
}

extension SignInView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case password:
            Task.detached {
                await self.model.signIn()
            }
        case email:
            password.becomeFirstResponder()
        default:
            break
        }
        return true
    }
}
