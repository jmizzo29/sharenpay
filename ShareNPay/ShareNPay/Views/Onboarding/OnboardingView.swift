import SwiftUI

struct SetupView: View {
    var reason: String

    var body: some View {
        ZStack {
            SNP.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 28) {
                BrandMark(size: 52)
                VStack(alignment: .leading, spacing: 10) {
                    Wordmark(size: 36)
                    Text("Firebase isn’t set up yet.")
                        .font(SNP.display(28, weight: .regular))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(reason)
                    .font(.body)
                    .foregroundStyle(SNP.textMuted)
                VStack(alignment: .leading, spacing: 12) {
                    step("1", "Create a Firebase project and add an iOS app with bundle ID com.sharenpay.app")
                    step("2", "Enable Authentication → Google")
                    step("3", "Replace ShareNPay/ShareNPay/GoogleService-Info.plist with the file Firebase downloads")
                    step("4", "Set Info.plist GIDClientID and the URL scheme to REVERSED_CLIENT_ID")
                    step("5", "Deploy firebase/firestore.rules")
                }
                Text("The app will not crash without a real project. Sign in with Google starts after that plist is real.")
                    .font(.subheadline)
                    .foregroundStyle(SNP.textMuted)
                Spacer()
            }
            .padding(28)
        }
    }

    private func step(_ number: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(number)
                .font(SNP.money(18, weight: .semibold))
                .foregroundStyle(SNP.textMuted)
                .frame(width: 22, alignment: .leading)
            Text(text)
                .font(.body)
                .foregroundStyle(SNP.text)
        }
    }
}

struct SignInView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        ZStack {
            SNP.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 28) {
                BrandMark(size: 52)
                VStack(alignment: .leading, spacing: 10) {
                    Wordmark(size: 36)
                    Text("Add a bill. Split it. See who owes what.")
                        .font(.title3)
                        .foregroundStyle(SNP.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button {
                    Task { await session.signInWithGoogle() }
                } label: {
                    Text(session.isWorking ? "Signing in…" : "Continue with Google")
                }
                .buttonStyle(QuietButtonStyle(filled: true, enabled: !session.isWorking))
                .disabled(session.isWorking)
                if let message = session.errorMessage, !message.isEmpty {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(SNP.textMuted)
                }
                Text("Settle outside the app. ShareNPay does not take payments. Your bills live on your Google account.")
                    .font(.subheadline)
                    .foregroundStyle(SNP.textMuted)
            }
            .padding(28)
        }
    }
}
