import UIKit
import Combine
import Domain
import DesignSystem

class FriendView: UIView {
    private var subscriptions = Set<AnyCancellable>()
    private let label = {
        let l = UILabel()
        l.font = .p.text
        l.textColor = .p.primary
        return l
    }()
    private let avatar = Avatar(config: Avatar.Config(letter: "", style: .regular))

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupView() {
        [label, avatar].forEach(addSubview)
        layer.cornerRadius = 16
        layer.masksToBounds = true
        backgroundColor = .p.backgroundContent
    }

    func reuse() {
        subscriptions.removeAll()
        label.text = nil
    }

    func render(contentUpdater: CurrentValueSubject<User, Never>) {
        render(user: contentUpdater.value)
        subscriptions.removeAll()
        contentUpdater
            .receive(on: DispatchQueue.main)
            .sink { user in
                self.render(user: user)
            }
            .store(in: &subscriptions)
    }

    func render(user: User) {
        label.text = user.id
        avatar.config = Avatar.Config(letter: user.id.prefix(1).uppercased(), style: .regular)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let avatarSize = avatar.sizeThatFits(bounds.size)
        avatar.frame = CGRect(
            x: 12,
            y: bounds.midY - avatarSize.height / 2,
            width: avatarSize.width,
            height: avatarSize.height
        )
        let labelSize = label.sizeThatFits(bounds.size)
        label.frame = CGRect(
            x: avatar.frame.maxX + 12,
            y: bounds.midY - labelSize.height / 2,
            width: labelSize.width,
            height: labelSize.height
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: 56)
    }
}
