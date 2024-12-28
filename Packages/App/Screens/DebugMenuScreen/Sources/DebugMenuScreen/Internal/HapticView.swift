import SwiftUI
internal import DesignSystem

struct HapticView: View {
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors

    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                DesignSystem.Button(
                    config: DesignSystem.Button.Config(style: .secondary, text: "success"),
                    action: HapticEngine.success.perform
                )
                DesignSystem.Button(
                    config: DesignSystem.Button.Config(style: .secondary, text: "warning"),
                    action: HapticEngine.warning.perform
                )
                DesignSystem.Button(
                    config: DesignSystem.Button.Config(style: .secondary, text: "error"),
                    action: HapticEngine.error.perform
                )
                DesignSystem.Button(
                    config: DesignSystem.Button.Config(style: .secondary, text: "impact light"),
                    action: HapticEngine.lightImpact.perform
                )
                DesignSystem.Button(
                    config: DesignSystem.Button.Config(style: .secondary, text: "impact medium"),
                    action: HapticEngine.mediumImpact.perform
                )
                DesignSystem.Button(
                    config: DesignSystem.Button.Config(style: .secondary, text: "impact heavy"),
                    action: HapticEngine.heavyImpact.perform
                )
                DesignSystem.Button(
                    config: DesignSystem.Button.Config(style: .secondary, text: "selection changed"),
                    action: HapticEngine.selectionChanged.perform
                )
                Spacer()
            }
            Spacer()
        }
        .background(colors.background.secondary.alternative)
    }
}

#Preview {
    HapticView()
        .preview(packageClass: DebugMenuModel.self)
}
