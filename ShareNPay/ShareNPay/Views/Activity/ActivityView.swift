import SwiftData
import SwiftUI

struct ActivityView: View {
    @Environment(PaymentService.self) private var service
    @Query(sort: \Payment.createdAt, order: .reverse) private var payments: [Payment]
    @State private var showProfile = false
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                SNP.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        monthSummary
                        HomeComposer { payment in
                            if let payment { path.append(payment.id) }
                        }
                        bills
                    }
                    .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Wordmark(size: 20)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: {
                        if let me = service.currentUser {
                            AvatarView(person: me, size: 28)
                        }
                    }
                    .accessibilityLabel("Profile")
                }
            }
            .toolbarBackground(SNP.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                if let payment = payments.first(where: { $0.id == id }) {
                    PaymentDetailView(payment: payment)
                }
            }
            .sheet(isPresented: $showProfile) {
                YouView()
            }
        }
    }

    private var monthSummary: some View {
        HStack(spacing: 12) {
            summaryCard("You owe", service.youOweTotal())
            summaryCard("Owed to you", service.owedToYouTotal())
        }
    }

    private func summaryCard(_ title: String, _ cents: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(SNP.textMuted)
            MoneyLabel(cents: cents, size: 22)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(SNP.hairline, lineWidth: 1)
        }
    }

    private var bills: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bills")
                .font(.headline)
                .foregroundStyle(SNP.text)
            if payments.isEmpty {
                Text("No bills yet.")
                    .foregroundStyle(SNP.textMuted)
            } else {
                ForEach(payments, id: \.id) { payment in
                    NavigationLink(value: payment.id) {
                        ActivityRow(payment: payment, delta: service.viewerDelta(for: payment))
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    if payment.id != payments.last?.id {
                        Divider().overlay(SNP.hairline)
                    }
                }
            }
        }
    }
}

struct HomeComposer: View {
    @Environment(PaymentService.self) private var service
    var onCreated: (Payment?) -> Void = { _ in }

    @State private var note = ""
    @State private var cents = 0
    @State private var category: ExpenseCategory = .dinner
    @State private var payerID: UUID?
    @State private var selected: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a bill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SNP.text)
            TextField("Dinner, Uber, rent, concert…", text: $note)
                .onChange(of: note) { _, value in
                    if value.count > 160 { note = String(value.prefix(160)) }
                }
            HStack(alignment: .firstTextBaseline) {
                AmountField(cents: $cents, size: 28)
                Spacer()
                Menu {
                    ForEach(ExpenseCategory.splitCases) { item in
                        Button(item.title) { category = item }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(category.shortTitle)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline)
                    .foregroundStyle(SNP.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(SNP.fill, in: Capsule())
                }
            }
            HStack {
                Text("Paid by")
                    .font(.caption)
                    .foregroundStyle(SNP.textMuted)
                Menu {
                    ForEach(service.people, id: \.id) { person in
                        Button(person.isCurrentUser ? "You" : person.firstName) {
                            payerID = person.id
                        }
                    }
                } label: {
                    Text(payerLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SNP.text)
                }
            }
            Text("Who splits")
                .font(.caption)
                .foregroundStyle(SNP.textMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(service.people, id: \.id) { person in
                        Button {
                            if selected.contains(person.id) {
                                if selected.count > 1 { selected.remove(person.id) }
                            } else {
                                selected.insert(person.id)
                            }
                        } label: {
                            Text(person.isCurrentUser ? "You" : person.firstName)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .foregroundStyle(selected.contains(person.id) ? Color.white : SNP.text)
                                .background(
                                    Capsule().fill(selected.contains(person.id) ? SNP.accent : SNP.fill)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            HStack {
                Text(splitCopy)
                    .font(.caption)
                    .foregroundStyle(SNP.textMuted)
                Spacer()
                Button("Add bill") { post() }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .foregroundStyle(canPost ? Color.white : SNP.textMuted)
                    .background(canPost ? SNP.accent : SNP.fill, in: Capsule())
                    .disabled(!canPost)
            }
        }
        .padding(14)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(SNP.hairline, lineWidth: 1)
        }
        .onAppear {
            if selected.isEmpty, let me = service.currentUser {
                selected = [me.id]
            }
            if payerID == nil {
                payerID = service.currentUser?.id
            }
        }
    }

    private var payerLabel: String {
        let person = service.people.first { $0.id == payerID }
        if person?.isCurrentUser == true { return "You" }
        return person?.firstName ?? "You"
    }

    private var splitCopy: String {
        guard selected.count >= 2, cents > 0 else {
            return "Pick who split this. Even split."
        }
        let parts = LedgerMath.evenSplit(totalCents: cents, participantCount: selected.count)
        let each = parts.first ?? 0
        return "\(selected.count) people · \(LedgerMath.currencyString(cents: each)) each"
    }

    private var canPost: Bool {
        cents > 0 && selected.count >= 2 && !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func post() {
        let people = service.people.filter { selected.contains($0.id) }
        let payer = service.people.first { $0.id == payerID }
        let payment = service.createSharedExpense(
            note: note,
            amountCents: cents,
            category: category,
            payer: payer,
            people: people
        )
        note = ""
        cents = 0
        onCreated(payment)
    }
}

#Preview {
    ActivityView()
        .previewShareNPay()
}
