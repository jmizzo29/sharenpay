import SwiftUI

struct ActivityRow: View {
    let payment: Payment
    let delta: Int

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(payment.category.tint.opacity(0.16))
                    .frame(width: 48, height: 48)
                Image(systemName: payment.category.symbol)
                    .foregroundStyle(payment.category.tint)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(payment.note)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(SNP.text)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(SNP.textMuted)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    StatusPill(status: payment.status)
                    Text(payment.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(SNP.textMuted)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 6) {
                if payment.status == .settled {
                    MoneyLabel(cents: payment.amountCents, size: 17, tint: SNP.textMuted)
                } else {
                    MoneyLabel(cents: delta == 0 ? payment.amountCents : delta, signed: delta != 0, size: 17)
                }
                AvatarStack(people: payment.otherPeople, size: 22)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let names = payment.otherPeople.map(\.firstName).joined(separator: ", ")
        switch payment.kind {
        case .sharedExpense:
            let payer = payment.payer?.isCurrentUser == true ? "You" : (payment.payer?.firstName ?? "Someone")
            return "\(payer) paid · \(payment.participants.count) people · \(payment.category.shortTitle)"
        case .pay:
            if payment.payer?.isCurrentUser == true {
                return "You paid \(payment.recipient?.firstName ?? "someone") · \(payment.category.shortTitle)"
            }
            return "\(payment.payer?.firstName ?? "Someone") paid you · \(payment.category.shortTitle)"
        case .request:
            if payment.payer?.isCurrentUser == true {
                return "\(names) requested · \(payment.category.shortTitle)"
            }
            return "You requested \(payment.payer?.firstName ?? "someone") · \(payment.category.shortTitle)"
        }
    }
}
