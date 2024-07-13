import UIKit

private let hPadding: CGFloat = 22
private let iconTitleSpacing: CGFloat = 12
private let iconSize: CGFloat = 36
public class RefreshPlaceholder: UIControl {
    public struct Config {
        public let message: String
        public let icon: UIImage?

        public init(message: String, icon: UIImage?) {
            self.message = message
            self.icon = icon
        }
    }

    private lazy var title = {
        let label = UILabel()
        label.text = config.message
        label.numberOfLines = 0
        label.font = .p.secondaryText
        label.textAlignment = .center
        return label
    }()
    private lazy var icon = {
        let v = UIImageView(image: config.icon)
        v.tintColor = .p.accent
        v.contentMode = .scaleAspectFit
        return v
    }()
    private let config: Config

    public init(config: Config) {
        self.config = config
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupView() {
        [icon, title].forEach(addSubview)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        icon.frame = CGRect(
            x: bounds.midX - iconSize / 2,
            y: 0,
            width: iconSize,
            height: iconSize
        )
        let titleSize = title.sizeThatFits(CGSize(width: bounds.width - hPadding * 2, height: bounds.height))
        title.frame = CGRect(
            x: bounds.midX - titleSize.width / 2,
            y: icon.frame.maxY + iconTitleSpacing,
            width: titleSize.width,
            height: titleSize.height
        )
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(
            width: size.width,
            height: [
                iconSize,
                iconTitleSpacing,
                title.sizeThatFits(CGSize(width: size.width - hPadding * 2, height: size.height)).height
            ].reduce(0, +)
        )
    }
}
