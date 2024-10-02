import UIKit
import SwiftUI

public struct Placeholder: View {
    public let message: String
    public let icon: Image

    public var body: some View {
        VStack {
            Text(message)
                .padding(.bottom, 22)
                .fontStyle(.textSecondary)
            icon
                .tint(.palette.accent)

        }
    }
}

#Preview {
    VStack {
        Placeholder(
            message: "placeholder",
            icon: .palette.cross
        )
    }
}
