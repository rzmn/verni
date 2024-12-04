import SwiftUI

public struct TabTransition {
    public let progress: Binding<CGFloat>
    
    public init(progress: Binding<CGFloat>) {
        self.progress = progress
    }
}

public struct ModalTransition {
    public let progress: Binding<CGFloat>
    public let sourceOffset: Binding<CGFloat?>
    public let destinationOffset: Binding<CGFloat?>
    
    public init(progress: Binding<CGFloat>, sourceOffset: Binding<CGFloat?>, destinationOffset: Binding<CGFloat?>) {
        self.progress = progress
        self.sourceOffset = sourceOffset
        self.destinationOffset = destinationOffset
    }
}
