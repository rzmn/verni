import UIKit
import Base

private let topPadding: CGFloat = 16
private let titleSubtitleSpace: CGFloat = 12
private let titleButtonsSpace: CGFloat = 24
private let buttonHeight: CGFloat = 44
class AlertContentView: UIView {
    private let config: Alert.Config

    private lazy var title = {
        let label = UILabel()
        label.font = .p.title2
        label.textColor = .p.primary
        label.text = config.title
        return label
    }()
    private lazy var subtitle = {
        let label = UILabel()
        label.font = .p.text
        label.textColor = .p.iconSecondary
        label.text = config.message
        label.numberOfLines = 0
        return label
    }()
    private lazy var buttons = config.actions.map { action in
        let b = Button(
            config: Button.Config(
                style: .primary,
                title: action.title
            )
        )
        action.handler.flatMap { handler in
            b.addAction({ [weak self] in
                guard let self else {
                    return
                }
                guard let controller = sequence(first: self, next: \.next)
                    .first(where: { $0 is UIViewController }) as? UIViewController
                else {
                    return
                }
                Task.detached { @MainActor in
                    await handler(controller)
                }
            }, for: .touchUpInside)
        }
        return b
    }
    private lazy var separators = config.actions.map { _ in
        let v = UIView()
        v.backgroundColor = .p.separator
        return v
    }

    init(config: Alert.Config) {
        self.config = config
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupView() {
        backgroundColor = .p.backgroundContent
        layer.masksToBounds = true
        layer.cornerRadius = 20
        [title, subtitle].forEach(addSubview)
        buttons.forEach(addSubview)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let titleSize = title.sizeThatFits(bounds.size)
        title.frame = CGRect(
            x: bounds.midX - titleSize.width / 2,
            y: topPadding,
            width: titleSize.width,
            height: titleSize.height
        )
        let subtitleSize = subtitle.sizeThatFits(bounds.size)
        subtitle.frame = CGRect(
            x: bounds.midX - subtitleSize.width / 2,
            y: title.frame.maxY + titleSubtitleSpace,
            width: subtitleSize.width,
            height: subtitleSize.height
        )
        _ = buttons.reduce(subtitle.frame.maxY + titleButtonsSpace, { yOffset, button in
            button.frame = CGRect(
                x: 0,
                y: yOffset,
                width: bounds.width,
                height: buttonHeight
            )
            return yOffset + buttonHeight
        })
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let titleSize = title.sizeThatFits(size)
        let subtitleSize = subtitle.sizeThatFits(size)
        let hPadding: CGFloat = 88
        let maxWidth = [[title, subtitle] as [UIView], buttons]
            .flatMap { $0 }
            .map { $0.sizeThatFits(size).width + hPadding }
            .max() ?? size.width
        return CGSize(
            width: min(size.width, maxWidth),
            height: [
                topPadding,
                titleSize.height,
                titleSubtitleSpace,
                subtitleSize.height,
                titleButtonsSpace,
                CGFloat(buttons.count) * buttonHeight
            ].reduce(0, +)
        )
    }
}
