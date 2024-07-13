import UIKit
import DesignSystem
import Combine

private let topPadding: CGFloat = 88
private let bottomPadding: CGFloat = 66
private let textFieldHeight: CGFloat = 48
private let buttonHeight: CGFloat = 44
private let hPadding: CGFloat = 22
private let vPadding: CGFloat = 22

class LoginView: UIView {
    private let title = {
        let l = UILabel()
        l.text = "login_title".localized
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
    private let signup = Button(
        config: Button.Config(
            style: .secondary,
            title: "login_go_to_signup".localized
        )
    )
    private let model: LoginModel
    private var subscriptions = Set<AnyCancellable>()

    init(model: LoginModel) {
        self.model = model
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupView() {
        [title, login, confirm, signup].forEach(addSubview)
        backgroundColor = .p.background
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        login.addAction({ [weak self] in
            guard let self else { return }
            login.text.flatMap(model.updateLogin)
        }, for: .editingChanged)
        confirm.addAction({ [weak self] in
            await self?.model.confirmLogin()
        }, for: .touchUpInside)
        signup.addAction({ [weak self] in
            await self?.model.signup()
        }, for: .touchUpInside)
        model.subject
            .receive(on: RunLoop.main)
            .sink { state in
                self.login.render(
                    TextField.Config(
                        placeholder: "login_placeholder".localized,
                        content: .login,
                        formatHint: state.loginHint
                    )
                )
            }
            .store(in: &subscriptions)
    }

    @objc private func onTap() {
        endEditing(true)
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
        signup.frame = CGRect(
            x: hPadding,
            y: bounds.height - buttonHeight - bottomPadding,
            width: bounds.width - 2 * hPadding,
            height: buttonHeight
        )
    }
}
