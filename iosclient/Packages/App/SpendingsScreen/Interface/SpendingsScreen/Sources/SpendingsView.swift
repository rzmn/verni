import SwiftUI
import AppBase
import Entities
internal import DesignSystem

public struct SpendingsView: View {
    @ObservedObject var store: Store<SpendingsState, SpendingsAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    
    @Binding private var appearTransitionProgress: CGFloat
    @Binding private var appearDestinationOffset: CGFloat?
    @Binding private var appearSourceOffset: CGFloat?
    
    @Binding private var tabTransitionProgress: CGFloat
    
    public init(
        store: Store<SpendingsState, SpendingsAction>,
        transitions: SpendingsTransitions
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
                    rightItem: NavigationBar.Item(
                        config: .icon(
                            .init(
                                style: .primary,
                                icon: .search
                            )
                        ),
                        action: {
                            store.dispatch(.onSearchTap)
                        }
                    ),
                    title: .spendingsTitle,
                    style: .primary
                )
            )
            .modifier(VerticalTranslateEffect(offset: -0.8 * appearTransitionOffset))
            .modifier(HorizontalTranslateEffect(offset: tabTransitionOffset))
            .opacity(tabTransitionOpacity)
            overallSection
                .padding(.top, appearTransitionOffset)
                .opacity(adjustedTransitionOpacity)
                .modifier(HorizontalTranslateEffect(offset: tabTransitionOffset))
            ForEach(items) { (item: SpendingsState.Item) in
                SpendingsItem(
                    config: SpendingsItem.Config(
                        avatar: item.image,
                        name: item.name,
                        style: item.isPositive ? .positive : .negative,
                        amount: item.amount ?? .settledUp
                    )
                )
                .padding(.bottom, 2)
                .id(item.id)
                .onTapGesture {
                    store.dispatch(.onGroupTap(item.id))
                }
            }
            .opacity(adjustedTransitionOpacity)
            .modifier(HorizontalTranslateEffect(offset: tabTransitionOffset))
            Spacer()
        }
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
    
    private var items: [SpendingsState.Item] {
        store.state.previews
    }
    
    private var overallSection: some View {
        HStack(spacing: 0) {
            Image.chevronDown
                .frame(width: 24, height: 24)
                .padding(.leading, 16)
                .foregroundStyle(colors.text.primary.alternative)
            VStack(alignment: .leading, spacing: 0) {
                Text(.spendingsOverallTitle)
                    .font(.bold(size: 15))
                    .foregroundStyle(colors.text.primary.alternative)
                    .padding(.top, 20)
                Spacer()
                Text(.spendingsPeopleInvolved(count: store.state.previews.count))
                    .font(.medium(size: 15))
                    .foregroundStyle(colors.text.secondary.alternative)
                    .padding(.bottom, 20)
            }
            .padding(.leading, 12)
            Spacer()
        }
        .background(colors.background.primary.alternative)
        .frame(height: 82)
        .clipShape(.rect(cornerRadius: 24))
    }
}

#if DEBUG

private struct SpendingsPreview: View {
    @State var appearTransition: CGFloat = 1
    @State var tabTransition: CGFloat = 0
    @State var sourceOffset: CGFloat?
    
    var body: some View {
        ZStack {
            SpendingsView(
                store: Store(
                    state: SpendingsState(
                        previews: [
                            SpendingsState.Item(
                                id: UUID().uuidString,
                                image: nil,
                                name: "displayName",
                                balance: [
                                    .euro: 123
                                ]
                            )
                        ]
                    ),
                    reducer: { state, _ in state }
                ),
                transitions: SpendingsTransitions(
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
        .preview(packageClass: ClassToIdentifyBundle.self)
}

#endif
