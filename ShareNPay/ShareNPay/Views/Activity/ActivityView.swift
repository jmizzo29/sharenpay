import SwiftData
import SwiftUI
import UIKit

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
                    VStack(alignment: .leading, spacing: 40) {
                        monthSummary
                        HomeComposer { payment in
                            if let payment { path.append(payment.id) }
                        }
                        bills
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Wordmark(size: 22)
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
        HStack(alignment: .top, spacing: 28) {
            summaryColumn("You owe", service.youOweTotal())
            summaryColumn("Owed to you", service.owedToYouTotal())
        }
    }

    private func summaryColumn(_ title: String, _ cents: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
            MoneyLabel(cents: cents, size: 40)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bills: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Bills")
                .font(SNP.display(20))
                .foregroundStyle(SNP.text)
                .padding(.bottom, 4)
            if payments.isEmpty {
                Text("No bills yet.")
                    .font(.body)
                    .foregroundStyle(SNP.textMuted)
                    .padding(.top, 16)
            } else {
                ForEach(payments, id: \.id) { payment in
                    NavigationLink(value: payment.id) {
                        ActivityRow(payment: payment, delta: service.viewerDelta(for: payment))
                    }
                    .buttonStyle(.plain)
                    if payment.id != payments.last?.id {
                        Hairline()
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
        FieldChrome {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Dinner, Uber, rent, concert…", text: $note)
                    .font(SNP.display(20, weight: .regular))
                    .onChange(of: note) { _, value in
                        if value.count > 160 { note = String(value.prefix(160)) }
                    }
                HStack(alignment: .firstTextBaseline) {
                    AmountField(cents: $cents, size: 34)
                    Spacer(minLength: 12)
                    Menu {
                        ForEach(ExpenseCategory.splitCases) { item in
                            Button(item.title) { category = item }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Text(category.shortTitle)
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.semibold))
                        }
                        .font(.subheadline)
                        .foregroundStyle(SNP.textMuted)
                    }
                }
                HStack(spacing: 8) {
                    ForEach(service.people, id: \.id) { person in
                        Button {
                            withAnimation(SNP.spring) {
                                if selected.contains(person.id) {
                                    if selected.count > 1 { selected.remove(person.id) }
                                } else {
                                    selected.insert(person.id)
                                }
                            }
                        } label: {
                            Text(person.isCurrentUser ? "You" : person.firstName)
                                .font(.subheadline.weight(selected.contains(person.id) ? .semibold : .regular))
                                .foregroundStyle(selected.contains(person.id) ? SNP.text : SNP.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 8)
                    Menu {
                        ForEach(service.people, id: \.id) { person in
                            Button(person.isCurrentUser ? "You" : person.firstName) {
                                payerID = person.id
                            }
                        }
                    } label: {
                        Text("Paid by \(payerLabel)")
                            .font(.subheadline)
                            .foregroundStyle(SNP.textMuted)
                    }
                }
                HStack(alignment: .center) {
                    Text(splitCopy)
                        .font(.subheadline)
                        .foregroundStyle(SNP.textMuted)
                        .contentTransition(.opacity)
                    Spacer()
                    Button("Add") { post() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(canPost ? Color.white : SNP.textMuted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(canPost ? SNP.accent : Color.clear, in: Capsule())
                        .overlay {
                            Capsule().strokeBorder(canPost ? SNP.accent : SNP.hairline, lineWidth: 1)
                        }
                        .disabled(!canPost)
                }
            }
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
        if person?.isCurrentUser == true { return "you" }
        return person?.firstName ?? "you"
    }

    private var splitCopy: String {
        guard selected.count >= 2, cents > 0 else {
            return "Who splits · even"
        }
        let parts = LedgerMath.evenSplit(totalCents: cents, participantCount: selected.count)
        let each = parts.first ?? 0
        return "\(selected.count) · \(LedgerMath.currencyString(cents: each)) each"
    }

    private var canPost: Bool {
        cents > 0 && selected.count >= 2 && !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func post() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
