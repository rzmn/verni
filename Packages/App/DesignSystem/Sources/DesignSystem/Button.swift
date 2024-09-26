import UIKit
import Combine
import SwiftUI

public enum DS {
    public struct Button: View {
        public enum Style {
            case primary
            case secondary
            case destructive
        }

        public let style: Style
        public let title: String
        public let enabled: Bool
        public let action: () -> Void

        public init(
            style: Style,
            title: String,
            enabled: Bool,
            action: @escaping () -> Void
        ) {
            self.style = style
            self.title = title
            self.enabled = enabled
            self.action = action
        }

        public var body: some View {
            SwiftUI.Button(action: action) {
                Text(title)
                    .font(font)
                    .frame(height: .palette.buttonHeight)
                    .padding(.horizontal, .palette.defaultHorizontal)
            }
            .tint(tintColor)
            .background(backgroundColor)
            .clipShape(.rect(cornerRadius: 10))
        }

        private var tintColor: Color {
            let base: UIColor
            switch style {
            case .primary:
                base = .palette.primary
            case .secondary:
                base = .palette.iconSecondary
            case .destructive:
                base = .palette.destructive
            }
            return Color(uiColor: base)
        }

        private var backgroundColor: Color {
            let base: UIColor
            switch style {
            case .primary:
                base = .palette.backgroundContent
            case .secondary:
                base = .clear
            case .destructive:
                base = .palette.destructiveBackground
            }
            return Color(uiColor: base)
        }

        private var font: Font {
            let base: UIFont
            switch style {
            case .primary, .secondary, .destructive:
                base = .palette.title2
            }
            return Font(base)
        }
    }
}

#Preview {
    VStack {
        DS.Button(
            style: .primary,
            title: "Primary",
            enabled: true
        ) {}
        DS.Button(
            style: .secondary,
            title: "Secondary",
            enabled: true
        ) {}
        DS.Button(
            style: .destructive,
            title: "Destructive",
            enabled: true
        ) {}
    }
}

public class Button: UIButton {
    public struct Config {
        public enum Style {
            case primary
            case secondary
            case destructive
        }
        public let style: Style
        public let title: String
        public let enabled: Bool

        public init(style: Style, title: String, enabled: Bool = true) {
            self.style = style
            self.title = title
            self.enabled = enabled
        }
    }
    public var tapPublisher: AnyPublisher<Void, Never> {
        tapSubject.eraseToAnyPublisher()
    }
    let tapSubject = PassthroughSubject<Void, Never>()

    public init(config: Config) {
        super.init(frame: .zero)
        titleLabel?.font = .palette.title2
        titleLabel?.numberOfLines = 0
        layer.masksToBounds = true
        layer.cornerRadius = 10
        addAction({ [unowned self] in
            tapSubject.send(())
        }, for: .touchUpInside)
        render(config: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func render(config: Config) {
        setTitle(config.title, for: .normal)
        switch config.style {
        case .primary:
            setTitleColor(.palette.primary, for: .normal)
            setTitleColor(.palette.primary.withAlphaComponent(0.34), for: .highlighted)
            backgroundColor = .palette.backgroundContent
        case .secondary:
            setTitleColor(.secondaryLabel, for: .normal)
            setTitleColor(.secondaryLabel.withAlphaComponent(0.34), for: .highlighted)
            backgroundColor = .clear
        case .destructive:
            setTitleColor(.palette.destructive, for: .normal)
            setTitleColor(.palette.destructive.withAlphaComponent(0.34), for: .highlighted)
            backgroundColor = .palette.destructiveBackground
        }
        alpha = config.enabled ? 1 : 0.64
        setNeedsLayout()
    }
}
