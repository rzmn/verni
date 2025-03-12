import SwiftUI
import Entities
import AppBase
internal import Convenience
internal import DesignSystem

public struct UserPreviewView: View {
    @ObservedObject var store: Store<UserPreviewState, UserPreviewAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    
    private let transitions: UserPreviewTransitions


    public init(
        store: Store<UserPreviewState, UserPreviewAction>,
        transitions: UserPreviewTransitions
    ) {
        self.store = store
        self.transitions = transitions
    }

    public var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    IconButton(
                        config: .init(
                            style: .primary,
                            icon: .close
                        )
                    ) {
                        store.dispatch(.close)
                    }
                }
                var smallerSide: CGFloat {
                    min(proxy.size.width, proxy.size.height)
                }
                AvatarView(
                    avatar: store.state.user.payload.avatar
                )
                .frame(
                    width: smallerSide,
                    height: smallerSide
                )
                .clipShape(.circle)
                Text(store.state.user.payload.displayName)
                    .font(.medium(size: 32))
                Spacer()
                DesignSystem.Button(
                    config: .init(
                        style: .primary,
                        text: "add me"
                    )
                ) {
                    store.dispatch(.createSpendingGroup)
                }
                Spacer()
            }
        }
        .padding(16)
    }
}

#if DEBUG

class ClassToIdentifyBundle {}

private struct ProfilePreview: View {
    @State var tabTransition: CGFloat = 0

    var body: some View {
        ZStack {
            UserPreviewView(
                store: Store(
                    state: UserPreviewState(
                        user: User(
                            id: "",
                            payload: UserPayload(
                                displayName: "name",
                                avatar: "123"
                            )
                        )
                        
                    ),
                    reducer: { state, _ in state }
                ),
                transitions: UserPreviewTransitions()
            )
            .environment(ColorPalette.light)
            VStack {
                Slider(value: $tabTransition, in: -1...1)
            }
        }
    }
}

#Preview {
    ProfilePreview()
        .preview(packageClass: ClassToIdentifyBundle.self)
}

#endif
