import AppBase
import UIKit
import Combine
internal import DesignSystem
internal import Base

class UpdateEmailView: View<UpdateEmailViewActions> {
    private var subscriptions = Set<AnyCancellable>()

    private let email = {
        let label = UILabel()
        label.font = .palette.text
        label.textColor = .palette.primary
        return label
    }()
    private let resendCode = Button(
        config: Button.Config(
            style: .secondary,
            title: "resend_verification_email_code".localized
        )
    )
    private let confirmEmail = Button(
        config: Button.Config(
            style: .primary,
            title: "confirm_verification_email_code".localized
        )
    )
    private let enterCode = TextField(
        config: TextField.Config(
            placeholder: "enter_verification_email_code".localized,
            content: .oneTimeCode
        )
    )
    private var keyboardBottomInset: CGFloat = 0

    override func setupView() {
        for view in [email, resendCode, enterCode, confirmEmail] {
            addSubview(view)
        }
        backgroundColor = .palette.background
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        enterCode.delegate = self
        resendCode.tapPublisher
            .sink(receiveValue: curry(model.handle)(.onResendTap))
            .store(in: &subscriptions)
        confirmEmail.tapPublisher
            .sink(receiveValue: curry(model.handle)(.onConfirmTap))
            .store(in: &subscriptions)
        enterCode.textPublisher
            .map { $0 ?? "" }
            .sink(receiveValue: model.handle • UpdateEmailViewActionType.onConfirmationCodeTextChanged)
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
            }.store(in: &subscriptions)
    }

    private func onConfirmTap() {
        endEditing(true)
        model.handle(.onConfirmTap)
    }

    @objc private func onTap() {
        endEditing(true)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = email.sizeThatFits(
            CGSize(
                width: max(0, bounds.width - .palette.defaultHorizontal * 2),
                height: bounds.height
            )
        )
        email.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: safeAreaInsets.top + .palette.defaultVertical,
            width: size.width,
            height: size.height
        )
        enterCode.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: email.frame.maxY + .palette.defaultVertical,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
        resendCode.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: bounds.maxY - safeAreaInsets.bottom - .palette.defaultVertical - .palette.buttonHeight,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
        let confirmEmailMaxY = keyboardBottomInset == 0 ? resendCode.frame.minY : (bounds.maxY - keyboardBottomInset)
        confirmEmail.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: confirmEmailMaxY - .palette.defaultVertical - .palette.buttonHeight,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
    }

    private func render(state: UpdateEmailState) {
        switch state.confirmation {
        case .confirmed:
            resendCode.isHidden = true
            enterCode.isHidden = true
            confirmEmail.isHidden = true
            email.text = "\(state.email) (confirmed)"
        case .uncorfirmed(let uncorfirmed):
            resendCode.isHidden = false
            if let countdown = uncorfirmed.resendCountdownHint {
                resendCode.render(
                    config: Button.Config(
                        style: .secondary,
                        title: String(format: "email_code_send_countdown".localized, countdown),
                        enabled: state.canResendCode
                    )
                )
            } else {
                resendCode.render(
                    config: Button.Config(
                        style: .secondary,
                        title: "resend_verification_email_code".localized,
                        enabled: state.canResendCode
                    )
                )
            }
            confirmEmail.render(
                config: Button.Config(
                    style: .primary,
                    title: "confirm_verification_email_code".localized,
                    enabled: state.canConfirm
                )
            )
            enterCode.isHidden = false
            confirmEmail.isHidden = false
            email.text = "\(state.email) (unconfirmed)"
        }
        setNeedsLayout()
    }
}

extension UpdateEmailView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case enterCode:
            confirmEmail.sendActions(for: .touchUpInside)
        default:
            break
        }
        return true
    }
}
