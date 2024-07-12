import UIKit
import DesignSystem

private let topPadding: CGFloat = 88
private let bottomPadding: CGFloat = 66
private let textFieldHeight: CGFloat = 48
private let buttonHeight: CGFloat = 44
private let hPadding: CGFloat = 22
private let vPadding: CGFloat = 22
class SignupView: UIView {
    private let title = {
        let l = UILabel()
        l.text = "signup_title".localized
        l.font = .p.title1
        l.textColor = .p.primary
        l.textAlignment = .center
        return l
    }()
    private let login = TextField(
        config: TextField.Config(
            placeholder: "login_placeholder".localized,
            content: .login
        )
    )
    private let confirm = Button(
        config: Button.Config(
            style: .primary,
            title: "continue".localized
        )
    )
    let model: SignupModel

    init(model: SignupModel) {
        self.model = model
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupView() {
        [title, login, confirm].forEach(addSubview)
        login.addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }
            login.text.flatMap(model.updateLogin)
        }), for: .editingChanged)
        confirm.addAction(UIAction(handler: { [weak self] _ in
            Task { [weak self] in
                await self?.model.confirmLogin()
            }
        }), for: .touchUpInside)
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
        login.frame = CGRect(
            x: hPadding,
            y: title.frame.maxY + vPadding,
            width: bounds.width - 2 * hPadding,
            height: textFieldHeight
        )
        confirm.frame = CGRect(
            x: hPadding,
            y: login.frame.maxY + vPadding,
            width: bounds.width - 2 * hPadding,
            height: buttonHeight
        )
    }

    func startEditing() {
        login.becomeFirstResponder()
    }
}
