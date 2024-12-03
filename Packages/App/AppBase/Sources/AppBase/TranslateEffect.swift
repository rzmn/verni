import SwiftUI

public struct TranslateEffect: GeometryEffect {
    var offset: CGFloat

    public var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    public init(offset: CGFloat) {
        self.offset = offset
    }

    public func effectValue(size: CGSize) -> ProjectionTransform {
        return ProjectionTransform(CGAffineTransform(translationX: 0, y: offset))
    }
}
