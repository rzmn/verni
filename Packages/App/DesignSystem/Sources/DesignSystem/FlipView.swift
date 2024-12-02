import SwiftUI

public struct FlipView<FrontView: View, BackView: View>: View {
    private let frontView: FrontView
    private let backView: BackView
    @Binding private var flipsCount: CGFloat
    @State private var direction: CGFloat = 1
    
    public init(frontView: FrontView, backView: BackView, flipsCount: Binding<CGFloat>) {
        self.frontView = frontView
        self.backView = backView
        _flipsCount = flipsCount
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                frontView
                    .modifier(FlipOpacity(isBack: false, direction: direction, animatableData: flipsCount))
                backView
                    .modifier(FlipOpacity(isBack: true, direction: direction, animatableData: flipsCount))
            }
            .onTapGesture(coordinateSpace: .local) { point in
                let width = geometry.size.width
                let delta = CGFloat(point.x > width / 2 ? +1 : -1)
                HapticEngine.mediumImpact.perform()
                direction = delta
                withAnimation {
                    flipsCount += delta
                }
            }
        }
    }
}

private struct FlipOpacity: AnimatableModifier {
    var animatableData: CGFloat
    
    private let isBack: Bool
    private let direction: CGFloat
    
    init(isBack: Bool, direction: CGFloat, animatableData: CGFloat) {
        self.animatableData = animatableData
        self.isBack = isBack
        self.direction = direction
    }
    
    private var frontOpacity: CGFloat {
        1 - backOpacity
    }
    
    private var backOpacity: CGFloat {
        let positive: (CGFloat) -> CGFloat = {
            var val = $0 / 2
            val = val - floor(val)
            val = min(val, 1 - val)
            return val * 2
        }
        return positive(abs(animatableData))
    }
    
    private var opacity: CGFloat {
        isBack ? backOpacity : frontOpacity
    }
    
    private var scaleFactor: CGFloat {
        max(backOpacity, frontOpacity)
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .opacity(Double(opacity.rounded()))
                .transformEffect(
                    CGAffineTransform(translationX: -geometry.size.width / 2, y: -geometry.size.height / 2)
                        .concatenating(.init(scaleX: scaleFactor, y: scaleFactor))
                        .concatenating(CGAffineTransform(translationX: geometry.size.width / 2, y: geometry.size.height / 2))
                )
                .rotation3DEffect(
                    Angle.degrees(
                        Double(animatableData * 180 + (isBack ? 180 : 0))
                    ),
                    axis: (0, direction, 0)
                )
        }
    }
}

#if DEBUG

private struct FlipPreview: View {
    @State private var flipsCount: CGFloat = 0
    
    var body: some View {
        Text("v: \(flipsCount)")
        Slider(value: $flipsCount, in: -2...2)
        
        FlipView(
            frontView: Color.green
                .clipShape(.rect(cornerRadius: 22)),
            backView: Color.red
                .clipShape(.rect(cornerRadius: 22)),
            flipsCount: $flipsCount
        )
        .aspectRatio(3.0 / 2.0, contentMode: .fit)
    }
}

#Preview {
    FlipPreview()
}

#endif
