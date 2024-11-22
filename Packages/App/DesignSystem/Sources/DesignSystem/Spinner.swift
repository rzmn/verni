import SwiftUI

public struct Spinner: View {
    @State var show: Bool
    @State private var isRotating = 0.0

    public var body: some View {
        if show {
            Group {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(ColorPalette.dark.icon.primary.default, lineWidth: 4)
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(isRotating))
                    .onAppear {
                        withAnimation(
                            .linear(duration: 1)
                            .repeatForever(autoreverses: false)
                        ) {
                            isRotating = 360
                        }
                    }
            }
            .padding(.all, .palette.defaultHorizontal)
            .background(ColorPalette.dark.background.primary.brand)
            .clipShape(.rect(cornerRadius: 10))
        }
    }
}

extension Spinner {
    struct Modifier: ViewModifier {
        private let show: Bool
        @State private var appeared = false

        init(show: Bool) {
            self.show = show
        }

        func body(content: Content) -> some View {
            ZStack {
                content
                if show && appeared {
                    ColorPalette.dark.background.primary.brand
                        .transition(.opacity)
                    Spinner(show: show)
                }
            }.onAppear {
                withAnimation {
                    appeared = true
                }
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
    ColorPalette.dark.background.primary.brand
        .spinner(show: true)
        .ignoresSafeArea()
}
