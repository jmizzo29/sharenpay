import SwiftData
import SwiftUI

struct PersonProfileView: View {
    @Environment(PaymentService.self) private var service
    let person: Person

    @State private var showSettle = false
    @Query(sort: \Payment.createdAt, order: .reverse) private var payments: [Payment]

    var body: some View {
        ZStack {
            SNP.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 36) {
                    identity
                    balance
                    sharedBills
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSettle) {
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

    private var identity: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(person.displayName)
                .font(SNP.display(34))
                .foregroundStyle(SNP.text)
            Text(person.blurb)
                .font(.body)
                .foregroundStyle(SNP.textMuted)
        }
    }

    private var balance: some View {
        let net = service.netCents(with: person)
        return VStack(alignment: .leading, spacing: 14) {
            if person.isCurrentUser {
                Text("This is you.")
                    .foregroundStyle(SNP.textMuted)
            } else if net == 0 {
                Text("You’re square.")
                    .font(SNP.display(22))
            } else {
                MoneyLabel(cents: net, signed: true, size: 40)
                Text(net > 0 ? "They owe you." : "You owe them.")
                    .font(.body)
                    .foregroundStyle(SNP.textMuted)
                if net < 0 {
                    Button("Pay outside") { showSettle = true }
                        .buttonStyle(QuietButtonStyle(filled: true))
                } else {
                    Button("Mark paid") { service.settleUp(with: person) }
                        .buttonStyle(QuietButtonStyle())
                }
            }
        }
    }

    private var sharedBills: some View {
        let mine = payments.filter { payment in
            payment.participants.contains(where: { $0.id == person.id })
        }
        return VStack(alignment: .leading, spacing: 0) {
            Text("Shared bills")
                .font(SNP.display(20))
                .padding(.bottom, 4)
            if mine.isEmpty {
                Text("No bills yet.")
                    .foregroundStyle(SNP.textMuted)
                    .padding(.top, 12)
            } else {
                ForEach(mine, id: \.id) { payment in
                    NavigationLink {
                        PaymentDetailView(payment: payment)
                    } label: {
                        ActivityRow(payment: payment, delta: service.viewerDelta(for: payment))
                    }
                    .buttonStyle(.plain)
                    if payment.id != mine.last?.id {
                        Hairline()
                    }
                }
            }
        }
    }
}
