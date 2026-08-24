import SwiftUI

struct BalancesView: View {
    @Environment(PaymentService.self) private var service
    @State private var path: [UUID] = []
    @State private var settlePerson: Person?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                SNP.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 36) {
                        HStack(alignment: .top, spacing: 28) {
                            totalColumn("You owe", service.youOweTotal())
                            totalColumn("Owed to you", service.owedToYouTotal())
                        }
                        openList
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Ledger")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: UUID.self) { id in
                if let person = service.people.first(where: { $0.id == id }) {
                    PersonProfileView(person: person)
                }
            }
            .sheet(isPresented: Binding(
                get: { settlePerson != nil },
                set: { if !$0 { settlePerson = nil } }
            )) {
                if let person = settlePerson {
                    let net = service.netCents(with: person)
                    SettleOutsideSheet(
                        payee: person,
                        cents: abs(net),
                        billNote: "Shared bills"
                    ) {
                        service.settleUp(with: person)
                    }
                }
            }
        }
    }

    private func totalColumn(_ title: String, _ cents: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
            MoneyLabel(cents: cents, size: 40)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var openList: some View {
        let rows = service.balances()
        if rows.isEmpty {
            Text("All square.")
                .font(.body)
                .foregroundStyle(SNP.textMuted)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(rows, id: \.person.id) { row in
                    VStack(alignment: .leading, spacing: 14) {
                        Button {
                            path.append(row.person.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(row.person.displayName)
                                    .font(SNP.display(22))
                                    .foregroundStyle(SNP.text)
                                MoneyLabel(cents: row.cents, signed: true, size: 28)
                                Text(row.cents > 0 ? "owes you" : "you owe")
                                    .font(.subheadline)
                                    .foregroundStyle(SNP.textMuted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        if row.cents < 0 {
                            Button("Pay outside") {
                                settlePerson = row.person
                            }
                            .buttonStyle(QuietButtonStyle(filled: true))
                        } else {
                            Button("Mark paid") {
                                service.settleUp(with: row.person)
                            }
                            .buttonStyle(QuietButtonStyle())
                        }
                    }
                    .padding(.vertical, 20)
                    if row.person.id != rows.last?.person.id {
                        Hairline()
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
