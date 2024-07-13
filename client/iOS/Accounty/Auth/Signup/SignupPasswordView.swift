import UIKit
import DesignSystem
import Combine

private let topPadding: CGFloat = 88
private let bottomPadding: CGFloat = 66
private let textFieldHeight: CGFloat = 48
private let buttonHeight: CGFloat = 44
private let hPadding: CGFloat = 22
private let vPadding: CGFloat = 22
class SignupPasswordView: UIView {
    private let title = {
        let l = UILabel()
        l.text = "signup_pwd_title".localized
        l.font = .p.title1
        l.textColor = .p.primary
        l.textAlignment = .center
        return l
    }()
    private let password = TextField(
        config: TextField.Config(
            placeholder: "signup_pwd_placeholder".localized,
            content: .password
        )
     )
    private let confirm = {
        let b = UIButton()
        b.setTitle("continue".localized, for: .normal)
        b.setTitleColor(.label, for: .normal)
        b.titleLabel?.font = .p.title2
        return b
    }()
    private let model: SignupModel
    private var subscriptions = Set<AnyCancellable>()

    init(model: SignupModel) {
        self.model = model
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupView() {
        [title, password, confirm].forEach(addSubview)
        backgroundColor = .p.background
        password.addAction({ [weak self] in
            guard let self else { return }
            await model.updatePassword(password.text ?? "")
        }, for: .editingChanged)
        confirm.addAction({ [weak self] in
            await self?.model.confirmPassword()
        }, for: .touchUpInside)
        model.subject
            .receive(on: RunLoop.main)
            .sink { state in
                self.password.render(
                    TextField.Config(
                        placeholder: "signup_pwd_placeholder".localized,
                        content: .login,
                        formatHint: state.passwordHint
                    )
                )
            }
            .store(in: &subscriptions)
        backgroundColor = .p.background
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        title.frame = CGRect(
            x: 0,
            y: safeAreaInsets.top + topPadding,
            width: bounds.width,
            height: title.sizeThatFits(bounds.size).height
        )
        password.frame = CGRect(
            x: hPadding,
            y: title.frame.maxY + vPadding,
            width: bounds.width - 2 * hPadding,
            height: textFieldHeight
        )
        confirm.frame = CGRect(
            x: hPadding,
            y: password.frame.maxY + vPadding,
            width: bounds.width - 2 * hPadding,
            height: buttonHeight
        )
    }

    func startEditing() {
        password.becomeFirstResponder()
    }
}
