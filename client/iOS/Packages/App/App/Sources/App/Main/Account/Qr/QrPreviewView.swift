import UIKit
import Domain
internal import DesignSystem

class QrPreviewView: UIView {
    private let qrView: UIView
    private let user: User
    private let avatar: Avatar
    private let login: UILabel

    init(qrView: UIView, user: User) {
        self.qrView = qrView
        self.user = user
        avatar = Avatar(config: Avatar.Config(letter: "\(user.id.prefix(1).uppercased())", style: .large))
        login = {
            let l = UILabel()
            l.text = "@\(user.id)"
            l.font = .p.title1
            l.textAlignment = .center
            l.textColor = .p.accent
            return l
        }()
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupView() {
        [qrView, avatar, login].forEach(addSubview)
        backgroundColor = .p.background
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let padding: CGFloat = 44

        let qrFitSize = qrView.sizeThatFits(bounds.size)
        qrView.frame = CGRect(
            x: bounds.midX - qrFitSize.width / 2,
            y: bounds.midY - qrFitSize.height / 2,
            width: qrFitSize.width,
            height: qrFitSize.height
        ).insetBy(dx: padding, dy: padding)
        let avatarFitSize = avatar.sizeThatFits(bounds.size)
        avatar.frame = CGRect(
            x: qrView.frame.midX - avatarFitSize.width / 2,
            y: qrView.frame.minY - avatarFitSize.height / 3 * 2,
            width: avatarFitSize.width,
            height: avatarFitSize.height
        )
        let qrExtraBottom = qrFitSize.height - qrFitSize.width
        let loginFit = login.sizeThatFits(bounds.size)
        login.frame = CGRect(
            x: qrView.frame.midX - loginFit.width / 2,
            y: qrView.frame.maxY - qrExtraBottom - loginFit.height / 2,
            width: loginFit.width,
            height: loginFit.height
        )
    }
}
