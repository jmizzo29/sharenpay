import SwiftUI
import UIKit

struct PaymentDetailView: View {
    @Environment(PaymentService.self) private var service
    let payment: Payment

    @State private var draft = ""
    @State private var showSettle = false

    var body: some View {
        ZStack {
            SNP.background.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        splitCard
                        actions
                        thread
                    }
                    .padding(16)
                }
                composer
            }
        }
        .navigationTitle(payment.category.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSettle) {
            if let payee = payment.payer, let me = service.currentUser, let share = service.share(for: me, in: payment) {
                SettleOutsideSheet(
                    payee: payee,
                    cents: share.amountCents,
                    billNote: payment.note,
                    household: service.householdName
                ) {
                    service.markSharePaid(payment)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(payment.category.shortTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SNP.textMuted)
                StatusPill(status: payment.status)
            }
            Text(payment.note)
                .font(.title3.weight(.bold))
                .foregroundStyle(SNP.text)
            MoneyLabel(cents: payment.amountCents, size: 32)
            Text(storyline)
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
        }
    }

    private var storyline: String {
        let payer = payment.payer?.isCurrentUser == true ? "You" : (payment.payer?.displayName ?? "Someone")
        let when = payment.createdAt.formatted(date: .abbreviated, time: .omitted)
        return "\(payer) paid · \(when)"
    }

    private var splitCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("Shares")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SNP.textMuted)
                ForEach(payment.sortedSplits, id: \.persistentModelID) { share in
                    if let person = share.person {
                        HStack {
                            AvatarView(person: person, size: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(person.isCurrentUser ? "You" : person.displayName)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(SNP.text)
                                Text(role(for: person, share: share))
                                    .font(.caption)
                                    .foregroundStyle(SNP.textMuted)
                            }
                            Spacer()
                            MoneyLabel(cents: share.amountCents, size: 16)
                        }
                    }
                }
            }
        }
    }

    private func role(for person: Person, share: SplitShare) -> String {
        if person.id == payment.payer?.id { return "Paid the bill" }
        if share.settled { return "Paid" }
        if share.agreed { return "That's their share · unpaid" }
        return "Needs to confirm"
    }

    @ViewBuilder
    private var actions: some View {
        if service.canAgree(payment) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                service.agree(payment)
            } label: {
                Text("Yes, that's my share")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(SNP.accent)
        }

        if service.canMarkOwnSharePaid(payment) {
            Button {
                showSettle = true
            } label: {
                Text("Pay outside")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(SNP.accent)
        }

        if payment.status == .settled {
            Text("This bill is paid.")
                .font(.footnote)
                .foregroundStyle(SNP.textMuted)
        } else if payment.status == .pending, !service.canAgree(payment), !service.canMarkOwnSharePaid(payment) {
            Text(waitingCopy)
                .font(.footnote)
                .foregroundStyle(SNP.textMuted)
        }
    }

    private var waitingCopy: String {
        let names = service.requiredApprovers(for: payment)
            .filter { service.share(for: $0, in: payment)?.agreed != true }
            .map(\.firstName)
        if names.isEmpty { return "Waiting for roommates to pay outside the app." }
        return "Waiting on \(names.joined(separator: ", ")) to confirm."
    }

    private var thread: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Discuss")
                .font(.headline)
                .foregroundStyle(SNP.text)
            ForEach(payment.sortedMessages, id: \.persistentModelID) { message in
                threadBubble(message)
            }
        }
    }

    @ViewBuilder
    private func threadBubble(_ message: ThreadMessage) -> some View {
        if message.isSystem {
            Text(message.body)
                .font(.caption)
                .foregroundStyle(SNP.textMuted)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        } else {
            let mine = message.author?.isCurrentUser == true
            HStack(alignment: .bottom, spacing: 8) {
                if mine { Spacer(minLength: 36) }
                if !mine, let author = message.author {
                    AvatarView(person: author, size: 26)
                }
                VStack(alignment: mine ? .trailing : .leading, spacing: 4) {
                    if !mine {
                        Text(message.author?.firstName ?? "")
                            .font(.caption2)
                            .foregroundStyle(SNP.textMuted)
                    }
                    Text(message.body)
                        .font(.body)
                        .foregroundStyle(mine ? Color.white : SNP.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            mine ? SNP.accent : SNP.fill,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                }
                if !mine { Spacer(minLength: 36) }
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Message the house", text: $draft, axis: .vertical)
                .lineLimit(1...3)
                .padding(10)
                .background(SNP.fill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Button {
                service.addMessage(draft, to: payment)
                draft = ""
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? SNP.hairline : SNP.accent)
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send")
        }
        .padding(12)
        .background(SNP.background)
    }
}
