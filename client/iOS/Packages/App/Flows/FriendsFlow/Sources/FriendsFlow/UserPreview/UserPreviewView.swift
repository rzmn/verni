import UIKit
import Combine
import AppBase
internal import DesignSystem

class UserPreviewView: View<UserPreviewFlow> {
    private let avatar = {
        let size: CGFloat = 88
        let frame = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        let view = AvatarView(frame: frame)
        view.fitSize = frame.size
        view.layer.masksToBounds = true
        view.layer.cornerRadius = size / 2
        view.contentMode = .scaleAspectFill
        return view
    }()
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

    override func setupView() {
        [[name, avatar], buttons as [UIView]].flatMap { $0 }.forEach(addSubview)
        backgroundColor = .p.background
        acceptButton.addAction({ [weak self] in
            await self?.model.acceptRequest()
        }, for: .touchUpInside)
        sendButton.addAction({ [weak self] in
            await self?.model.sendRequest()
        }, for: .touchUpInside)
        rejectButton.addAction({ [weak self] in
            await self?.model.rejectRequest()
        }, for: .touchUpInside)
        unfriendButton.addAction({ [weak self] in
            await self?.model.unfriend()
        }, for: .touchUpInside)
        rollbackButton.addAction({ [weak self] in
            await self?.model.rollbackRequest()
        }, for: .touchUpInside)
        render(state: model.subject.value)
        model.subject
            .receive(on: DispatchQueue.main)
            .sink { state in
                self.render(state: state)
            }
            .store(in: &subscriptions)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let avatarSize = avatar.sizeThatFits(bounds.size)
        avatar.frame = CGRect(
            x: bounds.midX - avatarSize.width / 2,
            y: safeAreaInsets.top + .p.defaultVertical,
            width: avatarSize.width,
            height: avatarSize.height
        )
        let loginSize = name.sizeThatFits(bounds.size)
        name.frame = CGRect(
            x: bounds.midX - loginSize.width / 2,
            y: avatar.frame.maxY + .p.vButtonSpacing,
            width: loginSize.width,
            height: loginSize.height
        )
        let buttons = buttons.filter { !$0.isHidden }
        _ = buttons.reduce(name.frame.maxY + .p.vButtonSpacing, { yOffset, button in
            button.frame = CGRect(
                x: .p.defaultHorizontal,
                y: yOffset,
                width: bounds.width - .p.defaultHorizontal * 2,
                height: .p.buttonHeight
            )
            return yOffset + .p.buttonHeight + .p.vButtonSpacing
        })
    }

    private func render(state: UserPreviewState) {
        avatar.avatarId = state.user.avatar?.id
        if case .me = state.user.status {
            name.text = String(format: "login_your_format".localized, state.user.displayName)
        } else {
            name.text = state.user.displayName
        }
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
