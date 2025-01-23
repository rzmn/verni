import SwiftUI
import AppBase
import AVKit
internal import DesignSystem

public struct SplashView: View {
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    @Binding private var transitionProgress: CGFloat
    @Binding private var destinationOffset: CGFloat?
    @Binding private var sourceOffset: CGFloat?

    public init(transition: ModalTransition) {
        _transitionProgress = transition.progress
        _sourceOffset = transition.sourceOffset
        _destinationOffset = transition.destinationOffset
    }

    public var body: some View {
        GeometryReader { geometry in
            Group {
                let geometry = Geometry(viewport: geometry.size)
                Image.splashTop
                    .resizable()
                    .aspectRatio(geometry.topFrame.width / geometry.topFrame.height, contentMode: .fit)
                    .position(x: geometry.topFrame.minX, y: geometry.topFrame.minY)
                    .frame(width: geometry.topFrame.width, height: geometry.topFrame.height)
                    .foregroundStyle(colors.background.primary.default)
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    sourceOffset = geometry.size.height
                                }
                        }
                    }
                    .modifier(VerticalTranslateEffect(offset: -transitionOffset))
                Image.splashBottom
                    .resizable()
                    .aspectRatio(geometry.bottomFrame.width / geometry.bottomFrame.height, contentMode: .fit)
                    .position(x: geometry.bottomFrame.minX, y: geometry.bottomFrame.minY)
                    .frame(width: geometry.bottomFrame.width, height: geometry.bottomFrame.height)
                    .foregroundStyle(colors.background.primary.default)
                    .modifier(VerticalTranslateEffect(offset: transitionOffset * 2))
            }
        }
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
                transition: ModalTransition(
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

class ClassToIdentifyBundle {}

#Preview {
    SplashPreview()
        .preview(packageClass: ClassToIdentifyBundle.self)
}

#endif
