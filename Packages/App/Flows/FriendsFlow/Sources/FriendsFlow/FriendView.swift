import UIKit
import Combine
import Domain
import AppBase
internal import DesignSystem

class FriendView: UIView {
    private var subscriptions = Set<AnyCancellable>()
    private let label = {
        let label = UILabel()
        label.font = .p.text
        label.textColor = .p.primary
        return label
    }()
    private let balanceLabel = {
        let label = UILabel()
        label.font = .p.subtitle
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
        [label, avatar, balanceLabel].forEach(addSubview)
        backgroundColor = .p.backgroundContent
    }

    func reuse() {
        subscriptions.removeAll()
        label.text = nil
    }
    
    func render(item: FriendsState.Item) {
        subscriptions.removeAll()
        item.$data
            .sink(receiveValue: render)
            .store(in: &subscriptions)
    }

    private func render(data: FriendsState.ItemData) {
        let user = data.user
        let balance = data.balance
        label.text = user.displayName
        avatar.avatarId = user.avatar?.id
        if balance.isEmpty || balance.values.allSatisfy({ $0 == 0 }) {
            balanceLabel.text = "expense_settled_up".localized
            balanceLabel.textColor = .p.primary
        } else {
            let description = balance.map { "\($0.key.stringValue):\($0.value)" }.joined(separator: ", ")
            let color: UIColor
            if balance.values.allSatisfy({ $0 >= 0 }) {
                color = .p.positive
            } else if balance.values.allSatisfy({ $0 <= 0 }) {
                color = .p.destructive
            } else {
                color = .p.primary
            }
            balanceLabel.text = String(
                format: "expense_balance_fmt".localized,
                description
            )
            balanceLabel.textColor = color
        }
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
        let balanceSize = balanceLabel.sizeThatFits(bounds.size)
        let minY = (bounds.height - labelSize.height - balanceSize.height) / 2
        label.frame = CGRect(
            x: avatar.frame.maxX + .p.defaultHorizontal,
            y: minY,
            width: labelSize.width,
            height: labelSize.height
        )
        balanceLabel.frame = CGRect(
            x: avatar.frame.maxX + .p.defaultHorizontal,
            y: label.frame.maxY,
            width: balanceSize.width,
            height: balanceSize.height
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: 52)
    }
}
