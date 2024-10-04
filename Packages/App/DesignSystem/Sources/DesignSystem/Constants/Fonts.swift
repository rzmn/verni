import SwiftUI

public enum TextContentType: Hashable {
    case title1
    case button
    case text
    case textSecondary
}

private extension Font {
    static func text(size: CGFloat) -> Font {
        Font(UIFont(name: "SF Pro", size: size) ?? .systemFont(ofSize: size))
    }

    static func display(size: CGFloat) -> Font {
        Font(UIFont(name: "SF Pro Display Semibold", size: size) ?? .systemFont(ofSize: size, weight: .bold))
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
        case .title1:
            .display(size: 27)
        case .button:
            .display(size: 17)
        case .text:
            .text(size: 16)
        case .textSecondary:
            .text(size: 13)
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
            TextItem(contentType: .title1, name: "title1"),
            TextItem(contentType: .button, name: "button"),
            TextItem(contentType: .text, name: "text"),
            TextItem(contentType: .textSecondary, name: "text secondary")
        ]) { item in
            Text(item.name)
                .fontStyle(item.contentType)
                .padding(.palette.defaultHorizontal)
        }
    }
}
