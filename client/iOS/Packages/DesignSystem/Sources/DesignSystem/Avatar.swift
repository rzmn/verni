import UIKit

private let font = "Copperplate"
public class Avatar: UIView {
    public struct Config {
        public enum Style {
            case large
            case regular
        }
        public let letter: String
        public let style: Style

        public init(letter: String, style: Style) {
            self.letter = letter
            self.style = style
        }
    }
    public var config: Config {
        didSet {
            layer.cornerRadius = size / 2
            label.font = UIFont(name: font, size: fontSize)
            label.text = config.letter.prefix(1).uppercased()
            setNeedsLayout()
        }
    }
    private var size: CGFloat {
        switch config.style {
        case .large:
            return 88
        case .regular:
            return 32
        }
    }
    private var fontSize: CGFloat {
        switch config.style {
        case .large:
            return 48
        case .regular:
            return 20
        }
    }
    private lazy var label = {
        let label = UILabel()
        label.textColor = .p.backgroundContent
        label.font = UIFont(name: font, size: fontSize)
        label.text = config.letter.prefix(1).uppercased()
        label.textAlignment = .center
        return label
    }()

    public init(config: Config) {
        self.config = config
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupView() {
        [label].forEach(addSubview)
        backgroundColor = .p.accent
        layer.masksToBounds = true
        layer.cornerRadius = size / 2
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let fitSize = label.sizeThatFits(CGSize(width: 1000, height: 1000))
        label.frame = CGRect(
            x: bounds.midX - fitSize.width / 2,
            y: bounds.midY - fitSize.height / 2,
            width: fitSize.width,
            height: fitSize.height
        )
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: self.size, height: self.size)
    }
}
