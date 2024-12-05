import SwiftUI
import AppBase
import Domain
import AVKit
internal import DesignSystem

public struct SplashView: View {
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    @Binding private var transitionProgress: CGFloat
    @Binding private var destinationOffset: CGFloat?
    @Binding private var sourceOffset: CGFloat?

    init(transition: ModalTransition) {
        _transitionProgress = transition.progress
        _sourceOffset = transition.sourceOffset
        _destinationOffset = transition.destinationOffset
    }

    public var body: some View {
        GeometryReader { geometry in
            let top = CGSize(
                width: [
                    letterRelativeWidth,
                    letterRelativePadding,
                    letterRelativeWidth
                ].reduce(0, +),
                height: letterRelativeHeigth
            )
            let bottom = CGSize(
                width: [
                    letterRelativeWidth,
                    letterRelativePadding,
                    letterRelativeWidth
                ].reduce(0, +),
                height: [
                    letterRelativeHeigth,
                    letterRelativePadding,
                    letterRelativeHeigth
                ].reduce(0, +)
            )
            let all = CGSize(
                width: top.width,
                height: top.height + letterRelativePadding + bottom.height
            )
            let contentFrame = AVMakeRect(
                aspectRatio: all,
                insideRect: CGRect(
                    origin: .zero,
                    size: geometry.size
                )
            )
            let xScale = contentFrame.width / all.width
            let yScale = contentFrame.height / all.height
            Group {
                let topFrame = CGRect(
                    x: contentFrame.minX + top.width / 2 * xScale,
                    y: contentFrame.minY + top.height / 2 * yScale,
                    width: top.width * xScale,
                    height: top.height * yScale
                )
                let bottomFrame = CGRect(
                    x: topFrame.minX,
                    y: topFrame.maxY + top.height / 2 * yScale,
                    width: bottom.width * xScale,
                    height: bottom.height * yScale
                )
                Image.splashTop
                    .resizable()
                    .aspectRatio(topFrame.width / topFrame.height, contentMode: .fit)
                    .position(x: topFrame.minX, y: topFrame.minY)
                    .frame(width: topFrame.width, height: topFrame.height)
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
                    .aspectRatio(bottomFrame.width / bottomFrame.height, contentMode: .fit)
                    .position(x: bottomFrame.minX, y: bottomFrame.minY)
                    .frame(width: bottomFrame.width, height: bottomFrame.height)
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
    
    private var letterRelativeWidth: CGFloat {
        187
    }
    
    private var letterRelativeHeigth: CGFloat {
        245
    }
    
    private var letterRelativePadding: CGFloat {
        1
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

#Preview {
    SplashPreview()
        .preview(packageClass: DefaultSplashFactory.self)
}

#endif
