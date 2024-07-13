import UIKit
import Combine
internal import DesignSystem

private let topPadding: CGFloat = 22
private let vSpacing: CGFloat = 12
private let buttonHeight: CGFloat = 88
private let hPadding: CGFloat = 22
class AccountView: UIView {
    private let model: AccountModel
    private let avatar = Avatar(config: Avatar.Config(letter: "", style: .large))
    private let login = {
        let label = UILabel()
        label.textColor = .p.primary
        label.font = .p.title2
        label.textAlignment = .center
        return label
    }()
    private let logout = Button(
        config: Button.Config(
            style: .destructive,
            title: "account_logout".localized
        )
    )
    private let refreshPlaceholder = Placeholder(
        config: Placeholder.Config(
            message: "refresh_account_info".localized,
            icon: UIImage(systemName: "arrow.clockwise")
        )
    )
    private var subscriptions = Set<AnyCancellable>()

    init(model: AccountModel) {
        self.model = model
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupView() {
        [logout, refreshPlaceholder, avatar, login].forEach(addSubview)
        [avatar, login].forEach {
            $0.alpha = 0
        }
        backgroundColor = .p.background
        logout.addAction({ [weak self] in
            await self?.model.logout()
        }, for: .touchUpInside)
        refreshPlaceholder.addAction({ [weak self] in
            await self?.model.refresh()
        }, for: .touchUpInside)
        model.subject
            .receive(on: DispatchQueue.main)
            .sink { state in
                self.handle(state: state)
            }
            .store(in: &subscriptions)
        handle(state: model.subject.value, animated: false)
    }

    private func handle(state: AccountState, animated: Bool = true) {
        let contentViews = [avatar, login]
        let placeholderViews = [refreshPlaceholder]
        switch state.session {
        case .loaded(let user):
            avatar.config = Avatar.Config(
                letter: user.id.prefix(1).uppercased(),
                style: .large
            )
            login.text = String(format: "account_hello".localized, user.id)
            if animated {
                UIView.animate(withDuration: 0.15) {
                    contentViews.forEach { $0.alpha = 1 }
                }
            } else {
                UIView.performWithoutAnimation {
                    contentViews.forEach { $0.alpha = 1 }
                }
            }
            placeholderViews.forEach { $0.isHidden = true }
            setNeedsLayout()
        case .initial, .loading:
            contentViews.forEach { $0.alpha = 0 }
            placeholderViews.forEach { $0.isHidden = true }
        case .failed:
            contentViews.forEach { $0.alpha = 0 }
            placeholderViews.forEach { $0.isHidden = false }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let avatarSize = avatar.sizeThatFits(bounds.size)
        avatar.frame = CGRect(
            x: bounds.midX - avatarSize.width / 2,
            y: safeAreaInsets.top + topPadding,
            width: avatarSize.width,
            height: avatarSize.height
        )
        let loginSize = login.sizeThatFits(bounds.size)
        login.frame = CGRect(
            x: bounds.midX - loginSize.width / 2,
            y: avatar.frame.maxY + vSpacing,
            width: loginSize.width,
            height: loginSize.height
        )
        logout.frame = CGRect(
            x: hPadding,
            y: bounds.height - safeAreaInsets.bottom - buttonHeight - vSpacing,
            width: bounds.width - 2 * hPadding,
            height: buttonHeight
        )
        let refreshPlaceholderSize = refreshPlaceholder.sizeThatFits(bounds.size)
        refreshPlaceholder.frame = CGRect(
            x: bounds.midX - refreshPlaceholderSize.width / 2,
            y: bounds.midY - refreshPlaceholderSize.height / 2,
            width: refreshPlaceholderSize.width,
            height: refreshPlaceholderSize.height
        )
    }
}
