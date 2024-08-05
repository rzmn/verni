import UIKit

public class IconButton: UIButton {
    public struct Config {
        let icon: UIImage?

        public init(icon: UIImage?) {
            self.icon = icon
        }
    }

    public init(config: Config) {
        super.init(frame: .zero)
        configuration = {
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = .zero
            configuration.imagePadding = 0
            configuration.imagePlacement = .all
            configuration.image = config.icon
            configuration.imageColorTransformer = UIConfigurationColorTransformer { _ in
                .p.accent
            }
            return configuration
        }()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: .p.iconSize, height: .p.iconSize)
    }
}
