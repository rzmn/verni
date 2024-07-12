import UIKit
import DesignSystem
import Combine

private let topPadding: CGFloat = 22
private let vSpacing: CGFloat = 12
private let buttonHeight: CGFloat = 88
private let hPadding: CGFloat = 22
class UserView: UIView {
    private let model: UserModel
    private let avatar = Avatar(config: Avatar.Config(letter: "", style: .large))
    private let name = {
        let label = UILabel()
        label.textColor = .p.primary
        label.font = .p.title2
        label.textAlignment = .center
        return label
    }()
    private var subscriptions = Set<AnyCancellable>()
    private let acceptButton = Button(config: Button.Config(style: .primary, title: "friend_req_accept".localized))
    private let sendButton = Button(config: Button.Config(style: .primary, title: "friend_req_send".localized))
    private let rejectButton = Button(config: Button.Config(style: .destructive, title: "friend_req_reject".localized))
    private let unfriendButton = Button(config: Button.Config(style: .destructive, title: "friend_unfriend".localized))
    private let rollbackButton = Button(config: Button.Config(style: .destructive, title: "friend_req_rollback".localized))
    private var buttons: [Button] {
        [acceptButton, sendButton, rejectButton, unfriendButton, rollbackButton]
    }

    init(model: UserModel) {
        self.model = model
        super.init(frame: .zero)
        setupView()
        render(state: model.subject.value)
        model.subject
            .receive(on: DispatchQueue.main)
            .sink { state in
                self.render(state: state)
            }
            .store(in: &subscriptions)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupView() {
        [[name, avatar], buttons as [UIView]].flatMap { $0 }.forEach(addSubview)
        backgroundColor = .p.background
        acceptButton.addAction(UIAction(handler: { _ in
            Task.detached {
                await self.model.acceptRequest()
            }
        }), for: .touchUpInside)
        sendButton.addAction(UIAction(handler: { _ in
            Task.detached {
                await self.model.sendRequest()
            }
        }), for: .touchUpInside)
        rejectButton.addAction(UIAction(handler: { _ in
            Task.detached {
                await self.model.rejectRequest()
            }
        }), for: .touchUpInside)
        unfriendButton.addAction(UIAction(handler: { _ in
            Task.detached {
                await self.model.unfriend()
            }
        }), for: .touchUpInside)
        rollbackButton.addAction(UIAction(handler: { _ in
            Task.detached {
                await self.model.rollbackRequest()
            }
        }), for: .touchUpInside)
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
        let loginSize = name.sizeThatFits(bounds.size)
        name.frame = CGRect(
            x: bounds.midX - loginSize.width / 2,
            y: avatar.frame.maxY + vSpacing,
            width: loginSize.width,
            height: loginSize.height
        )
        let buttons = buttons.filter { !$0.isHidden }
        _ = buttons.reduce(name.frame.maxY + vSpacing, { yOffset, button in
            button.frame = CGRect(
                x: hPadding,
                y: yOffset,
                width: bounds.width - hPadding * 2,
                height: buttonHeight
            )
            return yOffset + buttonHeight + vSpacing
        })
    }

    private func render(state: UserState) {
        avatar.config = Avatar.Config(letter: state.user.id.prefix(1).uppercased(), style: .large)
        name.text = state.user.id
        buttons.forEach {
            $0.isHidden = true
        }
        switch state.user.status {
        case .me:
            break
        case .outgoing:
            rollbackButton.isHidden = false
        case .incoming:
            acceptButton.isHidden = false
            rejectButton.isHidden = false
        case .friend:
            unfriendButton.isHidden = false
        case .no:
            sendButton.isHidden = false
        }
        setNeedsLayout()
    }
}
