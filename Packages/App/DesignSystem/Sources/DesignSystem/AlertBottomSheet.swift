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
    case blocker(title: String, subtitle: String, actionTitle: String, action: @MainActor @Sendable () -> Void)
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.kind == rhs.kind
    }
    
    private var kind: String {
        switch self {
        case .noConnection:
            "noConnection"
        case .service(let description, _):
            "service_\(description)"
        case .blocker(let title, _, _, _):
            "blocker_\(title)"
        }
    }
    
    var canClose: Bool {
        switch self {
        case .noConnection, .service:
            true
        case .blocker:
            false
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
        case .blocker(let title, let subtitle, let actionTitle, let action):
            AlertBottomSheet(
                config: AlertBottomSheet.Config(
                    image: nil,
                    title: LocalizedStringKey(title),
                    subtitle: LocalizedStringKey(subtitle)
                ),
                onClose: nil
            ) {
                Button(
                    config: Button.Config(
                        style: .secondary,
                        text: LocalizedStringKey(actionTitle)
                    ),
                    action: action
                )
                .padding([.leading, .trailing, .bottom], 16)
                .padding(.top, 18)
            }
        }
    }
}

// MARK: - View Modifier

private struct AlertBottomSheetModifier: ViewModifier {
    @Binding private var preset: AlertBottomSheetPreset?
    @State private var presentToBeKeptOnDismissalTransition: AlertBottomSheetPreset?
    @State private var appeared: Bool = false
    @State private var shown: Bool = false
    @State private var offset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @State private var dragOffsetTranslationTrust: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @Environment(ColorPalette.self) var colors

    init(preset: Binding<AlertBottomSheetPreset?>) {
        _preset = preset
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                if shown {
                    Color.black
                        .opacity(0.36)
                        .transition(.opacity)
                        .ignoresSafeArea()
                        .onTapGesture {
                            if let preset, preset.canClose {
                                appeared = false
                            }
                        }
                }
            }
            .overlay {
                GeometryReader { geometry in
                    VStack {
                        if let preset {
                            self.content(geometry: geometry, preset: preset)
                        } else if let preset = presentToBeKeptOnDismissalTransition {
                            self.content(geometry: geometry, preset: preset)
                                .onAppear {
                                    appeared = false
                                }
                        }
                        Spacer()
                    }
                    .onChange(of: contentHeight) { _, _ in
                        performTransitionAnimationWhenNeeded()
                    }
                    .onChange(of: appeared) { _, _ in
                        performTransitionAnimationWhenNeeded()
                    }
                    .ignoresSafeArea()
                }
            }
    }
    
    @ViewBuilder private func content(geometry: GeometryProxy, preset: AlertBottomSheetPreset) -> some View {
        let overallHeight = [
            geometry.safeAreaInsets.bottom,
            geometry.size.height,
            geometry.safeAreaInsets.top,
            offset,
            dragOffset
        ].reduce(0, +)
        preset.view(colors: colors)
            .overlay {
                GeometryReader { contentGeometry in
                    HStack {}
                        .onAppear {
                            presentToBeKeptOnDismissalTransition = preset
                            contentHeight = contentGeometry.size.height + geometry.safeAreaInsets.bottom
                        }
                }
            }
            .offset(y: overallHeight)
            .gesture(dragGesture)
            .onAppear {
                appeared = true
            }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                dragOffsetTranslationTrust = min(1, dragOffsetTranslationTrust + 0.1)
                let dy = gesture.translation.height * dragOffsetTranslationTrust
                if dy > 0 {
                    dragOffset = dy
                } else {
                    dragOffset = -sqrt(abs(dy))
                }
            }
            .onEnded { _ in
                if dragOffset > 100 {
                    appeared = false
                } else {
                    withAnimation(animation) {
                        dragOffset = 0
                        dragOffsetTranslationTrust = 0
                    }
                }
            }
    }
    
    private func performTransitionAnimationWhenNeeded() {
        if shown {
            if !appeared && contentHeight != 0 {
                performDismissTransition()
            }
        } else {
            if appeared && contentHeight != 0 {
                performAppearTransition()
            }
        }
    }
    
    private func performAppearTransition() {
        withAnimation(animation) {
            shown = true
            offset = -contentHeight
        }
    }
    
    private func performDismissTransition() {
        withAnimation(animation) {
            shown = false
            offset = 0
        } completion: {
            preset = nil
            presentToBeKeptOnDismissalTransition = nil
            dragOffset = 0
            dragOffsetTranslationTrust = 0
        }
    }
    
    private var animation: Animation {
        .snappy.speed(1.5)
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
        .bottomSheet(preset: .constant(.blocker(title: "title", subtitle: "subtitle", actionTitle: "action", action: {})))
        .environment(ColorPalette.light)
        .loadCustomFonts()
}
