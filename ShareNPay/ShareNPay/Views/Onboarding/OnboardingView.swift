import SwiftUI

struct OnboardingView: View {
    @Environment(PaymentService.self) private var service
    @State private var name = "Alex Rivera"
    @FocusState private var nameFocused: Bool

    private let cases = ExpenseCategory.allCases.filter { $0 != .other }

    var body: some View {
        ZStack {
            SNP.background.ignoresSafeArea()
            coolGlow
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    story
                    useCases
                    nameField
                    startButton
                    disclaimer
                }
                .padding(24)
                .padding(.top, 20)
            }
        }
    }

    private var coolGlow: some View {
        LinearGradient(
            colors: [SNP.accent.opacity(0.16), .clear, SNP.positive.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandMark(size: 72)
            Wordmark(size: 40)
            Text("Record a shared expense like a tweet. Talk it through. Agree. Then settle.")
                .font(.title3.weight(.medium))
                .foregroundStyle(SNP.text)
                .fixedSize(horizontal: false, vertical: true)
            Text("Salt Lake City, 2010 — rebuilt for 2026. Conversation around money, not a public feed.")
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
        }
    }

    private var story: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 10) {
                Label("How a share works", systemImage: "quote.opening")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SNP.accent)
                step("1", "Write a short note, pick a category, add people.")
                step("2", "Split evenly. Everyone sees who owes whom.")
                step("3", "Discuss, agree, approve — then settle the mock ledger.")
            }
        }
    }

    private func step(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(SNP.accent, in: Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(SNP.text)
        }
    }

    private var useCases: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Built for the original table")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SNP.textMuted)
            FlowChips(categories: cases)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What should friends call you?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SNP.text)
            TextField("Display name", text: $name)
                .textInputAutocapitalization(.words)
                .focused($nameFocused)
                .padding(14)
                .background(SNP.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(SNP.hairline, lineWidth: 1)
                }
            Text("Stays on this iPhone. No server, no real account.")
                .font(.caption)
                .foregroundStyle(SNP.textMuted)
        }
    }

    private var startButton: some View {
        Button {
            service.completeOnboarding(displayName: name)
        } label: {
            Text("Sit down at the table")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(SNP.accent)
        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var disclaimer: some View {
        Text("v1 uses a mock ledger. Nothing here moves real money or talks to PayPal, cards, or a bank.")
            .font(.caption)
            .foregroundStyle(SNP.textMuted)
            .padding(.bottom, 12)
    }
}

private struct FlowChips: View {
    let categories: [ExpenseCategory]

    var body: some View {
        FlexibleChipRow(categories: categories)
    }
}

private struct FlexibleChipRow: View {
    let categories: [ExpenseCategory]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories) { category in
                    CategoryChip(category: category)
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
        .previewShareNPay(onboarded: false)
}
