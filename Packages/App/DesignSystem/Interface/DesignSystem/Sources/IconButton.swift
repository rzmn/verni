import UIKit
import SwiftUI

public struct IconButton: View {
    @Environment(ColorPalette.self) var palette

    public enum Style {
        case primary
        case secondary
    }

    public struct Config {
        public let style: Style
        public let icon: Image

        public init(style: Style, icon: Image) {
            self.style = style
            self.icon = icon
        }
    }

    private let config: Config
    private let action: () -> Void

    public init(config: Config, action: @escaping () -> Void) {
        self.config = config
        self.action = {
            HapticEngine.mediumImpact.perform()
            action()
        }
    }

    public var body: some View {
        SwiftUI.Button(action: action) {
            backgroundColor
                .frame(width: side, height: side)
                .clipShape(.rect(cornerRadius: side / 2))
                .overlay {
                    config.icon.tint(iconColor)
                }
        }
        .frame(width: side, height: side)
    }

    private var side: CGFloat {
        54
    }

    private var backgroundColor: Color {
        switch config.style {
        case .primary:
            palette.background.primary.default
        case .secondary:
            palette.background.secondary.default
        }
    }

    private var iconColor: Color {
        switch config.style {
        case .primary:
            palette.icon.primary.default
        case .secondary:
            palette.icon.primary.default
        }
    }
}

private struct ConfigForPreview: Identifiable {
    let config: IconButton.Config

    var id: String {
        "\(config)"
    }
}

#Preview {
    HStack {
        Spacer()
        VStack {
            Spacer()

            let icon = Image(systemName: "heart.fill")
            let configs = [.primary, .secondary]
                .map { (style: IconButton.Style) -> IconButton.Config in
                    IconButton.Config(style: style, icon: icon)
                }
                .map(ConfigForPreview.init)

            ForEach(configs) { identifiableWrapper in
                IconButton(config: identifiableWrapper.config, action: {})
            }
            Spacer()
        }
        Spacer()
    }
    .environment(ColorPalette.light)
    .loadCustomFonts()
    .ignoresSafeArea()
}
