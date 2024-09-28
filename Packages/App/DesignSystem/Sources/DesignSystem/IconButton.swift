import Combine
import SwiftUI
internal import Base

private struct IconButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: .palette.iconSize, height: .palette.iconSize)
            .tint(.palette.accent)
    }
}

extension View {
    public func iconButtonStyle() -> some View {
        modifier(IconButtonStyle())
    }
}

#Preview {
    Button {} label: {
        Image.palette.cross
    }
    .iconButtonStyle()
}
