import SwiftUI

public struct Spinner: View {
    let show: Bool

    public var body: some View {
        if show {
            Group {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.palette.accent, lineWidth: 4)
                    .frame(width: 44, height: 44)
                    .rotationEffect(Angle(degrees: show ? 360 : 0))
                    .animation(.linear.repeatForever(), value: show)
            }
            .padding(.all, .palette.defaultHorizontal)
            .background(Color.palette.backgroundContent)
            .clipShape(.rect(cornerRadius: 10))
        }
    }
}

extension Spinner {
    struct Modifier: ViewModifier {
        private let show: Bool

        init(show: Bool) {
            self.show = show
        }

        func body(content: Content) -> some View {
            ZStack {
                content
                Spinner(show: show)
            }
        }
    }
}

extension View {
    public func spinner(show: Bool) -> some View {
        modifier(Spinner.Modifier(show: show))
    }
}

#Preview {
    Spinner(show: true)
}
