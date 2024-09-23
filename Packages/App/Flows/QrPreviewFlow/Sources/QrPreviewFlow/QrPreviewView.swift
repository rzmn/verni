import UIKit
import Domain
import AppBase
internal import DesignSystem

class QrPreviewView: View<QrPreviewFlow> {
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
    private var qrView: UIView {
        model.state.qrView
    }

    override func setupView() {
        for view in [qrView, avatar] {
            addSubview(view)
        }
        avatar.avatarId = model.state.user.avatar?.id
        backgroundColor = .palette.background
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
    }
}
