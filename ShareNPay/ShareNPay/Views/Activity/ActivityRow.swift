import SwiftUI

struct ActivityRow: View {
    @Environment(PaymentService.self) private var service
    let payment: Payment
    let delta: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(payment.note)
                    .font(SNP.display(21))
                    .tracking(-0.4)
                    .foregroundStyle(SNP.text)
                    .lineLimit(2)
                Spacer(minLength: 12)
                if payment.status == .settled {
                    Text("Paid")
                        .font(SNP.money(28, weight: .medium))
                        .foregroundStyle(SNP.textMuted)
                } else {
                    MoneyLabel(cents: shownAmount, signed: delta != 0, size: 28)
                }
            }
            Text(whoLine)
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
                .lineLimit(2)
            if payment.isRecurring, let due = Recurrence.dueCopy(
                nextDueAt: payment.nextDueAt,
                isRecurring: true,
                settled: payment.status == .settled
            ) {
                Text(due)
                    .font(.subheadline)
                    .foregroundStyle(SNP.textMuted)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
    }

    private var shownAmount: Int {
        if delta != 0 { return delta }
        return payment.amountCents
    }

    private var whoLine: String {
        if payment.status == .settled {
            let payer = payment.payer?.isCurrentUser == true ? "You" : (payment.payer?.firstName ?? "Someone")
            return "\(payer) paid · everyone is clear"
        }
        let unpaid = payment.splits.filter { $0.person?.id != payment.payer?.id && !$0.settled }
        let names = unpaid.compactMap { share -> String? in
            guard let person = share.person else { return nil }
            return person.isCurrentUser ? "You" : person.firstName
        }
        if names.isEmpty {
            return "Everyone is clear"
        }
        if delta < 0, let payer = payment.payer {
            return "You owe \(payer.firstName)"
        }
        if delta > 0 {
            return names.joined(separator: ", ") + (names.count == 1 ? " owes you" : " owe you")
        }
        return names.joined(separator: ", ")
    }
}
