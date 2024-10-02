import SwiftUI

extension View {
    @ViewBuilder public func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder public func fMap<Content: View>(transform: (Self) -> Content) -> some View {
        transform(self)
    }
}
