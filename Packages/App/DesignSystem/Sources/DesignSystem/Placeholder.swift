import UIKit
import SwiftUI

extension DS {
    public struct Placeholder: View {
        public let message: String
        public let icon: UIImage

        public var body: some View {
            VStack {
                Text(message)
                    .padding(.bottom, 22)
                    .font(Font(UIFont.palette.secondaryText))
                Image(uiImage: icon)
                    .tint(Color(uiColor: .palette.accent))

            }
        }
    }
}

#Preview {
    VStack {
        DS.Placeholder(
            message: "placeholder",
            icon: UIImage(systemName: "dollarsign")!
        )
    }
}

private let hPadding: CGFloat = 22
private let iconTitleSpacing: CGFloat = 12
private let iconSize: CGFloat = 36
public class Placeholder: UIControl {
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
        label.numberOfLines = 0
        label.font = .palette.secondaryText
        label.textAlignment = .center
        return label
    }()
    private lazy var icon = {
        let view = UIImageView()
        view.tintColor = .palette.accent
        view.contentMode = .scaleAspectFit
        return view
    }()
    private let config: Config

    public init(config: Config) {
        self.config = config
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        for view in [icon, title] {
            addSubview(view)
        }
        render(config)
    }

    public func render(_ config: Placeholder.Config) {
        icon.image = config.icon
        title.text = config.message
        setNeedsLayout()
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
