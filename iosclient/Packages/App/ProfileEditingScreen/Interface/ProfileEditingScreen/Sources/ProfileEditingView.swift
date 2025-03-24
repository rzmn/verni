import SwiftUI
import Entities
import AppBase
import PhotosUI
internal import Convenience
internal import DesignSystem

public struct ProfileEditingView: View {
    @ObservedObject var store: Store<ProfileEditingState, ProfileEditingAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    
    @Binding private var tabTransitionProgress: CGFloat
    
    public init(store: Store<ProfileEditingState, ProfileEditingAction>, transitions: ProfileEditingTransitions) {
        self.store = store
        _tabTransitionProgress = transitions.tab.progress
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
                .background(colors.background.secondary.default)
                .opacity(tabTransitionOpacity)
                .modifier(HorizontalTranslateEffect(offset: tabTransitionOffset))
            VStack {
                displayNameEditor
                avatarEditor
                DesignSystem.Button(
                    config: .init(
                        style: .primary,
                        text: .profileEditConfirm,
                        enabled: store.state.hasChanges && store.state.canSubmit
                    )
                ) {
                    store.dispatch(.onSaveChanges)
                }
                .padding(.top, 54)
            }
            .opacity(tabTransitionOpacity)
            .animation(.default.speed(5), value: tabTransitionOpacity)
            .modifier(HorizontalTranslateEffect(offset: tabTransitionOffset))
            Spacer()
        }
        .background(colors.background.primary.default.opacity(tabTransitionOpacity))
        .photosPicker(
            isPresented: Binding(
                get: {
                    store.state.showingImagePicker
                }, set: { newValue in
                    guard newValue != store.state.showingImagePicker else {
                        return
                    }
                    if newValue {
                        store.dispatch(.onSelectImage)
                    } else {
                        store.dispatch(.onCloseImagePicker)
                    }
                }
            ),
            selection: Binding(
                get: {
                    store.state.imageSelection?.image
                }, set: {
                    store.dispatch(.onSelectedImageChanged($0))
                }
            ),
            matching: .images
        )
        .keyboardDismiss()
    }
    
    @ViewBuilder var displayDiffView: some View {
        if store.state.displayName.isEmpty {
            HStack {
                Text(.profileEditCurrent)
                    .foregroundStyle(colors.text.secondary.default)
                    .font(.medium(size: 14))
                Spacer()
                Text(store.state.currentDisplayName)
                    .foregroundStyle(colors.text.secondary.default)
                    .font(.medium(size: 14))
            }
        } else {
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(store.state.currentDisplayName)
                        .foregroundStyle(colors.text.secondary.default)
                        .font(.medium(size: 14))
                    Spacer()
                    Text(store.state.displayName)
                        .foregroundStyle(colors.text.secondary.default)
                        .font(.medium(size: 14))
                }
                .overlay {
                    HStack(spacing: 0) {
                        Spacer()
                        SwiftUI.Image.arrowRight
                        Spacer()
                    }
                }
                IconButton(
                    config: .init(
                        style: .primary,
                        icon: .close
                    )
                ) {
                    store.dispatch(.onDiscardName)
                }
            }
        }
    }
    
    @ViewBuilder var displayNameEditor: some View {
        VStack(spacing: 0) {
            displayDiffView
                .frame(height: 54)
            DesignSystem.TextField(
                text: Binding(
                    get: {
                        store.state.displayName
                    }, set: {
                        store.dispatch(.onDisplayNameChanged($0))
                    }
                ),
                config: .init(
                    placeholder: .profileEditDisplayNamePlaceholder,
                    hint: .hintsEnabled(
                        store.state.displayNameHint
                            .flatMap { LocalizedStringKey($0) }
                    )
                )
            )
        }
    }
    
    @ViewBuilder private func avatarModifier(_ content: some View) -> some View {
        content
            .frame(width: 54, height: 54)
            .background(colors.background.secondary.default)
            .clipShape(.rect(cornerRadius: 44))
    }
    
    @ViewBuilder var avatarEditor: some View {
        VStack {
            if let selection = store.state.imageSelection {
                HStack(spacing: 0) {
                    avatarModifier(AvatarView(avatar: store.state.currentAvatar))
                    Spacer()
                    SwiftUI.Image.arrowRight
                    Spacer()
                    if let image = selection.image {
                        if let uiImage = selection.uiImage {
                            avatarModifier(
                                SwiftUI.Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            )
                        } else {
                            avatarModifier(ProgressView())
                        }
                    } else {
                        avatarModifier(AvatarView(avatar: nil))
                    }
                    IconButton(
                        config: .init(
                            style: .primary,
                            icon: .close
                        )
                    ) {
                        store.dispatch(.onDiscardImage)
                    }
                }
            } else {
                HStack {
                    Text(.profileEditCurrent)
                        .foregroundStyle(colors.text.secondary.default)
                        .font(.medium(size: 14))
                    Spacer()
                    avatarModifier(AvatarView(avatar: store.state.currentAvatar))
                }
            }
            if let selection = store.state.imageSelection {
                if selection.image == nil {
                    HStack {
                        DesignSystem.Button(
                            config: .init(
                                style: .secondary,
                                text: .profileEditSetAnotherAvatar
                            )
                        ) {
                            store.dispatch(.onSelectImage)
                        }
                    }
                } else {
                    HStack {
                        if store.state.currentAvatar != nil {
                            DesignSystem.Button(
                                config: .init(
                                    style: .secondary,
                                    text: .profileEditSetDefault
                                )
                            ) {
                                store.dispatch(.onSelectDefaultImage)
                            }
                        }
                        DesignSystem.Button(
                            config: .init(
                                style: .secondary,
                                text: .profileEditSetAnotherAvatar
                            )
                        ) {
                            store.dispatch(.onSelectImage)
                        }
                    }
                }
            } else {
                if store.state.currentAvatar == nil {
                    DesignSystem.Button(
                        config: .init(
                            style: .secondary,
                            text: .profileEditSetNewAvatar
                        )
                    ) {
                        store.dispatch(.onSelectImage)
                    }
                } else {
                    HStack {
                        DesignSystem.Button(
                            config: .init(
                                style: .secondary,
                                text: .profileEditSetDefault
                            )
                        ) {
                            store.dispatch(.onSelectDefaultImage)
                        }
                        DesignSystem.Button(
                            config: .init(
                                style: .secondary,
                                text: .profileEditSetAnotherAvatar
                            )
                        ) {
                            store.dispatch(.onSelectImage)
                        }
                    }
                }
            }
        }
    }
    
    private var navigationBar: some View {
        NavigationBar(
            config: NavigationBar.Config(
                leftItem: NavigationBar.Item(
                    config: .icon(
                        .init(
                            style: .primary,
                            icon: .arrowLeft
                        )
                    ),
                    action: {
                        store.dispatch(.onClose)
                    }
                ),
                title: .profileTitle,
                style: .primary
            )
        )
    }
}

// MARK: - Transitions

extension ProfileEditingView {
    private var tabTransitionOpacity: CGFloat {
        1 - abs(tabTransitionProgress)
    }
    
    private var tabTransitionOffset: CGFloat {
        28 * tabTransitionProgress
    }
}

#if DEBUG

class ClassToIdentifyBundle {}

private struct ProfilePreview: View {
    @State var tabTransition: CGFloat = 0
    
    var body: some View {
        ZStack {
            ProfileEditingView(
                store: Store(
                    state: ProfileEditingState(
                        currentDisplayName: "display name",
                        displayName: "display name",
                        displayNameHint: "123",
                        currentAvatar: "123",
                        imageSelection: .init(image: nil, uiImage: nil),
                        canSubmit: true,
                        showingImagePicker: true
                    ),
                    reducer: { state, _ in state }
                ),
                transitions: ProfileEditingTransitions(
                    tab: TabTransition(
                        progress: $tabTransition
                    )
                )
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
        .environment(AvatarView.Repository { _ in
                .stubAvatar
        })
        .preview(packageClass: ClassToIdentifyBundle.self)
}

#endif
