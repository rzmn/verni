import UIKit
import Domain
import Combine
import AppBase

class UserView: UIView {
    private var subscriptions = Set<AnyCancellable>()
    private let label = {
        let label = UILabel()
        label.font = .p.text
        label.textColor = .p.primary
        return label
    }()
    private let avatar = {
        let size: CGFloat = 44
        let frame = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        let view = AvatarView(frame: frame)
        view.fitSize = frame.size
        view.layer.masksToBounds = true
        view.layer.cornerRadius = size / 2
        view.contentMode = .scaleAspectFill
        return view
    }()

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

    func render(user: User) {
        label.text = user.displayName
        avatar.avatarId = user.avatar?.id
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
