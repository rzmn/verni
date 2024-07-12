import UIKit
import DesignSystem

private let topPadding: CGFloat = 88
private let bottomPadding: CGFloat = 66
private let textFieldHeight: CGFloat = 48
private let buttonHeight: CGFloat = 44
private let hPadding: CGFloat = 22
private let vPadding: CGFloat = 22
class LoginPasswordView: UIView {
    private let title = {
        let l = UILabel()
        l.text = "login_pwd_title".localized
        l.font = .p.title1
        l.textColor = .p.primary
        l.textAlignment = .center
        return l
    }()
    private let password = TextField(
        config: TextField.Config(
            placeholder: "login_pwd_placeholder".localized,
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

    private let model: LoginModel

    init(model: LoginModel) {
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
        password.addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }
            password.text.flatMap(model.updatePassword)
        }), for: .editingChanged)
        confirm.addAction(UIAction(handler: { [weak self] _ in
            Task { [weak self] in
                guard let self else { return }
                await model.confirmPassword()
            }
        }), for: .touchUpInside)
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
