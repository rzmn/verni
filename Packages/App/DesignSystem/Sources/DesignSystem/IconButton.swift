import UIKit
import Combine
import SwiftUI
internal import Base

extension DS {
    public struct IconButton: View {
        let icon: UIImage
        let action: () -> Void

        public init(icon: UIImage, action: @escaping () -> Void) {
            self.icon = icon
            self.action = action
        }

        public var body: some View {
            SwiftUI.Button(action: action) {
                Image(uiImage: icon)
                    .frame(width: .palette.iconSize, height: .palette.iconSize)
                    .tint(Color(uiColor: .palette.accent))
            }
        }
    }
}

#Preview {
    VStack {
        DS.IconButton(
            icon: UIImage(systemName: "dollarsign")!
        ) {}
    }
}

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
