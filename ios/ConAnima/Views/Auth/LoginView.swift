import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var auth
    @FocusState private var focused: Field?
    @State private var appeared = false

    private enum Field: Hashable { case user, pass }

    private var canSubmit: Bool {
        !auth.username.trimmingCharacters(in: .whitespaces).isEmpty
            && !auth.password.isEmpty
            && !auth.isLoading
    }

    var body: some View {
        @Bindable var auth = auth

        ZStack {
            background
                .ignoresSafeArea()
                .onTapGesture { focused = nil }

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 48)

                    brandBlock
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                    formCard(auth: auth)
                        .padding(.top, 36)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    Spacer(minLength: 48)

                    Text("Музыкальная школа")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 440)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                appeared = true
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.91, green: 0.93, blue: 0.99),
                Color(red: 0.96, green: 0.97, blue: 1.0),
                Color(.systemBackground),
            ],
            startPoint: .topLeading,
            endPoint: .bottom
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(AppTheme.primary.opacity(0.16))
                .frame(width: 240, height: 240)
                .blur(radius: 46)
                .offset(x: 70, y: -50)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Color(red: 0.78, green: 0.83, blue: 0.98).opacity(0.55))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .offset(x: -60, y: 30)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .center) {
            Circle()
                .fill(Color(red: 0.98, green: 0.85, blue: 0.9).opacity(0.28))
                .frame(width: 160, height: 160)
                .blur(radius: 44)
                .offset(x: 110, y: 60)
                .allowsHitTesting(false)
        }
    }

    private var brandBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.primary)
                    .frame(width: 56, height: 56)
                    .shadow(color: AppTheme.primary.opacity(0.35), radius: 16, y: 8)
                Image(systemName: "music.note")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(AppTheme.brand)
                    .font(.system(size: 36, weight: .semibold, design: .serif))
                    .italic()
                    .tracking(-0.5)

                Text("Кабинет для спокойной работы с учениками")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formCard(auth: AuthViewModel) -> some View {
        @Bindable var auth = auth

        return VStack(alignment: .leading, spacing: 18) {
            Text("С возвращением")
                .font(.title3.weight(.semibold))

            AppTextField(
                label: "Логин",
                text: $auth.username,
                placeholder: "Ваш логин",
                contentType: .username,
                submitLabel: .next,
                focusValue: Field.user,
                focused: $focused,
                onSubmit: { focused = .pass }
            )

            AppTextField(
                label: "Пароль",
                text: $auth.password,
                placeholder: "Пароль",
                isSecure: true,
                contentType: .password,
                submitLabel: .go,
                focusValue: Field.pass,
                focused: $focused,
                onSubmit: { Task { await submit() } }
            )

            if let err = auth.errorMessage {
                ErrorCallout(message: err)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Button {
                Task { await submit() }
            } label: {
                ZStack {
                    if auth.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Войти")
                            .font(.body.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: AppTheme.controlRadius))
            .tint(AppTheme.primary)
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.55)
            .padding(.top, 4)
            .animation(.easeInOut(duration: 0.2), value: auth.errorMessage)
        }
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
        }
        .shadow(color: .black.opacity(0.10), radius: 30, y: 16)
        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
    }

    private func submit() async {
        focused = nil
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        await auth.login()
        if auth.isAuthenticated {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else if auth.errorMessage != nil {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
