import SwiftUI

struct BalancesView: View {
    @Environment(PaymentService.self) private var service
    @State private var settleTarget: Person?
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                SNP.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        totals
                        openList
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Who owes whom")
                        .font(.headline)
                        .foregroundStyle(SNP.text)
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let person = service.network.first(where: { $0.id == id }) {
                    PersonProfileView(person: person)
                }
            }
            .confirmationDialog(
                "Settle up on the mock ledger?",
                isPresented: Binding(
                    get: { settleTarget != nil },
                    set: { if !$0 { settleTarget = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Settle up", role: .destructive) {
                    if let person = settleTarget {
                        service.settleUp(with: person)
                    }
                    settleTarget = nil
                }
                Button("Cancel", role: .cancel) { settleTarget = nil }
            } message: {
                Text("Closes every open share with this person. No real money moves.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("The running tab")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(SNP.text)
            Text("Reminders stay until you agree and settle. This is a ledger, not a bank.")
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
        }
    }

    private var totals: some View {
        HStack(spacing: 12) {
            totalCard("You owe", service.youOweTotal(), SNP.accent)
            totalCard("Owed to you", service.owedToYouTotal(), SNP.positive)
        }
    }

    private func totalCard(_ title: String, _ cents: Int, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SNP.textMuted)
            MoneyLabel(cents: cents, size: 24, tint: tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(SNP.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(SNP.hairline, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var openList: some View {
        let rows = service.balances()
        if rows.isEmpty {
            CardSurface {
                VStack(alignment: .leading, spacing: 8) {
                    Text("All square")
                        .font(.headline)
                        .foregroundStyle(SNP.text)
                    Text("Nobody owes anyone on the open ledger. New shares will show up here until they’re settled.")
                        .font(.subheadline)
                        .foregroundStyle(SNP.textMuted)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Open with people")
                    .font(.headline)
                    .foregroundStyle(SNP.text)
                ForEach(rows, id: \.person.id) { row in
                    CardSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                path.append(row.person.id)
                            } label: {
                                HStack(spacing: 12) {
                                    AvatarView(person: row.person, size: 48)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(row.person.displayName)
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(SNP.text)
                                        Text(row.cents > 0 ? "owes you" : "you owe")
                                            .font(.caption)
                                            .foregroundStyle(SNP.textMuted)
                                    }
                                    Spacer()
                                    MoneyLabel(cents: row.cents, signed: true, size: 22)
                                }
                            }
                            .buttonStyle(.plain)
                            Button {
                                settleTarget = row.person
                            } label: {
                                Text("Settle up")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(row.cents > 0 ? SNP.positive : SNP.accent)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    BalancesView()
        .previewShareNPay()
}
