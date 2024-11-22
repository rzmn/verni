import SwiftUI

public enum TextContentType: Hashable {
    case button
    case text
}

extension Font {
    static let mediumTextFontName = "JetBrainsMono-Medium"
    static let regularTextFontName = "JetBrainsMono-Regular"
    
    public static func regular(size: CGFloat) -> Font {
        Font.custom(regularTextFontName, size: size)
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

private struct TextItem: Hashable, Identifiable {
    let contentType: TextContentType
    let name: String

    var id: String { name }
}

#Preview {
    VStack {
        ForEach([
            TextItem(contentType: .button, name: "button"),
            TextItem(contentType: .text, name: "text"),
        ]) { item in
            Text(item.name)
                .fontStyle(item.contentType)
                .padding(.palette.defaultHorizontal)
        }
    }
    .loadCustomFonts()
}
