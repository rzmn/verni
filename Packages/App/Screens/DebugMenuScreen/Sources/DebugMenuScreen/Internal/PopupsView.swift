import SwiftUI
internal import DesignSystem

struct PopupsView: View {
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    
    @State private var bottomSheet: AlertBottomSheetPreset?
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                DesignSystem.Button(
                    config: DesignSystem.Button.Config(style: .secondary, text: .sheetNoConnectionTitle),
                    action: {
                        if bottomSheet != nil {
                            bottomSheet = nil
                        } else {
                            bottomSheet = .noConnection(onRetry: {
                                bottomSheet = nil
                            }, onClose: {
                                bottomSheet = nil
                            })
                        }
                    }
                )
                Spacer()
            }
            Spacer()
        }
        .background(colors.background.secondary.alternative)
        .bottomSheet(preset: $bottomSheet)
    }
}
