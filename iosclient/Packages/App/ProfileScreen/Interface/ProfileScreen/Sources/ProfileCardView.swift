import SwiftUI
import AppBase
import Entities
internal import DesignSystem

struct ProfileCardView: View {
    @ObservedObject private var store: Store<ProfileState, ProfileAction>
    @Environment(ColorPalette.self) private var colors

    init(store: Store<ProfileState, ProfileAction>) {
        self.store = store
    }

    var body: some View {
        FlipView(
            frontView: avatarCard,
            backView: qrCodeCard,
            flipsCount: Binding(
                get: {
                    store.state.avatarCardFlipCount
                },
                set: { _ in
                    store.dispatch(.onFlipAvatarTap)
                }
            )
        )
        .overlay {
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        let side = qrCodeSide(geometry: geometry)
                        if side > 0, store.state.qrCodeData == nil {
                            store.dispatch(.onRequestQrImage(size: side * Int(UIScreen.main.scale)))
                        }
                    }
            }
        }
        .aspectRatio(cardAspectRatio, contentMode: .fit)
    }

    @ViewBuilder private var avatarCard: some View {
        AvatarView(avatar: store.state.profileInfo.avatar)
            .aspectRatio(cardAspectRatio, contentMode: .fit)
            .clipped()
            .clipShape(.rect(cornerRadius: cornerRadius, style: .circular))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                colors.background.brand.static,
                                .green.opacity(0.4)
                            ],
                            startPoint: UnitPoint(x: 0.5, y: 1),
                            endPoint: UnitPoint(x: 0.5, y: 97.0 / 281.0)
                        )
                    )
            }
            .overlay {
                HStack {
                    VStack {
                        Spacer()
                        Text(store.state.profileInfo.displayName)
                            .font(.medium(size: 28))
                            .foregroundStyle(colors.text.primary.staticLight)
                            .padding(.leading, 16)
                            .padding(.bottom, 14)
                    }
                    Spacer()
                    VStack {
                        Spacer()
                        IconButton(
                            config: IconButton.Config(
                                style: .primary,
                                icon: .qrCode
                            )
                        ) {}.allowsHitTesting(false)
                    }
                    .padding([.bottom, .trailing], 10)
                }
            }
    }

    @ViewBuilder private var qrCodeCard: some View {
        colors.background.primary.alternative
            .overlay {
                GeometryReader { geometry in
                    let side = CGFloat(qrCodeSide(geometry: geometry))
                    let image = store.state.qrCodeData
                        .flatMap(Image.init(uiImage:))
                    if let image {
                        HStack(spacing: 0) {
                            Spacer()
                            VStack(spacing: 0) {
                                Spacer()
                                image
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fit)
                                    .foregroundStyle(colors.text.primary.alternative)
                                    .frame(width: side, height: side)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
            }
            .aspectRatio(cardAspectRatio, contentMode: .fit)
            .clipShape(.rect(cornerRadius: cornerRadius, style: .circular))
            .overlay {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        IconButton(
                            config: IconButton.Config(
                                style: .primary,
                                icon: .question
                            )
                        ) {
                            store.dispatch(.onShowQrHintTap)
                        }
                    }
                    .padding([.bottom, .trailing], 10)
                }
            }
    }
}

extension ProfileCardView {
    private var cornerRadius: CGFloat {
        22
    }

    private var cardAspectRatio: CGFloat {
        cardFitSize.width / cardFitSize.height
    }

    private var cardFitSize: CGSize {
        CGSize(width: 371, height: 281)
    }

    private func qrCodeSide(geometry: GeometryProxy) -> Int {
        Int(max(min(geometry.size.width, geometry.size.height) - 30 * 2, 88))
    }
}

#if DEBUG

class ClassToIdentifyBundle {}

#Preview {
    ProfileCardView(
        store: Store(
            state: ProfileState(
                profile: Profile(
                    userId: "",
                    email: .undefined
                ),
                profileInfo: UserPayload(
                    displayName: "name",
                    avatar: nil
                ),
                avatarCardFlipCount: 0,
                qrCodeData: nil
            ),
            reducer: { state, _ in state }
        )
    )
    .debugBorder()
    .preview(packageClass: ClassToIdentifyBundle.self)
}

#endif
