import SwiftUI
import AppBase
import Entities
internal import Convenience
internal import DesignSystem

public struct SpendingsGroupView: View {
    @ObservedObject var store: Store<SpendingsGroupState, SpendingsGroupAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    
    @Binding private var appearTransitionProgress: CGFloat
    @Binding private var appearDestinationOffset: CGFloat?
    @Binding private var appearSourceOffset: CGFloat?
    
    @Binding private var tabTransitionProgress: CGFloat
    
    public init(
        store: Store<SpendingsGroupState, SpendingsGroupAction>,
        transitions: SpendingsGroupTransitions
    ) {
        self.store = store
        
        _appearTransitionProgress = transitions.appear.progress
        _appearSourceOffset = transitions.appear.sourceOffset
        _appearDestinationOffset = transitions.appear.destinationOffset
        
        _tabTransitionProgress = transitions.tab.progress
    }
    
    public var body: some View {
        VStack(spacing: 0) {
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
                            store.dispatch(.onTapBack)
                        }
                    ),
                    title: "",
                    style: .primary
                )
            )
            .modifier(VerticalTranslateEffect(offset: -0.8 * appearTransitionOffset))
            .modifier(HorizontalTranslateEffect(offset: tabTransitionOffset))
            .opacity(tabTransitionOpacity)
            HStack {
                AvatarView(avatar: store.state.preview.image)
                    .frame(width: 68, height: 68)
                    .clipShape(.rect(cornerRadius: 34))
                    .padding(.top, 12)
                Spacer()
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    Text(store.state.preview.name)
                        .font(.medium(size: 20))
                        .foregroundStyle(colors.text.primary.default)
                        .padding(.top, 4)
                    Text(.spendingsOverallBalance(amount: store.state.balanceFormatted ?? .settledUp))
                        .font(.medium(size: 14))
                        .minimumScaleFactor(0.3)
                        .foregroundStyle(colors.text.secondary.default)
                    Spacer()
                }
                .frame(height: 68)
                Spacer()
            }
            .padding(.all, 12)
            .modifier(VerticalTranslateEffect(offset: -0.8 * appearTransitionOffset))
            .modifier(HorizontalTranslateEffect(offset: tabTransitionOffset))
            .opacity(tabTransitionOpacity)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.state.items) { (item: SpendingsGroupState.Item) in
                        SpendingItemView(store: store, item: item)
                            .padding(.top, 2)
                            .id(item.id)
                            .transition(.slide)
                    }
                }
            }
            .opacity(adjustedTransitionOpacity)
            .modifier(HorizontalTranslateEffect(offset: tabTransitionOffset))
            Spacer()
        }
        .background(colors.background.secondary.default)
        .onAppear {
            store.dispatch(.onAppear)
        }
    }
    
    private var adjustedTransitionOpacity: CGFloat {
        tabTransitionOpacity * appearTransitionProgress
    }
    
    private var tabTransitionOpacity: CGFloat {
        1 - abs(tabTransitionProgress)
    }
    
    private var tabTransitionOffset: CGFloat {
        28 * tabTransitionProgress
    }
    
    private var appearTransitionOffset: CGFloat {
        (1 - appearTransitionProgress) * UIScreen.main.bounds.height / 5
    }
}

#if DEBUG

private struct SpendingsPreview: View {
    @State var appearTransition: CGFloat = 1
    @State var tabTransition: CGFloat = 0
    @State var sourceOffset: CGFloat?
    
    var body: some View {
        ZStack {
            SpendingsGroupView(
                store: Store(
                    state: SpendingsGroupState(
                        preview: SpendingsGroupState.GroupPreview(
                            image: "123",
                            name: "group name",
                            balance: [
                                .euro: 123,
                                .russianRuble: 342
                            ]
                        ),
                        items: [
                            .preview,
                            modify(.preview) {
                                $0.id = UUID().uuidString
                            }
                        ]
                    ),
                    reducer: { state, _ in state }
                ),
                transitions: SpendingsGroupTransitions(
                    appear: ModalTransition(
                        progress: $appearTransition,
                        sourceOffset: .constant(0),
                        destinationOffset: $sourceOffset
                    ),
                    tab: TabTransition(
                        progress: $tabTransition
                    )
                )
                
            )
            VStack {
                Text("sourceOffset: \(sourceOffset ?? -1)")
                    .foregroundStyle(.red)
                Slider(value: $appearTransition, in: 0...1)
                Slider(value: $tabTransition, in: -1...1)
            }
        }
    }
}

class ClassToIdentifyBundle {}

#Preview {
    SpendingsPreview()
        .environment(AvatarView.Repository { _ in .stubAvatar })
        .preview(packageClass: ClassToIdentifyBundle.self)
}

#endif
