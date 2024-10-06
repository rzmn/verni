import SwiftUI

public struct Snackbar: View {
    enum Style {
        case warning
    }
    private let style: Style
    private let icon: String?
    private let message: String

    init(
        style: Style,
        icon: String?,
        message: String
    ) {
        self.style = style
        self.icon = icon
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                if let name = icon {
                    Image(systemName: name)
                        .resizable()
                        .foregroundColor(self.iconColor)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                }
                Text(message)
                    .fontStyle(.text)
                    .foregroundColor(textColor)
                    .font(.system(size: 14))
                    .frame(alignment: .leading)
                Spacer()
            }
            .frame(height: 48)
        }
        .padding(.horizontal, 16)
        .background(backgroundColor)
        .clipShape(.rect(cornerRadius: 10))
        .padding(.horizontal, 16)
    }

    private var backgroundColor: Color {
        switch style {
        case .warning:
            .palette.backgroundContent
        }
    }
    private var textColor: Color {
        switch style {
        case .warning:
            .palette.primary
        }
    }
    private var iconColor: Color {
        switch style {
        case .warning:
            .palette.primary
        }
    }
}

// MARK: - Presets

extension Snackbar {
    public enum Preset: Sendable, Equatable {
        case emailAlreadyTaken
        case noConnection
        case incorrectCredentials
        case notAuthorized
        case internalError(String)

        var kind: String {
            switch self {
            case .emailAlreadyTaken:
                return "emailAlreadyTaken"
            case .noConnection:
                return "noConnection"
            case .internalError:
                return "internalError"
            case .incorrectCredentials:
                return "incorrectCredentials"
            case .notAuthorized:
                return "notAuthorized"
            }
        }
    }

    init(preset: Preset) {
        switch preset {
        case .emailAlreadyTaken:
            self = .emailAlreadyTaken()
        case .noConnection:
            self = .noConnection()
        case .incorrectCredentials:
            self = .incorrectCredentials()
        case .notAuthorized:
            self = .notAuthorized()
        case .internalError(let error):
            self = .internalError(error: error)
        }
    }

    private static func incorrectCredentials() -> Snackbar {
        Snackbar(
            style: .warning,
            icon: nil,
            message: .l10n.auth.wrongCredentials
        )
    }

    private static func emailAlreadyTaken() -> Snackbar {
        Snackbar(
            style: .warning,
            icon: nil,
            message: .l10n.auth.emailAlreadyTaken
        )
    }

    private static func noConnection() -> Snackbar {
        Snackbar(
            style: .warning,
            icon: nil,
            message: .l10n.noConnection
        )
    }

    private static func notAuthorized() -> Snackbar {
        Snackbar(
            style: .warning,
            icon: nil,
            message: .l10n.auth.unauthorized
        )
    }

    private static func noSuchUser() -> Snackbar {
        Snackbar(
            style: .warning,
            icon: nil,
            message: .l10n.noSuchUser
        )
    }

    private static func internalError(error: String) -> Snackbar {
        Snackbar(
            style: .warning,
            icon: nil,
            message: "\(error)"
        )
    }
}

// MARK: - View Modifier

extension Snackbar {
    struct Modifier: ViewModifier {
        @Binding var preset: Preset?

        init(preset: Binding<Preset?>) {
            _preset = preset
        }

        func body(content: Content) -> some View {
            ZStack {
                content
                VStack {
                    if let preset {
                        Snackbar(preset: preset)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    Spacer()
                }
            }
        }
    }
}

extension View {
    @ViewBuilder public func snackbar(preset: Binding<Snackbar.Preset?>) -> some View {
        modifier(Snackbar.Modifier(preset: preset))
    }
}

#Preview {
    Snackbar(
        style: .warning,
        icon: "network.slash",
        message: "message"
    )
}
