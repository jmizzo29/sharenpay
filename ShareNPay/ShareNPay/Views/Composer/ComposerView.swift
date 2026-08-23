import SwiftUI

struct ComposerView: View {
    @Environment(PaymentService.self) private var service
    @Environment(\.dismiss) private var dismiss

    var onCreated: (Payment?) -> Void = { _ in }

    @State private var note = ""
    @State private var cents = 0
    @State private var category: ExpenseCategory = .restaurant
    @State private var selected: Set<UUID> = []

    private let limit = 160

    var body: some View {
        NavigationStack {
            ZStack {
                SNP.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text("Like a tweet — a note, a category, an amount, the people at the table.")
                            .font(.subheadline)
                            .foregroundStyle(SNP.textMuted)
                        noteEditor
                        AmountField(cents: $cents)
                        categoryRow
                        peoplePicker
                        splitPreview
                        postButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("What did you share?", text: $note, axis: .vertical)
                .lineLimit(3...5)
                .font(.title3)
                .padding(14)
                .background(SNP.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(SNP.hairline, lineWidth: 1)
                }
                .onChange(of: note) { _, value in
                    if value.count > limit {
                        note = String(value.prefix(limit))
                    }
                }
            Text("\(note.count)/\(limit)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(SNP.textMuted)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var categoryRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Account")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SNP.textMuted)
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
    }

    private var peoplePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Who’s in")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SNP.textMuted)
            ForEach(service.network.filter { !$0.isCurrentUser }, id: \.id) { person in
                Button {
                    if selected.contains(person.id) {
                        selected.remove(person.id)
                    } else {
                        selected.insert(person.id)
                    }
                } label: {
                    HStack(spacing: 12) {
                        AvatarView(person: person, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.displayName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(SNP.text)
                            Text("@\(person.handle) · \(person.kind.sectionTitle)")
                                .font(.caption)
                                .foregroundStyle(SNP.textMuted)
                        }
                        Spacer()
                        Image(systemName: selected.contains(person.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected.contains(person.id) ? SNP.accent : SNP.hairline)
                            .font(.title3)
                    }
                    .padding(10)
                    .background(SNP.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var splitPreview: some View {
        let count = selected.count + 1
        let parts = LedgerMath.evenSplit(totalCents: cents, participantCount: max(count, 1))
        let high = parts.first ?? 0
        let low = parts.last ?? 0
        let splitCopy = high == low
            ? "\(count) people · \(LedgerMath.currencyString(cents: high)) each"
            : "\(count) people · \(LedgerMath.currencyString(cents: high)) and \(LedgerMath.currencyString(cents: low))"
        return CardSurface {
            VStack(alignment: .leading, spacing: 8) {
                Text("Even split")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SNP.accent)
                if selected.isEmpty {
                    Text("Add at least one friend, family member, or business.")
                        .font(.subheadline)
                        .foregroundStyle(SNP.textMuted)
                } else {
                    Text(splitCopy)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(SNP.text)
                    Text("Leftover pennies sit on your seat. You covered the bill — they agree, then settle.")
                        .font(.caption)
                        .foregroundStyle(SNP.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var postButton: some View {
        Button {
            let people = service.network.filter { selected.contains($0.id) }
            let payment = service.createSharedExpense(
                note: note,
                amountCents: cents,
                category: category,
                people: people
            )
            dismiss()
            onCreated(payment)
        } label: {
            Text("Add bill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(SNP.accent)
        .disabled(!canPost)
        .padding(.bottom, 8)
    }

    private var canPost: Bool {
        cents > 0 && !selected.isEmpty && !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
