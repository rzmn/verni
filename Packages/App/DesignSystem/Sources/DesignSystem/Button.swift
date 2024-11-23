import UIKit
import SwiftUI

public struct Button: View {
    @Environment(ColorPalette.self) var palette
    
    public enum Style {
        case primary
        case secondary
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
            if let icon = config.icon {
                HStack(spacing: -10) {
                    switch icon {
                    case .left(let image):
                        self.icon(image: image)
                        button
                    case .right(let image):
                        button
                        self.icon(image: image)
                    }
                }
            } else {
                button
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }
    
    private func icon(image: Image) -> some View {
        backgroundColor
            .frame(width: height, height: height)
            .clipShape(.rect(cornerRadius: height / 2))
            .overlay {
                image.tint(iconColor)
            }
    }
    
    private var button: some View {
        backgroundColor
            .frame(height: height)
            .clipShape(.rect(cornerRadius: 16))
            .overlay {
                Text(config.text)
                    .font(.medium(size: 15))
                    .tint(textColor)
            }
    }
    
    private var height: CGFloat {
        54
    }
    
    private var backgroundColor: Color {
        switch config.style {
        case .primary:
            palette.background.primary.brand
        case .secondary:
            palette.background.secondary.default
        }
    }
    
    private var textColor: Color {
        switch config.style {
        case .primary:
            palette.text.primary.alternative
        case .secondary:
            palette.text.primary.default
        }
    }
    
    private var iconColor: Color {
        switch config.style {
        case .primary:
            palette.icon.primary.alternative
        case .secondary:
            palette.icon.primary.default
        }
    }
}
