import SwiftUI

private struct AlertBottomSheet<Content: View>: View {
    struct Config {
        let image: Image?
        let title: LocalizedStringKey
        let subtitle: LocalizedStringKey
    }
    @Environment(ColorPalette.self) var colors
    private let config: Config
    private let onClose: (() -> Void)?
    private let actions: () -> Content

    init(config: Config, onClose: (() -> Void)?, @ViewBuilder actions: @escaping () -> Content) {
        self.config = config
        self.actions = actions
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            if let onClose {
                HStack {
                    Spacer()
                    IconButton(
                        config: IconButton.Config(
                            style: .secondary,
                            icon: .close
                        ),
                        action: onClose
                    )
                    .padding([.trailing, .top], 8)
                }
            } else {
                Spacer()
                    .frame(height: 24)
            }
            if let image = config.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(colors.icon.primary.default)
                    .padding(.top, 4)
                    .padding(.horizontal, 16)
            }
            Text(config.title)
                .font(.bold(size: 20))
                .foregroundStyle(colors.text.primary.default)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
            Text(config.subtitle)
                .font(.medium(size: 15))
                .foregroundStyle(colors.text.secondary.default)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            actions()
        }
        .background(colors.background.primary.default)
        .clipShape(.rect(cornerRadius: 24))
        .padding([.leading, .trailing, .bottom], 8)
    }
}

public enum AlertBottomSheetPreset: Sendable, Equatable {
    case noConnection(onRetry: @MainActor @Sendable () -> Void, onClose: @MainActor @Sendable () -> Void)
    case service(String, onClose: @MainActor @Sendable () -> Void)
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.kind == rhs.kind
    }
    
    private var kind: String {
        switch self {
        case .noConnection:
            "noConnection"
        case .service(let description, _):
            "service_\(description)"
        }
    }
    
    @MainActor @ViewBuilder func view(colors: ColorPalette) -> some View {
        switch self {
        case .noConnection(let onRetry, let onClose):
            AlertBottomSheet(
                config: AlertBottomSheet.Config(
                    image: .noConnection,
                    title: .sheetNoConnectionTitle,
                    subtitle: .sheetNoConnectionSubtitle
                ),
                onClose: onClose
            ) {
                Button(
                    config: Button.Config(
                        style: .primary,
                        text: .sheetActionTryAgain,
                        icon: .right(.refresh)
                    ),
                    action: onRetry
                )
                .padding([.leading, .trailing, .bottom], 16)
                .padding(.top, 18)
            }
        case .service(let description, let onClose):
            AlertBottomSheet(
                config: AlertBottomSheet.Config(
                    image: nil,
                    title: .sheetInternalErrorTitle,
                    subtitle: .serviceMessageWarning
                ),
                onClose: nil
            ) {
                Text(description)
                    .foregroundStyle(colors.text.negative.default)
                    .font(.medium(size: 12))
                    .padding(.top, 12)
                Button(
                    config: Button.Config(
                        style: .secondary,
                        text: .sheetClose
                    ),
                    action: onClose
                )
                .padding([.leading, .trailing, .bottom], 16)
                .padding(.top, 18)
            }
        }
    }
}

// MARK: - View Modifier

private struct AlertBottomSheetModifier: ViewModifier {
    @Binding var preset: AlertBottomSheetPreset?
    @Environment(ColorPalette.self) var colors

    init(preset: Binding<AlertBottomSheetPreset?>) {
        _preset = preset
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                if preset != nil {
                    Color.black
                        .opacity(0.36)
                        .transition(.opacity)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                preset = nil
                            }
                        }
                }
            }
            .overlay {
                VStack {
                    Spacer()
                    if let preset {
                        preset.view(colors: colors)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
    }
}

extension View {
    @ViewBuilder public func bottomSheet(
        preset: Binding<AlertBottomSheetPreset?>
    ) -> some View {
        modifier(AlertBottomSheetModifier(preset: preset))
    }
}

#Preview {
    Color.gray
        .ignoresSafeArea()
        .bottomSheet(preset: .constant(.noConnection(onRetry: {}, onClose: {})))
        .environment(ColorPalette.light)
        .loadCustomFonts()
}
