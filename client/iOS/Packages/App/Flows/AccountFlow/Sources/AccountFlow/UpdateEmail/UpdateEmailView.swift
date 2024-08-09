import AppBase
import UIKit
import Combine
internal import DesignSystem

class UpdateEmailView: View<UpdateEmailFlow> {
    private var subscriptions = Set<AnyCancellable>()

    private let email = {
        let label = UILabel()
        label.font = .p.text
        label.textColor = .p.primary
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
            content: .unspecified
        )
    )

    override func setupView() {
        [email, resendCode, enterCode, confirmEmail].forEach(addSubview)
        backgroundColor = .p.background
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        resendCode.addAction({ [weak model] in
            await model?.resendCode()
        }, for: .touchUpInside)
        confirmEmail.addAction({ [weak model] in
            await model?.confirm()
        }, for: .touchUpInside)
        enterCode.addAction({ [weak model, weak enterCode] in
            model?.update(code: enterCode?.text ?? "")
        }, for: .editingChanged)
        model.subject
            .receive(on: RunLoop.main)
            .sink(receiveValue: render)
            .store(in: &subscriptions)
        render(state: model.subject.value)
    }

    @objc private func onTap() {
        endEditing(true)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = email.sizeThatFits(CGSize(width: max(0, bounds.width - .p.defaultHorizontal * 2), height: bounds.height))
        email.frame = CGRect(
            x: .p.defaultHorizontal,
            y: safeAreaInsets.top + .p.defaultVertical,
            width: size.width,
            height: size.height
        )
        enterCode.frame = CGRect(
            x: .p.defaultHorizontal,
            y: email.frame.maxY + .p.defaultVertical,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        resendCode.frame = CGRect(
            x: .p.defaultHorizontal,
            y: bounds.maxY - safeAreaInsets.bottom - .p.defaultVertical - .p.buttonHeight,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        confirmEmail.frame = CGRect(
            x: .p.defaultHorizontal,
            y: resendCode.frame.minY - .p.defaultVertical - .p.buttonHeight,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
    }

    private func render(state: UpdateEmailState) {
        switch state.confirmation {
        case .confirmed:
            resendCode.isHidden = true
            enterCode.isHidden = true
            confirmEmail.isHidden = true
            email.text = "\(state.email) (confirmed)"
        case .uncorfirmed(_, let hint):
            resendCode.isHidden = false
            if let hint {
                resendCode.render(
                    config: Button.Config(
                        style: .secondary,
                        title: String(format: "email_code_send_countdown".localized, hint)
                    )
                )
                resendCode.isEnabled = false
                resendCode.alpha = 0.64
            } else {
                resendCode.render(
                    config: Button.Config(
                        style: .secondary,
                        title: "resend_verification_email_code".localized
                    )
                )
                resendCode.isEnabled = true
                resendCode.alpha = 1
            }
            enterCode.isHidden = false
            confirmEmail.isHidden = false
            email.text = "\(state.email) (unconfirmed)"
        }
        setNeedsLayout()
    }
}
