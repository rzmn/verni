import SwiftUI

//public struct AlertStyle {
//    public enum Action: Identifiable {
//        case regular(title: String, action: () -> Void)
//        case destructive(title: String, action: () -> Void)
//
//        var execute: () -> Void {
//            switch self {
//            case .regular(_, let action), .destructive(_, let action):
//                return action
//            }
//        }
//
//        var title: String {
//            switch self {
//            case .regular(let title, _), .destructive(let title, _):
//                return title
//            }
//        }
//
//        var buttonType: ButtonType {
//            switch self {
//            case .regular:
//                .primary
//            case .destructive:
//                .destructive
//            }
//        }
//
//        public var id: String {
//            switch self {
//            case .regular(let title, _):
//                return "regular" + title
//            case .destructive(let title, _):
//                return "destructive" + title
//            }
//        }
//    }
//
//    let title: String
//    let subtitle: String?
//    let actions: [Action]
//}
//
//private struct Alert: View {
//    let style: AlertStyle
//
//    var body: some View {
//        Text("alert")
//    }
//}
//
//private struct AlertModifier: ViewModifier {
//    @Binding var isPresented: Bool
//    let onDimmingTap: () -> Void
//    let style: AlertStyle
//
//    func body(content: Content) -> some View {
//        ZStack {
//            content
//            if isPresented {
//                ColorPalette.dark.background.primary.brand
//                    .onTapGesture {
//                        onDimmingTap()
//                    }
//            }
//            VStack(alignment: .center) {
//                if isPresented {
//                    Spacer()
//                    VStack {
//                        Text(style.title)
//                            .fontStyle(.title1)
//                        if let subtitle = style.subtitle {
//                            Spacer()
//                                .frame(height: 18)
//                            Text(subtitle)
//                                .fontStyle(.text)
//                            Spacer()
//                                .frame(height: 18)
//                        } else {
//                            Spacer()
//                                .frame(height: 44)
//                        }
//                        ForEach(style.actions) { action in
//                            Button {
//                                action.execute()
//                            } label: {
//                                Text(action.title)
//                            }
//                            .buttonStyle(type: action.buttonType, enabled: true)
//                        }
//                    }
//                    .padding(.palette.defaultVertical)
//                    .padding(.horizontal, .palette.defaultHorizontal * 2)
//                    .background(ColorPalette.dark.background.primary.brand)
//                    .clipShape(.rect(cornerRadius: 20))
//                    Spacer()
//                }
//            }
//        }
//    }
//}
//
//extension View {
//    public func alert(isPresented: Binding<Bool>, style: AlertStyle, onDimmingTap: @escaping () -> Void) -> some View {
//        modifier(AlertModifier(isPresented: isPresented, onDimmingTap: onDimmingTap, style: style))
//    }
//}
//
//#Preview {
//    ColorPalette.dark.background.primary.brand
//        .alert(
//            isPresented: Binding { true } set: { _ in },
//            style: AlertStyle(
//                title: "title",
//                subtitle: "subtitle",
//                actions: [
//                    .regular(title: "regular", action: {}),
//                    .destructive(title: "destructive", action: {})
//                ]
//            ),
//            onDimmingTap: {}
//        )
//        .ignoresSafeArea()
//}
