import SwiftUI

public enum TextContentType: Hashable {
    case button
    case text
}

extension Font {
    static let mediumTextFontName = "JetBrainsMonoNL-Medium"
    static let boldTextFontName = "JetBrainsMonoNL-Bold"
    
    public static func bold(size: CGFloat) -> Font {
        Font.custom(boldTextFontName, size: size)
    }
    
    public static func medium(size: CGFloat) -> Font {
        Font.custom(mediumTextFontName, size: size)
    }
}

private struct TextContentModifier: ViewModifier {
    let contentType: TextContentType

    func body(content: Content) -> some View {
        content
            .font(font)
    }

    private var font: Font {
        switch contentType {
        case .button:
            .medium(size: 15)
        case .text:
            .medium(size: 15)
        }
    }
}

extension View {
    public func fontStyle(_ content: TextContentType) -> some View {
        modifier(TextContentModifier(contentType: content))
    }
}
