import UIKit
import Combine
internal import Base

public class IconButton: UIButton {
    public struct Config {
        let icon: UIImage?

        public init(icon: UIImage?) {
            self.icon = icon
        }
    }
    public var tapPublisher: AnyPublisher<Void, Never> {
        tapSubject.eraseToAnyPublisher()
    }
    let tapSubject = PassthroughSubject<Void, Never>()

    public init(config: Config) {
        super.init(frame: .zero)
        addAction({ [unowned self] in
            tapSubject.send(())
        }, for: .touchUpInside)
        configuration = {
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = .zero
            configuration.imagePadding = 0
            configuration.imagePlacement = .all
            configuration.image = config.icon
            configuration.imageColorTransformer = UIConfigurationColorTransformer { _ in
                .palette.accent
            }
            return configuration
        }()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: .palette.iconSize, height: .palette.iconSize)
    }
}
