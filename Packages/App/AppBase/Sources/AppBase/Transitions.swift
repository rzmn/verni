import SwiftUI

public protocol Transition {
    var progress: Binding<CGFloat> { get }
}

public struct BottomSheetTransition {
    public let progress: Binding<CGFloat>
    public let sourceOffset: Binding<CGFloat?>
    public let destinationOffset: Binding<CGFloat?>
    
    public init(progress: Binding<CGFloat>, sourceOffset: Binding<CGFloat?>, destinationOffset: Binding<CGFloat?>) {
        self.progress = progress
        self.sourceOffset = sourceOffset
        self.destinationOffset = destinationOffset
    }
}
