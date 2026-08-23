import SwiftUI

struct BalancesView: View {
    @Environment(PaymentService.self) private var service
    @State private var path: [UUID] = []
    @State private var settleRoommate: Person?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                SNP.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            totalCard("You owe", service.youOweTotal())
                            totalCard("Owed to you", service.owedToYouTotal())
                        }
                        openList
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Ledger")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { id in
                if let person = service.household.first(where: { $0.id == id }) {
                    PersonProfileView(person: person)
                }
            }
            .sheet(isPresented: Binding(
                get: { settleRoommate != nil },
                set: { if !$0 { settleRoommate = nil } }
            )) {
                if let person = settleRoommate {
                    let net = service.netCents(with: person)
                    SettleOutsideSheet(
                        payee: person,
                        cents: abs(net),
                        billNote: "House ledger",
                        household: service.householdName
                    ) {
                        service.settleUp(with: person)
                    }
                }
            }
        }
    }

    private func totalCard(_ title: String, _ cents: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(SNP.textMuted)
            MoneyLabel(cents: cents, size: 22)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(SNP.hairline, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var openList: some View {
        let rows = service.balances()
        if rows.isEmpty {
            Text("All square.")
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
        } else {
            ForEach(rows, id: \.person.id) { row in
                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        path.append(row.person.id)
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(person: row.person, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.person.displayName)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(SNP.text)
                                Text(row.cents > 0 ? "owes you" : "you owe")
                                    .font(.caption)
                                    .foregroundStyle(SNP.textMuted)
                            }
                            Spacer()
                            MoneyLabel(cents: row.cents, signed: true, size: 18)
                        }
                    }
                    .buttonStyle(.plain)
                    if row.cents < 0 {
                        Button("Pay outside") {
                            settleRoommate = row.person
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(SNP.accent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        Button("Mark paid") {
                            service.settleUp(with: row.person)
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(SNP.text)
                        .background(SNP.fill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .padding(14)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(SNP.hairline, lineWidth: 1)
                }
            }
        }
    }
}

#Preview {
    BalancesView()
        .previewShareNPay()
}
