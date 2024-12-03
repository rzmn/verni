import SwiftUI

public protocol Transition {
    var progress: Binding<CGFloat> { get }
}

public struct TwoSideTransition<From: Transition, To: Transition> {
    public let from: From
    public let to: To
    
    public init(from: From, to: To) {
        self.from = from
        self.to = to
    }
}

public struct BottomSheetTransition: Transition {
    public let progress: Binding<CGFloat>
    public let sourceOffset: Binding<CGFloat?>
    public let destinationOffset: Binding<CGFloat?>
    
    public init(progress: Binding<CGFloat>, sourceOffset: Binding<CGFloat?>, destinationOffset: Binding<CGFloat?>) {
        self.progress = progress
        self.sourceOffset = sourceOffset
        self.destinationOffset = destinationOffset
    }
}
