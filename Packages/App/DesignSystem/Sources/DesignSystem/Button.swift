import UIKit
import SwiftUI

public struct Button: View {
    @Environment(ColorPalette.self) var palette
    
    public enum Style {
        case primary
        case secondary
        case tertiary
    }
    
    public enum Icon {
        case left(Image)
        case right(Image)
    }
    
    public struct Config {
        public let style: Style
        public let text: LocalizedStringKey
        public let icon: Icon?
        
        public init(style: Style, text: LocalizedStringKey, icon: Icon?) {
            self.style = style
            self.text = text
            self.icon = icon
        }
    }
    
    private let config: Config
    private let action: () -> Void
    
    public init(config: Config, action: @escaping () -> Void) {
        self.config = config
        self.action = action
    }
    
    public var body: some View {
        SwiftUI.Button(action: action) {
            buttonWithIcon
                .background(backgroundShape)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }
    
    @ViewBuilder private var buttonWithIcon: some View {
        if let icon = config.icon {
            HStack(spacing: -overlap) {
                switch icon {
                case .left(let image):
                    image.tint(iconColor)
                        .frame(width: height, height: height)
                    button
                case .right(let image):
                    button
                    image.tint(iconColor)
                        .frame(width: height, height: height)
                }
            }
        } else {
            button
        }
        
    }
    
    @ViewBuilder private var backgroundShape: some View {
        if let icon = config.icon {
            let rectInset: UIEdgeInsets = {
                switch icon {
                case .left:
                    UIEdgeInsets(top: 0, left: height - overlap, bottom: 0, right: 0)
                case .right:
                    UIEdgeInsets(top: 0, left: 0, bottom: 0, right: height - overlap)
                }
            }()
            let sign: CGFloat = {
                switch icon {
                case .left:
                    return -1
                case .right:
                    return +1
                }
            }()
            GeometryReader { proxy in
                Circle()
                    .offset(x: (proxy.size.width - height) * sign / 2)
                    .union(
                        Path { path in
                            path.addRoundedRect(
                                in: CGRect(origin: .zero, size: proxy.size).inset(by: rectInset),
                                cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
                            )
                        }
                    )
                    .foregroundStyle(backgroundColor)
            }
        } else {
            backgroundColor.clipShape(.rect(cornerRadius: cornerRadius))
        }
    }
    
    private var button: some View {
        HStack {
            Spacer()
            Text(config.text)
                .font(.medium(size: 15))
                .tint(textColor)
            Spacer()
        }
        .frame(height: height)
    }
    
    private var height: CGFloat {
        54
    }
    
    private var overlap: CGFloat {
        10
    }
    
    private var cornerRadius: CGFloat {
        16
    }
    
    private var backgroundColor: Color {
        switch config.style {
        case .primary:
            palette.background.primary.brand
        case .secondary:
            palette.background.secondary.default
        case .tertiary:
            .clear
        }
    }
    
    private var textColor: Color {
        switch config.style {
        case .primary:
            palette.text.primary.alternative
        case .secondary:
            palette.text.primary.default
        case .tertiary:
            palette.text.primary.default
        }
    }
    
    private var iconColor: Color {
        switch config.style {
        case .primary:
            palette.icon.primary.alternative
        case .secondary:
            palette.icon.primary.default
        case .tertiary:
            palette.icon.primary.default
        }
    }
}

#Preview {
    Button(
        config: Button.Config(
            style: .primary,
            text: .logIn,
            icon: .right(.arrowRight)
        ), action: {}
    )
    .environment(ColorPalette.light)
    .environment(PaddingsPalette.default)
}
