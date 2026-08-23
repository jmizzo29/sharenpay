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
                    VStack(alignment: .leading, spacing: 32) {
                        header
                        whoOwes
                        actions
                        thread
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                composer
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSettle) {
            if let payee = payment.payer, let me = service.currentUser, let share = service.share(for: me, in: payment) {
                SettleOutsideSheet(
                    payee: payee,
                    cents: share.amountCents,
                    billNote: payment.note
                ) {
                    service.markSharePaid(payment)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(payment.category.shortTitle)
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
            Text(payment.note)
                .font(SNP.display(36))
                .tracking(-0.8)
                .foregroundStyle(SNP.text)
            MoneyLabel(cents: payment.amountCents, size: 44)
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

    private var whoOwes: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Who owes")
                .font(SNP.display(20))
                .padding(.bottom, 8)
            ForEach(payment.sortedSplits, id: \.persistentModelID) { share in
                if let person = share.person {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(person.isCurrentUser ? "You" : person.displayName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(SNP.text)
                            Text(payment.oweLine(for: share, viewer: service.currentUser) ?? "")
                                .font(.subheadline)
                                .foregroundStyle(SNP.textMuted)
                            if canCollect(from: person, share: share) {
                                Button("Mark paid") {
                                    withAnimation(SNP.spring) {
                                        service.markSharePaid(payment, person: person)
                                    }
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SNP.accent)
                            }
                        }
                        Spacer()
                        MoneyLabel(cents: share.amountCents, size: 20)
                    }
                    .padding(.vertical, 16)
                    if share.persistentModelID != payment.sortedSplits.last?.persistentModelID {
                        Hairline()
                    }
                }
            }
        }
    }

    private func canCollect(from person: Person, share: SplitShare) -> Bool {
        guard payment.status != .settled, !share.settled else { return false }
        guard let me = service.currentUser, me.id == payment.payer?.id else { return false }
        return person.id != me.id
    }

    @ViewBuilder
    private var actions: some View {
        if service.canAgree(payment) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                service.agree(payment)
            } label: {
                Text("Yes, that’s my share")
            }
            .buttonStyle(QuietButtonStyle(filled: true))
        }

        if service.canMarkOwnSharePaid(payment) {
            Button {
                showSettle = true
            } label: {
                Text("Pay outside")
            }
            .buttonStyle(QuietButtonStyle(filled: true))
        }

        if payment.status == .settled {
            Text("This bill is paid.")
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
        } else if payment.status == .pending, !service.canAgree(payment), !service.canMarkOwnSharePaid(payment) {
            Text(waitingCopy)
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
        }
    }

    private var waitingCopy: String {
        let names = service.requiredApprovers(for: payment)
            .filter { service.share(for: $0, in: payment)?.agreed != true }
            .map(\.firstName)
        if names.isEmpty { return "Waiting for people to pay outside the app." }
        return "Waiting on \(names.joined(separator: ", ")) to confirm."
    }

    private var thread: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(SNP.display(20))
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
        } else {
            let mine = message.author?.isCurrentUser == true
            VStack(alignment: .leading, spacing: 4) {
                Text(mine ? "You" : (message.author?.firstName ?? ""))
                    .font(.caption)
                    .foregroundStyle(SNP.textMuted)
                Text(message.body)
                    .font(.body)
                    .foregroundStyle(SNP.text)
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 12) {
            TextField("Add a note", text: $draft, axis: .vertical)
                .lineLimit(1...3)
                .font(.body)
            Button {
                service.addMessage(draft, to: payment)
                draft = ""
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(canSend ? Color.white : SNP.textMuted)
                    .frame(width: 32, height: 32)
                    .background(canSend ? SNP.accent : Color.clear, in: Circle())
                    .overlay {
                        Circle().strokeBorder(canSend ? SNP.accent : SNP.hairline, lineWidth: 1)
                    }
            }
            .disabled(!canSend)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(.bar)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
