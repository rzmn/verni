import SwiftUI

private struct Shake: GeometryEffect {
    var animatableData: CGFloat
    var amount: CGFloat
    var shakesPerUnit: Int

    init(amount: CGFloat = 10, shakesPerUnit: Int = 3, animatableData: CGFloat) {
        self.amount = amount
        self.shakesPerUnit = shakesPerUnit
        self.animatableData = animatableData
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

private struct ShakingModifier: ViewModifier {
    @Binding var shakeCounter: Int

    func body(content: Content) -> some View {
        content
            .modifier(Shake(animatableData: CGFloat(shakeCounter)))
    }
}

extension View {
    public func shake(counter: Binding<Int>) -> some View {
        modifier(ShakingModifier(shakeCounter: counter))
    }
}
