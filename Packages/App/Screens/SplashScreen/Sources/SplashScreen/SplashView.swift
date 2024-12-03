import SwiftUI
import AppBase
import Domain
internal import DesignSystem

public struct SplashView: View {
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    @Binding private var transitionProgress: CGFloat
    @Binding private var destinationOffset: CGFloat?
    @Binding private var sourceOffset: CGFloat?

    init(transition: BottomSheetTransition) {
        _transitionProgress = transition.progress
        _sourceOffset = transition.sourceOffset
        _destinationOffset = transition.destinationOffset
    }

    public var body: some View {
        VStack(spacing: -1) {
            Image.splashTop
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 2)
                .foregroundStyle(colors.background.primary.default)
                .overlay {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                sourceOffset = geometry.size.height
                            }
                    }
                }
                .modifier(TranslateEffect(offset: -transitionOffset))
            Image.splashBottom
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(colors.background.primary.default)
                .modifier(TranslateEffect(offset: transitionOffset * 2))
        }
        .aspectRatio(402.0 / 778.0, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.all, -2)
        .background(
            colors.background.primary.default
                .opacity(transitionProgress)
        )
        .background(colors.background.brand.static)
    }
    
    private var transitionOffset: CGFloat {
        guard let sourceOffset else {
            return 0
        }
        return sourceOffset * transitionProgress
    }
}

#if DEBUG

private struct SplashPreview: View {
    @State var transition: CGFloat = 0
    @State var sourceOffset: CGFloat?
    
    var body: some View {
        ZStack {
            SplashView(
                transition: BottomSheetTransition(
                    progress: $transition,
                    sourceOffset: $sourceOffset,
                    destinationOffset: .constant(0)
                )
            )
            VStack {
                Text("sourceOffset: \(sourceOffset ?? -1)")
                    .foregroundStyle(.red)
                Slider(value: $transition, in: 0...1)
            }
        }
    }
}

#Preview {
    SplashPreview()
        .preview(packageClass: DefaultSplashFactory.self)
}

#endif
