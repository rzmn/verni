import SwiftUI

public struct Snackbar: View {
    enum Style {
        case warning
    }
    private let show: Bool
    private let style: Style
    private let icon: String?
    private let message: String

    init(
        show: Bool,
        style: Style,
        icon: String?,
        message: String
    ) {
        self.show = show
        self.style = style
        self.icon = icon
        self.message = message
    }

    public var body: some View {
        if show {
            VStack {
                Spacer()
                HStack(alignment: .center, spacing: 12) {
                    if let name = icon {
                        Image(systemName: name)
                            .resizable()
                            .foregroundColor(self.iconColor)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14)
                    }

                    Text(message)
                        .foregroundColor(textColor)
                        .font(.system(size: 14))
                        .frame(alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 35)
                .padding(.vertical, 8)
                .background(backgroundColor)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.bottom, show ? 54 : 0)
                .animation(.easeInOut, value: show)
            }
            .transition(.move(edge: .bottom))
            .edgesIgnoringSafeArea(.bottom)
        }
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
        case wrongFormat
        case noConnection
        case incorrectCredentials
        case notAuthorized
        case internalError(String)

        var kind: String {
            switch self {
            case .emailAlreadyTaken:
                return "emailAlreadyTaken"
            case .wrongFormat:
                return "wrongFormat"
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

    init(show: Bool, preset: Preset) {
        switch preset {
        case .emailAlreadyTaken:
            self = .emailAlreadyTaken(show: show)
        case .wrongFormat:
            self = .wrongFormat(show: show)
        case .noConnection:
            self = .noConnection(show: show)
        case .incorrectCredentials:
            self = .incorrectCredentials(show: show)
        case .notAuthorized:
            self = .notAuthorized(show: show)
        case .internalError(let error):
            self = .internalError(show: show, error: error)
        }
    }

    private static func incorrectCredentials(
        show: Bool
    ) -> Snackbar {
        Snackbar(
            show: show,
            style: .warning,
            icon: nil,
            message: "wrong_credentials_hint".localized
        )
    }

    private static func emailAlreadyTaken(
        show: Bool
    ) -> Snackbar {
        Snackbar(
            show: show,
            style: .warning,
            icon: nil,
            message: "email_already_taken".localized
        )
    }

    private static func wrongFormat(
        show: Bool
    ) -> Snackbar {
        Snackbar(
            show: show,
            style: .warning,
            icon: nil,
            message: "wrong_credentials_format_hint".localized
        )
    }

    private static func noConnection(
        show: Bool
    ) -> Snackbar {
        Snackbar(
            show: show,
            style: .warning,
            icon: nil,
            message: "no_connection_hint".localized
        )
    }

    private static func notAuthorized(
        show: Bool
    ) -> Snackbar {
        Snackbar(
            show: show,
            style: .warning,
            icon: nil,
            message: "alert_title_unauthorized".localized
        )
    }

    private static func noSuchUser(
        show: Bool
    ) -> Snackbar {
        Snackbar(
            show: show,
            style: .warning,
            icon: nil,
            message: "alert_action_no_such_user".localized
        )
    }

    private static func internalError(
        show: Bool,
        error: String
    ) -> Snackbar {
        Snackbar(
            show: show,
            style: .warning,
            icon: nil,
            message: "\(error)"
        )
    }
}

// MARK: - View Modifier

extension Snackbar {
    struct Modifier: ViewModifier {
        private let show: Bool
        private let preset: Preset

        init(show: Bool, preset: Preset) {
            self.show = show
            self.preset = preset
        }

        func body(content: Content) -> some View {
            ZStack {
                content
                Snackbar(show: show, preset: preset)
            }
        }
    }
}

extension View {
    public func snackbar(show: Bool, preset: Snackbar.Preset) -> some View {
        modifier(Snackbar.Modifier(show: show, preset: preset))
    }
}

#Preview {
    Snackbar(
        show: true,
        style: .warning,
        icon: "network.slash",
        message: "message"
    )
}
