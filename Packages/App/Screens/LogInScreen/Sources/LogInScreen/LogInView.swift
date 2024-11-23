import SwiftUI
import AppBase
internal import DesignSystem

public struct LogInView: View {
    @ObservedObject var store: Store<LogInState, LogInAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors

    init(store: Store<LogInState, LogInAction>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                IconButton(
                    config: IconButton.Config(
                        style: .primary,
                        icon: .arrowLeft
                    )
                ) {
                    store.dispatch(.onTapBack)
                }
                Spacer()
            }
            .overlay {
                Text(.loginScreenTitle)
                    .font(.medium(size: 15))
                    .foregroundStyle(colors.text.primary.alternative)
            }
            VStack {
                DesignSystem.TextField(
                    text: Binding(get: {
                        store.state.email
                    }, set: { text in
                        store.dispatch(.emailTextChanged(text))
                    }),
                    config: TextField.Config(
                        placeholder: .loginEmailPlaceholder,
                        content: .email
                    )
                )
                DesignSystem.TextField(
                    text: Binding(get: {
                        store.state.password
                    }, set: { text in
                        store.dispatch(.passwordTextChanged(text))
                    }),
                    config: TextField.Config(
                        placeholder: .loginPasswordPlaceholder,
                        content: .password
                    )
                )
                Spacer()
                bottomButtonsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colors.background.primary.alternative)
                    .edgesIgnoringSafeArea([.bottom])
            )
        }
        .background(
            colors.background.primary.default
                .ignoresSafeArea()
        )
        .keyboardDismiss()
    }
    
    private var titleSection: some View {
        Text(.authWelcomeTitle)
            .foregroundStyle(colors.text.secondary.default)
            .font(.regular(size: 13))
            .multilineTextAlignment(.center)
            .padding(.all, 16)
    }
    
    private var bottomButtonsSection: some View {
        VStack {
            DesignSystem.Button(
                config: Button.Config(
                    style: .primary,
                    text: .logIn,
                    icon: .right(.arrowRight)
                ), action: {
                    store.dispatch(.onLogInTap)
                }
            )
            DesignSystem.Button(
                config: Button.Config(
                    style: .tertiary,
                    text: .loginForgotPassword,
                    icon: .none
                ), action: {
                    store.dispatch(.onCreateAccountTap)
                }
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 12)
    }
}

#Preview {
    LogInView(
        store: Store(
            state: LogInModel.initialState,
            reducer: LogInModel.reducer
        )
    )
    .preview(packageClass: LogInModel.self)
}
