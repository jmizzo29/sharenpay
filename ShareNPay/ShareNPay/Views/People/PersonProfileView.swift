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
                VStack(alignment: .leading, spacing: 16) {
                    identity
                    balance
                    sharedBills
                }
                .padding(16)
            }
        }
        .navigationTitle(person.isCurrentUser ? "You" : person.firstName)
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
            AvatarView(person: person, size: 64)
            Text(person.displayName)
                .font(.title2.weight(.bold))
                .foregroundStyle(SNP.text)
            Text(person.blurb)
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
        }
    }

    private var balance: some View {
        let net = service.netCents(with: person)
        return VStack(alignment: .leading, spacing: 10) {
            if person.isCurrentUser {
                Text("This is you.")
                    .foregroundStyle(SNP.textMuted)
            } else if net == 0 {
                Text("You’re square.")
                    .font(.headline)
            } else {
                MoneyLabel(cents: net, signed: true, size: 28)
                Text(net > 0 ? "They owe you." : "You owe them.")
                    .font(.subheadline)
                    .foregroundStyle(SNP.textMuted)
                if net < 0 {
                    Button("Pay outside") { showSettle = true }
                        .buttonStyle(.borderedProminent)
                        .tint(SNP.accent)
                } else {
                    Button("Mark paid") { service.settleUp(with: person) }
                        .buttonStyle(.bordered)
                        .tint(SNP.accent)
                }
            }
        }
    }

    private var sharedBills: some View {
        let mine = payments.filter { payment in
            payment.participants.contains(where: { $0.id == person.id })
        }
        return VStack(alignment: .leading, spacing: 10) {
            Text("Shared bills")
                .font(.headline)
            if mine.isEmpty {
                Text("No bills yet.")
                    .foregroundStyle(SNP.textMuted)
            } else {
                ForEach(mine, id: \.id) { payment in
                    NavigationLink {
                        PaymentDetailView(payment: payment)
                    } label: {
                        ActivityRow(payment: payment, delta: service.viewerDelta(for: payment))
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
