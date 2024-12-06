import SwiftUI
import DesignSystem

extension View {
    public func preview(packageClass: AnyClass) -> some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                modifier(PreviewModifier(packageClass: packageClass))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

private struct PreviewModifier: ViewModifier {
    let packageClass: AnyClass
    
    func body(content: Content) -> some View {
        content
            .environment(ColorPalette.dark)
            .environment(PaddingsPalette.default)
            .environment(
                AvatarView.Repository(getBlock: { _ in .stubAvatar }, getIfCachedBlock: { _ in .stubAvatar })
            )
            .loadCustomFonts(class: packageClass)
    }
}
