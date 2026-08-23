import SwiftUI

struct OnboardingView: View {
    @Environment(PaymentService.self) private var service
    @State private var name = "Alex Rivera"

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
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your name")
                        .font(.subheadline)
                        .foregroundStyle(SNP.textMuted)
                    TextField("Display name", text: $name)
                        .font(SNP.display(28, weight: .regular))
                        .textInputAutocapitalization(.words)
                }
                Button {
                    service.completeOnboarding(displayName: name)
                } label: {
                    Text("Continue")
                }
                .buttonStyle(QuietButtonStyle(filled: true, enabled: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Text("Settle outside the app. ShareNPay does not take payments.")
                    .font(.subheadline)
                    .foregroundStyle(SNP.textMuted)
                Spacer()
            }
            .padding(28)
        }
    }
}
