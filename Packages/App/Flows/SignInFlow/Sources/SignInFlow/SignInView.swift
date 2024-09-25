import UIKit
import AppBase
import Combine
internal import Base
internal import DesignSystem

private let appIconSize: CGFloat = 158
private let appIconBottomPadding: CGFloat = 48
class SignInView: UIKitBasedView<SignInViewActions> {
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
    private var keyboardBottomInset: CGFloat = 0
    private var subscriptions = Set<AnyCancellable>()

    override func setupView() {
        backgroundColor = .palette.background
        for view in [email, password, close, confirm, createAccount, appIcon] {
            addSubview(view)
        }
        close.tapPublisher
            .sink(receiveValue: curry(model.handle)(.onSignInCloseTap))
            .store(in: &subscriptions)
        email.textPublisher
            .map { $0 ?? "" }
            .sink(receiveValue: model.handle • SignInViewActionType.onEmailTextUpdated)
            .store(in: &subscriptions)
        password.textPublisher
            .map { $0 ?? "" }
            .sink(receiveValue: model.handle • SignInViewActionType.onPasswordTextUpdated)
            .store(in: &subscriptions)
        confirm.tapPublisher
            .sink { [weak self] in
                self?.onConfirmTap()
            }
            .store(in: &subscriptions)
        createAccount.tapPublisher
            .sink { [weak self] in
                self?.onCreateAccountTap()
            }
            .store(in: &subscriptions)
        email.delegate = self
        password.delegate = self
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
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
        let closeFitSize = close.sizeThatFits(bounds.size)
        close.frame = CGRect(
            x: bounds.maxX - .palette.defaultHorizontal - closeFitSize.width,
            y: safeAreaInsets.top + .palette.defaultVertical,
            width: closeFitSize.width,
            height: closeFitSize.height
        )
        appIcon.frame = CGRect(
            x: bounds.midX - appIconSize / 2,
            y: close.frame.maxY + .palette.defaultVertical,
            width: appIconSize,
            height: appIconSize
        )
        email.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: appIcon.frame.maxY + appIconBottomPadding,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
        password.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: email.frame.maxY + .palette.vButtonSpacing,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
        createAccount.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: bounds.maxY - safeAreaInsets.bottom - .palette.buttonHeight - .palette.defaultVertical,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
        let confirmEmailMaxY = keyboardBottomInset == 0 ? createAccount.frame.minY : (bounds.maxY - keyboardBottomInset)
        confirm.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: confirmEmailMaxY - .palette.vButtonSpacing - .palette.buttonHeight,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
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
        password.render(
            TextField.Config(
                placeholder: "login_pwd_placeholder".localized,
                content: .password
            )
        )
        confirm.render(
            config: Button.Config(
                style: .primary,
                title: "login_go_to_signin".localized,
                enabled: state.canConfirm
            )
        )
    }

    private func onConfirmTap() {
        endEditing(true)
        model.handle(.onSignInTap)
    }

    private func onCreateAccountTap() {
        endEditing(true)
        model.handle(.onCreateAccountTap)
    }

    @objc private func onTap() {
        endEditing(true)
    }
}

extension SignInView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case password:
            confirm.sendActions(for: .touchUpInside)
        case email:
            password.becomeFirstResponder()
        default:
            break
        }
        return true
    }
}
