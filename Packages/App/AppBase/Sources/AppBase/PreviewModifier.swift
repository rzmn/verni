import SwiftUI
import DesignSystem

extension View {
    public func preview(packageClass: AnyClass) -> some View {
        modifier(PreviewModifier(packageClass: packageClass))
    }
}

private struct PreviewModifier: ViewModifier {
    let packageClass: AnyClass
    
    func body(content: Content) -> some View {
        content
            .environment(ColorPalette.dark)
            .environment(PaddingsPalette.default)
            .loadCustomFonts(class: packageClass)
    }
}
