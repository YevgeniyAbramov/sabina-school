import SwiftUI

@main
struct ConAnimaApp: App {
    @State private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .tint(AppTheme.primary)
        }
    }
}

struct RootView: View {
    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: auth.isAuthenticated)
    }
}
