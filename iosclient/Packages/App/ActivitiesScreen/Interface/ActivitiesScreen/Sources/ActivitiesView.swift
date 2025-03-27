import SwiftUI
import Entities
import AppBase
import Foundation
internal import Convenience
internal import DesignSystem

public struct ActivitiesView: View {
    @ObservedObject var store: Store<ActivitiesState, ActivitiesAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    
    @Binding private var onTapOwnerTabCounter: Int
    @Binding private var tabTransitionProgress: CGFloat
    private let dateFormatter: DateFormatter
    
    public init(
        store: Store<ActivitiesState, ActivitiesAction>,
        dateFormatter: DateFormatter,
        transitions: ActivitiesTransitions
    ) {
        self.store = store
        self.dateFormatter = dateFormatter
        
        _onTapOwnerTabCounter = transitions.tapOwnerTab.tapCounter
        _tabTransitionProgress = transitions.tab.progress
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            navigationBar
            content
        }
        .background(colors.background.secondary.default)
        .keyboardDismiss()
        .onAppear {
            store.dispatch(.appeared)
        }
        .onChange(of: onTapOwnerTabCounter) { _ in
            store.dispatch(.cancel)
        }
        .opacity(tabTransitionOpacity)
        .modifier(HorizontalTranslateEffect(offset: tabTransitionOffset))
        .id(store.state.sessionId)
    }
    
    private var content: some View {
        ScrollView {
            LazyVStack {
                ForEach(store.state.operations) { operation in
                    VStack {
                        HStack(spacing: 0) {
                            Text(operation.operationType)
                                .font(.medium(size: 14))
                                .foregroundStyle(colors.text.primary.default)
                            Spacer()
                            Text(operation.author.payload.displayName)
                                .font(.medium(size: 16))
                                .foregroundStyle(colors.text.primary.default)
                            Spacer()
                                .frame(width: 12)
                            AvatarView(avatar: operation.author.payload.avatar)
                                .frame(width: 48, height: 48)
                                .clipShape(.rect(cornerRadius: 24))
                            
                        }
                        .frame(height: 48)
                        HStack {
                            Text(
                                dateFormatter.string(
                                    from: Date(timeIntervalSince1970: TimeInterval(operation.createdAt) / 1000)
                                )
                            )
                            .font(.medium(size: 13))
                            .foregroundStyle(colors.text.secondary.default)
                            Spacer()
                            Text("status: \(operation.operationStatus)")
                                .font(.medium(size: 13))
                                .foregroundStyle(colors.text.secondary.default)
                        }
                        .frame(height: 22)
                        Rectangle()
                            .background(colors.background.brand.static)
                            .frame(height: 1 / UIScreen.main.scale)
                            .frame(maxHeight: .infinity)
                            .padding(.horizontal, 8)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 8)
        }
        .background(colors.background.primary.default)
        .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))
        .ignoresSafeArea(edges: [.bottom])
    }
    
    private var navigationBar: some View {
        NavigationBar(
            config: NavigationBar.Config(
                leftItem: .init(
                    config: .button(
                        .init(
                            title: .addExpenseNavCancel,
                            enabled: true
                        )
                    ),
                    action: {
                        store.dispatch(.cancel)
                    }
                ),
                title: .addExpenseNavTitle,
                style: .primary
            )
        )
    }
}

extension ActivitiesView {
    private var tabTransitionOpacity: CGFloat {
        1 - abs(tabTransitionProgress)
    }
    
    private var tabTransitionOffset: CGFloat {
        28 * tabTransitionProgress
    }
}

#if DEBUG

class ClassToIdentifyBundle {}

private struct ActivitiesPreview: View {
    @State var tabTransition: CGFloat = 0
    
    var body: some View {
        ZStack {
            ActivitiesView(
                store: Store(
                    state: ActivitiesState(
                        operations: [],
                        sessionId: UUID()
                    ),
                    reducer: { state, _ in state }
                ), dateFormatter: DateFormatter(),
                transitions: ActivitiesTransitions(
                    tab: TabTransition(
                        progress: .constant(1)
                    ),
                    tapOwnerTab: TapOwnerTabTransition(
                        tapCounter: .constant(0)
                    )
                )
            )
        }
    }
}

#Preview {
    ActivitiesPreview()
        .environment(ColorPalette.dark)
        .preview(packageClass: ClassToIdentifyBundle.self)
}

#endif
