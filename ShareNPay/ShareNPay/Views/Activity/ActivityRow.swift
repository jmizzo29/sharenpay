import SwiftUI

struct ActivityRow: View {
    @Environment(PaymentService.self) private var service
    let payment: Payment
    let delta: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.note)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(SNP.text)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(SNP.textMuted)
                HStack(spacing: 8) {
                    StatusPill(status: rowStatus)
                    Text(shareLine)
                        .font(.caption)
                        .foregroundStyle(SNP.textMuted)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                MoneyLabel(cents: payment.amountCents, size: 16)
                if payment.status != .settled, delta != 0 {
                    MoneyLabel(cents: delta, signed: true, size: 13, tint: SNP.textMuted)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let payer = payment.payer?.isCurrentUser == true ? "You" : (payment.payer?.firstName ?? "Someone")
        return "\(payer) paid · \(payment.category.shortTitle) · \(payment.participants.count) people"
    }

    private var rowStatus: PaymentStatus {
        if payment.status == .settled { return .settled }
        if let me = service.currentUser, service.share(for: me, in: payment)?.settled == true, me.id != payment.payer?.id {
            return .settled
        }
        return payment.status
    }

    private var shareLine: String {
        let unpaid = payment.splits.filter { $0.person?.id != payment.payer?.id && !$0.settled }
        if payment.status == .settled || unpaid.isEmpty {
            return "All paid"
        }
        let names = unpaid.compactMap { $0.person?.isCurrentUser == true ? "You" : $0.person?.firstName }
        return "Unpaid: \(names.joined(separator: ", "))"
    }
}
