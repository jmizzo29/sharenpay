import SwiftUI

struct ActivityRow: View {
    @Environment(PaymentService.self) private var service
    let payment: Payment
    let delta: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(payment.note)
                .font(SNP.display(22))
                .foregroundStyle(SNP.text)
                .lineLimit(2)
            if payment.status == .settled {
                Text("Paid")
                    .font(SNP.money(28, weight: .medium))
                    .foregroundStyle(SNP.textMuted)
            } else {
                MoneyLabel(cents: shownAmount, signed: delta != 0, size: 28)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(whoLine)
                    .font(.subheadline)
                    .foregroundStyle(SNP.textMuted)
                    .lineLimit(2)
                Spacer(minLength: 8)
                StatusPill(status: rowStatus)
            }
        }
        .padding(.vertical, 18)
        .accessibilityElement(children: .combine)
    }

    private var shownAmount: Int {
        if delta != 0 { return delta }
        return payment.amountCents
    }

    private var rowStatus: PaymentStatus {
        if payment.status == .settled { return .settled }
        if let me = service.currentUser, service.share(for: me, in: payment)?.settled == true, me.id != payment.payer?.id {
            return .settled
        }
        return payment.status
    }

    private var whoLine: String {
        if payment.status == .settled {
            let payer = payment.payer?.isCurrentUser == true ? "You" : (payment.payer?.firstName ?? "Someone")
            return "\(payer) paid · \(payment.participants.count) people"
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
        return "Unpaid: \(names.joined(separator: ", "))"
    }
}
