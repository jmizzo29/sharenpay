import SwiftUI

struct PayRequestView: View {
    @Environment(PaymentService.self) private var service
    @Environment(\.dismiss) private var dismiss

    let kind: PaymentKind
    var initialPerson: Person? = nil
    var onCreated: (Payment?) -> Void = { _ in }

    @State private var note = ""
    @State private var cents = 0
    @State private var category: ExpenseCategory = .friendsFamily
    @State private var personID: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                SNP.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text(kind == .pay
                             ? "Send a single person an amount. They agree, then you settle the mock ledger."
                             : "Ask one person for an amount. They agree, then you settle the mock ledger.")
                            .font(.subheadline)
                            .foregroundStyle(SNP.textMuted)
                        AmountField(cents: $cents)
                        TextField(kind == .pay ? "What’s this for?" : "What are you asking for?", text: $note, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(14)
                            .background(SNP.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(SNP.hairline, lineWidth: 1)
                            }
                            .onChange(of: note) { _, value in
                                if value.count > 160 { note = String(value.prefix(160)) }
                            }
                        categoryRow
                        personList
                        Button(action: submit) {
                            Text(kind == .pay ? "Send pay request" : "Send request")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SNP.accent)
                        .disabled(!canSubmit)
                    }
                    .padding(20)
                }
            }
            .onAppear {
                if personID == nil {
                    personID = initialPerson?.id
                }
            }
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var categoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ExpenseCategory.allCases) { item in
                    CategoryChip(category: item, selected: category == item) {
                        category = item
                    }
                }
            }
        }
    }

    private var personList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(kind == .pay ? "Pay whom" : "Request from")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SNP.textMuted)
            ForEach(service.network.filter { !$0.isCurrentUser }, id: \.id) { person in
                Button {
                    personID = person.id
                } label: {
                    HStack(spacing: 12) {
                        AvatarView(person: person, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.displayName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(SNP.text)
                            Text(person.kind == .business ? "Small business" : "@\(person.handle)")
                                .font(.caption)
                                .foregroundStyle(SNP.textMuted)
                        }
                        Spacer()
                        Image(systemName: personID == person.id ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(personID == person.id ? SNP.accent : SNP.hairline)
                    }
                    .padding(10)
                    .background(SNP.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var canSubmit: Bool {
        cents > 0
            && personID != nil
            && !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() {
        guard let person = service.network.first(where: { $0.id == personID }) else { return }
        let payment: Payment?
        if kind == .pay {
            payment = service.createPay(to: person, amountCents: cents, note: note, category: category)
        } else {
            payment = service.createRequest(from: person, amountCents: cents, note: note, category: category)
        }
        dismiss()
        onCreated(payment)
    }
}
