import SwiftUI

struct OnboardingView: View {
    @Environment(PaymentService.self) private var service
    @State private var name = "Alex Rivera"

    var body: some View {
        ZStack {
            SNP.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                BrandMark(size: 56)
                Wordmark(size: 32)
                Text("Your name")
                    .font(.subheadline)
                    .foregroundStyle(SNP.textMuted)
                TextField("Display name", text: $name)
                    .textInputAutocapitalization(.words)
                    .padding(12)
                    .background(SNP.fill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Button {
                    service.completeOnboarding(displayName: name)
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(SNP.accent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Text("You’ll join the 300 West household. ShareNPay does not take payments.")
                    .font(.caption)
                    .foregroundStyle(SNP.textMuted)
                Spacer()
            }
            .padding(24)
        }
    }
}
