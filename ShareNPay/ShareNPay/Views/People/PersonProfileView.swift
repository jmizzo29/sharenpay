import SwiftData
import SwiftUI

struct PersonProfileView: View {
    @Environment(PaymentService.self) private var service
    let person: Person

    @State private var compose: PaymentKind?
    @State private var confirmSettle = false
    @Query(sort: \Payment.createdAt, order: .reverse) private var payments: [Payment]

    var body: some View {
        ZStack {
            SNP.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    identity
                    balanceCard
                    actions
                    sharedActivity
                }
                .padding(20)
            }
        }
        .navigationTitle(person.firstName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $compose) { kind in
            PayRequestView(kind: kind, initialPerson: person)
        }
        .confirmationDialog(
            "Settle up with \(person.firstName)?",
            isPresented: $confirmSettle,
            titleVisibility: .visible
        ) {
            Button("Settle up", role: .destructive) {
                service.settleUp(with: person)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Closes open shares with \(person.firstName) on the mock ledger.")
        }
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 12) {
            AvatarView(person: person, size: 76)
            Text(person.displayName)
                .font(.title.weight(.bold))
                .foregroundStyle(SNP.text)
            Text("@\(person.handle) · \(person.kind.sectionTitle)")
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
            Text(person.blurb)
                .font(.body)
                .foregroundStyle(SNP.text)
        }
    }

    private var balanceCard: some View {
        let net = service.netCents(with: person)
        return CardSurface {
            VStack(alignment: .leading, spacing: 6) {
                Text("Open with \(person.firstName)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SNP.textMuted)
                if net == 0 {
                    Text("You’re square.")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(SNP.text)
                } else {
                    MoneyLabel(cents: net, signed: true, size: 32)
                    Text(net > 0 ? "They owe you." : "You owe them.")
                        .font(.subheadline)
                        .foregroundStyle(SNP.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                compose = .pay
            } label: {
                Label("Pay", systemImage: "arrow.up.right")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(SNP.accent)
            Button {
                compose = .request
            } label: {
                Label("Request", systemImage: "arrow.down.left")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(SNP.textMuted)
            if service.netCents(with: person) != 0 {
                Button {
                    confirmSettle = true
                } label: {
                    Image(systemName: "checkmark.circle")
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.bordered)
                .tint(SNP.positive)
                .accessibilityLabel("Settle up")
            }
        }
    }

    private var sharedActivity: some View {
        let mine = payments.filter { payment in
            payment.participants.contains(where: { $0.id == person.id })
        }
        return VStack(alignment: .leading, spacing: 10) {
            Text("Shared activity")
                .font(.headline)
                .foregroundStyle(SNP.text)
            if mine.isEmpty {
                Text("No shares yet.")
                    .foregroundStyle(SNP.textMuted)
            } else {
                ForEach(mine, id: \.id) { payment in
                    NavigationLink {
                        PaymentDetailView(payment: payment)
                    } label: {
                        CardSurface {
                            ActivityRow(payment: payment, delta: service.viewerDelta(for: payment))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
