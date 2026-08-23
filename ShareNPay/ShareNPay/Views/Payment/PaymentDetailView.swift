import SwiftUI
import UIKit

struct PaymentDetailView: View {
    @Environment(PaymentService.self) private var service
    let payment: Payment

    @State private var draft = ""
    @FocusState private var composerFocused: Bool

    var body: some View {
        ZStack {
            SNP.background.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        splitCard
                        actions
                        thread
                    }
                    .padding(20)
                }
                composer
            }
        }
        .navigationTitle(payment.kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CategoryChip(category: payment.category, selected: true)
                StatusPill(status: payment.status)
                Spacer()
            }
            Text(payment.note)
                .font(.title2.weight(.bold))
                .foregroundStyle(SNP.text)
            MoneyLabel(cents: payment.amountCents, size: 40)
            Text(storyline)
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
            if payment.status != .settled {
                let delta = service.viewerDelta(for: payment)
                if delta != 0 {
                    MoneyLabel(cents: delta, signed: true, size: 20)
                }
            }
        }
    }

    private var storyline: String {
        let when = payment.createdAt.formatted(date: .abbreviated, time: .shortened)
        switch payment.kind {
        case .sharedExpense:
            let payer = payment.payer?.isCurrentUser == true ? "You" : (payment.payer?.displayName ?? "Someone")
            return "\(payer) covered the bill · \(payment.participants.count) people · \(when)"
        case .pay:
            return "Pay · \(when)"
        case .request:
            return "Request · \(when)"
        }
    }

    private var splitCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text(payment.kind == .sharedExpense ? "Who owes whom" : "The two seats")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SNP.textMuted)
                ForEach(payment.sortedSplits, id: \.persistentModelID) { share in
                    if let person = share.person {
                        HStack {
                            AvatarView(person: person, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(person.isCurrentUser ? "You" : person.displayName)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(SNP.text)
                                Text(role(for: person, share: share))
                                    .font(.caption)
                                    .foregroundStyle(SNP.textMuted)
                            }
                            Spacer()
                            MoneyLabel(cents: share.amountCents, size: 17)
                        }
                    }
                }
            }
        }
    }

    private func role(for person: Person, share: SplitShare) -> String {
        if payment.status == .settled { return "Settled" }
        if payment.kind == .sharedExpense, person.id == payment.payer?.id {
            return "Covered the bill"
        }
        if share.agreed { return "Agreed" }
        return "Waiting to agree"
    }

    @ViewBuilder
    private var actions: some View {
        if service.canAgree(payment) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                service.agree(payment)
            } label: {
                Label("Agree with this share", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(SNP.accentDeep)
        }

        if service.canSettle(payment) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                service.settle(payment)
            } label: {
                Label("Settle on the mock ledger", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(SNP.positive)
        }

        if payment.status == .settled {
            Label("This one is closed. History stays so you always know who paid.", systemImage: "lock.fill")
                .font(.footnote)
                .foregroundStyle(SNP.textMuted)
        } else if payment.status == .pending, !service.canAgree(payment) {
            Text("Waiting on \(waitingNames) to agree. Keep talking in the thread — that’s the product.")
                .font(.footnote)
                .foregroundStyle(SNP.textMuted)
        }
    }

    private var waitingNames: String {
        service.requiredApprovers(for: payment)
            .filter { service.share(for: $0, in: payment)?.agreed != true }
            .map(\.firstName)
            .joined(separator: ", ")
    }

    private var thread: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The thread")
                .font(.headline)
                .foregroundStyle(SNP.text)
            Text("Split, discuss, agree, approve. Not a public feed.")
                .font(.caption)
                .foregroundStyle(SNP.textMuted)
            ForEach(payment.sortedMessages, id: \.persistentModelID) { message in
                threadBubble(message)
            }
        }
    }

    @ViewBuilder
    private func threadBubble(_ message: ThreadMessage) -> some View {
        if message.isSystem {
            HStack {
                Spacer(minLength: 24)
                Text(message.body)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SNP.textMuted)
                    .multilineTextAlignment(.center)
                Spacer(minLength: 24)
            }
            .padding(.vertical, 4)
        } else {
            let mine = message.author?.isCurrentUser == true
            HStack(alignment: .bottom, spacing: 8) {
                if mine { Spacer(minLength: 36) }
                if !mine, let author = message.author {
                    AvatarView(person: author, size: 28)
                }
                VStack(alignment: mine ? .trailing : .leading, spacing: 4) {
                    if !mine {
                        Text(message.author?.firstName ?? "Someone")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(SNP.textMuted)
                    }
                    Text(message.body)
                        .font(.body)
                        .foregroundStyle(mine ? .white : SNP.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            mine ? SNP.accent : SNP.card,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                    Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(SNP.textMuted)
                }
                if !mine { Spacer(minLength: 36) }
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Talk it through…", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .focused($composerFocused)
                .padding(12)
                .background(SNP.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Button {
                service.addMessage(draft, to: payment)
                draft = ""
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? SNP.hairline : SNP.accent)
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(SNP.background.ignoresSafeArea())
    }
}
