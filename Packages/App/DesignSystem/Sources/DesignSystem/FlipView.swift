import SwiftUI

public struct FlipView<FrontView: View, BackView: View>: View {
    private let frontView: FrontView
    private let backView: BackView
    @Binding private var flipsCount: Int
    @State private var direction: CGFloat = 1
    
    public init(frontView: FrontView, backView: BackView, flipsCount: Binding<Int>) {
        self.frontView = frontView
        self.backView = backView
        _flipsCount = flipsCount
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                frontView
                    .modifier(FlipOpacity(animatableData: (flipsCount % 2 == 0) ? 1 : 0))
                    .rotation3DEffect(Angle.degrees(Double(flipsCount * 180)), axis: (0, direction, 0))
                backView
                    .modifier(FlipOpacity(animatableData: (flipsCount % 2 == 0) ? 0 : 1))
                    .rotation3DEffect(Angle.degrees(Double(flipsCount * 180 + 180)), axis: (0, direction, 0))
            }
            .onTapGesture(coordinateSpace: .local) { point in
                let width = geometry.size.width
                let delta = point.x > width / 2 ? +1 : -1
                HapticEngine.mediumImpact.perform()
                direction = CGFloat(delta)
                withAnimation {
                    flipsCount += delta
                }
            }
        }
    }
}

private struct FlipOpacity: AnimatableModifier {
    var animatableData: CGFloat
    
    func body(content: Content) -> some View {
        content
            .opacity(Double(animatableData.rounded()))
    }
}
